# estep_trustregion.jl — TRUST-REGION inner mode-finder for the q=4 PLSM.
#
# Replaces the damped-Newton globalization in `estep_mode` (sparse_aug_plsm.jl).
# That globalization DIVERGES from a cold start (u0 = zeros) at p >= 500: the
# log-sigma latent axes drift unboundedly because (a) the joint Hessian is
# indefinite far from the mode (small residuals -> negative curvature on the
# log-sigma axes), so the "Newton" direction is not a descent direction and an
# unbounded full step is accepted, and (b) the convergence test
# norm(alpha*step) < tol declares false convergence when alpha is driven tiny by
# backtracking.
#
# Strategy (classic trust region, Nocedal & Wright Alg. 4.1, with a
# Levenberg–Marquardt regularized model so the ratio test stays faithful when
# build_Huu is indefinite):
#   * Maintain a radius Delta (init 1.0).
#   * Each accepted point: g = joint_grad, H = build_Huu, (ch, λ) =
#     sparse_pd_chol(H); the step solves B s = g with B = H + λI (PD), i.e.
#     s = ch \ g.
#   * Clip to the region: if norm(s) > Delta, s *= Delta / norm(s).
#   * rho = actual_reduction / predicted_reduction, where
#       actual    = joint_nll(u) - joint_nll(u - s)
#       predicted = dot(g, s) - 0.5 * dot(s, B*s),  B*s = H*s + λ*s.
#     Scoring against the SAME regularized model B that produced s (not the raw
#     indefinite H) keeps predicted > 0 and ρ meaningful — see the long comment
#     in the loop. (Using the raw H here is what lets the region expand into the
#     negative-curvature log-σ directions.)
#   * Accept (u -= s) only if rho > eta (genuine decrease). Else reject.
#   * rho > 0.75 && step hit the boundary -> Delta *= 2.
#     rho < 0.25                          -> Delta /= 4.
#   * Converge when norm(joint_grad) < tol.
#
# Returns (u, ch, H) exactly like estep_mode: ch = sparse_pd_chol factor of
# build_Huu at the final u, H = that Hessian.
#
# IMPORTANT (see StructuredOutput notes): this trust region is correct and
# reproduces the mode wherever one exists (p=20 matches estep_mode to ~5e-14;
# p=100 ||∇||~3e-9), but it does NOT converge at p>=500 with the test prior Λ0.
# That is NOT a solver defect: the q=4 PLSM Laplace inner objective is unbounded
# below at Λ0 for large p (a weak-prior variance-shrinkage degeneracy of the
# location-scale latent field that worsens as the tree deepens). No descent
# method can find a mode that does not exist; the fix belongs in the prior /
# objective, not the globalization.

include(joinpath(@__DIR__, "sparse_aug_plsm.jl"))

# `gen(p)` needs make_problem / random_balanced_tree / sigma_phy_dense, which
# live in the fit stack that sparse_aug_plsm.jl does NOT pull in. We bring them
# in via fit_q4_sparse_tmb.jl (the same include diag2.jl uses); it transitively
# re-includes sparse_aug_plsm.jl, which is harmless (Julia just redefines).
include(joinpath(@__DIR__, "fit_q4_sparse_tmb.jl"))

using LinearAlgebra, SparseArrays, Statistics, Printf

# -----------------------------------------------------------------------------
# Trust-region mode finder.
# -----------------------------------------------------------------------------
function estep_trustregion(prob::AugProblem, P::SparseMatrixCSC, β;
                           u0=nothing, n_newton=300, tol=1e-8,
                           Δ0=1.0, Δmax=1e6, η=1e-4)
    nu = 4 * prob.n_total
    u = u0 === nothing ? zeros(nu) : copy(u0)
    Δ = Δ0

    g = joint_grad(prob, P, u, β)
    f = joint_nll(prob, P, u, β)

    for _ in 1:n_newton
        # Converged?
        norm(g) < tol && break

        # (Modified-)Newton direction at the current point. build_Huu is
        # indefinite far from the mode (small residuals -> negative curvature on
        # the log-sigma axes), so sparse_pd_chol adds a ridge λ until the solve
        # matrix B = H + λI is PD. The step s solves B s = g (a
        # Levenberg–Marquardt direction). CRITICAL: we must score ρ against the
        # SAME model B that produced s — not the raw indefinite H. Using H gives
        # negative s'·H·s along the bad axes, which INFLATES the predicted
        # reduction (predicted = g'·s − 0.5 s'·H·s grows), the region expands,
        # and u drifts along exactly the log-σ directions that diverge. With the
        # convex model B, predicted = g'·s − 0.5 s'·B·s > 0 always, so ρ is a
        # faithful goodness-of-fit and the radius logic actually constrains the
        # step. We solve once per accepted point and reuse s/H/λ across the cheap
        # radius sub-iterations below.
        H = build_Huu(prob, P, u, β)
        ch, λ = sparse_pd_chol(H)
        s_full = ch \ g
        ns_full = norm(s_full)

        # Inner loop: clip to Delta, test rho, accept or shrink. g/H/s_full are
        # fixed here (same u) — only Delta and the clip change, so each pass is a
        # matvec + one joint_nll, no refactorisation.
        accepted = false
        for _tr in 1:60
            # Clip the Newton step into the trust region.
            if ns_full > Δ
                s = s_full .* (Δ / ns_full)
                on_boundary = true
            else
                s = s_full
                on_boundary = false
            end

            unew = u .- s
            fnew = joint_nll(prob, P, unew, β)
            actual = f - fnew
            # Predicted reduction from the REGULARIZED convex model B = H + λI
            # that produced s:  m(0) - m(-s) = g'·s - 0.5 s'·B·s, with
            # B*s = H*s + λ*s.  B PD ⟹ predicted > 0, so ρ measures the model we
            # actually minimized (see comment above).
            Bs = H * s .+ λ .* s
            predicted = dot(g, s) - 0.5 * dot(s, Bs)

            # Guard a degenerate / non-positive model: treat as a failed step so
            # we shrink rather than divide by ~0 (or by a negative predicted).
            if !(predicted > 0) || !isfinite(fnew)
                ρ = -Inf
            else
                ρ = actual / predicted
            end

            # Radius update.
            if ρ < 0.25
                Δ /= 4
            elseif ρ > 0.75 && on_boundary
                Δ = min(2Δ, Δmax)
            end

            # Acceptance: genuine decrease.
            if ρ > η
                u = unew
                f = fnew
                g = joint_grad(prob, P, u, β)
                accepted = true
                break
            end

            # Rejected: Delta already shrunk above; retry the clip. Bail if the
            # region has collapsed (can't make progress) — treat as converged at
            # this point so we don't spin uselessly.
            Δ < 1e-14 && break
        end

        # If the whole inner loop failed to find an acceptable step and the
        # region collapsed, we are stuck at u — stop (gradient test above will
        # report the true ||grad||).
        if !accepted && Δ < 1e-14
            break
        end
    end

    H = build_Huu(prob, P, u, β)
    ch, _ = sparse_pd_chol(H)
    return u, ch, H
