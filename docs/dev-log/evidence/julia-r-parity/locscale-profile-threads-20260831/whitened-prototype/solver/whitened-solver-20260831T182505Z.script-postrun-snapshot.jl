#!/usr/bin/env julia
# Float64 whitening prototype. Solver-only: no outer fit and no production edits.
using DRM, Serialization, SHA, LinearAlgebra, SparseArrays
const ROOT="/private/tmp/drm-parity-20260830/profile-threads-s11"
const INPUT=joinpath(ROOT,"post-compensation-profile","post-compensation-profile-20260831T175800Z.jls")
const INPUT_SHA="fabf3e4c1a7d016ecff94a6926944553bb5238a744f03d178b7e3548e9d6c89c"
const HELPER=joinpath(ROOT,"whitened-oracle","fixed-outer-gamma-oracle-20260831T163817Z.script-snapshot.jl")
const HELPER_SHA="405f28114a2d665cf40bc8c4ec46ec324422a00a141250849e35bead4dace73d"
const STAMP=get(ENV,"S11_STAMP","UNSET"); const OUTDIR=@__DIR__
const SOURCE_FILES=["src/locscale_inner.jl","src/locscale_grad.jl","src/locscale_marginal.jl","src/locscale_fit.jl","src/locscale_infer.jl"]
sha256_file(p)=bytes2hex(sha256(read(p))); hashes()=Dict(p=>sha256_file(p) for p in SOURCE_FILES)

# Independent Gamma derivatives are imported once at top level before `main`.
function helper_definition(ex)
 ex isa LineNumberNode && return true; ex isa Expr || return false
 ex.head in (:using,:import,:const,:function,:macro) && return true
 return ex.head === :(=) && ex.args[1] isa Expr && ex.args[1].head === :call
end
@assert sha256_file(HELPER)==HELPER_SHA
for ex in Meta.parseall(read(HELPER,String)).args
 helper_definition(ex) || break
 ex isa LineNumberNode || Core.eval(@__MODULE__,ex)
end

function exact_design(retained)
 d=retained.design
 @assert d.G==4 && length(d.y)==32 && d.kind == Val(:gamma)
 @assert size(d.Xmu)==(32,2) && size(d.Xpsi)==(32,1) && length(d.gidx)==32
 return d
end
function L_from(lambda)
 [exp(lambda[1]) 0.0;lambda[2] exp(lambda[3])]
end
function blockB(L,G,T=Float64)
 B=zeros(T,2G,2G);for g in 1:G;B[2g-1:2g,2g-1:2g].=T.(L);end;B
end
function transformed_loadings(Z,L)
 Matrix{Float64}(Z*L)
end
function prediction_ok(d,eta0,psi0,state,Zeta,Zpsi)
 for i in eachindex(d.y)
  g=d.gidx[i]; eta=eta0[i]+Zeta[i,1]*state[2g-1]+Zeta[i,2]*state[2g]
  psi=psi0[i]+Zpsi[i,1]*state[2g-1]+Zpsi[i,2]*state[2g]
  (isfinite(eta)&&isfinite(psi)&&(-DRM.LS_CLAMP<eta<DRM.LS_CLAMP)&&(-DRM.LS_CLAMP<psi<DRM.LS_CLAMP)) || return false
 end
 return true
end
function independent_big_gradient(d,theta,a_input)
 setprecision(BigFloat,256) do
  G=d.G; lambda=BigFloat.(theta[4:6]); L=BigFloat[exp(lambda[1]) 0;lambda[2] exp(lambda[3])]
  B=blockB(L,G,BigFloat); C=kron(BigFloat.(Matrix(d.Q)),Matrix{BigFloat}(I,2,2)); Binv=B\Matrix{BigFloat}(I,2G,2G)
  P=transpose(Binv)*C*Binv; a=BigFloat.(a_input); g=P*a
  y=BigFloat.(d.y); theta_big=BigFloat.(theta)
  eb=BigFloat.(d.Xmu)*theta_big[1:2]; pb=BigFloat.(d.Xpsi)*theta_big[3:3]
  for i in eachindex(y)
   group=d.gidx[i]; _,ge,gp,_,_,_=gamma_data(y[i],eb[i]+a[2group-1],pb[i]+a[2group])
   g[2group-1]+=ge;g[2group]+=gp
  end
  return (gradient=g,L=L,B=B,C=C,P=P,a=a)
 end
