"""
    DRM

`DRM.jl` — a Julia engine for distributional regression models, the Julia
twin of the R package **drmTMB**. Mirrors the gllvmTMB → GLLVM.jl move.

This v0.1.0-DEV scaffold migrates the verified `drm-julia-poc` engine for the
**q=4 phylogenetic bivariate location–scale model (PLSM)** — the selling-point
model of drmTMB (Nakagawa et al. 2025 MEE, Model 5). The marginal is a sparse
**augmented-state Laplace approximation** with an **exact O(p) gradient**
(implicit-function / TMB-style, via Takahashi selected inverse — never forms a
dense p×p Σ_phy), optimised by LBFGS with a fast-path-then-robust mode-finder.

Verified results (see report/comparison-grid.md):
- Single fit (real q4_p100, same model as drmTMB): **1.14 s vs drmTMB 2.48 s
  (2.18×)**, logLik matches, converged.
- O(p) scaling (per-dimension-variance model, nrep=4 replicates): **p=10000 in
  ~113 s, k≈1.08** (near-perfect O(p)).
- Inference: Wald SEs valid for 16/17 params where drmTMB's Hessian is all-NaN;
  parametric bootstrap 60/60.

NOTE (first cleanup task, see HANDOVER.md): the engine files were migrated as the
poc's script-style includes (chain: fit_q4_sparse_tmb → fit_ml_q4 → sparse_em_fit
→ sparse_aug_plsm → sparse_phy / takahashi_selinv). Inference (Wald + profile + parametric
bootstrap) is wired in `src/inference.jl`; the remaining comparison-suite engines
(REML, location-only, EM) live in `src/experimental/` and are NOT yet wired into
this module — wiring them into a clean public API is the v0.1 task.
"""
module DRM

# Load the verified core engine. The relative @__DIR__ includes inside
# fit_q4_sparse_tmb.jl transitively pull the whole chain from this src/ dir.
include("fit_q4_sparse_tmb.jl")

# Gaussian location–scale front end (public bf()/drm() API).
include("gaussian_core.jl")
include("gaussian_bivariate.jl")
include("gaussian_ranef.jl")
include("gaussian_meta.jl")
include("gaussian_structured.jl")
include("student.jl")
include("poisson.jl")
include("sparse_laplace_glmm.jl")
include("negbinomial.jl")
include("beta.jl")
include("betabinomial.jl")
include("binomial.jl")
include("gamma.jl")
include("lognormal.jl")
include("zeroonebeta.jl")
include("tweedie.jl")
include("cumulative.jl")
include("locscale_kernels.jl")   # #202 groundwork: two-axis (mean+log-disp) kernels
include("inference.jl")
include("variational.jl")
include("summary.jl")
include("visualization.jl")
include("comparison.jl")

# Public API — the verified single-fit + scaling engine.
export AugProblem, make_problem,
       fit_q4_sparse_tmb, marginal_and_exact_grad, marginal_nll,
       estep_mode, prior_precision, build_Huu, joint_grad, joint_nll,
       pack_theta, unpack_theta, lc_to_Λ, Λ_to_lc,
       augmented_phy, random_balanced_tree, sigma_phy_dense, takahashi_selinv

# Public API — the Gaussian distributional-regression front end.
export @formula, bf, drm_formula, drm, Gaussian, Student, Poisson, NegBinomial2, TruncatedNegBinomial2, Beta, BetaBinomial, Binomial, Gamma, LogNormal, ZeroOneBeta, Tweedie, CumulativeLogit, cbind, meta_V, relmat, animal, phylo, spatial, DrmFormula, BivariateDrmFormula, DrmFit,
       coef, vcov, loglik, nobs, dof, aic, bic, fixef, re_sd, vc, ranef, sigma, corpairs, rho12, stderror, confint, coeftable, fitted, residuals, predict, predict_parameters, marginal_parameters, prediction_grid, simulate, bootstrap_ci, bootstrap_summary, bootstrap_result, check_drm, family,
       profile_result, profile_curve, parameter_surface, corpairs_data,
       is_converged, deviance, dof_residual,
       lrtest, anova, aicc, weights, update

# Marginal method-selection surface (#136): VA/ELBO scaffold. Kept INTERNAL on
# purpose — the user-facing API is `method = :LA` / `:VA`, and exporting a bare
# `Laplace` would clash with `Distributions.Laplace`. Reach them as
# `DRM.Variational` etc. if needed.

end # module DRM
