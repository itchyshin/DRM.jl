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
| BetaBinomial | `src/betabinomial.jl` | yes | intercept + slope | **Tested** — `test/test_betabinomial.jl`, `test/test_betabinomial_re.jl`, `test/test_betabinomial_slope_re.jl` |
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
| Verified q=4 sparse-Laplace single fit + exact O(p) gradient | `src/fit_q4_sparse_tmb.jl` | **Tested** — `test/test_q4_laplace.jl`, `test/test_sparse_aug.jl`, FD gradient gate `test/test_qgate_fd_gradient.jl`, zero-alloc inner gate `test/test_qgate_alloc_inner.jl` |
| Sparse augmented phylo precision `kron(Q, Λ⁻¹)` foundation | `src/sparse_phy.jl` | **Tested** — `test/runtests.jl:13`, `test/test_step1_sparse.jl`, `test/test_crossed_selected_inverse.jl` |
| Takahashi selected inverse | `src/takahashi_selinv.jl` | **Tested** — `test/test_crossed_selected_inverse.jl`, used throughout the gradient gates |
| Public `bf(mu1=…, mu2=…, sigma1=…, sigma2=…, rho12=…)` q=4 front end | `src/gaussian_bivariate.jl:117` | **Tested** — `test/test_gaussian_bivariate_phylo.jl` (recovers Σ_a, β; validates marker constraints) |
| `Σ_a` stored on the fit (`fit.ranef.Sigma_a`, axes `mu1,mu2,sigma1,sigma2`) and surfaced via `vc(fit)` / `ranef(fit)` | `src/gaussian_ranef.jl:277` | **Tested** — `test/test_gaussian_bivariate_phylo.jl` (S1/S2 testsets) |
| Default `q4_vcov=true` path → finite vcov, Wald SEs for the fixed effects | `src/gaussian_bivariate.jl` | **Tested** — `test/test_gaussian_bivariate_phylo.jl` (B2 testset) |
| **Labelled coevolution-correlation accessor with CIs** (ρ_a between axes, with intervals) | — | **Absent** — `Σ_a` is stored and surfaced, but there is no dedicated derived-correlation-with-CI accessor for the q=4 group-level covariance |

## Bivariate Gaussian (residual correlation, no phylo)

| Capability | Source | Status |
|---|---|---|
| Bivariate Gaussian with residual `rho12` (`cbind` / `mu1`,`mu2`) | `src/gaussian_bivariate.jl` | **Tested** — `test/test_gaussian_bivariate.jl` |
| `rho12(fit)` accessor | `src/summary.jl:65` | **Tested** — `test/test_rho12_accessor.jl` |
| Cross-family bivariate (different families on `y1` vs `y2`) | — | **Absent** — the bivariate path is Gaussian-only (`src/gaussian_bivariate.jl`); no cross-family bivariate model is implemented |

## Meta-analysis

| Capability | Source | Status |
|---|---|---|
| `gaussian()` + `meta_V(v)` with **known diagonal** sampling variances; τ on the σ intercept | `src/gaussian_meta.jl:17` | **Tested** — `test/test_meta.jl` |
| Dense / bivariate known sampling covariance | — | **Absent** (documented as planned in `src/gaussian_meta.jl:15`) |
| Deprecated `meta_known_V` parity stub | — | **Absent** in this worktree (no such symbol) |

## Inference

| Method | Source | Status |
|---|---|---|
| Wald SEs + CIs (observed information) | `src/inference.jl`, `src/summary.jl:157` | **Tested** — `test/test_inference.jl`, `test/test_predict_se.jl` |
| Profile-likelihood CIs (`profile_result`, `confint(:profile)`) | `src/inference.jl:124` | **Tested** — `test/test_profile_ci.jl` |
| Parametric bootstrap (`bootstrap_ci`/`_summary`/`_result`, serial + threaded) | `src/inference.jl:708` | **Tested** — `test/test_bootstrap.jl`, `test/test_bootstrap_nongaussian.jl` |
| REML for the **fixed-effect Gaussian location–scale** fit (`method=:REML`), with the model-selection guard | `src/gaussian_core.jl`, `src/comparison.jl:84` | **Tested** — `test/test_reml.jl` |
| `reml_loglik` / `ml_loglik` / `estimation_method` accessors | `src/gaussian_core.jl` (exported `src/DRM.jl:89`) | **Tested** — `test/test_reml.jl` |
| Epsilon-method bias correction (`bias_correct`, TMB sdreport analogue) | `src/bias_correct.jl:97` | **Tested** — `test/test_bias_correct.jl` |
| **χ̄² (chi-bar-square) boundary inference** (Self–Liang / Stram–Lee mixture) | — | **Absent** — no implementation; listed as an open research item in `HANDOVER.md` §8C |
| **Exact REML gradient / REML on the q=4 Laplace model** (`reml_q4`) | `src/experimental/reml_q4.jl` | **Impl, untested / not wired** — present in `src/experimental/` only; not in the `DRM.jl` include list, no default-suite test |