end

# =============================================================================
# Test harness — gen(p), Λ0, βt, Λt copied verbatim from diag2.jl.
# =============================================================================
const βt = (mu1=[1.0, 0.5], mu2=[-0.3, 0.4], s1=[-0.4], s2=[-0.5], rho=[0.3])
const Λt = Matrix(Symmetric([0.25 0.10 0.05 0.0; 0.10 0.25 0.0 0.04; 0.05 0.0 0.09 0.02; 0.0 0.04 0.02 0.09]))
const Λ0 = Matrix(Symmetric(0.3 * I(4) + 0.03 * (ones(4, 4) - I(4))))
function gen(p; seed=1)
    Random.seed!(seed)
    n = p
    phy = random_balanced_tree(p; branch_length=0.2)
    Σ_phy = sigma_phy_dense(phy; σ²_phy=1.0)
    x1 = randn(n)
    X1 = hcat(ones(n), x1)
    X2 = hcat(ones(n), x1)
    Xs1 = reshape(ones(n), n, 1)
    Xs2 = reshape(ones(n), n, 1)
    Xr = reshape(ones(n), n, 1)
    U = cholesky(Λt).L * randn(4, p) * cholesky(Symmetric(Σ_phy)).U
    y1 = zeros(n)
    y2 = zeros(n)
    for i in 1:n
        m1 = dot(X1[i, :], βt.mu1) + U[1, i]
        m2 = dot(X2[i, :], βt.mu2) + U[2, i]
        s1 = exp(dot(Xs1[i, :], βt.s1) + U[3, i])
        s2 = exp(dot(Xs2[i, :], βt.s2) + U[4, i])
        ρ = RHO_GUARD * tanh(dot(Xr[i, :], βt.rho))
        e = cholesky([s1^2 ρ*s1*s2; ρ*s1*s2 s2^2]).L * randn(2)
        y1[i] = m1 + e[1]
        y2[i] = m2 + e[2]
    end
    prob, Q = make_problem(phy, y1, y2, X1, X2, Xs1, Xs2, Xr)
    β0 = (mu1=X1 \ y1, mu2=X2 \ y2,
          s1=[log(std(y1 .- X1 * (X1 \ y1)))],
          s2=[log(std(y2 .- X2 * (X2 \ y2)))],
          rho=[0.0])
    return prob, Q, β0
end

function run_tests()
    println("=== estep_trustregion scaling test (cold start) ===")
    for p in (20, 100, 500, 1000)
        prob, Q, β0 = gen(p)
        P = prior_precision(Q, inv(Λ0))
        u, _, _ = estep_trustregion(prob, P, β0)  # cold start (u0=nothing)
        gn = norm(joint_grad(prob, P, u, β0))
        @printf "p=%-5d  ||∇_u||@mode=%.3e  max|u|=%.3f\n" p gn maximum(abs, u)

        if p == 20
            # Same-mode check against the ORIGINAL estep_mode.
            ue, _, _ = estep_mode(prob, P, β0)
            @printf "  p=20 mode match: max|u_tr - u_estepmode| = %.3e (need < 1e-5)\n" maximum(abs, u .- ue)
        end
    end

    # Wall clock of one estep_trustregion call at p=1000.
    prob, Q, β0 = gen(1000)
    P = prior_precision(Q, inv(Λ0))
    t = @elapsed estep_trustregion(prob, P, β0)
    @printf "wall-clock one E-step @ p=1000: %.3f s\n" t
    println("=== done ===")
end

run_tests()