end
function certificate(d,eta0,psi0,theta,B,z,Pz,Weta,Wpsi,Zeta,Zpsi)
 a=B*z; gz=DRM._ls_joint_grad(d.kind,d.y,eta0,psi0,d.gidx,z,Pz,Weta,Wpsi)
 ga=transpose(B)\gz; H=DRM._ls_joint_hess(d.kind,d.y,eta0,psi0,d.gidx,d.G,z,Pz,Weta,Wpsi)
 ch=cholesky(Symmetric(H);check=false); bound=1e-9*(1+norm(a))
 bigactual=independent_big_gradient(d,theta,a)
 aimplicit=bigactual.B*BigFloat.(z); bigimplicit=independent_big_gradient(d,theta,aimplicit)
 zback=B\a
 return (z=copy(z),a=copy(a),gz=copy(gz),ga=copy(ga),ga_l2=norm(ga),original_bound=bound,
  original_certificate=(all(isfinite,ga)&&norm(ga)<=bound),white_l2=norm(gz),hpd=issuccess(ch),
  finite_predictions_z=prediction_ok(d,eta0,psi0,z,Weta,Wpsi),finite_predictions_a=prediction_ok(d,eta0,psi0,a,Zeta,Zpsi),
  roundtrip_maxabs=maximum(abs,B*zback-a),zback_minus_z_maxabs=maximum(abs,zback-z),
  big_actual_l2=norm(bigactual.gradient),big_actual_certificate=(norm(bigactual.gradient)<=BigFloat(bound)),
  implicit_a=aimplicit,implicit_vs_actual_maxabs=maximum(abs,aimplicit-BigFloat.(a)),big_implicit_l2=norm(bigimplicit.gradient),
  big_implicit_certificate=(norm(bigimplicit.gradient)<=BigFloat(1e-9)*(1+norm(aimplicit))) )
end
function solve_attempt(d,eta0,psi0,theta,B,Pz,Weta,Wpsi,Zeta,Zpsi,z0,tol)
 elapsed=@elapsed z,ch,white_ok=DRM._ls_inner_mode(d.kind,d.y,eta0,psi0,d.gidx,d.G,Pz,Weta,Wpsi;a0=z0,tol=tol)
 cert=certificate(d,eta0,psi0,theta,B,z,Pz,Weta,Wpsi,Zeta,Zpsi)
 return (tol=tol,elapsed_seconds=elapsed,inner_returned_ok=white_ok,returned_hpd=(ch!==nothing&&issuccess(ch)),certificate=cert)
end
function endpoint(e,d)
 theta=e.theta;lambda=theta[4:6];eta0=d.Xmu*theta[1:2];psi0=d.Xpsi*theta[3:3]
 L=L_from(lambda);B=blockB(L,d.G);Pz=kron(d.Q,sparse(1.0I,2,2));Zeta=DRM._ls_canonical_Zeta(length(d.y));Zpsi=DRM._ls_canonical_Zpsi(length(d.y))
 Weta=transformed_loadings(Zeta,L);Wpsi=transformed_loadings(Zpsi,L);z0=B\e.cold_mode
 invLnorm=opnorm(inv(L)); tight_tol=1e-9/max(1.0,invLnorm)
 first=solve_attempt(d,eta0,psi0,theta,B,Pz,Weta,Wpsi,Zeta,Zpsi,z0,1e-9)
 second=(first.certificate.original_certificate || tight_tol>=1e-9) ? nothing : solve_attempt(d,eta0,psi0,theta,B,Pz,Weta,Wpsi,Zeta,Zpsi,z0,tight_tol)
 return (idx=e.idx,side=e.side,cold_mode_accepted=e.cold_inner_ok,theta=theta,start_a=copy(e.cold_mode),start_z=z0,
  L=L,invL_opnorm=invLnorm,white_tight_tol=tight_tol,Weta=Weta,Wpsi=Wpsi,first=first,second=second)
end
function main()
 STAMP=="UNSET"&&error("set fresh actual UTC S11_STAMP");before=hashes();@assert sha256_file(INPUT)==INPUT_SHA
 input=deserialize(INPUT);@assert input.unchanged;d=exact_design(input);cases=[endpoint(e,d) for e in input.endpoints];after=hashes()
 receipt=(kind=:float64_whitened_mode_solver_prototype,input_sha256=INPUT_SHA,helper_sha256=HELPER_SHA,before_hashes=before,after_hashes=after,source_unchanged=(before==after),cases=cases,
  scope="prototype only; actual returned-a original-coordinate and independent Big intended-L/Q certificates retained; not an outer-fit or production-approval result",script_source=read(@__FILE__,String),stamp=STAMP)
 out=joinpath(OUTDIR,"whitened-solver-$(STAMP).jls");serialize(out,receipt);println("S11_WHITENED_SOLVER_RECEIPT ",out);@assert receipt.source_unchanged
end
main()
