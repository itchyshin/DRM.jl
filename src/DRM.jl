"""
    DRM

`DRM.jl` — a Julia engine for distributional regression models, the Julia
twin of the R package **drmTMB**. Mirrors the gllvmTMB → GLLVM.jl move.

This v0.1.0 release migrates the verified `drm-julia-poc` engine for the
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

# q=4 REML (Patterson–Thompson restricted likelihood; β_μ profiled out via a
# bordered augmented state). Additive — reuses the engine symbols above; ML
# remains the default and REML is opt-in (`method = :REML`). See #187.
include("reml_q4.jl")

# q=4 Fisher-z (D·R·D) OUTER reparameterization of the 4×4 among-axis covariance
# Σ_a (separation strategy: D = diag SDs, R = spherical/LKJ correlation-Cholesky).
# Additive — wraps the UNTOUCHED marginal_and_exact_grad; the engine still consumes
# the native log-Cholesky lc. Its value is conditioning/robustness at the σ-collapse
# boundary; it generalizes the verified q=2 atanh(ρ) bijection. See Ayumi #2.
include("fisherz_q4.jl")

# General-q multivariate-Brownian coevolution block (#188): reuses the q-agnostic
# sparse precision (kron(Q_tree, Λ⁻¹)) with a q×q Λ and an EXACT conjugate-Gaussian
# Laplace marginal. Independent of the q=4 location-scale leaf code above.
include("coevolution_q.jl")

# Gaussian location–scale front end (public bf()/drm() API).
include("gaussian_core.jl")
include("gaussian_bivariate.jl")
include("gaussian_ranef.jl")
include("gaussian_meta.jl")
include("gaussian_structured.jl")
include("phylo_interaction.jl")  # bipartite two-tree interaction RE: V = σ²(C_A⊗C_B) + σ_e²I
include("location_only.jl")      # #12: opt-in conjugate-EM for the Gaussian phylo-mean cell
include("student.jl")
include("skewnormal.jl")
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
include("link_residual.jl")      # S3: per-family link-scale variance for cross-family ρ
include("mixed_family.jl")       # S3: cross-family bivariate via shared-latent GHQ
include("mixed_family_postfit.jl") # post-fit accessors for fit_mixed_family
include("quantile_residuals.jl") # #183: per-family Dunn–Smyth quantile residuals
                                 # (included after all family types are defined)
include("locscale_kernels.jl")   # #202 groundwork: two-axis (mean+log-disp) kernels
include("locscale_inner.jl")     # #202 groundwork: q=2 augmented inner mode-finder
include("locscale_marginal.jl")  # #202 groundwork: q=2 Laplace marginal
include("locscale_fit.jl")       # #202 groundwork: end-to-end location–scale fit
include("locscale_grad.jl")      # #202 groundwork: exact O(p) outer gradient
include("locscale_infer.jl")     # #202 groundwork: Wald inference + RE summaries
include("locscale_profile.jl")   # #202: profile-likelihood CIs (trust-region inner solve)
include("locscale_frontend.jl")  # #202 slice 3b: drm() routing for (1|tag|group)
include("locscale_corr.jl")      # cluster ①: (1+x|g)/(0+x|g) reroute onto the q2 core
include("locscale_sigma.jl")     # cluster ②: standalone sigma ~ 1+(1|g) RE onto the q2 core
include("gaussian_locscale_phylo.jl")  # B1: Gaussian sigma~phylo(1|g) univariate route — separate/coupled/asymmetric + boundary CIs (Ayumi #2)
include("inference.jl")
include("bias_correct.jl")       # TMB-style epsilon-method bias correction (#227 B11)
include("heritability.jl")       # comparative-biology derived ratios (h²/ICC) + CIs
include("coevo_accessors.jl")    # #188: q=4 coevolution among-axis correlation + variance accessors
include("bootstrap_q4_phylo.jl") # Ayumi #2: parametric bootstrap of the q=4 among-axis SDs (boundary-honest CIs)
include("variational.jl")
include("summary.jl")
include("visualization.jl")
include("comparison.jl")
include("chibar.jl")             # chi-bar-square boundary p-values for variance-component LRTs
include("bridge.jl")
include("missing_data.jl")       # #49: documented listwise-deletion preprocessing (no engine change)

# Public API — the verified single-fit + scaling engine.
export AugProblem, make_problem,
       fit_q4_sparse_tmb, marginal_and_exact_grad, marginal_nll,
       fit_q4_sparse_fisherz, fz_DRD, fz_R, fz_correlations, fz_marginal_and_grad,
       fz_phi_to_lc, fz_init_from_Sigma,
       estep_mode, prior_precision, build_Huu, joint_grad, joint_nll, aug_prior_grad!,
       pack_theta, unpack_theta, lc_to_Λ, Λ_to_lc,
       augmented_phy, random_balanced_tree, random_caterpillar_tree,
       augmented_tree_precision, sigma_phy_dense, takahashi_selinv,
       fit_phylo_interaction, phylo_interaction_nll, phylo_correlation,
       # general-q coevolution block (#188)
       CoevoProblem, make_coevo_problem, coevo_marginal, fit_coevolution,
       simulate_coevolution, coevo_pack, coevo_unpack, coevo_theta_len,
       lc_to_cov, cov_to_lc, lc_len

# Public API — the Gaussian distributional-regression front end.
export @formula, bf, drm_formula, drm, Gaussian, Student, SkewNormal, Poisson, NegBinomial2, TruncatedNegBinomial2, Beta, BetaBinomial, Binomial, Gamma, LogNormal, ZeroOneBeta, Tweedie, CumulativeLogit, cbind, meta_V, relmat, animal, phylo, spatial, DrmFormula, BivariateDrmFormula, DrmFit,
       coef, vcov, loglik, nobs, dof, aic, bic, fixef, re_sd, vc, ranef, sigma, corpairs, rho12, stderror, confint, coeftable, fitted, residuals, predict, predict_parameters, marginal_parameters, prediction_grid, simulate, bootstrap_ci, bootstrap_summary, bootstrap_result, bootstrap_sigma_a, check_drm, family,
       profile_result, profile_curve, parameter_surface, corpairs_data, gaussian_locscale_phylo_sds,
       is_converged, deviance, dof_residual,
       lrtest, anova, aicc, weights, update,
       chibar_pvalue, lrt_boundary,
       bias_correct,
       heritability, repeatability, icc,
       coevolution_cor, coevolution_vc, coevolution_summary,
       reml_loglik, ml_loglik, estimation_method,
       drm_bridge, drm_bridge_inference,
       drm_listwise

# Public API — post-fit accessors for the cross-family bivariate fit
# (`fit_mixed_family`, currently reached as `DRM.fit_mixed_family`).
export mf_coef, mf_aic, mf_bic, mf_fitted, mf_summary

# Marginal method-selection surface (#136): VA/ELBO scaffold. Kept INTERNAL on
# purpose — the user-facing API is `method = :LA` / `:VA`, and exporting a bare
# `Laplace` would clash with `Distributions.Laplace`. Reach them as
# `DRM.Variational` etc. if needed.

end # module DRM
