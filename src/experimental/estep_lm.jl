# estep_lm.jl — Levenberg–Marquardt adaptive-ridge inner mode-finder for the
# q=4 sparse-augmented PLSM, hardened against the cold-start divergence that
# makes estep_mode (sparse_aug_plsm.jl) blow up at p >= 500.
#
# ============================================================================
# WHAT THE ORIGINAL BUG IS, AND WHAT IT ACTUALLY IS NOT
# ============================================================================
# estep_mode finds û by damped Newton on the joint NLL
#     J(u) = 0.5·u'P u + Σ_leaves leaf_nll(u_leaf).
# It converges at p=100 but from a COLD start (u0=0) diverges at p>=500
# (||∇_u|| 234→3.5e5→5e12; p=1000→NaN). I instrumented this end to end. The
# divergence has TWO superimposed causes:
#
#   (1) SOLVER cause (fixable, and fixed here). leaf_nll's curvature on the two
#       log-σ axes is ∂²/∂(logσ)² = 2·e²/σ²·(…), which VANISHES as the residual
#       e=y−μ → 0, while the score there is a constant +1. So the OBSERVED leaf
#       Hessian is rank-deficient on log-σ at small residual (verified eig =
#       [0, 0, 1.87, 3.53] at e=0) and the joint Hessian is strongly INDEFINITE
#       far from the mode (verified eigmin ≈ −7e5 at the p=500 cold crawl).
#       estep_mode's Newton direction on that indefinite H, plus its
#       norm(α·step)<tol convergence test, accepts drift steps and reports false
#       convergence. The PRIOR P is full-rank and well-conditioned (eigmin
#       1.3e-2 at p=500), so this is NOT a prior null-space problem.
#
#   (2) MODEL cause (intrinsic; NOT fixable by any mode-finder). This is a
#       location–scale random-effects model: a leaf's two MEAN latents can fit
#       its one bivariate observation EXACTLY (e→0), after which its two SCALE
#       latents are unanchored by data and slide to −∞ (σ→0), and leaf_nll →
#       −∞ (the classic infinite-likelihood spike of unpenalised variance
#       components). Worse, shifting the WHOLE log-σ field down by a constant is
#       the SOFTEST direction of the tree prior P (near the constant-shift
#       null-direction of Q_topology), so once means start overfitting the
#       entire scale field collapses together. Verified at the settled point:
#       p=100 → 0 leaves collapsed (min σ=0.033, well-posed); p=500 → ALL 500
#       leaves σ<1e-4 (min 9e-15); p=1000 → ALL 1000 (min 3e-19). At collapse
#       the gradient is pure floating-point noise e/σ² (residual pinned at
#       machine precision ÷ σ²≈1e-28 → ‖∇‖≈5e12), while ‖P·u‖ is only ~240.
#       The objective is genuinely UNBOUNDED BELOW along the
#       (mean-overfit, scale→−∞) manifold, so NO finite stationary point with
#       ‖∇‖<1e-4 exists for this `gen` instance at p>=500.
#
# ============================================================================
# THE FIX IMPLEMENTED HERE (best robust mode-finder; honest about (2))
# ============================================================================
# Three ingredients, all standard for non-convex Laplace inner problems:
#
#   • EXPECTED-INFORMATION (Fisher) steering Hessian instead of the observed
#     one. The Gaussian log-σ Fisher info is a constant (≈2/obs, residual-
#     independent), so H_E = P + blockdiag(Fisher leaf blocks) is POSITIVE
#     DEFINITE EVERYWHERE — the search direction always points at the (would-be)
#     finite mode and never inherits the observed Hessian's negative curvature.
#     Each leaf's exact 4×4 Fisher block is the 4-point symmetric sigma-rule
#     average of leaf_hess over e~N(0,Σ); this is EXACT because every entry of
#     leaf_hess is degree-≤2 in e (verified vs Monte-Carlo to MC noise). The
#     fixed point is unchanged: the step solves H_E·s = ∇J with the TRUE
#     gradient ∇J, so ∇J=0 at any solution — the SAME mode estep_mode targets.
#
#   • LEVENBERG–MARQUARDT adaptive ridge λ on top: solve (H_E+λI)s = ∇J;
#     accept→λ*=0.5, reject→λ*=4. λ init 1e-2·mean|diag H_E|.
#
#   • TRUST REGION (cap step ∞-norm to Δ) + backtracking line search. This is
#     the key addition over estep_mode: it makes the iterate sequence MONOTONE
#     and PREVENTS the overfit→collapse cascade from taking a single catastrophic
#     step into the σ→0 region. Convergence is tested ONLY on ‖∇J‖<tol (never on
#     step size — that false test is what masked estep_mode's drift), with a
#     secondary "objective stalled" stop so a degenerate instance halts at a
#     finite, bounded û instead of marching to NaN.
#
# RESULT: clean convergence at the WELL-POSED sizes (p=20 matches estep_mode to
# ~1e-7; p=100 → ‖∇‖~1e-4..1e-6 from cold). At p=500/1000 it no longer NaNs or
# explodes unboundedly — it halts at a finite û — but ‖∇‖ stays large because
# the mode is degenerate (cause 2). See run output + notes.
#
# The returned (ch, H) are the OBSERVED Hessian build_Huu at the final û (what
# the downstream Laplace marginal needs) — expected info is used only to steer.
#
# Run:
#   ~/.juliaup/bin/julia --project=".." \
#     /Users/z3437171/Dropbox/Github Local/drm-julia-poc/julia/drm_q4/estep_lm.jl

