using DRM
using Distributions, LinearAlgebra, Random, SparseArrays, SHA

const ROOT = "/private/tmp/drm-parity-20260830/integration/DRM.jl"

function smoke_inputs()
    Random.seed!(20_260_831)
    G, m = 4, 8
    n = G * m
    species = repeat(1:G, inner=m)
    x = repeat(range(-1.0, 1.0; length=m), G)
    eta = 0.70 .+ 0.55 .* x .+ (0.16 .* randn(G))[species]
    psi = 1.05 .+ (0.10 .* randn(G))[species]
    y = [begin
        shape = exp(psi[i]); mu = exp(eta[i])
        Float64(rand(Distributions.Gamma(shape, mu / shape)))
    end for i in 1:n]
    return y, hcat(ones(n), x), ones(n,1), species, G, sparse(1.0I,G,G)
end

function unpack(kind, y, Xmu, Xpsi, gidx, G, Q, theta)
    pmu, ppsi = size(Xmu,2), size(Xpsi,2)
    beta_mu = @view theta[1:pmu]
    beta_psi = @view theta[pmu+1:pmu+ppsi]
    lambda = @view theta[pmu+ppsi+1:pmu+ppsi+3]
    P = DRM.prior_precision(Q, DRM._ls_inv2x2(DRM._ls_lc_to_Λ(lambda)))
    return Xmu*beta_mu, Xpsi*beta_psi, P
end

function clamp_range(eta0, psi0, gidx, a)
    etas=Float64[]; psis=Float64[]
    for i in eachindex(gidx)
        g=gidx[i]
        push!(etas, eta0[i] + a[2g-1])
        push!(psis, psi0[i] + a[2g])
    end
    return (eta=(minimum(etas),maximum(etas)), psi=(minimum(psis),maximum(psis)))
end

# Copy-only trace of the current source loop, recording the last full undamped
# trial and terminal condition. It intentionally never changes the estimator.
function trace_inner(kind, y, eta0, psi0, gidx, G, P, a0; maxiter=200, tol=1e-9)
    a=copy(a0); last=nothing
    for iter in 1:maxiter
        grad=DRM._ls_joint_grad(kind,y,eta0,psi0,gidx,a,P)
        anorm=norm(a); gnorm=norm(grad); bound=tol*(1+anorm)
        if all(isfinite,a) && all(isfinite,grad) && isfinite(anorm) && isfinite(gnorm) &&
           isfinite(bound) && gnorm<=bound
            ch, certified=DRM._ls_inner_certificate(kind,y,eta0,psi0,gidx,G,P,
                                                     DRM._ls_canonical_Zeta(length(y)),
                                                     DRM._ls_canonical_Zpsi(length(y)),a,tol)
            return (; reason=:early,iter,a,ok=certified,last,gnorm,bound,range=clamp_range(eta0,psi0,gidx,a))
        end
        H=DRM._ls_joint_hess(kind,y,eta0,psi0,gidx,G,a,P)
        DRM._ls_allfinite(H) || return (;reason=:nonfinite_H,iter,a,ok=false,last,gnorm,bound,range=clamp_range(eta0,psi0,gidx,a))
        f0=DRM._ls_joint(kind,y,eta0,psi0,gidx,a,P)
        lambda=0.0; stepped=false
        while true
            F=cholesky(Symmetric(H + lambda*I);check=false)
            if issuccess(F)
                step=F \ grad; alpha=1.0
                while alpha>=1e-10
                    trial=a .- alpha.*step
                    ft=DRM._ls_joint(kind,y,eta0,psi0,gidx,trial,P)
                    if lambda==0.0 && alpha==1.0
                        tg=DRM._ls_joint_grad(kind,y,eta0,psi0,gidx,trial,P)
                        tch=DRM._ls_hess_chol(kind,y,eta0,psi0,gidx,G,trial,P)
                        est=DRM._ls_inner_estimated_change(kind,y,eta0,psi0,gidx,G,P,
                                                            DRM._ls_canonical_Zeta(length(y)),
                                                            DRM._ls_canonical_Zpsi(length(y)),a,trial)
                        last=(;f0,ft,raw=ft-f0,trial,trial_finite=all(isfinite,trial),
                               displacement=norm(trial-a),locality=sqrt(eps(Float64))*(1+norm(a)),
                               gradnorm=gnorm,trial_gradnorm=norm(tg),
                               trial_bound=tol*(1+norm(trial)),predicted=dot(grad,step),
                               trial_pd=issuccess(tch),estimated=est)
                    end
                    if all(trial .== a); break; end
                    if all(isfinite,trial) && isfinite(ft) && ft<=f0
                        a=trial; stepped=true; break
                    end
                    if lambda==0.0 && alpha==1.0
                        ch, polished=DRM._ls_inner_rounding_polish(kind,y,eta0,psi0,gidx,G,P,
                                                                   DRM._ls_canonical_Zeta(length(y)),
                                                                   DRM._ls_canonical_Zpsi(length(y)),
                                                                   a,grad,step,f0,trial,ft,tol)
                        polished && return (;reason=:polished,iter,a=trial,ok=true,last,
                                             gnorm=norm(DRM._ls_joint_grad(kind,y,eta0,psi0,gidx,trial,P)),
                                             bound=tol*(1+norm(trial)),range=clamp_range(eta0,psi0,gidx,trial))
                    end
                    alpha *= .5
                end
                stepped && break
            end
            lambda=lambda==0 ? 1e-8 : 10lambda
            lambda>1e12 && break
        end
        stepped || return (;reason=:rejected,iter,a,ok=false,last,gnorm,bound,range=clamp_range(eta0,psi0,gidx,a))
    end
    ch,ok=DRM._ls_inner_certificate(kind,y,eta0,psi0,gidx,G,P,
                                    DRM._ls_canonical_Zeta(length(y)),
                                    DRM._ls_canonical_Zpsi(length(y)),a,tol)
    return (;reason=:budget,iter=maxiter,a,ok,last,
             gnorm=norm(DRM._ls_joint_grad(kind,y,eta0,psi0,gidx,a,P)),
             bound=tol*(1+norm(a)),range=clamp_range(eta0,psi0,gidx,a))
