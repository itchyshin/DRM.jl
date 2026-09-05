#!/usr/bin/env julia
# Fixed-point arithmetic only: never call an inner solver or an outer optimiser.
using DRM, Serialization, SHA, LinearAlgebra, SparseArrays
const ROOT = "/private/tmp/drm-parity-20260830/profile-threads-s11"
const INPUT = joinpath(ROOT,"post-compensation-profile","post-compensation-profile-20260831T175800Z.jls")
const INPUT_SHA = "fabf3e4c1a7d016ecff94a6926944553bb5238a744f03d178b7e3548e9d6c89c"
const STAMP = get(ENV,"S11_STAMP","UNSET")
const OUTDIR = @__DIR__
const SOURCE_FILES=["src/locscale_inner.jl","src/locscale_grad.jl","src/locscale_marginal.jl","src/locscale_fit.jl","src/locscale_infer.jl"]
sha256_file(p)=bytes2hex(sha256(read(p)))
hashes()=Dict(p=>sha256_file(p) for p in SOURCE_FILES)

function lc_L(lambda)
    u,c,v=lambda
    return [exp(u) 0.0; c exp(v)]
end
function block_B(L,G,T=Float64)
    B=zeros(T,2G,2G)
    for g in 1:G
        B[2g-1:2g,2g-1:2g] .= T.(L)
    end
    B
end
safe_cond(A) = try cond(Matrix(A)) catch; NaN end
function safe_logdet(A)
    ch=cholesky(Symmetric(Matrix(A));check=false)
    return issuccess(ch) ? 2sum(log,diag(ch.L)) : NaN
end
function freeze_state(e,d)
    theta=e.theta; lambda=theta[4:6]; a=copy(e.cold_mode)
    eta=d.Xmu*theta[1:2]; psi=d.Xpsi*theta[3:3]
    nll=Vector{Float64}(undef,length(d.y))
    @inbounds for i in eachindex(d.y)
        g=d.gidx[i]; nll[i]=DRM._ls_nll(d.kind,d.y[i],eta[i]+a[2g-1],psi[i]+a[2g])
    end
    D=Matrix(DRM._ls_joint_hess(d.kind,d.y,eta,psi,d.gidx,d.G,a,spzeros(2d.G,2d.G)))
    return (;theta,lambda,a,eta,psi,nll,D)
end
function big_reference(f,d)
    setprecision(BigFloat,256) do
        G=d.G; lambda=BigFloat.(f.lambda); a=BigFloat.(f.a); D=BigFloat.(f.D)
        L=BigFloat[exp(lambda[1]) 0; lambda[2] exp(lambda[3])]
        B=block_B(L,G,BigFloat); C=kron(BigFloat.(Matrix(d.Q)),Matrix{BigFloat}(I,2,2))
        z=B\a; Binv=B\Matrix{BigFloat}(I,2G,2G); P=transpose(Binv)*C*Binv
        H=P+D; Hz=C+transpose(B)*D*B
        Jdata=sum(BigFloat.(f.nll)); Moriginal=Jdata+dot(a,P*a)/2+logdet(Symmetric(H))/2-logdet(Symmetric(P))/2
        Mwhiten=Jdata+dot(z,C*z)/2+logdet(Symmetric(Hz))/2-logdet(Symmetric(C))/2
        return (;L,B,C,z,P,H,Hz,Jdata,Moriginal,Mwhiten,identity_error=Moriginal-Mwhiten)
    end
end
function one_state(e,d)
    f=freeze_state(e,d); G=d.G
    P64=DRM.prior_precision(d.Q,DRM._ls_inv2x2(DRM._ls_lc_to_Λ(f.lambda)))
    H64=Matrix(P64)+f.D; L64=lc_L(f.lambda); B64=block_B(L64,G)
    Cint=kron(Matrix(d.Q),Matrix{Float64}(I,2,2)); z64=B64\f.a
    Hzint=Cint+transpose(B64)*f.D*B64
    # Distinct frozen-P target: this preserves the already rounded production P.
    Cfreeze=transpose(B64)*Matrix(P64)*B64; Hzfreeze=Cfreeze+transpose(B64)*f.D*B64
    Jdata64=sum(f.nll)
    Moriginal=Jdata64+dot(f.a,Matrix(P64)*f.a)/2+safe_logdet(H64)/2-safe_logdet(Matrix(P64))/2
    Mintended=Jdata64+dot(z64,Cint*z64)/2+safe_logdet(Hzint)/2-safe_logdet(Cint)/2
    MfrozenP=Jdata64+dot(z64,Cfreeze*z64)/2+safe_logdet(Hzfreeze)/2-safe_logdet(Cfreeze)/2
    ref=big_reference(f,d)
    return (idx=e.idx,side=e.side,cold_mode_accepted=e.cold_inner_ok,
      theta=f.theta,a=f.a,frozen_nll=f.nll,frozen_D=f.D,
      original=(M64=Moriginal,H_condition=safe_cond(H64),P_condition=safe_cond(P64),H_logdet=safe_logdet(H64),P_logdet=safe_logdet(Matrix(P64))),
      intended_whitening=(M64=Mintended,roundtrip_maxabs=maximum(abs,B64*z64-f.a),H_condition=safe_cond(Hzint),C_logdet=safe_logdet(Cint),Hz_logdet=safe_logdet(Hzint),target=:intended_L_Q),
      frozenP64_whitening=(M64=MfrozenP,roundtrip_maxabs=maximum(abs,B64*z64-f.a),H_condition=safe_cond(Hzfreeze),C_target_maxabs=maximum(abs,Cfreeze-Cint),target=:B64_transpose_P64_B64),
      big_reference=(Moriginal=ref.Moriginal,Mwhiten=ref.Mwhiten,identity_error=ref.identity_error,
        original_surrogate_abs_error=abs(BigFloat(Moriginal)-ref.Moriginal),
        intended_surrogate_abs_error=abs(BigFloat(Mintended)-ref.Mwhiten),
        frozenP64_surrogate_abs_error=abs(BigFloat(MfrozenP)-ref.Moriginal),
        intended_mapping_maxabs=maximum(abs,BigFloat.(B64)*BigFloat.(z64)-BigFloat.(f.a)),
        highprecision_point_uses=:exact_Float64_a_true_BigFloat_L_solve))
end
function main()
    STAMP=="UNSET" && error("set fresh actual UTC S11_STAMP")
    before=hashes(); @assert sha256_file(INPUT)==INPUT_SHA
    input=deserialize(INPUT); @assert input.unchanged
    cases=[one_state(e,input.design) for e in input.endpoints]
    after=hashes()
    receipt=(kind=:whitened_fixed_point_arithmetic_no_mode_evidence,input_sha256=INPUT_SHA,
      before_hashes=before,after_hashes=after,source_unchanged=(before==after),cases=cases,
      scope="fixed frozen Float64 NLL/Hessian values only; not a mode or solver acceptance diagnostic",
      script_source=read(@__FILE__,String),stamp=STAMP)
    out=joinpath(OUTDIR,"whitened-fixed-point-$(STAMP).jls"); serialize(out,receipt)
    println("S11_WHITENED_FIXED_POINT_RECEIPT ",out)
    @assert receipt.source_unchanged
end
main()
