# fit_em_closed.jl — FAST correct EM using ONLY profiled-fast validated pieces.
# Root cause (profiled at p=100): finite-diff Λ gradient = 420ms = 2725× the
# 0.2ms closed-form Λ update. Fix: Λ update = closed-form direction (0.2ms,
# from current û + Takahashi) + WARM-started-E-step line search (1.2ms/eval),
# which prevents the closed-form's overshoot while staying ~50× faster than
# finite-diff and correct (line-searched on the TRUE Laplace marginal).
# Warm-start the E-step throughout. β by conditional Newton. No exact-gradient
# dependency, no Dual-through-sparse.
using LinearAlgebra, SparseArrays, ForwardDiff, Random, Statistics, Printf
include(joinpath(@__DIR__, "sparse_em_fit.jl"))

function marg_warm(prob, Q_cond, β, Λ, u0; nit=15)
    P = prior_precision(Q_cond, inv(Λ))
    u, ch, _ = estep_mode(prob, P, β; u0=u0, n_newton=nit)
    return laplace_ll(prob, P, β, u, ch), u, ch
end

# Λ block: closed-form direction + warm line search (NO finite-diff).
function lambda_step(prob, Q_cond, β, Λ, u, ch, ll0)
    Λem = mstep_Lambda(prob, Q_cond, u, ch)
    bestΛ, bestll, bestu, bestch = Λ, ll0, u, ch
    for α in (1.0, 0.6, 0.3, 0.15, 0.07, 0.03, 0.01)
        Λα = Matrix(Symmetric(Λ .+ α .* (Λem .- Λ)))
        isposdef(Λα) || continue
        llα, uα, chα = marg_warm(prob, Q_cond, β, Λα, u)
        if llα > bestll; bestΛ, bestll, bestu, bestch = Λα, llα, uα, chα; end
    end
    return bestΛ, bestll, bestu, bestch
end

function fit_em_closed(prob, Q_cond, β0, Λ0; max_em=150, tol=1e-6, verbose=true)
    β = β0; Λ = Matrix(Λ0)
    P = prior_precision(Q_cond, inv(Λ)); u, ch, _ = estep_mode(prob, P, β; n_newton=60)
    ll = laplace_ll(prob, P, β, u, ch); hist = [ll]
    verbose && @info "init" loglik=round(ll;digits=4)
    it_done = 0
    for it in 1:max_em
        it_done = it; ll0 = ll
        βn = mstep_beta(prob, u, β)
        lln, un, chn = marg_warm(prob, Q_cond, βn, Λ, u)
        if lln >= ll; β, ll, u, ch = βn, lln, un, chn; end
        Λ, ll, u, ch = lambda_step(prob, Q_cond, β, Λ, u, ch, ll)
        push!(hist, ll)
        verbose && (it<=8 || it%10==0) && @info "it $it" loglik=round(ll;digits=4) Δ=round(ll-ll0;digits=6)
        if ll - ll0 < tol && it > 3; verbose && @info "converged" it loglik=round(ll;digits=4); break; end
    end
    @assert all(diff(hist) .>= -1e-6) "marginal decreased: $(round.(hist;digits=4))"
    return (β=β, Λ=Λ, loglik=ll, u=u, iters=it_done, hist=hist)
end

if abspath(PROGRAM_FILE) == @__FILE__
    Random.seed!(7); p=20; n=p
    phy=random_balanced_tree(p;branch_length=0.2); Σ_phy=sigma_phy_dense(phy;σ²_phy=1.0)
    βt=(mu1=[1.0,0.5],mu2=[-0.3,0.4],s1=[-0.4],s2=[-0.5],rho=[0.3])
    Λt=[0.25 0.10 0.05 0.0;0.10 0.25 0.0 0.04;0.05 0.0 0.09 0.02;0.0 0.04 0.02 0.09];Λt=(Λt+Λt')/2
    x1=randn(n);X1=hcat(ones(n),x1);X2=hcat(ones(n),x1);Xs1=reshape(ones(n),n,1);Xs2=reshape(ones(n),n,1);Xr=reshape(ones(n),n,1)
    U=cholesky(Λt).L*randn(4,p)*cholesky(Symmetric(Σ_phy)).U
    y1=zeros(n);y2=zeros(n)
    for i in 1:n
        m1=(X1[i,:]'βt.mu1)+U[1,i];m2=(X2[i,:]'βt.mu2)+U[2,i]
        s1=exp((Xs1[i,:]'βt.s1)+U[3,i]);s2=exp((Xs2[i,:]'βt.s2)+U[4,i]);ρ=RHO_GUARD*tanh(Xr[i,:]'βt.rho)
        e=cholesky([s1^2 ρ*s1*s2;ρ*s1*s2 s2^2]).L*randn(2);y1[i]=m1+e[1];y2[i]=m2+e[2]
    end
    prob,Q_cond=make_problem(phy,y1,y2,X1,X2,Xs1,Xs2,Xr)
    β0=(mu1=X1\y1,mu2=X2\y2,s1=[log(std(y1.-X1*(X1\y1)))],s2=[log(std(y2.-X2*(X2\y2)))],rho=[0.0])
    fit_em_closed(prob,Q_cond,β0,Matrix(0.3*I(4));max_em=3,verbose=false)  # warmup
    t=@elapsed r=fit_em_closed(prob,Q_cond,β0,Matrix(0.3*I(4));max_em=200,tol=1e-6)
    println("\n=== fast closed-form EM p=20 ===")
    @printf "wall=%.3fs iters=%d logLik=%.4f\n" t r.iters r.loglik
    @printf "β_mu1 %s->%s  β_s1 %s->%s  β_rho %s->%s\n" βt.mu1 round.(r.β.mu1;digits=2) βt.s1 round.(r.β.s1;digits=2) βt.rho round.(r.β.rho;digits=2)
    println("Λ diag truth ",round.(diag(Λt);digits=3)," -> ",round.(diag(r.Λ);digits=3))
    println("=== done ===")
end