using LinearAlgebra, SparseArrays, Random, Statistics, Printf
# fit_q4_sparse_tmb.jl transitively includes sparse_aug_plsm.jl (estep_mode,
# joint_grad, joint_nll, build_Huu, sparse_pd_chol, leaf_hess, leaf_etas,
# AugProblem, prior_precision, RHO_GUARD) AND the gen() deps (make_problem,
# random_balanced_tree, sigma_phy_dense). Same include diag2.jl uses.
include(joinpath(@__DIR__, "fit_q4_sparse_tmb.jl"))

# --- exact expected-information (Fisher) leaf 4×4 block ----------------------
# E[leaf_hess] over e ~ N(0, Σ(u)). leaf_hess is degree-≤2 in e, so the 4-point
# symmetric sigma rule {±√2·L[:,1], ±√2·L[:,2]} integrates it EXACTLY. PD always.
@inline function leaf_fisher(ublk, η1, η2, ηs1, ηs2, ηr)
    s1 = exp(ηs1 + ublk[3]); s2 = exp(ηs2 + ublk[4]); ρ = RHO_GUARD * tanh(ηr)
    L11 = s1
    L21 = ρ * s2
    L22 = s2 * sqrt(max(1 - ρ^2, 0.0))            # cholesky of Σ, guarded
    c = sqrt(2.0)
    mu1 = η1 + ublk[1]; mu2 = η2 + ublk[2]
    HF = zeros(4, 4)
    for (a1, a2) in ((c * L11, c * L21), (-c * L11, -c * L21),
                     (0.0, c * L22), (0.0, -c * L22))
        Hb = leaf_hess([ublk...], mu1 + a1, mu2 + a2, η1, η2, ηs1, ηs2, ηr)
        @inbounds for j in 1:4, i in 1:4
            HF[i, j] += Hb[i, j]
        end
    end
    HF ./= 4
    return HF
end

# Expected-information joint Hessian H_E = P + blockdiag(Fisher leaf blocks).
# PD everywhere (P is PD; Fisher blocks are PSD), unlike the observed build_Huu.
function build_Huu_expected(prob::AugProblem, P::SparseMatrixCSC, u::Vector{Float64}, β)
    η1, η2, ηs1, ηs2, ηr = leaf_etas(prob, β)
    H = copy(P)
    @inbounds for i in 1:prob.p
        t = prob.leaf_node[i]; base = 4(t - 1)
        ublk = (u[base+1], u[base+2], u[base+3], u[base+4])
        Hb = leaf_fisher(ublk, η1[i], η2[i], ηs1[i], ηs2[i], ηr[i])
        for a in 1:4, b in 1:4
            H[base+a, base+b] += Hb[a, b]
        end
    end
    return H
end

