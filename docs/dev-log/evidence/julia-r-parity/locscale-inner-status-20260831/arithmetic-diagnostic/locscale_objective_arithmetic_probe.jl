using DRM
using Random, LinearAlgebra, SparseArrays, Distributions, Serialization, SHA

const SOURCE = "/private/tmp/drm-parity-20260830/integration/DRM.jl/src/locscale_inner.jl"
const STATE_PATH = "/private/tmp/locscale_objective_arithmetic_states-001.jls"
const RECORDS = Any[]
const LAST_FULL = Ref{Any}(nothing)

@eval DRM begin
    const _arithmetic_records = Main.RECORDS
    const _arithmetic_last_full = Main.LAST_FULL
    function _arithmetic_snapshot(kind, y, eta, psi, gidx, G, P, Zeta, Zpsi,
                                  a, grad, step, f0, trial, ft, tol)
        return (kind=kind, y=copy(y), eta=copy(eta), psi=copy(psi), gidx=copy(gidx),
                G=G, P=copy(P), Zeta=copy(Zeta), Zpsi=copy(Zpsi), a=copy(a),
                trial=copy(trial), grad=copy(grad), step=copy(step), f0=f0, ft=ft,
                tol=tol)
    end
end

src = read(SOURCE, String)
start = findfirst("function _ls_inner_mode(", src)
solver = src[first(start):end]
solver = replace(solver, "function _ls_inner_mode(" => "function _arithmetic_inner_mode("; count=1)
solver = replace(solver,
    "a = a0 === nothing ? zeros(2G) : copy(a0)" =>
    "a = a0 === nothing ? zeros(2G) : copy(a0)\n    _arithmetic_last_full[] = nothing";
    count=1)
solver = replace(solver,
    "ft = _ls_joint(kind, y, η0, ψ0, gidx, trial, P, Zη, Zψ)" =>
    "ft = _ls_joint(kind, y, η0, ψ0, gidx, trial, P, Zη, Zψ)\n                    if λ == 0.0 && α == 1.0\n                        _arithmetic_last_full[] = _arithmetic_snapshot(\n                            kind, y, η0, ψ0, gidx, G, P, Zη, Zψ, a, grad, step, f0, trial, ft, tol)\n                    end";
    count=1)
Core.eval(DRM, Meta.parse(solver))
@eval DRM begin
    function _ls_inner_mode(kind, y, eta, psi, gidx, G, P,
                            Zeta = _ls_canonical_Zeta(length(y)),
                            Zpsi = _ls_canonical_Zpsi(length(y)); a0=nothing,
                            maxiter::Int=200, tol::Real=1e-9)
        a, ch, ok = _arithmetic_inner_mode(kind, y, eta, psi, gidx, G, P, Zeta, Zpsi;
                                             a0=a0, maxiter=maxiter, tol=tol)
        !ok && _arithmetic_last_full[] !== nothing && length(_arithmetic_records) < 4 &&
            push!(_arithmetic_records, _arithmetic_last_full[])
        return a, ch, ok
    end
end

function nb2_fixture()
    Random.seed!(424242); G=50; m=35; n=G*m; gidx=repeat(1:G, inner=m); x=randn(n)
    L=cholesky(Symmetric([0.25 0.05; 0.05 0.16])).L; A=[L*randn(2) for _ in 1:G]
    Xmu=hcat(ones(n),x); Xpsi=ones(n,1)
    y=[begin eta=.5+.4*x[i]+A[gidx[i]][1]; psi=.3+A[gidx[i]][2];
       r=exp(psi); mu=exp(eta); Float64(rand(NegativeBinomial(r,r/(r+mu)))) end for i in 1:n]
    return Val(:nb2),y,Xmu,Xpsi,gidx,G,sparse(1.0I,G,G)
end
function gamma_fixture()
    Random.seed!(20_260_831); G=4; m=8; n=G*m; gidx=repeat(1:G,inner=m)
    x=repeat(range(-1.,1.;length=m),G); eta = 0.70 .+ 0.55 .* x .+ (0.16 .* randn(G))[gidx]
    psi = 1.05 .+ (0.10 .* randn(G))[gidx]
    y=[Float64(rand(Distributions.Gamma(exp(psi[i]),exp(eta[i])/exp(psi[i])))) for i in 1:n]
    return Val(:gamma),y,hcat(ones(n),x),ones(n,1),gidx,G,sparse(1.0I,G,G)
end

function neumaier(xs)
    s=0.0; c=0.0
    for x in xs
        t=s+x
        c += abs(s) >= abs(x) ? (s-t)+x : (x-t)+s
        s=t
    end
    return s+c
