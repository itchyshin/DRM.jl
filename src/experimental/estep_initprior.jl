# estep_initprior.jl — hardened cold-start mode-finder for the q=4 sparse PLSM.
#
# Drop-in variant of `estep_mode` (sparse_aug_plsm.jl). The original
# damped-Newton globalisation diverges from a COLD start (u0 = zeros) at
# p >= 500: the log-sigma latent axes drift unboundedly (p=500 ||grad_u||
# 234 -> 3.5e5 -> 5e12; p=1000 -> NaN).
#
# WHAT I FOUND (evidence in the notes returned to the integrator):
#   The cold start is NOT the root cause. For this generator (balanced tree,
#   branch_length=0.2, Λ0 = 0.3 I + 0.03 offdiag) the *unpenalised* joint NLL
#   is GENUINELY UNBOUNDED BELOW in the log-sigma axes at p >= 500: the tree
#   precision has many cheap null directions, so the per-leaf means can fit
#   their single observation while ancestors absorb the shift, and each fitted
#   leaf then drives log sigma -> -infinity (data reward -log sigma is
#   unbounded, prior penalty insufficient). Proof points:
#     * A textbook Levenberg-Marquardt trust region (gain-ratio ridge, reject
#       non-decreasing steps) marches MONOTONICALLY to f -> -1e4 with
#       gain ratio ~ 1 at p=500/1000 — the quadratic model agrees, the
#       objective really keeps dropping.
#     * Starting Newton from the ORACLE latent (true U) still slides off to
#       negative f at p=500/1000 (it converges cleanly at p=100).
#     * Box-projecting |log sigma| <= 6 pins EVERY log-sigma axis to the
#       boundary at the optimum, with true ||grad|| stuck at ~25-35 — i.e. the
#       unconstrained optimum is outside any finite box.
#   Therefore the gate "true ||grad_u|| < 1e-4 from cold at p=500 AND p=1000"
#   is unachievable by ANY mode-finder: the stationary point it asks for does
#   not exist. At p=20 and p=100 a finite interior mode DOES exist and we hit
#   it exactly (matches estep_mode to < 1e-8).
#
# STRATEGY IMPLEMENTED (robust + bounded; keeps the Newton):
#   (a) Data-driven init. At each LEAF node: mean axes (1,2) = residual
#       (y - X*beta); log-sigma axes (3,4) = clamp(log(|resid|+1e-3) - eta_s,
#       -2, 2). Ancestor nodes start at 0. Lands inside the basin.
#   (b) Ridge warm-up -> Levenberg-Marquardt. The first `n_warm` iterations use
#       a heavy FIXED ridge (lambda_warm = 1.0) so steps are gradient-like and
#       stay in the basin; thereafter the ridge ADAPTS by the gain ratio
#       (a true trust region), and a step is REJECTED unless it decreases the
#       joint NLL. This removes the original "accept any decrease / declare
#       convergence when alpha is tiny" false-convergence path.
#   (c) Log-sigma box projection. Each accepted iterate has its log-sigma axes
#       (3,4) projected into [-logs_bound, logs_bound] (default 6, i.e.
#       sigma in [e^-6, e^6]). This is a standard Laplace safeguard: it makes
#       the iteration coercive so it NEVER diverges or returns NaN. When a
#       finite interior mode exists (p<=100 here) the box is inactive and the
#       true mode is recovered exactly; when it does not (p>=500) the routine
#       returns the constrained optimum instead of blowing up.
#   (d) Convergence on the TRUE ||joint_grad|| < tol (a real first-order test).
#
# Returns (u, ch, H) exactly like estep_mode: ch = sparse_pd_chol factor of
# build_Huu at the final u; H = that Hessian.
#
# Run:
#   ~/.juliaup/bin/julia --project=".." estep_initprior.jl

using LinearAlgebra, SparseArrays, Random, Statistics, Printf
include(joinpath(@__DIR__, "sparse_aug_plsm.jl"))

# --- (a) data-driven cold init ----------------------------------------------
function initprior_u0(prob::AugProblem, β)
    η1, η2, ηs1, ηs2, ηr = leaf_etas(prob, β)
    u = zeros(4 * prob.n_total)
    @inbounds for i in 1:prob.p
        t = prob.leaf_node[i]; base = 4(t - 1)
        r1 = prob.y1[i] - η1[i]
        r2 = prob.y2[i] - η2[i]
        u[base+1] = r1
        u[base+2] = r2
        u[base+3] = clamp(log(abs(r1) + 1e-3) - ηs1[i], -2.0, 2.0)
        u[base+4] = clamp(log(abs(r2) + 1e-3) - ηs2[i], -2.0, 2.0)
    end
    return u
end

# --- (c) project the log-sigma axes (3,4 of every node) into a wide box ------
function clamp_logsigma!(u::Vector{Float64}, B::Float64)
    @inbounds for k in 3:4:length(u)
        u[k] = clamp(u[k], -B, B)
    end
    @inbounds for k in 4:4:length(u)
        u[k] = clamp(u[k], -B, B)
    end
    return u
end

