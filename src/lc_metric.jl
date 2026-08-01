# lc_metric.jl — Fisher / observed-information metric on log-Cholesky params.
#
# Extracted from `src/experimental/fit_em_natgrad.jl` after the #13 decision gate
# (2026-08-01) FAIL: `fit_em_natgrad` stalls on the q4 location–scale cell at
# logLik ≈ −259.80 vs the verified sparse-TMB MLE −256.51 (same stall class as
# plain block-coordinate EM). Per `report/wire-em-solvers-design.md`, do **not**
# expose `algorithm = :natgrad` as a public solver; land the reusable Fisher /
# AI-REML metric for #11 / #165 follow-ups instead.
#
# `lc_metric` is the 10×10 observed information of the marginal NLL w.r.t. the
# log-Cholesky parameters of Λ (finite-difference of the exact lc-gradient,
# ridge-projected to SPD). Natural-gradient / Fisher-scoring steps use
# `H \\ g_lc` as the Newton direction on that metric.

"""
    lc_metric(prob, Q_cond, θ, u0; h=1e-5) -> Matrix{Float64}

Observed-information (Fisher-scoring) metric on the 10 log-Cholesky parameters
of the q=4 among-axis covariance Λ.

Builds a 10×10 Hessian of the marginal NLL w.r.t. `θ[8:17]` by central
finite-differences of the exact lc-gradient from `marginal_and_exact_grad`,
symmetrises, and ridge-projects to SPD so the metric is usable as a
preconditioner / natural-gradient operator (AI-REML / Fisher scoring).

# Notes
- Infrastructure for REML / non-Gaussian RE gradient work (#11 / #165) — **not**
  a public ML solver. The natural-gradient EM that used this metric failed the
  #13 MLE-parity gate against `fit_q4_sparse_tmb` (see
  `docs/dev-log/plans/2026-08-01-natgrad-decision-gate.md`).
- Cost: 20 exact-gradient evaluations per call (warm-started from `u0`).
"""
function lc_metric(prob::AugProblem, Q_cond::SparseMatrixCSC, θ::AbstractVector,
                   u0; h::Float64 = 1e-5, n_newton::Int = 30)
    H = zeros(10, 10)
    θ = Vector{Float64}(θ)
    for k in 1:10
        θp = copy(θ); θp[7 + k] += h
        _, gp, _, _ = marginal_and_exact_grad(prob, Q_cond, θp; u0 = u0, n_newton = n_newton)
        θm = copy(θ); θm[7 + k] -= h
        _, gm, _, _ = marginal_and_exact_grad(prob, Q_cond, θm; u0 = u0, n_newton = n_newton)
        H[:, k] = (gp[8:17] .- gm[8:17]) ./ (2h)
    end
    Hs = Symmetric((H + H') / 2)
    ev = eigen(Hs)
    λf = max(1e-3, 1e-3 * maximum(abs.(ev.values)))
    return Matrix(ev.vectors * Diagonal(max.(ev.values, λf)) * ev.vectors')
end
