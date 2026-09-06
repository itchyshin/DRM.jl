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

All families are exported from `src/DRM.jl:165`. Each is validated by **simulation
parameter recovery** (simulate with known coefficients, fit, assert recovery).
The numerical drmTMB-parity gate (committed drmTMB 0.6.0 reference fixtures, no
live R; `test/parity/README.md:9`) is separate and gated off by default
(`DRM_PARITY_TESTS`, `test/runtests.jl:455`).

| Family | Source | Fixed-effects fit | RE on mean | Status |
|---|---|---|---|---|
| Gaussian | `src/gaussian_core.jl` | yes | yes | **Tested** — `test/test_gaussian_core.jl` |
| Student-t | `src/student.jl` | yes | intercept + slope | **Tested** — `test/test_student.jl`, `test/test_student_re.jl`, `test/test_student_slope_re.jl` |
| SkewNormal | `src/skewnormal.jl` | yes | — | **Tested** — `test/test_skewnormal.jl` (fixed effects only; random effects refused at `src/skewnormal.jl:52`) |
| Poisson | `src/poisson.jl` | yes | intercept + slope + crossed + phylo | **Tested** — `test/test_poisson.jl`, `test/test_poisson_re.jl`, `test/test_poisson_slope_re.jl` |
| NegBinomial2 | `src/negbinomial.jl` | yes | intercept + slope + crossed + phylo | **Tested** — `test/test_nbinom2.jl`, `test/test_nbinom2_re.jl`, `test/test_nbinom2_slope_re.jl`, `test/test_crossed_laplace_generic.jl:233` |
| TruncatedNegBinomial2 | `src/negbinomial.jl` | yes | — | **Tested** — `test/test_truncated_nb.jl` |
| Beta | `src/beta.jl` | yes | intercept + slope + crossed + phylo | **Tested** — `test/test_beta.jl`, `test/test_beta_re.jl`, `test/test_beta_slope_re.jl`, `test/test_crossed_laplace_generic.jl:100` (crossed: internal kernel only, no `drm()` route test) |
| BetaBinomial | `src/betabinomial.jl` | yes | intercept + slope + crossed + phylo | **Tested** — `test/test_betabinomial.jl`, `test/test_betabinomial_re.jl`, `test/test_betabinomial_slope_re.jl`, `test/test_betabinomial_phylo_laplace.jl`, `test/test_betabinomial_crossed_laplace.jl` (#166; constant-σ only) |
| Binomial | `src/binomial.jl` | yes | intercept + crossed + phylo | **Tested** — `test/test_binomial.jl`, `test/test_binomial_re.jl`, `test/test_crossed_laplace_generic.jl:224` (slope REs refused, `src/binomial.jl:115`) |
| Gamma | `src/gamma.jl` | yes | intercept + slope + crossed + phylo | **Tested** — `test/test_gamma.jl`, `test/test_gamma_re.jl`, `test/test_gamma_slope_re.jl`, `test/test_crossed_laplace_generic.jl:83` (crossed: internal kernel only, no `drm()` route test) |
| LogNormal | `src/lognormal.jl` | yes | intercept + slope + phylo/relmat | **Tested** — `test/test_lognormal.jl`, `test/test_lognormal_re.jl`, `test/test_lognormal_slope_re.jl`, `test/test_lognormal_structured_mean.jl` (`animal`/`spatial` refused, `src/lognormal.jl:70`) |
| ZeroOneBeta | `src/zeroonebeta.jl` | yes | — | **Tested** — `test/test_zeroonebeta.jl` |
| Tweedie | `src/tweedie.jl` | yes | intercept + independent slope | **Tested** — `test/test_tweedie.jl`, `test/test_tweedie_ranef.jl` |
| CumulativeLogit (ordinal) | `src/cumulative.jl` | yes | intercept + independent slope + phylo | **Tested** — `test/test_cumulative.jl`, `test/test_cumlogit_ranef.jl`, `test/test_cumlogit_phylo.jl` |

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
| Phylogenetic LSS `sd(species, phylogenetic) ~ z` (ML + REML; sparse automatically above 500 species) | `src/gaussian_lss.jl` | **Tested** — `test/test_lss_phylo.jl`, `test/test_lss_reml.jl`, `test/test_lss_sparse.jl` |
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
| BetaBinomial | **Tested** (constant σ only, #166) — `test/test_betabinomial_phylo_laplace.jl` |
| CumulativeLogit (ordinal) | **Tested** (intercept-only) — `src/cumulative.jl:518`, `test/test_cumlogit_phylo.jl` |

## Location–scale with a phylogenetic random effect on the scale (q=2 route)

A shared random effect on **both** the mean and the log-dispersion axis (the
non-Gaussian location–scale model), built on a q=2 augmented inner mode-finder +
exact O(p) outer gradient (`src/locscale_*.jl`).

| Capability | Source | Status |
|---|---|---|
| Two-axis (mean + log-dispersion) kernels — NB2, Gamma | `src/locscale_kernels.jl:56`, `:94` | **Tested** (analytic grad/Hessian vs ForwardDiff) — `test/test_locscale_kernels.jl` |
| Two-axis kernels — Beta, BetaBinomial (logit mean, precision φ = exp(−2ψ)) | `src/locscale_kernels.jl:129`, `:188` | **Tested** — engine-lane recovery through a structured `C⁻¹` plus an off-optimum FD gradient gate, `test/test_locscale_structured.jl`; whitened paired route `test/test_locscale_whitened.jl` |
| Two-axis kernels — Gaussian mean leaf (η = mean, ψ = log σ_res) | `src/locscale_kernels.jl:266` | **Tested** — driven by the public Gaussian σ-phylo route (`src/gaussian_locscale_phylo.jl:607`, reached from `drm()` at `src/gaussian_core.jl:639`), `test/test_gaussian_locscale_phylo.jl` |
| Two-axis kernels — Poisson (ψ-axis null: mean-only leaf), LogNormal | `src/locscale_kernels.jl:216`, `:239` | **Impl, untested** — no default-suite test asserts their values; `Val(:poisson)` appears only in a *negative* assertion (`test/test_locscale_inner_status.jl:468`), and the LogNormal leaf's only test, `test/test_corr_locscale_equiv.jl`, is commented out of the suite (`test/runtests.jl:222`) |
| q=2 augmented inner mode-finder | `src/locscale_inner.jl` | **Tested** — `test/test_locscale_inner.jl` |
| q=2 Laplace marginal | `src/locscale_marginal.jl` | **Tested** — `test/test_locscale_marginal.jl` |
| End-to-end fit (`_fit_locscale`) | `src/locscale_fit.jl` | **Tested** — `test/test_locscale_fit.jl` |
| Exact O(p) outer gradient | `src/locscale_grad.jl` | **Tested** (FD gate) — `test/test_locscale_grad.jl` |
| Wald inference + RE summaries | `src/locscale_infer.jl` | **Tested** — `test/test_locscale_infer.jl` |
| Profile-likelihood CIs (trust-region inner solve) | `src/locscale_profile.jl` | **Tested** — `test/test_locscale_profile.jl` |
| `drm()` routing for the coupled `(1\|tag\|group)` RE, **NB2 + Gamma** | `src/negbinomial.jl:94`, `src/gamma.jl:59` (guard: `src/locscale_frontend.jl:152`) | **Tested** — `test/test_locscale_frontend.jl`, `test/test_locscale_gamma_e2e.jl`, `test/test_locscale_phylo_e2e.jl` |

!!! note
    The **non-Gaussian** coupled location–scale RE front end is wired for **NB2
    and Gamma only**: `src/negbinomial.jl:94` and `src/gamma.jl:59` are the only
    two `drm()` call sites of `_fit_locscale_frontend`
    (`src/locscale_frontend.jl:180`). The design builder itself also accepts a
    `Val{:beta}` kind (`src/locscale_frontend.jl:148`) and refuses everything
    else (`src/locscale_frontend.jl:152`), but no family `drm()` routes Beta
    there. Apart from this route, non-Gaussian families carry `phylo`/`(1|g)` on
    the **mean axis only**.

    **Gaussian is the exception, and it has its own engine** (corrects older
    audit text, which said "mean axis only" for every family outside NB2/Gamma).
    `src/gaussian_locscale_phylo.jl` (module include `src/DRM.jl:120`) fits a
    univariate Gaussian location–scale model with a phylogenetic random effect on
    **both** axes, through the public `drm()` grammar, in three blocks:

    - **Separate** (the default): `Λ = diag(L11², L22²)` with `L21 ≡ 0`, so the
      μ-phylo and σ-phylo effects are uncorrelated
      (`src/gaussian_locscale_phylo.jl:37`). Written
      `bf(y ~ … + phylo(1|sp), sigma ~ phylo(1|sp))`, routed at
      `src/gaussian_core.jl:621`. **Tested** —
      `test/test_gaussian_locscale_phylo.jl` (public-`drm()` recovery of both SDs
      at p=128, no-silent-drop against `sigma ~ 1`, ≤1e-6 FD gradient gate).
    - **Asymmetric** (σ-phylo only, fixed-effect mean): `phylo(1|sp)` on `sigma`
      alone, mean-axis variance pinned at ε
      (`src/gaussian_locscale_phylo.jl:505`, routed at `src/gaussian_core.jl:653`).
      **Tested** — `test/test_gaussian_locscale_phylo.jl` (FD gate),
      `test/test_gaussian_locscale_phylo_boundary.jl` (honest `[0, x]` profile CI
      when the scale-phylo signal is genuinely absent).
    - **Coupled** (free `L21`, a live μ↔σ phylo correlation): opt-in
      `drm(…; phylo_coupled = true)` (`src/gaussian_core.jl:436`, dispatched at
      `:641`; block at `src/gaussian_locscale_phylo.jl:846`) — the plain
      both-`phylo` grammar on its own gives the separate block, not this one.
      **Tested** — `test/test_phylo_penalty.jl:242`, `test/test_bridge.jl:256`;
      correlation recovery (sign and loose magnitude) via the internal fitter in
      `test/test_gaussian_locscale_phylo.jl:126`.

    Both σ-phylo test files run in the default suite (`test/runtests.jl:394`,
    `:395`). The two SDs come off the fit with the exported
    `gaussian_locscale_phylo_sds(fit)` (`src/gaussian_locscale_phylo.jl:959`,
    exported at `src/DRM.jl:169`); the coupled correlation is
    `fit.scales[:lambda_cor]`, and `profile_ci = true` adds
    `fit.scales[:profile_ci_sd_mu]` / `[:profile_ci_sd_sigma]`. The route is
    narrow by design: μ and σ must share one grouping factor, the structured mean
    marker must be `phylo`, only one structured mean component is allowed, and no
    additional random effects or `meta_V` may be present
    (`src/gaussian_core.jl:623-638`).

    `method = :REML` is wired for the separate and asymmetric blocks of **this**
    route (`src/gaussian_locscale_phylo.jl:774`, `:661`) — **Tested** end-to-end
    through public `drm(…; method = :REML)` in `test/test_reml_sigma_phylo.jl`
    and `test/test_reml_newton_sigma_phylo.jl` (default suite,
    `test/runtests.jl:422-423`). This is the one exception to "σ-RE … stay
    rejected" in the REML-scope warning below, which still holds for the iid
    `sigma ~ (1|g)` Gauss–Hermite route. REML is **refused** for the coupled
    block (`src/gaussian_locscale_phylo.jl:851`, `src/gaussian_core.jl:628`).

    Gaussian also carries a plain iid random effect on the scale axis
    (`sigma ~ (1|g)`, Gauss–Hermite — see the location–scale table above), and
    the q=4 PLSM below puts a phylogenetic effect on `log σ1` / `log σ2`. A
    standalone **non-Gaussian** σ-axis-only intercept exists
    (`src/locscale_sigma.jl:126`) and is **Tested** by direct internal call
    (`test/test_sigma_axis_re.jl:56`, default suite `test/runtests.jl:225`), but
    it has no `drm()` call site anywhere in `src/`, so it is not reachable from
    the public grammar.

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

## Bivariate and paired responses (residual correlation)

The Gaussian, lognormal and Student-t routes here fit two responses jointly with a
residual/scatter `rho12`; `associate_pairs` instead couples two *already-fitted*
univariate models in a second stage. Only the lognormal route reaches the
structured (`phylo`/`relmat`/`animal`/`spatial`) engines of the two sections
above, and it does so by delegation rather than by a second engine.

| Capability | Source | Status |
|---|---|---|
| Bivariate Gaussian with residual `rho12` (`cbind` / `mu1`,`mu2`) | `src/gaussian_bivariate.jl` | **Tested** — `test/test_gaussian_bivariate.jl` |
| `rho12(fit)` accessor | `src/summary.jl:65` | **Tested** — `test/test_rho12_accessor.jl` |
| Bivariate **lognormal** (`drm(bf(…), LogNormal())`, drmTMB's `biv_lognormal()`) | `src/bivariate_lognormal.jl:84` (included `src/DRM.jl:94`; family exported `src/DRM.jl:165`) | **Tested** — `test/test_bivariate_lognormal.jl` (`test/runtests.jl:84`). Two strictly positive responses with `log(Y)` bivariate normal. The **whole** fit delegates to `drm(f, Gaussian(); data = log.(data))` (`src/bivariate_lognormal.jl:112`) and only the reported likelihood shifts, by the parameter-free Jacobian (`src/bivariate_lognormal.jl:126`) — so `mu1`/`mu2` are means on the **log** scale and `rho12` is the **log-residual** correlation, not the raw-scale Pearson correlation (`src/bivariate_lognormal.jl:23`). Because the delegation is total, structured markers reach exactly the q=2 and q=4 engines of the two sections above, run on `log(y)` — **tested for `phylo`** (`test/test_bivariate_lognormal.jl:132`, q=4 across three tree heights; `:153`, q=2 on `mu1`/`mu2` only) **and for `relmat`** (`:166`, q=4). `animal` and `spatial` are **implemented but untested on this route**: the same delegation carries them, but nothing in `test/test_bivariate_lognormal.jl` instantiates either marker. Boundary: a non-positive **observed** response cell is refused (`ArgumentError`, `src/bivariate_lognormal.jl:152`; `test/test_bivariate_lognormal.jl:58`), and `method = :REML` is refused on **every** cell including the structured ones (`ArgumentError`, `src/bivariate_lognormal.jl:88`; `test/test_bivariate_lognormal.jl:67`, `:191`). |
| Bivariate **Student-t** (`drm(bf(…, nu = …), Student())`, drmTMB's `biv_student()`) | `src/bivariate_student.jl:118` (included `src/DRM.jl:92`; family exported `src/DRM.jl:165`) | **Tested** — `test/test_bivariate_student.jl` (`test/runtests.jl:85`). Exact bivariate-t density, closed form (`src/bivariate_student.jl:166`). `sigma1`/`sigma2` are **scale** parameters, *not* marginal SDs (for `ν > 2` the marginal `SD = σ·√(ν/(ν−2))`); `rho12` is the **scatter** correlation; `nu` uses the `logm2` link `ν = 2 + exp(η)`, so `ν > 2` and the variance is finite (`test/test_bivariate_student.jl:57`). Block order mirrors drmTMB's dpars `mu1, mu2, sigma1, sigma2, nu, rho12` (`src/bivariate_student.jl:216`; `test/test_bivariate_student.jl:63`). **`nu` is shared across the two responses by construction** — one scalar mixing variable governs both margins, so there is no per-margin `nu1`/`nu2` and `bf` refuses one (`ArgumentError`, `src/gaussian_bivariate.jl:28`, called at `:81`; `test/test_bivariate_student.jl:72`); it may still vary across **rows** via `nu ~ x` (`src/bivariate_student.jl:147`), and defaults to `~ 1` when omitted (`test/test_bivariate_student.jl:83`). **Zero `rho12` is not independence** at finite `ν` (`src/bivariate_student.jl:22`). Boundary: residual-only — `phylo`/`relmat`/`animal`/`spatial` markers are a **deliberate rejection**, not a missing port (`ArgumentError`, `src/bivariate_student.jl:126`; `test/test_bivariate_student.jl:92`, which asserts the message says so), as is `method = :REML` (`src/bivariate_student.jl:120`). drmTMB 0.7.0's own `biv_student()` defers the identical request; re-verified live 2026-08-25 with the reproducing snippet at `src/bivariate_student.jl:86`. |
| **Staged pair association** — `associate_pairs` / `latent_normal` / `association` / `PairAssociation` / `integration_diagnostics` (drmTMB's `associate_pairs()`) | `src/associate_pairs.jl:101` (included `src/DRM.jl:95`; exported `src/DRM.jl:180`, `src/DRM.jl:181`) | **Tested** — `test/test_associate_pairs.jl` (`test/runtests.jl:86`). A **two-stage, frozen-margin** estimator, not a joint model: two already-fitted univariate `drm` fits are coupled by a single latent-normal correlation `eta = 0.999999·tanh(alpha)`, fitted by bounded golden-section multistart (`src/associate_pairs.jl:124`, `:171`). **All five reviewed pair classes are implemented and recover the association** — `gaussian_bernoulli` and `gaussian_nbinom2` in closed form (`src/associate_pairs.jl:445`, `:465`), and `bernoulli_bernoulli` / `bernoulli_nbinom2` / `nbinom2_nbinom2` via a 1-D adaptive rectangle integral whose QuadGK error estimate is retained and surfaced by `integration_diagnostics` (`src/associate_pairs.jl:484`, `:509`); `test/test_associate_pairs.jl:63` (all five), `:115` (quadrature diagnostics). **The uncertainty is conditional on the frozen margins** — it ignores margin estimation error, and no simultaneous `eta` bands or profile intervals are offered, matching drmTMB (`src/associate_pairs.jl:540`; `test/test_associate_pairs.jl:167`). Boundary: the kernel must be explicit (`src/associate_pairs.jl:111`; `test/test_associate_pairs.jl:57`), only an intercept-only `association ~ 1` is implemented (`src/associate_pairs.jl:199`; `test/test_associate_pairs.jl:162`), `marginal = :AGHQ` is refused because QuadGK is not Liu–Pierce AGHQ (`src/associate_pairs.jl:105`), a **non-converged** margin is refused rather than frozen (`src/associate_pairs.jl:395`), a binomial margin must be literal 0/1 Bernoulli (`src/associate_pairs.jl:423`; `test/test_associate_pairs.jl:152`), and any pair outside the five reviewed classes is refused rather than approximated (`src/associate_pairs.jl:355`; `test/test_associate_pairs.jl:142`). |
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
  unwired variants not exposed (`fit_em_natgrad.jl` — #13 decision-gate FAIL, a
  recorded negative result; `fit_em_closed.jl`, `em_squarem_fit.jl` — the
  closed-form Λ step, whose #472 descent was an artefact of a dropped-zeros
  sparsity pattern and was repaired in #577); four superseded predecessors of the production engine
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
4. **q=2 location–scale coverage beyond NB2/Gamma.** (corrected 2026-09-05: the
   old premise — "the two-axis kernels exist only for NB2 and Gamma" — was
   false. `src/locscale_kernels.jl` implements seven leaves: NB2 `:56`, Gamma
   `:94`, Beta `:129`, BetaBinomial `:188`, Poisson `:216`, LogNormal `:239`,
   Gaussian mean `:266`.) Two genuine gaps remain, and they are different in
   kind:
   - **Kernels with no test.** The Poisson and LogNormal leaves are
     `Impl, untested`. Nothing in the default suite asserts their values —
     `Val(:poisson)` appears only in a negative assertion
     (`test/test_locscale_inner_status.jl:468`), and the one file exercising the
     LogNormal leaf, `test/test_corr_locscale_equiv.jl`, is commented out at
     `test/runtests.jl:222`. Each needs a ForwardDiff kernel-gradient gate of
     the kind `test/test_locscale_kernels.jl` already applies to NB2/Gamma.
   - **Tested kernels with no public route.** Beta and BetaBinomial are gated
     *and* recover parameters at the engine lane
     (`test/test_locscale_structured.jl`) but are unreachable from `drm()`:
     only `src/negbinomial.jl:94` and `src/gamma.jl:59` call
     `_fit_locscale_frontend`, even though `_ls_frontend_design` already carries
     both a BetaBinomial branch (`src/locscale_frontend.jl:126`, two-column
     response validation at `:127`) and a Beta response check (`:148`). Closing
     this needs a family-frontend change plus a public end-to-end recovery test
     — not a new kernel.

---

*Generated by an evidence-based capability audit against `src/DRM.jl` (include
list + exports) and `test/runtests.jl`. Each "Tested" row corresponds to a file
in the default `Pkg.test()` suite.*
