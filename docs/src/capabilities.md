# Capability matrix

This page is an **evidence-based audit** of what `DRM.jl` actually implements and
tests, with file and test citations. It is deliberately conservative: every
"tested" claim points at a `test/` file that exercises the capability through the
public API (or, where noted, an internal kernel). Use it to know what is solid,
what is implemented but not yet guarded by a test (a follow-up target), and what
is genuinely absent.

Status legend:

- **Tested** — implemented and exercised by a `test/` file that runs in the
  default `Pkg.test()` suite (`test/runtests.jl`).
- **Impl, untested** — code exists and is reachable, but no test in the default
  suite asserts its behaviour. These are the highest-value follow-up test
  targets.
- **Absent** — not implemented in this worktree.

The audit was taken against `src/DRM.jl`'s include list and exports, and the
`test/runtests.jl` include list. Citations are `path:line` or `path` where a
whole file is the evidence.

## Response families

All families are exported from `src/DRM.jl:82`. Each is validated by **simulation
parameter recovery** (simulate with known coefficients, fit, assert recovery).
The numerical drmTMB-parity gate (RCall vs. drmTMB v0.1.3) is separate and gated
off by default (`DRM_PARITY_TESTS`, `test/runtests.jl:153`).

| Family | Source | Fixed-effects fit | RE on mean | Status |
|---|---|---|---|---|
| Gaussian | `src/gaussian_core.jl` | yes | yes | **Tested** — `test/test_gaussian_core.jl` |
| Student-t | `src/student.jl` | yes | intercept + slope | **Tested** — `test/test_student.jl`, `test/test_student_re.jl`, `test/test_student_slope_re.jl` |
| Poisson | `src/poisson.jl` | yes | intercept + slope + crossed + phylo | **Tested** — `test/test_poisson.jl`, `test/test_poisson_re.jl`, `test/test_poisson_slope_re.jl` |
| NegBinomial2 | `src/negbinomial.jl` | yes | intercept + slope + phylo | **Tested** — `test/test_nbinom2.jl`, `test/test_nbinom2_re.jl`, `test/test_nbinom2_slope_re.jl` |
| TruncatedNegBinomial2 | `src/negbinomial.jl` | yes | — | **Tested** — `test/test_truncated_nb.jl` |
| Beta | `src/beta.jl` | yes | intercept + slope + phylo | **Tested** — `test/test_beta.jl`, `test/test_beta_re.jl`, `test/test_beta_slope_re.jl` |
| BetaBinomial | `src/betabinomial.jl` | yes | intercept + slope + crossed + phylo | **Tested** — `test/test_betabinomial.jl`, `test/test_betabinomial_re.jl`, `test/test_betabinomial_slope_re.jl`, `test/test_betabinomial_phylo_laplace.jl`, `test/test_betabinomial_crossed_laplace.jl` (#166; constant-σ only) |
| Binomial | `src/binomial.jl` | yes | intercept + phylo | **Tested** — `test/test_binomial.jl`, `test/test_binomial_re.jl` |
| Gamma | `src/gamma.jl` | yes | intercept + slope + phylo | **Tested** — `test/test_gamma.jl`, `test/test_gamma_re.jl`, `test/test_gamma_slope_re.jl` |
| LogNormal | `src/lognormal.jl` | yes | intercept + slope | **Tested** — `test/test_lognormal.jl`, `test/test_lognormal_re.jl`, `test/test_lognormal_slope_re.jl` |
| ZeroOneBeta | `src/zeroonebeta.jl` | yes | — | **Tested** — `test/test_zeroonebeta.jl` |
| Tweedie | `src/tweedie.jl` | yes | — | **Tested** — `test/test_tweedie.jl` |
| CumulativeLogit (ordinal) | `src/cumulative.jl` | yes | — | **Tested** — `test/test_cumulative.jl` |

**Count modifiers** `zi` (zero-inflation) and `hu` (hurdle): implemented in the
Poisson/NB2 paths; **Tested** — `test/test_zi.jl`, `test/test_hurdle.jl`.

**Beta boundary modifiers** `zoi` / `coi` (zero-/one-inflation): the
`ZeroOneBeta()` family handles the boundary mass; **Tested** —
`test/test_zeroonebeta.jl`.

## Distributional (location–scale) sub-models

A formula per distributional parameter is the core grammar (`bf(...)`,
`src/gaussian_core.jl`; grammar tests `test/test_bf_grammar.jl`).

| Capability | Source | Status |
|---|---|---|
| Mean μ formula + scale σ (`sigma`) formula, Gaussian | `src/gaussian_core.jl` | **Tested** — `test/test_gaussian_core.jl` (recovers both μ and log σ slopes) |
| `sigma`/dispersion formula for non-Gaussian families | per-family `src/*.jl` | **Tested** per family (e.g. Gamma CV, NB2 size) via the family recovery tests above |
| Student-t `nu` (degrees of freedom) sub-model | `src/student.jl` | **Tested** — `test/test_student.jl` |
| Random effect on the **scale** axis (`sigma ~ (1\|g)`, Gauss–Hermite) | `src/gaussian_core.jl` | **Tested** — `test/test_sigma_re.jl` |
| `sigma(fit)` / `corpairs(fit)` scale + correlation accessors | `src/summary.jl`, `src/gaussian_core.jl` | **Tested** — `test/test_sigma.jl`, `test/test_corpairs.jl` |

## Location–scale–scale models (LSS, `sd()`)

A third submodel putting a linear predictor on the log standard deviation of a random effect (`sd(group) ~ z` or `sd(species, phylogenetic) ~ z`, `src/gaussian_lss.jl`, `src/gaussian_sparse_lss.jl`).

| Capability | Source | Status |
|---|---|---|
| Plain iid LSS `sd(group) ~ z` (ML + REML) | `src/gaussian_lss.jl` | **Tested** — `test/test_lss_group.jl`, `test/test_lss_reml.jl` |
| Phylogenetic LSS `sd(species, phylogenetic) ~ z` (ML + REML, dense) | `src/gaussian_lss.jl` | **Tested** — `test/test_lss_phylo.jl`, `test/test_lss_reml.jl` |
| Sparse $O(p)$ phylogenetic LSS engine (`sparse = true` / `algorithm = :sparse_lbfgs`) | `src/gaussian_sparse_lss.jl` | **Tested** — `test/test_lss_sparse.jl` (exact match to dense comparator on logLik, SEs, BLUPs) |
| Multi-component LSS (e.g. multi-iid, iid + phylo) | `src/gaussian_lss.jl` | **Tested** — `test/test_lsss_multi.jl`, `test/test_lss_reml.jl` |
| Incomplete response handling (`missing` / `NaN` in `y`, observed-rows pattern) | `src/gaussian_lss.jl` | **Tested** — `test/test_lss_missing_response.jl` |


## Random-effect structures

### Plain (unstructured) random effects on the mean

| Structure | Source | Status |
|---|---|---|
| Random intercept `(1\|g)`, Gaussian | `src/gaussian_ranef.jl` | **Tested** — `test/test_gaussian_ranef.jl`, `test/test_ranef.jl` |
| Random slope `(x\|g)` | `src/gaussian_ranef.jl` | **Tested** — `test/test_ranef.jl` and per-family `*_slope_re` tests |
| Correlated intercept+slope | `src/gaussian_ranef.jl` | **Tested** — `test/test_correlated_re.jl` |
| Multiple / crossed-nested grouping factors | `src/gaussian_ranef.jl`, `src/sparse_laplace_glmm.jl` | **Tested** — `test/test_multi_re.jl`, `test/test_crossed_laplace_generic.jl`, `test/test_crossed_selected_inverse.jl` |
| Non-Gaussian crossed RE (Poisson), sparse Laplace | `src/sparse_laplace_glmm.jl` | **Tested** — `test/test_poisson_crossed_laplace.jl`, gradient gate `test/test_poisson_crossed_grad_gate.jl` |

### Structured random effects with a known relatedness matrix (closed-form Gaussian)

A structured intercept `u ~ N(0, σ_s² K)` keeps the Gaussian marginal exactly
Gaussian and is fit in closed form (PGLS / matrix-determinant lemma), in
`src/gaussian_structured.jl`.

| Marker | Supplies | Source | Status |
|---|---|---|---|
| `relmat(1\|id)` | user matrix `K` | `src/gaussian_structured.jl:28` | **Tested** — `test/test_gaussian_structured.jl` |
| `animal(1\|id)` | additive-relatedness `A` | `src/gaussian_structured.jl:37` | **Tested** — `test/test_gaussian_structured.jl` |
| `phylo(1\|species)` on the **mean** | tree (`AugmentedPhy` or Newick) | `src/gaussian_structured.jl:49` | **Tested** — `test/test_gaussian_structured.jl`; sparse all-node + GLS routes also in `test/test_two_structured_gaussian.jl`, `test/test_two_structured_gaussian_sparse.jl` |
| `spatial(1\|site)` | coordinates; `K(ρ)=exp(-d/ρ)`, ρ estimated | `src/gaussian_structured.jl:68` | **Tested** — `test/test_gaussian_spatial.jl` |

### Non-Gaussian phylogenetic random intercept on the mean (sparse Laplace)

A `phylo(1|species)` intercept on the mean for non-Gaussian families uses the
verified sparse augmented-state Laplace engine (`src/sparse_laplace_glmm.jl`).

| Family | Status |
|---|---|
| Poisson | **Tested** — `test/test_poisson_phylo_laplace.jl`, exact-gradient gate `test/test_poisson_phylo_grad_gate.jl` |
| NegBinomial2 | **Tested** — `test/test_nb2_phylo_laplace.jl`, gate `test/test_nongaussian_phylo_grad_gate.jl` |
| Gamma | **Tested** — `test/test_gamma_beta_phylo_laplace.jl`, gate `test/test_nongaussian_phylo_grad_gate.jl` |
| Binomial | **Tested** — `test/test_binomial_phylo_laplace.jl`, gate `test/test_nongaussian_phylo_grad_gate.jl` |
| Beta | **Tested** (gradient reported honestly — looser than 1e-6) — `test/test_gamma_beta_phylo_laplace.jl`, `test/test_nongaussian_phylo_grad_gate.jl` |

## Location–scale with a phylogenetic random effect on the scale (q=2 route)

A shared random effect on **both** the mean and the log-dispersion axis (the
non-Gaussian location–scale model), built on a q=2 augmented inner mode-finder +
exact O(p) outer gradient (`src/locscale_*.jl`).

| Capability | Source | Status |
|---|---|---|
| Two-axis (mean + log-dispersion) kernels, **NB2 and Gamma only** | `src/locscale_kernels.jl` | **Tested** (analytic grad/Hessian vs ForwardDiff) — `test/test_locscale_kernels.jl` |
| q=2 augmented inner mode-finder | `src/locscale_inner.jl` | **Tested** — `test/test_locscale_inner.jl` |
| q=2 Laplace marginal | `src/locscale_marginal.jl` | **Tested** — `test/test_locscale_marginal.jl` |
| End-to-end fit (`_fit_locscale`) | `src/locscale_fit.jl` | **Tested** — `test/test_locscale_fit.jl` |
| Exact O(p) outer gradient | `src/locscale_grad.jl` | **Tested** (FD gate) — `test/test_locscale_grad.jl` |
| Wald inference + RE summaries | `src/locscale_infer.jl` | **Tested** — `test/test_locscale_infer.jl` |
| Profile-likelihood CIs (trust-region inner solve) | `src/locscale_profile.jl` | **Tested** — `test/test_locscale_profile.jl` |
| `drm()` routing for the coupled `(1\|tag\|group)` RE, **NB2 + Gamma** | `src/locscale_frontend.jl:90` | **Tested** — `test/test_locscale_frontend.jl`, `test/test_locscale_gamma_e2e.jl`, `test/test_locscale_phylo_e2e.jl` |

!!! note
    The coupled location–scale RE front end is wired for **NB2 and Gamma only**
    (`src/locscale_frontend.jl:90`). Other families carry `phylo`/`(1|g)` on the
    **mean axis only**.

## Coevolution: q=4 phylogenetic bivariate location–scale model (PLSM)

The selling-point model: a shared phylogenetic random effect on all four axes
`(μ1, μ2, log σ1, log σ2)` with a 4×4 between-species covariance `Σ_a`, plus a
residual correlation ρ12. This is the verified core engine (`src/sparse_phy.jl`,
`src/takahashi_selinv.jl`, `src/sparse_aug_plsm.jl`, `src/sparse_em_fit.jl`,
`src/fit_ml_q4.jl`, `src/fit_q4_sparse_tmb.jl`).

| Capability | Source | Status |
|---|---|---|
| Verified q=4 sparse-Laplace single fit + exact O(p) gradient | `src/fit_q4_sparse_tmb.jl` | **Tested** — `test/test_sparse_aug.jl`, FD gradient gate `test/test_qgate_fd_gradient.jl`, zero-alloc inner gate `test/test_qgate_alloc_inner.jl` |
| Sparse augmented phylo precision `kron(Q, Λ⁻¹)` foundation | `src/sparse_phy.jl` | **Tested** — `test/runtests.jl:13`, `test/test_step1_sparse.jl`, `test/test_crossed_selected_inverse.jl` |
| Takahashi selected inverse | `src/takahashi_selinv.jl` | **Tested** — `test/test_crossed_selected_inverse.jl`, used throughout the gradient gates |
| Public `bf(mu1=…, mu2=…, sigma1=…, sigma2=…, rho12=…)` q=4 front end | `src/gaussian_bivariate.jl` | **Tested** — `test/test_gaussian_bivariate_phylo.jl` (recovers Σ_a, β; validates marker constraints) |
| q=4 `relmat` / `animal` / fixed-range `spatial` providers (level-indexed `Q_cond`) | `src/gaussian_bivariate.jl`, `src/sparse_em_fit.jl` (`make_problem_from_Q`) | **Tested** — `test/test_gaussian_bivariate_q4_structured.jl` (#189); spatial uses fixed `spatial_range` (default = mean pairwise distance); joint ρ estimation deferred |
| `Σ_a` stored on the fit (`fit.ranef.Sigma_a`, axes `mu1,mu2,sigma1,sigma2`) and surfaced via `vc(fit)` / `ranef(fit)` / `coevolution_cor` | `src/gaussian_ranef.jl`, `src/coevo_accessors.jl` | **Tested** — `test/test_gaussian_bivariate_phylo.jl`, `test/test_coevo_accessors.jl`, `test/test_gaussian_bivariate_q4_structured.jl` |
| Default `q4_vcov=true` path → finite vcov, Wald SEs for the fixed effects | `src/gaussian_bivariate.jl` | **Tested** — `test/test_gaussian_bivariate_phylo.jl` (B2 testset) |
| Non-tree `bootstrap_sigma_a` for q=4 structured providers | `src/bootstrap_q4_phylo.jl` | **Rejected** — clear `ArgumentError`; tree-driven phylo bootstrap only |
| **Labelled coevolution-correlation accessor with bootstrap CIs** (ρ_a between axes) | `src/coevo_accessors.jl`, `src/bootstrap_q4_phylo.jl` | **Tested for phylo** — `test/test_coevo_accessors.jl`, `test/test_bootstrap_sigma_a.jl`; point `coevolution_cor` works for structured providers too |

## Structured q=2 bivariate Gaussian (mu1/mu2 only)

This is a complete-response exact-Gaussian ML point-fit cell for matching
structured random intercepts on `mu1` and `mu2`. It requires the same fixed-effect
design on both mean formulas and intercept-only `sigma1`, `sigma2`, and `rho12`
formulas. The payloads are point/export evidence only; they do not promote q2
REML, interval reliability, interval coverage, non-Gaussian q2, or broad R bridge
support.

| Capability | Source | Status |
|---|---|---|
| `phylo(1\|species)` on `mu1` and `mu2`, with residual `rho12` | `src/gaussian_bivariate.jl`, `src/coevolution_q.jl` | **Tested** — `test/test_bridge_q2_direct_export.jl` (native `drm`, direct export, and bridge marshalling fixture) |
| `relmat(1\|id)` and `animal(1\|id)` on `mu1` and `mu2`, using known `K` / `A` | `src/gaussian_bivariate.jl`, `src/coevolution_q.jl` | **Tested** — `test/test_bridge_q2_direct_export.jl` |
| Fixed-covariance spatial q2 fixture | `src/coevolution_q.jl`, `src/bridge.jl` | **Tested as direct fixture evidence only** — `test/test_bridge_q2_direct_export.jl`; the range-estimating `spatial(...)` formula route is rejected |

## Bivariate Gaussian (residual correlation, no phylo)

| Capability | Source | Status |
|---|---|---|
| Bivariate Gaussian with residual `rho12` (`cbind` / `mu1`,`mu2`) | `src/gaussian_bivariate.jl` | **Tested** — `test/test_gaussian_bivariate.jl` |
| `rho12(fit)` accessor | `src/summary.jl:65` | **Tested** — `test/test_rho12_accessor.jl` |
| Cross-family bivariate (different families on `y1` vs `y2`) | `src/mixed_family.jl`, `src/mixed_family_postfit.jl` | **Experimental — implemented, not absent.** `drm(bf(...), (Gaussian(), Poisson()); data = …)` fits two responses from different families coupled by a **latent-scale scalar** correlation, read from `fit.rho_latent`. Tested: `test/test_mixed_family.jl`, `test/test_mixed_family_postfit.jl`, `test/test_cross_family_formula.jl`. Methods reference: [Cross-family methods](model-guides/cross-family-methods.md). **Not release-ready** (`cross_family_latent` is `experimental`): single-fixture evidence, no interval coverage. `rho12 ~ x` is **rejected** on this route — the correlation is latent and scalar, so a per-observation formula would imply a model it does not fit; that is the two-Gaussian residual route above. |

## Meta-analysis

| Capability | Source | Status |
|---|---|---|
| `gaussian()` + `meta_V(v)` with **known diagonal** sampling variances; τ on the σ intercept | `src/gaussian_meta.jl:17` | **Tested** — `test/test_meta.jl` |
| Bivariate known sampling covariance (`meta_vcov_bivariate`) | `src/meta_vcov_bivariate.jl` (A8, `src/DRM.jl:72`) | **Tested** (corrected 2026-09-02: was listed Absent; exported at `src/DRM.jl:183`) — `test/test_meta_vcov_bivariate.jl` (`test/runtests.jl:338`) |
| Deprecated `meta_known_V` parity stub | — | **Absent** in this worktree (no such symbol) |

## Inference

| Method | Source | Status |
|---|---|---|
| Wald SEs + CIs (observed information) | `src/inference.jl`, `src/summary.jl:157` | **Tested** — `test/test_inference.jl`, `test/test_predict_se.jl` |
| Profile-likelihood CIs (`profile_result`, `confint(:profile)`) | `src/inference.jl:124` | **Tested** — `test/test_profile_ci.jl` |
| Parametric bootstrap (`bootstrap_ci`/`_summary`/`_result`, serial + threaded) | `src/inference.jl:708` | **Tested** — `test/test_bootstrap.jl`, `test/test_bootstrap_nongaussian.jl` |
| REML for the **fixed-effect Gaussian location–scale** fit (`method=:REML`), with the model-selection guard | `src/gaussian_core.jl`, `src/comparison.jl:84` | **Tested** — `test/test_reml.jl` |
| REML for **Gaussian mean `(1 \| g)`** (`method=:REML`, Woodbury Patterson–Thompson) | `src/gaussian_core.jl`, `src/gaussian_ranef.jl` | **Tested** (corrected 2026-09-02: `test/test_reml_ordinary_ranef.jl` is included at `test/runtests.jl:40`, not standalone) |
| `reml_loglik` / `ml_loglik` / `estimation_method` accessors | `src/gaussian_core.jl` (exported `src/DRM.jl:89`) | **Tested** — `test/test_reml.jl` |
| Epsilon-method bias correction (`bias_correct`, TMB sdreport analogue) | `src/bias_correct.jl:97` | **Tested** — `test/test_bias_correct.jl` |
| **χ̄² (chi-bar-square) boundary inference** (Self–Liang / Stram–Lee mixture) | `src/chibar.jl` | **Tested** — `test/test_chibar.jl` (corrects older audit text that listed this as Absent) |
| REML on the q=4 Laplace model (`method = :REML`, `reml_q4`) | `src/reml_q4.jl` | **Tested** — wired into the module; `test/test_reml_q4_allaxes.jl` (corrects older audit text that left this in `experimental/`) |
| REML on Location–Scale–Scale models (`method = :REML`, iid, phylo, multi) | `src/gaussian_lss.jl`, `src/gaussian_sparse_lss.jl` | **Tested** — `test/test_lss_reml.jl`, `test/test_lss_sparse.jl` |

!!! warning "REML scope"
    `method=:REML` is opt-in. **ML is the default** (REML likelihoods are not
    comparable across fixed-effect structures). Wired cells: the fixed-effect
    Gaussian location–scale model (`test/test_reml.jl`); a single Gaussian mean
    intercept `(1 | g)` on the Woodbury spine (`test/test_reml_ordinary_ranef.jl`,
    in the default suite at `test/runtests.jl:40`; #439); Location–Scale–Scale models
    (`sd(g) ~ z`, `sd(species, phylogenetic) ~ z`, and multi-component LSS;
    `test/test_lss_reml.jl`, `test/test_lss_sparse.jl`; #558); and the
    bivariate q=4 location–scale engine (`test/test_reml_q4_allaxes.jl`).
    σ-RE, random slopes, and non-Gaussian REML stay rejected. This is not AI-REML.

    **Normalisation convention (#477, resolved 2026-08-25):** every REML route
    in DRM.jl now reports the **normalised** Patterson–Thompson restricted
    log-likelihood, so `reml_loglik` is directly comparable to lme4's,
    glmmTMB's, TMB's and drmTMB's `logLik()`. The bivariate q=2/q=4 Laplace
    routes previously omitted the `(n_β/2)·log(2π)` constant while the
    fixed-effect location–scale and mean `(1 | g)` routes included it, so one
    package reported two scales under one name. Evidence: the q=4 parity gate's
    `atol_loglik` fell from **5.5436 to 0.03** once the constant was no longer
    being absorbed by the tolerance.

## Model comparison & accessors

| Capability | Source | Status |
|---|---|---|
| `lrtest`, `anova`, `aicc`, `weights`, `update` | `src/comparison.jl:54` | **Tested** — `test/test_comparison.jl` |
| `aic` / `bic` / `dof` / `nobs` / `deviance` / `dof_residual` | `src/gaussian_core.jl`, `src/summary.jl` | **Tested** — `test/test_aic_bic.jl` |
| `coef` / `vcov` / `confint` / `stderror` / `coeftable` | `src/inference.jl`, `src/summary.jl` | **Tested** — `test/test_inference.jl`, `test/test_summary.jl`, `test/test_summary_method.jl` |
| `fixef` / `re_sd` / `vc` / `ranef` / `sigma` / `corpairs` | `src/gaussian_ranef.jl`, `src/summary.jl` | **Tested** — `test/test_ranef.jl`, `test/test_sigma.jl`, `test/test_corpairs.jl` |
| `family` accessor | `src/gaussian_core.jl` | **Tested** — `test/test_family_accessor.jl` |
| `heritability` / `repeatability` / `icc` with delta + profile CIs | `src/heritability.jl:246` | **Tested** — `test/test_heritability.jl` |
| Drop-in parity accessors (StatsAPI surface) | `src/summary.jl` | **Tested** — `test/test_parity_accessors.jl` |

## Prediction, post-fit, residuals, simulation

| Capability | Source | Status |
|---|---|---|
| `fitted` / `residuals` | `src/gaussian_core.jl` | **Tested** — `test/test_postfit.jl` |
| `predict` (response scale) | `src/gaussian_core.jl` | **Tested** — `test/test_predict.jl`, `test/test_predict_response.jl` |
| `predict_parameters` / `marginal_parameters` / `prediction_grid` | `src/gaussian_core.jl` | **Tested** — `test/test_predict_parameters.jl`, `test/test_prediction_grid.jl` |
| Delta-method prediction SEs | `src/inference.jl` | **Tested** — `test/test_predict_se.jl` |
| `simulate` | `src/gaussian_core.jl` | **Tested** — `test/test_simulate.jl` |
| `check_drm` (convergence / gradient / vcov diagnostics) | `src/gaussian_core.jl` | **Tested** — `test/test_check_drm.jl` |
| Randomized (Dunn–Smyth) quantile residuals, per family | `src/quantile_residuals.jl` | **Tested** — `test/test_quantile_residuals.jl` |
| Visualization *data* providers (`profile_curve` / `parameter_surface` / `corpairs_data`) | `src/visualization.jl` | **Tested** — `test/test_visualization.jl` |
| Drawing layer (`drm_figure` / thin `plot_*`; Confidence Eye on `:profile`) | `src/plotting_ext.jl` + `ext/DRMMakieExt.jl` (Makie + AlgebraOfGraphics weakdeps) | **Stub-tested in CI** — `test/test_makie_ext_stub.jl` (`isempty(methods(drm_figure))` without Makie). Actual rendering is opt-in local (`using CairoMakie, AlgebraOfGraphics`); default CI does **not** draw. |

## R → Julia bridge (engine = "julia")

A marshalling-friendly boundary for `drmTMB(..., engine = "julia")`
(`src/bridge.jl`). Only primitive R-reconstructable pieces cross the boundary.

| Capability | Source | Status |
|---|---|---|
| `drm_bridge` (string/dict/named-tuple formula → fit → flattened `Dict`); univariate, bivariate, phylo-mean, and narrow q2 structured Gaussian fixtures | `src/bridge.jl:25` | **Tested** — `test/test_bridge.jl` and `test/test_bridge_q2_direct_export.jl` (assert bridge output equals native `drm` output for the admitted fixture cells) |
| q2/q4 direct point-export payloads (`q2_point_export`, `q4_point_export`) | `src/bridge.jl` | **Tested** — `test/test_bridge_q2_direct_export.jl`, `test/test_bridge_q4_direct_export.jl`; point/export evidence only, not broad bridge or interval coverage evidence |
| `drm_bridge_inference` (profile + bootstrap), **limited to the Gaussian phylo SD block** (`param=:resd`) | `src/bridge.jl:47` | **Tested** — `test/test_bridge.jl` |
| Newick tree string parsing + small LRU cache | `src/bridge.jl:127` | **Tested** — `test/test_bridge.jl` |
| Full R-side glue / `engine="julia"` round-trip in drmTMB | (R repo) | **Absent here** — the Julia primitive is tested; the R package glue lives in the drmTMB repo and is out of scope for this audit |

## Marginal method selection (VA/ELBO)

| Capability | Source | Status |
|---|---|---|
| `marginal=:LA` (Laplace) — the default | engine-wide | **Tested** — implicitly by every fit test |
| `marginal=:VA` Poisson `(1\|g)` public path | `src/poisson.jl`, `_fit_poisson_ranef_va` | **Experimental** — routes to the existing ELBO kernel; `DrmFit.marginal === :VA`; mixed LA/VA AIC/LRT error; `aicc` errors on VA before the small-n `Inf` short-circuit. **Does not close #136.** |
| `marginal=:VA` Binomial / NB2 / Gamma / Beta `(1\|g)` | family `drm()` + `_fit_*_ranef_va` | **Experimental** — same keyword / `_va_reject` / `DrmFit.marginal` tag as Poisson; scale families require `sigma ~ 1`. Mixed LA/VA AIC/LRT covered on NB2 as well as Poisson. **Does not close #136.** |
| `method=:VA` on non-Gaussian `drm()` | `_reject_method_as_marginal` | **Rejected** — `method` is ML/REML; pointer to `marginal` |

## Absent / out-of-scope (explicit)

To avoid overclaiming, these are confirmed **not** implemented in this worktree:

- **Missing-data handling** (corrected 2026-09-02: this bullet was stale —
  several routes are implemented on `main`). What exists: (1) listwise-deletion
  predictor preprocessing, `src/missing_data.jl` (#49, `src/DRM.jl:136`) — pure
  data preprocessing, explicitly documented as NOT FIML; (2) the exported joint
  missing-predictor routes (`mi()`, `JointDrmFit`/`JointTwoDrmFit`/
  `JointFiniteDrmFit`, `imputed`, `miss_control`) — five files included at
  `src/DRM.jl:137–143` (#563), tested by `test/test_joint_missing_*.jl`
  (`test/runtests.jl:435–446`) — **Experimental**: exported for evaluation;
  fenced for v1.0 (D-181); API and numerics may change; not covered by the
  R-parity scoreboard; (3) the Gaussian observed-response mask route,
  `src/gaussian_core.jl` (`_observed_response_mask`, `:320`; #517, commit
  `53141006`); (4) missing-response handling on the location-scale-scale
  `sd()` routes, `src/gaussian_lss.jl` (`has_missing_response`; #559, commit
  `140460a0`), **Tested** — `test/test_lss_missing_response.jl`
  (`test/runtests.jl:68`). Still absent: general multiple imputation for
  missing predictors outside the joint-model routes, and an `na.action`-style
  option.
- **χ̄² boundary inference** — see Inference table.
- **Cross-family bivariate models** — see Bivariate table.
- **Variational (VA/ELBO) public path beyond `(1\|g)` on Poisson / Binomial / NB2 / Gamma / Beta** — Experimental random-intercept VA only (`sigma ~ 1` where the family has a scale). Phylo, crossed, correlated slopes, ZI/hu remain open on #136. `_fit_va` still errors for unwired families. Scoped #136e public Gamma RI smoke: `report/va-vs-laplace-bias.md` (LA ≈ VA on shape `α`; LA faster; does not close #136).
- ~~**Dense/bivariate `meta_V`** — diagonal known variances only.~~ (corrected
  2026-09-02: false — bivariate known sampling covariance is implemented via
  `meta_vcov_bivariate`; see the Meta-analysis table.)
- ~~**Labelled q=4 coevolution-correlation accessor with CIs** — `Σ_a` is
  stored and surfaced, but no derived-correlation-with-interval accessor
  exists.~~ (corrected 2026-09-02: false, and contradicted the Coevolution
  table above in the same page — `coevolution_cor(fit)` is the labelled
  accessor, `src/coevo_accessors.jl`, and `bootstrap_sigma_a(fit)`,
  `src/bootstrap_q4_phylo.jl`, adds bootstrap CIs to it for tree-driven phylo
  fits; **Tested** — `test/test_coevo_accessors.jl`, `test/test_bootstrap_sigma_a.jl`.)
- **`src/experimental/`** (corrected 2026-09-02: `reml_q4` and `location_only`
  were promoted and are wired — see the Inference table and `src/DRM.jl:55`/`:81`
  — this bullet listed them as unmigrated by mistake). What remains in
  `src/experimental/` (`ls src/experimental`, per its own README) is: two
  recorded negative results not exposed (`fit_em_natgrad.jl` — #13 decision-gate
  FAIL; `fit_em_closed.jl`, `em_squarem_fit.jl` — #472, the closed-form Λ step
  descends the marginal); four superseded predecessors of the production engine
  (`fit_q4_tmbgrad.jl`, `fit_ml_q4.jl`, `fit_ml_warm.jl`, `fit_q4_p100_tmb.jl`,
  and the four `estep_*.jl` mode-finder hardenings); two diagnostic oracles
  (`q4_em_dense.jl`, `fit_sparse_direct.jl`); and a stale pre-promotion copy of
  `location_only.jl` (the wired file is `src/location_only.jl`). None of these
  are in the `DRM.jl` include list or the default suite.

## Follow-up test targets (implemented but untested)

The highest-value gaps where code exists but no default-suite test guards it:

1. **`src/experimental/` promotions.** (corrected 2026-09-02: `reml_q4` is
   already promoted and tested — see the Inference table; drop it from this
   list.) If/when `fit_em_natgrad`, the `estep_*` mode-finder candidates,
   `q4_em_dense`, or `fit_q4_tmbgrad` were wired into the public API, each would
   need its own recovery/gradient test — but per `src/experimental/README.md`
   several of these are recorded *negative* results (e.g. `fit_em_natgrad`
   failed the #13 decision gate) that the project has decided not to expose,
   not pending promotions. Today none of `src/experimental/` is reachable from
   `DRM.jl` or tested in the default suite.
2. **Labelled q=4 coevolution-correlation accessor.** (corrected 2026-09-02:
   this already exists and is tested — `coevolution_cor(fit)` +
   `bootstrap_sigma_a(fit)`, see the Coevolution table and the "Absent"
   section above; remove this as a follow-up target.)
3. **`drm_bridge_inference` beyond `:resd`.** The bridge inference primitive is
   tested only for the Gaussian phylogenetic SD block; broadening it to other
   parameters (with the R-side response-scale transforms) needs matching tests.
4. **q=2 location–scale RE for families beyond NB2/Gamma.** The two-axis kernels
   exist only for NB2 and Gamma; adding Beta/Binomial/Poisson location–scale
   kernels would each need a kernel-gradient gate + an end-to-end recovery test.

---

*Generated by an evidence-based capability audit against `src/DRM.jl` (include
list + exports) and `test/runtests.jl`. Each "Tested" row corresponds to a file
in the default `Pkg.test()` suite.*
