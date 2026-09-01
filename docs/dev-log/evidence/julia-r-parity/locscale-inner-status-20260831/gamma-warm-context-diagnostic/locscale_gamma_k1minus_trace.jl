using DRM
using Random, SparseArrays, LinearAlgebra, SHA
import Distributions
const ROOT="/private/tmp/drm-parity-20260830/integration/DRM.jl"

function inputs()
    Random.seed!(20_260_831); G,m=4,8; n=G*m; species=repeat(1:G,inner=m)
    x=repeat(range(-1.0,1.0;length=m),G)
    eta=.70 .+ .55 .* x .+ (.16 .* randn(G))[species]
    psi=1.05 .+ (.10 .* randn(G))[species]
    y=[begin shape=exp(psi[i]); mu=exp(eta[i]); Float64(rand(Distributions.Gamma(shape,mu/shape))) end for i in 1:n]
    return y,hcat(ones(n),x),ones(n,1),species,G,sparse(1.0I,G,G)
end

function trace_inner(kind,y,eta0,psi0,gidx,G,P,a0;tol=1e-9,maxiter=200)
    Zeta=DRM._ls_canonical_Zeta(length(y)); Zpsi=DRM._ls_canonical_Zpsi(length(y))
    a=copy(a0); last=nothing
    for iter in 1:maxiter
        grad=DRM._ls_joint_grad(kind,y,eta0,psi0,gidx,a,P,Zeta,Zpsi)
        anorm=norm(a); gnorm=norm(grad); bound=tol*(1+anorm)
        if all(isfinite,a) && all(isfinite,grad) && isfinite(anorm) && isfinite(gnorm) &&
           isfinite(bound) && gnorm<=bound
            ch,ok=DRM._ls_inner_certificate(kind,y,eta0,psi0,gidx,G,P,Zeta,Zpsi,a,tol)
            return (;reason=:early,iter,a,ok,gnorm,bound,last)
        end
        H=DRM._ls_joint_hess(kind,y,eta0,psi0,gidx,G,a,P,Zeta,Zpsi)
        DRM._ls_allfinite(H) || return (;reason=:nonfinite_hessian,iter,a,ok=false,gnorm,bound,last)
        f0=DRM._ls_joint(kind,y,eta0,psi0,gidx,a,P,Zeta,Zpsi)
        lambda=0.0; stepped=false
        while true
            F=cholesky(Symmetric(H+lambda*I);check=false)
            if issuccess(F)
                step=F \ grad; alpha=1.0
                while alpha>=1e-10
                    trial=a .- alpha.*step
                    ft=DRM._ls_joint(kind,y,eta0,psi0,gidx,trial,P,Zeta,Zpsi)
                    if lambda==0.0 && alpha==1.0
                        tg=DRM._ls_joint_grad(kind,y,eta0,psi0,gidx,trial,P,Zeta,Zpsi)
                        tch=DRM._ls_hess_chol(kind,y,eta0,psi0,gidx,G,trial,P,Zeta,Zpsi)
                        estimate=DRM._ls_inner_estimated_change(kind,y,eta0,psi0,gidx,G,P,Zeta,Zpsi,a,trial)
                        last=(;f0,ft,raw=ft-f0,trial,a,displacement=norm(trial-a),
                               locality=sqrt(eps(Float64))*(1+norm(a)),
                               predicted=dot(grad,step),gradnorm=gnorm,
                               trial_gradnorm=norm(tg),trial_bound=tol*(1+norm(trial)),
                               trial_pd=issuccess(tch),
                               estimate=estimate===nothing ? nothing : estimate.estimate,
                               error=estimate===nothing ? nothing : estimate.error,
                               margin=estimate===nothing ? nothing : estimate.margin)
                    end
                    if all(trial .== a); break; end
                    if all(isfinite,trial) && isfinite(ft) && ft<=f0
                        a=trial; stepped=true; break
                    end
                    if lambda==0.0 && alpha==1.0
                        ch,polished=DRM._ls_inner_rounding_polish(kind,y,eta0,psi0,gidx,G,P,Zeta,Zpsi,
                                                                   a,grad,step,f0,trial,ft,tol)
                        polished && return (;reason=:polished,iter,a=trial,ok=true,
                                             gnorm=norm(DRM._ls_joint_grad(kind,y,eta0,psi0,gidx,trial,P,Zeta,Zpsi)),
                                             bound=tol*(1+norm(trial)),last)
                    end
                    alpha*=0.5
                end
                stepped && break
            end
            lambda=lambda==0.0 ? 1e-8 : 10lambda
            lambda>1e12 && break
        end
        stepped || return (;reason=:step_rejected,iter,a,ok=false,gnorm,bound,last)
    end
    ch,ok=DRM._ls_inner_certificate(kind,y,eta0,psi0,gidx,G,P,Zeta,Zpsi,a,tol)
    return (;reason=:budget,iter=maxiter,a,ok,gnorm=norm(DRM._ls_joint_grad(kind,y,eta0,psi0,gidx,a,P,Zeta,Zpsi)),
             bound=tol*(1+norm(a)),last)
end

y,Xmu,Xpsi,gidx,G,Q=inputs()
theta=[0.6370344140473198 - 1e-5,0.24410249013547608,1.4752127409228124,
       -1.6628726394324707,-0.0960544541933801,-7.410523644260694]
a0=[-0.19461120443594232,0.09859649213346595,0.13400068536422194,-0.0678899460768282,
    0.12409547734767255,-0.06287024953287514,-0.1075471663780886,0.054487480395986596]
P=DRM.prior_precision(Q,DRM._ls_inv2x2(DRM._ls_lc_to_Λ(theta[4:6])))
eta0=Xmu*theta[1:2]; psi0=Xpsi*theta[3:3]
Zeta=DRM._ls_canonical_Zeta(length(y)); Zpsi=DRM._ls_canonical_Zpsi(length(y))
direct_a,direct_ch,direct_inner_ok = DRM._ls_inner_mode(Val(:gamma),y,eta0,psi0,gidx,G,P,Zeta,Zpsi; a0=a0)
direct_prior_ch = cholesky(Symmetric(P); check=false)
direct_nll,direct_marg_a,direct_marg_ok = DRM._ls_marginal_nll(Val(:gamma),y,eta0,psi0,gidx,G,P,Zeta,Zpsi; a0=a0)
println("DIRECT_INNER_OK ", direct_inner_ok)
println("DIRECT_INNER_A ", repr(direct_a))
println("DIRECT_INNER_GRADNORM ", norm(DRM._ls_joint_grad(Val(:gamma),y,eta0,psi0,gidx,direct_a,P,Zeta,Zpsi)))
println("DIRECT_INNER_H_OK ", issuccess(direct_ch))
println("DIRECT_PRIOR_OK ", issuccess(direct_prior_ch))
println("DIRECT_JOINT ", DRM._ls_joint(Val(:gamma),y,eta0,psi0,gidx,direct_a,P,Zeta,Zpsi))
println("DIRECT_MARG_OK ", direct_marg_ok)
println("DIRECT_MARG_A_MATCH ", direct_marg_a == direct_a)
println("DIRECT_MARG_NLL ", direct_nll)
result=trace_inner(Val(:gamma),y,eta0,psi0,gidx,G,P,a0)
println("GAMMA_K1_MINUS_TRACE")
println("SOURCE_SHA ",bytes2hex(sha256(read(joinpath(ROOT,"src/locscale_inner.jl")))))
println("RESULT ",repr(result))
println("GAMMA_K1_MINUS_TRACE_COMPLETE")
