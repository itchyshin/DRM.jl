using DRM, Random, LinearAlgebra, SparseArrays
import Distributions

function replay_inner(kind, y, eta0, psi0, gidx, G, P; maxiter=200, tol=1e-9)
    Zeta = DRM._ls_canonical_Zeta(length(y)); Zpsi = DRM._ls_canonical_Zpsi(length(y))
    a = zeros(2G)
    last = nothing
    for iter in 1:maxiter
        grad = DRM._ls_joint_grad(kind, y, eta0, psi0, gidx, a, P, Zeta, Zpsi)
        anorm, gnorm = norm(a), norm(grad)
        bound = tol * (1 + anorm)
        if all(isfinite, a) && all(isfinite, grad) && isfinite(anorm) && isfinite(gnorm) && isfinite(bound) && gnorm <= bound
            ch = DRM._ls_hess_chol(kind, y, eta0, psi0, gidx, G, a, P, Zeta, Zpsi)
            return (; a, ok=issuccess(ch), reason=:early_stationary, iter, anorm, gnorm, bound, last, ch)
        end
        H = DRM._ls_joint_hess(kind, y, eta0, psi0, gidx, G, a, P, Zeta, Zpsi)
        f0 = DRM._ls_joint(kind, y, eta0, psi0, gidx, a, P, Zeta, Zpsi)
        lambda = 0.0; stepped = false; finaltrial = nothing
        while true
            F = cholesky(Symmetric(H + lambda * I); check=false)
            if issuccess(F)
                step = F \ grad
                alpha = 1.0
                while alpha >= 1e-10
                    trial = a .- alpha .* step
                    ft = DRM._ls_joint(kind, y, eta0, psi0, gidx, trial, P, Zeta, Zpsi)
                    finaltrial = (; f0, ft, alpha, lambda, stepnorm=norm(step), trialgradnorm=norm(DRM._ls_joint_grad(kind, y, eta0, psi0, gidx, trial, P, Zeta, Zpsi)))
                    if isfinite(ft) && ft <= f0
                        a = trial; stepped = true; break
                    end
                    alpha *= 0.5
                end
                stepped && break
            end
            lambda = lambda == 0.0 ? 1e-8 : 10lambda
            lambda > 1e12 && break
        end
        last = finaltrial
        if !stepped
            ch = DRM._ls_hess_chol(kind, y, eta0, psi0, gidx, G, a, P, Zeta, Zpsi)
            return (; a, ok=false, reason=:step_rejected, iter, anorm, gnorm, bound, last, ch)
        end
    end
    ch, ok = DRM._ls_inner_certificate(kind, y, eta0, psi0, gidx, G, P, Zeta, Zpsi, a, tol)
    grad = DRM._ls_joint_grad(kind, y, eta0, psi0, gidx, a, P, Zeta, Zpsi)
    anorm, gnorm = norm(a), norm(grad)
    return (; a, ok, reason=:budget_certificate, iter=maxiter, anorm, gnorm, bound=tol*(1+anorm), last, ch)
end

function fixture_state(kind, y, Xmu, Xpsi, gidx, G, Q, theta)
    pmu, ppsi = size(Xmu,2), size(Xpsi,2)
    lambda = theta[pmu+ppsi+1:pmu+ppsi+3]
    P = DRM.prior_precision(Q, DRM._ls_inv2x2(DRM._ls_lc_to_Λ(lambda)))
    return Xmu * theta[1:pmu], Xpsi * theta[pmu+1:pmu+ppsi], P
end