end

function shorttrace(t)
    last=t.last
    return (; reason=t.reason, iter=t.iter, ok=t.ok, gnorm=t.gnorm, bound=t.bound,
             range=t.range, last=last === nothing ? nothing :
               (; raw=last.raw, displacement=last.displacement, locality=last.locality,
                  gradnorm=last.gradnorm, trial_gradnorm=last.trial_gradnorm,
                  trial_bound=last.trial_bound, predicted=last.predicted,
                  trial_finite=last.trial_finite, trial_pd=last.trial_pd,
                  estimate=last.estimated === nothing ? nothing : last.estimated.estimate,
                  error=last.estimated === nothing ? nothing : last.estimated.error,
                  margin=last.estimated === nothing ? nothing : last.estimated.margin))
end

y,Xmu,Xpsi,gidx,G,Q=smoke_inputs()
fit=DRM._fit_locscale(Val(:gamma),y,Xmu,Xpsi,gidx,G,Q;se=false)
eta0,psi0,P=unpack(Val(:gamma),y,Xmu,Xpsi,gidx,G,Q,fit.θ)
base_nll,a_hat,base_ok=DRM._ls_marginal_nll(Val(:gamma),y,eta0,psi0,gidx,G,P)
println("GAMMA_VCOV_INNER_DIAGNOSTIC")
println("SOURCE_SHA ",bytes2hex(sha256(read(joinpath(ROOT, "src/locscale_inner.jl")))))
println("FIT theta=",repr(fit.θ)," converged=",fit.converged," nll=",fit.nll,
        " base_ok=",base_ok," base_nll=",base_nll," a_hat_finite=",all(isfinite,a_hat))
for k in eachindex(fit.θ), sign in (-1.0,1.0)
    theta=copy(fit.θ); theta[k]+=sign*1e-5
    eta,psi,Pside=unpack(Val(:gamma),y,Xmu,Xpsi,gidx,G,Q,theta)
    value,a,ok=DRM._ls_marginal_nll(Val(:gamma),y,eta,psi,gidx,G,Pside;a0=a_hat)
    gradient=try DRM._ls_marginal_grad(Val(:gamma),y,Xmu,Xpsi,gidx,G,Q,theta;a0=a_hat) catch err; err end
    finite_grad=gradient isa AbstractVector && all(isfinite,gradient)
    trace=(!ok || !finite_grad) ? trace_inner(Val(:gamma),y,eta,psi,gidx,G,Pside,a_hat) : nothing
    println("SIDE k=",k," sign=",sign," nll=",repr(value)," inner_ok=",ok,
            " a_finite=",all(isfinite,a)," gradient=",gradient isa AbstractVector ? repr(gradient) : sprint(showerror,gradient),
            " gradient_finite=",finite_grad," trace=",trace === nothing ? "not_needed" : repr(shorttrace(trace)))
end
println("GAMMA_VCOV_INNER_DIAGNOSTIC_COMPLETE")
