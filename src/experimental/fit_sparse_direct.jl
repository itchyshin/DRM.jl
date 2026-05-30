# fit_sparse_direct.jl — direct optimization of the VALIDATED sparse marginal
# (Checkpoint 3 exact). Diagnoses the EM stall: if LBFGS finds a much higher
# logLik than the EM's, the EM is stalling; if similar, the EM point is the MLE
# and the "poor recovery" at p=20 is just phylo identifiability.
#
# θ = [β_mu1(2),β_mu2(2),β_s1(1),β_s2(1),β_rho(1), log_sd(4), chol_off(6)] (17).
# Λ built by log-Cholesky (PD by construction). marginal via the sparse E-step.

using LinearAlgebra, SparseArrays, ForwardDiff, Optim, Random, Statistics, Printf
include(joinpath(@__DIR__, "sparse_em_fit.jl"))   # sparse_aug_plsm + make_problem

# log-Cholesky 4×4 covariance from (log_sd[4], offdiag[6])
function build_Lambda(logsd, off)
    L = zeros(eltype(off), 4, 4)
    k = 0
    for i in 1:4
        L[i, i] = exp(logsd[i])
        for j in 1:(i-1)
            k += 1; L[i, j] = off[k]
        end
    end
    return L * L'
end

unpack(θ) = ((mu1=θ[1:2], mu2=θ[3:4], s1=θ[5:5], s2=θ[6:6], rho=θ[7:7]),
             build_Lambda(θ[8:11], θ[12:17]))

function nll_theta(θ, prob, Q_cond)
    β, Λ = unpack(θ)
    P = prior_precision(Q_cond, inv(Λ))
    u, ch, _ = estep_mode(prob, P, β)
    return -laplace_ll(prob, P, β, u, ch)
end

function fit_direct(prob, Q_cond, θ0; iters=150, h=1e-5)
    f = θ -> nll_theta(θ, prob, Q_cond)
    function g!(G, θ)
        @inbounds for k in eachindex(θ)
            tp = copy(θ); tp[k] += h; tm = copy(θ); tm[k] -= h
            G[k] = (f(tp) - f(tm)) / (2h)
        end
        return G
    end
    res = optimize(f, g!, θ0, LBFGS(linesearch=Optim.LineSearches.BackTracking()),
                   Optim.Options(g_tol=1e-3, iterations=iters, show_trace=false))
    return res
end

if abspath(PROGRAM_FILE) == @__FILE__
    Random.seed!(7); p=20; n=p
    phy = random_balanced_tree(p; branch_length=0.2)
    Σ_phy = sigma_phy_dense(phy; σ²_phy=1.0)
    βt=(mu1=[1.0,0.5],mu2=[-0.3,0.4],s1=[-0.4],s2=[-0.5],rho=[0.3])
    Λt=[0.25 0.10 0.05 0.0;0.10 0.25 0.0 0.04;0.05 0.0 0.09 0.02;0.0 0.04 0.02 0.09];Λt=(Λt+Λt')/2
    x1=randn(n);X1=hcat(ones(n),x1);X2=hcat(ones(n),x1)
    Xs1=reshape(ones(n),n,1);Xs2=reshape(ones(n),n,1);Xr=reshape(ones(n),n,1)
    U=cholesky(Λt).L*randn(4,p)*cholesky(Symmetric(Σ_phy)).U
    y1=zeros(n);y2=zeros(n)
    for i in 1:n
        m1=(X1[i,:]'βt.mu1)+U[1,i];m2=(X2[i,:]'βt.mu2)+U[2,i]
        s1=exp((Xs1[i,:]'βt.s1)+U[3,i]);s2=exp((Xs2[i,:]'βt.s2)+U[4,i]);ρ=RHO_GUARD*tanh(Xr[i,:]'βt.rho)
        e=cholesky([s1^2 ρ*s1*s2;ρ*s1*s2 s2^2]).L*randn(2);y1[i]=m1+e[1];y2[i]=m2+e[2]
    end
    prob,Q_cond = make_problem(phy,y1,y2,X1,X2,Xs1,Xs2,Xr)
    θ0 = vcat(X1\y1, X2\y2, log(std(y1.-X1*(X1\y1))), log(std(y2.-X2*(X2\y2))), 0.0,
              fill(log(sqrt(0.3)),4), zeros(6))
    nll_theta(θ0, prob, Q_cond)  # warmup
    t=@elapsed res=fit_direct(prob,Q_cond,θ0)
    β,Λ = unpack(Optim.minimizer(res))
    println("\n=== sparse DIRECT (LBFGS, finite-diff) p=20 ===")
    @printf "wall=%.3fs  logLik=%.4f  (EM gave -55.1561)  conv=%s iters=%d\n" t (-Optim.minimum(res)) Optim.converged(res) Optim.iterations(res)
    @printf "β_mu1 %s->%s  β_mu2 %s->%s\n" βt.mu1 round.(β.mu1;digits=3) βt.mu2 round.(β.mu2;digits=3)
    @printf "β_s1 %s->%s β_s2 %s->%s β_rho %s->%s\n" βt.s1 round.(β.s1;digits=3) βt.s2 round.(β.s2;digits=3) βt.rho round.(β.rho;digits=3)
    println("Λ diag truth ",round.(diag(Λt);digits=3)," -> ",round.(diag(Λ);digits=3))
    println("=== done ===")
end