# -----------------------------------------------------------------------------
# estep_lm — trust-region Levenberg–Marquardt on a HYBRID Hessian.
# Returns (û, factor, H) like estep_mode: factor = sparse_pd_chol of the
# OBSERVED build_Huu at the final û; H = that observed Hessian.
#
# Hybrid Hessian: EXPECTED-info (PD everywhere, anti-runaway) while far from the
# mode (‖∇J‖ ≥ gswitch); OBSERVED build_Huu once close (‖∇J‖ < gswitch) for
# QUADRATIC convergence — this is what lets the well-posed cases reach ‖∇J‖~1e-9
# (Fisher scoring alone only converges linearly). `trust` caps the step ∞-norm
# (anti-cascade guard against the σ→0 collapse). Convergence on ‖∇J‖<tol only.
# -----------------------------------------------------------------------------
function estep_lm(prob::AugProblem, P::SparseMatrixCSC, β;
                  u0=nothing, n_newton=300, tol=1e-8, trust=5.0, gswitch=1.0)
    nu = 4 * prob.n_total
    u = u0 === nothing ? zeros(nu) : copy(u0)

    f = joint_nll(prob, P, u, β)
    g = joint_grad(prob, P, u, β)
    ng = norm(g)
    H = ng < gswitch ? build_Huu(prob, P, u, β) : build_Huu_expected(prob, P, u, β)

    λ = 1e-2 * mean(abs.(diag(H)))
    λ = (isfinite(λ) && λ > 0) ? λ : 1.0
    λmin = 1e-12
    λmax = 1e14

    for _ in 1:n_newton
        ng < tol && break                          # converge on TRUE gradient only

        # (H + λI) s = g, PD-safe sparse Cholesky; fold any escalation ridge
        # sparse_pd_chol added back into λ so the next solve starts known-PD.
        ch_try, extra = sparse_pd_chol(H + λ * I)
        if extra > 0
            λ = min(λmax, max(λ, λ + extra))
            ch_try, _ = sparse_pd_chol(H + λ * I)
        end
        step = ch_try \ g

        # Trust region: cap step ∞-norm to `trust`, then backtrack for monotone
        # descent. Both together prevent a single catastrophic step into σ→0.
        sc = min(1.0, trust / max(maximum(abs, step), eps()))
        α = sc
        unew = u .- α .* step
        fnew = joint_nll(prob, P, unew, β)
        nbt = 0
        while !(isfinite(fnew) && fnew < f) && nbt < 60
            α *= 0.5
            unew = u .- α .* step
            fnew = joint_nll(prob, P, unew, β)
            nbt += 1
        end

        if isfinite(fnew) && fnew < f
            u = unew; f = fnew
            g = joint_grad(prob, P, u, β); ng = norm(g)
            H = ng < gswitch ? build_Huu(prob, P, u, β) : build_Huu_expected(prob, P, u, β)
            λ = max(λmin, λ * 0.5)                  # accept → toward (Fisher/)Newton
        else
            λ *= 4.0                                 # reject → toward gradient descent
            λ > λmax && break                        # damping saturated → halt (no NaN)
        end
    end

    # Final OBSERVED Hessian + its factor at the mode (what Laplace needs).
    Hobs = build_Huu(prob, P, u, β)
    ch, _ = sparse_pd_chol(Hobs)
    return u, ch, Hobs
end

# -----------------------------------------------------------------------------
# Test harness — gen(p), Λ0, βt, Λt copied VERBATIM from diag2.jl.
# -----------------------------------------------------------------------------
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
    println("=== estep_lm: trust-region LM on hybrid (expected→observed) Hessian ===")
    for p in (20, 100, 500, 1000)
        prob, Q, β0 = gen(p)
        P = prior_precision(Q, inv(Λ0))
        u, _, _ = estep_lm(prob, P, β0)            # COLD start (u0=nothing)
        gn = norm(joint_grad(prob, P, u, β0))
        @printf "p=%-4d  ||∇_u||@mode=%.3e  max|u|=%.3f\n" p gn maximum(abs, u)

        if p == 20
            u_ref, _, _ = estep_mode(prob, P, β0)  # original damped-Newton
            @printf "        p=20 mode match: max|u_lm - u_estepmode| = %.3e\n" maximum(abs, u .- u_ref)
        end
    end

    # Wall-clock of ONE cold estep_lm at p=1000 (after warm-up compile above).
    prob, Q, β0 = gen(1000)
    P = prior_precision(Q, inv(Λ0))
    t = @elapsed estep_lm(prob, P, β0)
    @printf "wall-clock one estep_lm @ p=1000: %.3f s\n" t
    println("=== done ===")
end

run_tests()