function report_point(tag, kind, y, Xmu, Xpsi, gidx, G, Q, theta)
    eta0, psi0, P = fixture_state(kind, y, Xmu, Xpsi, gidx, G, Q, theta)
    replay = replay_inner(kind, y, eta0, psi0, gidx, G, P)
    a, ch, ok = DRM._ls_inner_mode(kind, y, eta0, psi0, gidx, G, P)
    ga = DRM._ls_marginal_grad(kind, y, Xmu, Xpsi, gidx, G, Q, theta)
    value = DRM._ls_fit_nll(kind, y, Xmu, Xpsi, gidx, G, Q, theta)
    println("POINT ", tag,
            " value=", value,
            " inner_ok=", ok,
            " replay_ok=", replay.ok,
            " reason=", replay.reason,
            " iter=", replay.iter,
            " finite_a=", all(isfinite, a),
            " finite_grad=", all(isfinite, DRM._ls_joint_grad(kind,y,eta0,psi0,gidx,a,P)),
            " gnorm=", replay.gnorm,
            " bound=", replay.bound,
            " ch=", issuccess(ch),
            " replay_match=", isapprox(a,replay.a; rtol=0, atol=0),
            " ga_finite=", all(isfinite, ga),
            " ga_maxabs=", maximum(abs.(ga)))
    if replay.last !== nothing
        x = replay.last
        println("LAST ", tag, " f0=", x.f0, " ft=", x.ft, " alpha=", x.alpha,
                " lambda=", x.lambda, " stepnorm=", x.stepnorm,
                " trial_gnorm=", x.trialgradnorm)
    end
    return (; value, ga, replay)
end

function diagnose(name, kind, y, Xmu, Xpsi, gidx, G, Q, theta)
    println("FIXTURE ", name, " p=", length(theta))
    base = report_point(name*":base", kind,y,Xmu,Xpsi,gidx,G,Q,theta)
    h=1e-6; gfd=zeros(length(theta))
    for k in eachindex(theta)
        tp=copy(theta); tm=copy(theta); tp[k]+=h; tm[k]-=h
        plus=report_point(name*":plus"*string(k), kind,y,Xmu,Xpsi,gidx,G,Q,tp)
        minus=report_point(name*":minus"*string(k), kind,y,Xmu,Xpsi,gidx,G,Q,tm)
        gfd[k]=(plus.value-minus.value)/(2h)
    end
    println("FD ",name," finite=",all(isfinite,gfd)," maxabs=",maximum(abs.(gfd)),
            " exact_finite=",all(isfinite,base.ga)," maxerror=",maximum(abs.(base.ga.-gfd)),
            " tolerance=",1e-4*(1+maximum(abs.(gfd)))," exact=",base.ga," fd=",gfd)
end

Random.seed!(202)
G=5; m=6; n=G*m; gidx=repeat(1:G,inner=m)
x=randn(n); z=randn(n); Xmu=hcat(ones(n),x); Xpsi=hcat(ones(n),z)
L=cholesky(Symmetric(DRM._ls_lc_to_Λ([log(.35),.05,log(.4)]))).L
A=[L*randn(2) for _ in 1:G]
ygamma=[begin alpha=exp(.5+A[gidx[i]][2]); mu=exp(.2+.3x[i]+A[gidx[i]][1]); rand(Distributions.Gamma(alpha,mu/alpha)) end for i in 1:n]
diagnose("gamma_iid",Val(:gamma),ygamma,Xmu,Xpsi,gidx,G,sparse(1.0I,G,G),[.15,.25,.4,.06,log(.4),.05,log(.45)])

Random.seed!(303)
p=6; m=6; n=p*m; phy=random_balanced_tree(p;branch_length=.25)
C=sigma_phy_dense(phy;σ²_phy=1.0); LC=cholesky(Symmetric(C)).L
LΛ=cholesky(Symmetric(DRM._ls_lc_to_Λ([log(.4),0.,log(.3)]))).L
A=LC*randn(p,2)*LΛ'; species=repeat(1:p,inner=m); x=randn(n); z=randn(n); Xmu=hcat(ones(n),x); Xpsi=hcat(ones(n),z)
ynb=[begin r=exp(.2+A[species[i],2]); mu=exp(.15+.4x[i]+A[species[i],1]); Float64(rand(Distributions.NegativeBinomial(r,r/(r+mu)))) end for i in 1:n]
Q,gidx,G=DRM._locscale_phylo_setup(phy,species)
diagnose("nb2_phy",Val(:nb2),ynb,Xmu,Xpsi,gidx,G,Q,[.2,.3,.1,.04,log(.42),.05,log(.32)])
println("LOCSCALE_INNER_FD_DIAGNOSTIC_COMPLETE")