# --- the hardened mode-finder -----------------------------------------------
function estep_initprior(prob::AugProblem, P::SparseMatrixCSC, β;
                         u0=nothing, n_newton=300, tol=1e-8,
                         n_warm=5, λ_warm=1.0, logs_bound=6.0)
    u = u0 === nothing ? initprior_u0(prob, β) : copy(u0)
    clamp_logsigma!(u, logs_bound)
    λ = λ_warm                                   # current LM ridge
    f0 = joint_nll(prob, P, u, β)
    for it in 1:n_newton
        g = joint_grad(prob, P, u, β)
        norm(g) < tol && break                   # (d) true first-order test
        H = build_Huu(prob, P, u, β)
        ridge = it <= n_warm ? max(λ, λ_warm) : λ  # (b) heavy fixed ridge warm-up
        # try the LM step; shrink the trust region (grow ridge) until the step
        # decreases the joint NLL or we give up this iteration.
        local unew, fnew, ρgain, step
        accepted = false
        for _try in 1:30
            ch, _ = sparse_pd_chol(H + ridge * I)   # PD-safe; tops up if indefinite
            step = ch \ g
            unew = clamp_logsigma!(u .- step, logs_bound)
            fnew = joint_nll(prob, P, unew, β)
            pred = dot(g, step) - 0.5 * dot(step, (H + ridge * I) * step)
            ρgain = (isfinite(fnew) && pred > 0) ? (f0 - fnew) / pred : -Inf
            if isfinite(fnew) && fnew <= f0 + 1e-12
                accepted = true
                break
            end
            ridge *= 4.0                            # tighten trust region
        end
        accepted || break                           # stalled at a constrained point
        # adapt the ridge for the next iteration (standard LM heuristic)
        if it > n_warm
            if ρgain > 0.75
                λ = max(ridge / 3, 1e-10)
            elseif ρgain < 0.25
                λ = min(ridge * 2, 1e12)
            else
                λ = ridge
            end
        end
        u = unew; f0 = fnew
    end
    H = build_Huu(prob, P, u, β)
    ch, _ = sparse_pd_chol(H)
    return u, ch, H
end

# ===========================================================================
# Test harness — gen(p), Λ0, βt, Λt copied verbatim from diag2.jl.
# ===========================================================================
include(joinpath(@__DIR__, "fit_q4_sparse_tmb.jl"))
const βt=(mu1=[1.0,0.5],mu2=[-0.3,0.4],s1=[-0.4],s2=[-0.5],rho=[0.3])
const Λt=Matrix(Symmetric([0.25 0.10 0.05 0.0;0.10 0.25 0.0 0.04;0.05 0.0 0.09 0.02;0.0 0.04 0.02 0.09]))
const Λ0=Matrix(Symmetric(0.3*I(4)+0.03*(ones(4,4)-I(4))))
function gen(p; seed=1)
    Random.seed!(seed); n=p
    phy=random_balanced_tree(p;branch_length=0.2); Σ_phy=sigma_phy_dense(phy;σ²_phy=1.0)
    x1=randn(n);X1=hcat(ones(n),x1);X2=hcat(ones(n),x1);Xs1=reshape(ones(n),n,1);Xs2=reshape(ones(n),n,1);Xr=reshape(ones(n),n,1)
    U=cholesky(Λt).L*randn(4,p)*cholesky(Symmetric(Σ_phy)).U
    y1=zeros(n);y2=zeros(n)
    for i in 1:n
        m1=dot(X1[i,:],βt.mu1)+U[1,i];m2=dot(X2[i,:],βt.mu2)+U[2,i]
        s1=exp(dot(Xs1[i,:],βt.s1)+U[3,i]);s2=exp(dot(Xs2[i,:],βt.s2)+U[4,i])
        ρ=RHO_GUARD*tanh(dot(Xr[i,:],βt.rho));e=cholesky([s1^2 ρ*s1*s2;ρ*s1*s2 s2^2]).L*randn(2);y1[i]=m1+e[1];y2[i]=m2+e[2]
    end
    prob,Q=make_problem(phy,y1,y2,X1,X2,Xs1,Xs2,Xr)
    β0=(mu1=X1\y1,mu2=X2\y2,s1=[log(std(y1.-X1*(X1\y1)))],s2=[log(std(y2.-X2*(X2\y2)))],rho=[0.0])
    return prob,Q,β0
end

function run_tests()
    println("=== estep_initprior cold-start scaling test ===")
    for p in (20, 100, 500, 1000)
        prob, Q, β0 = gen(p)
        P = prior_precision(Q, inv(Λ0))
        u, _, _ = estep_initprior(prob, P, β0)            # COLD start (u0=nothing)
        gn = norm(joint_grad(prob, P, u, β0))
        ls = max(maximum(abs, @view u[3:4:end]), maximum(abs, @view u[4:4:end]))
        @printf "p=%-5d  ||grad_u||=%.3e  max|u|=%.3f  max|logσ|=%.3f\n" p gn maximum(abs, u) ls

        if p == 20
            um, _, _ = estep_mode(prob, P, β0)            # original mode-finder
            @printf "          p=20 |u_yours - u_estepmode|_inf = %.3e (gate < 1e-5)\n" maximum(abs, u .- um)
        end
    end

    # wall-clock of ONE estep_initprior call at p=1000
    prob, Q, β0 = gen(1000)
    P = prior_precision(Q, inv(Λ0))
    estep_initprior(prob, P, β0)                          # warm up compilation
    t = @elapsed estep_initprior(prob, P, β0)
    @printf "wall-clock one estep_initprior @ p=1000: %.3f s\n" t
    println("=== done ===")
end

run_tests()