!!! warning "REML scope"
    `method=:REML` is wired and tested **only** for the fixed-effect Gaussian
    location–scale model (`test/test_reml.jl`); a random effect on the mean under
    REML is explicitly rejected. The general/Laplace-REML path (`reml_q4`) is
    experimental and unwired. **ML is the default** (REML likelihoods are not
    comparable across fixed-effect structures).

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
| Visualization (CairoMakie figures incl. the Confidence Eye) | `src/visualization.jl` | **Tested** — `test/test_visualization.jl` |

## R → Julia bridge (engine = "julia")

A marshalling-friendly boundary for `drmTMB(..., engine = "julia")`
(`src/bridge.jl`). Only primitive R-reconstructable pieces cross the boundary.

| Capability | Source | Status |
|---|---|---|
| `drm_bridge` (string/dict/named-tuple formula → fit → flattened `Dict`); univariate, bivariate, and phylo-mean | `src/bridge.jl:25` | **Tested** — `test/test_bridge.jl` (asserts bridge output equals native `drm` output) |
| `drm_bridge_inference` (profile + bootstrap), **limited to the Gaussian phylo SD block** (`param=:resd`) | `src/bridge.jl:47` | **Tested** — `test/test_bridge.jl` |
| Newick tree string parsing + small LRU cache | `src/bridge.jl:127` | **Tested** — `test/test_bridge.jl` |
| Full R-side glue / `engine="julia"` round-trip in drmTMB | (R repo) | **Absent here** — the Julia primitive is tested; the R package glue lives in the drmTMB repo and is out of scope for this audit |

## Marginal method selection (VA/ELBO)

| Capability | Source | Status |
|---|---|---|
| `method=:LA` (Laplace) — the default and only working marginal | engine-wide | **Tested** — implicitly by every fit test |
| `method=:VA` (variational / ELBO) | `src/variational.jl:37` | **Absent (stub)** — `_fit_va` deliberately `error`s and points to issue #136; `test/test_variational.jl` asserts the **method-selection plumbing**, not a VA fit |

## Absent / out-of-scope (explicit)

To avoid overclaiming, these are confirmed **not** implemented in this worktree:

- **Missing-data handling** (NA dropping, `na.action`, missing-response bridge):
  no implementation in `src/` (no `skipmissing`/`ismissing`/`na_action` code
  path). (A `codex/missing-response-bridge` branch exists separately and is not
  merged here.)
- **χ̄² boundary inference** — see Inference table.
- **Cross-family bivariate models** — see Bivariate table.
- **Variational (VA/ELBO) marginal** — stub only.
- **Dense/bivariate `meta_V`** — diagonal known variances only.
- **Labelled q=4 coevolution-correlation accessor with CIs** — `Σ_a` is stored
  and surfaced, but no derived-correlation-with-interval accessor exists.
- **`src/experimental/`** (`reml_q4`, `location_only`, EM variants, dense
  oracles) — migrated but **not** in the `DRM.jl` include list and not covered by
  the default suite.

## Follow-up test targets (implemented but untested)

The highest-value gaps where code exists but no default-suite test guards it:

1. **`src/experimental/` promotions.** If/when `reml_q4`, `fit_em_natgrad`, the
   `estep_*` mode-finder candidates, `q4_em_dense`, or `fit_q4_tmbgrad` are wired
   into the public API, each needs its own recovery/gradient test. Today they are
   unreachable from `DRM.jl` and untested in the default suite.
2. **Labelled q=4 coevolution-correlation accessor.** `Σ_a` is tested as stored;
   a derived ρ_a-with-CI accessor (analogous to `heritability`) would be the
   natural next public surface and should ship with a delta + profile CI test.
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