end
function terms_float(s, a)
    n=length(s.y); out=Vector{Float64}(undef,n+1)
    @inbounds for i in 1:n
        g=s.gidx[i]; eta=s.eta[i]+s.Zeta[i,1]*a[2g-1]+s.Zeta[i,2]*a[2g]
        psi=s.psi[i]+s.Zpsi[i,1]*a[2g-1]+s.Zpsi[i,2]*a[2g]
        out[i]=DRM._ls_nll(s.kind,s.y[i],eta,psi)
    end
    out[end]=0.5*dot(a,s.P*a)
    return out
end
function high_precision_recompute(s,a)
    setprecision(BigFloat,256) do
        total=BigFloat(0)
        for i in eachindex(s.y)
            g=s.gidx[i]
            eta=BigFloat(s.eta[i])+BigFloat(s.Zeta[i,1])*BigFloat(a[2g-1])+BigFloat(s.Zeta[i,2])*BigFloat(a[2g])
            psi=BigFloat(s.psi[i])+BigFloat(s.Zpsi[i,1])*BigFloat(a[2g-1])+BigFloat(s.Zpsi[i,2])*BigFloat(a[2g])
            total += DRM._ls_nll(s.kind,BigFloat(s.y[i]),eta,psi)
        end
        prior=BigFloat(0)
        for j in axes(s.P,2), i in axes(s.P,1)
            prior += BigFloat(a[i])*BigFloat(s.P[i,j])*BigFloat(a[j])
        end
        return total+prior/2
    end
end
function summarize(name,s)
    tf=terms_float(s,s.a); tt=terms_float(s,s.trial)
    current_a=DRM._ls_joint(s.kind,s.y,s.eta,s.psi,s.gidx,s.a,s.P,s.Zeta,s.Zpsi)
    current_t=DRM._ls_joint(s.kind,s.y,s.eta,s.psi,s.gidx,s.trial,s.P,s.Zeta,s.Zpsi)
    compensated_a=neumaier(tf); compensated_t=neumaier(tt)
    hp_sum_a=setprecision(256) do; sum(BigFloat.(tf)); end
    hp_sum_t=setprecision(256) do; sum(BigFloat.(tt)); end
    println("STATE ",name," source_f0=",repr(s.f0)," source_ft=",repr(s.ft))
    println("FLOAT_CURRENT a=",repr(current_a)," trial=",repr(current_t)," delta=",repr(current_t-current_a))
    println("FLOAT_NEUMAIER a=",repr(compensated_a)," trial=",repr(compensated_t)," delta=",repr(compensated_t-compensated_a))
    println("BIGFLOAT_SUM_OF_FLOAT_TERMS a=",hp_sum_a," trial=",hp_sum_t," delta=",hp_sum_t-hp_sum_a)
    try
        hp_a=high_precision_recompute(s,s.a); hp_t=high_precision_recompute(s,s.trial)
        println("BIGFLOAT_RECOMPUTED a=",hp_a," trial=",hp_t," delta=",hp_t-hp_a)
    catch err
        println("BIGFLOAT_RECOMPUTED_UNSUPPORTED ",typeof(err)," ",sprint(showerror,err))
    end
end
function recover_failure(name,fixture)
    empty!(RECORDS); kind,y,Xmu,Xpsi,gidx,G,Q=fixture()
    fit=DRM._fit_locscale(kind,y,Xmu,Xpsi,gidx,G,Q;se=false)
    pmu=size(Xmu,2); ppsi=size(Xpsi,2)
    Lambda=DRM._ls_lc_to_Λ(fit.θ[pmu+ppsi+1:pmu+ppsi+3])
    P=DRM.prior_precision(Q,DRM._ls_inv2x2(Lambda))
    _,a,_=DRM._ls_marginal_nll(kind,y,Xmu*fit.θ[1:pmu],Xpsi*fit.θ[pmu+1:pmu+ppsi],gidx,G,P;a0=nothing)
    empty!(RECORDS)
    DRM._ls_obs_information(kind,y,Xmu,Xpsi,gidx,G,Q,fit.θ;h=1e-5,a0=a)
    isempty(RECORDS) && error("no rejected full Newton trial captured for ",name)
    s=RECORDS[1]
    println("CASE ",name," theta_finite=",all(isfinite,fit.θ)," obs_records=",length(RECORDS))
    return s
end
println("SOURCE_SHA ",bytes2hex(sha256(read(SOURCE))))
println("THREADS ",Threads.nthreads()," BLAS ",BLAS.get_num_threads())
states=Dict("nb2"=>recover_failure("NB2_RECOVERY_424242_G50_M35",nb2_fixture),
            "gamma"=>recover_failure("GAMMA_STATUS_20260831_G4_M8",gamma_fixture))
serialize(STATE_PATH,states)
println("STATE_SHA ",bytes2hex(sha256(read(STATE_PATH))))
for (name,s) in states; summarize(name,s); end
