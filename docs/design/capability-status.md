# DRM.jl capability status (R <-> Julia parity view)

This file is the Julia-side input to the mission-control R <-> Julia parity
board. It uses the **same model-level capability names** as drmTMB's
`docs/design/capability-status.md` so the mission-control server can match
rows by name across the two twins.

Status words:

- `implemented` -- found real code AND a test file exercising it (an export in
  `src/DRM.jl`'s export list plus a matching `test/test_*.jl`, and for the
  default-suite claims, included in `test/runtests.jl`).
- `rejected` -- found real code that deliberately refuses the capability (an
  explicit `throw(ArgumentError(...))` or equivalent guard), verified by
  reading the guard.
- `planned` -- a tracked, documented stub (an issue number, an explicit `error()`
  pointing at a GitHub issue, or a `src/experimental/` file not yet wired into
  the module).
- `missing` -- no implementation found anywhere in `src/`, `docs/`, `README.md`,
  `ROADMAP.md`, or `HANDOVER.md`.

Nothing below is marked `implemented` without a source file and a test file
both found by reading the repository (not by trusting `docs/src/capabilities.md`
alone -- see the note at the end: that audit page is stale in three places that
this file corrects).

## Response families

`src/DRM.jl`'s export line lists all 13 named families plus the `zi`/`hu`
count modifiers and `zoi`/`coi` beta boundary modifiers; the bivariate
Gaussian route and the q4 phylogenetic bivariate location-scale (PLSM) model
are separate exports. Every row below has a source file under `src/` and a
`test/test_*.jl` file.

| Capability | Status |
|---|---|
| Gaussian location-scale (ML) | implemented |
| Bivariate Gaussian coscale (rho12) | implemented |
| Student-t location-scale | implemented |
| LogNormal location-scale | implemented |
| Gamma location-scale | implemented |
| Poisson counts | implemented |
| NegBinomial2 (NB2) counts | implemented |
| Zero-inflated Poisson (ZIP) | implemented |
| Zero-inflated NB2 (ZINB) | implemented |
| Beta proportions | implemented |
| Truncated NB2 (zero-truncated counts) | implemented |
| Hurdle NB2 | implemented |
| Cumulative logit (ordinal) | implemented |
| Beta-binomial proportions | implemented |
| Zero-one-inflated beta | implemented |
| Tweedie (compound Poisson-Gamma) | implemented |
| Skew-normal location-scale | implemented |
| Binomial (logistic) | implemented |

`Skew-normal location-scale` is marked `implemented` from direct source
evidence (`src/skewnormal.jl`, exported `SkewNormal` in `src/DRM.jl`,
`test/test_skewnormal.jl`) even though `docs/src/capabilities.md`'s family
table omits it -- that audit page is stale here.

## Random-effect structure

`src/gaussian_ranef.jl`, `src/gaussian_structured.jl`, and
`src/sparse_laplace_glmm.jl` back the Gaussian and non-Gaussian random-effect
rows; each has a `test/test_*.jl` file cited in `docs/src/capabilities.md`'s
"Random-effect structures" section.

| Capability | Status |
|---|---|
| Gaussian random intercept (mean) | implemented |
| Gaussian random slope (mean) | implemented |
| Gaussian random effect on sigma (scale) | implemented |
| Gaussian phylogenetic random intercept (mean) | implemented |
| Gaussian spatial random intercept (mean) | implemented |
| Gaussian animal-model random intercept (mean) | implemented |
| Gaussian relmat random intercept (mean) | implemented |
| Non-Gaussian phylogenetic random intercept (mean) | implemented |
| Non-Gaussian phylogenetic location-scale (μ + log σ) | implemented |

`Non-Gaussian phylogenetic random intercept (mean)` is `implemented` via the
sparse augmented-state Laplace engine (`src/sparse_laplace_glmm.jl`) for
Poisson, NegBinomial2, Gamma, Binomial, and Beta, each with its own
`test/test_*_phylo_laplace.jl` plus a gradient gate. This is a genuine R <-> Julia
gap: drmTMB reports this row `scope-limited` (mixed rejected/scope-limited
across families).

`Non-Gaussian phylogenetic location-scale (μ + log σ)` is `implemented`
(`closes #202`): shared structured RE on mean **and** scale via grammar B
`(1 | p | phylo(species))` on both axes, routed through `src/locscale_*.jl`.
Public evidence: `test/test_public_phylo_locscale.jl` (NB2 recovery + Gamma
smoke; dual issue-text `phylo(1|sp)` on both axes still rejected). Private
Gamma recovery + FD ≤1e-6 already in `test/test_phylo_locscale.jl` (#253).
**D-94 honesty:** drmTMB still skips coupled `(1|p|species)` for nbinom2 in
our parity generator; R q=1 NB2 structured-σ covers scale-axis existence.
No `nbinom2-locscale` R fixture in this closeout.

## Estimation and inference

| Capability | Status |
|---|---|
| REML (Gaussian fixed-effect location-scale) | implemented |
| REML with ordinary random effects (Gaussian mean) | implemented |
| REML bivariate phylogenetic location-scale (q4, all axes) | implemented |
| Conjugate-EM Gaussian phylo-mean (`algorithm = :em`) | implemented |
| Natural-gradient EM (`algorithm = :natgrad`) | rejected |
| Fisher / observed-info metric (`lc_metric`) | implemented |
| Wald SEs and CIs (observed information) | implemented |
| Profile-likelihood CIs | implemented |
| Parametric bootstrap CIs | implemented |
| AGHQ adaptive-quadrature marginal estimator | missing |
| Variational (VA/ELBO) marginal estimator | planned |
| Chi-bar-square boundary LRT p-value | implemented |
| Model comparison suite (LRT/anova/AICc/weights/update) | implemented |
| Heritability/repeatability/ICC accessors | implemented |

`Natural-gradient EM (algorithm = :natgrad)` is `rejected` on measured evidence
(2026-08-01 #13 decision gate): `fit_em_natgrad` stalls at logLik ≈ −259.80 on
`q4_p100` vs `fit_q4_sparse_tmb` −256.51 (same class as plain block-coordinate
EM). Brief: `docs/dev-log/plans/2026-08-01-natgrad-decision-gate.md`. The
reusable Fisher metric was extracted as `lc_metric` (`src/lc_metric.jl`,
`test/test_lc_metric.jl`) — infrastructure for AI-REML / #11/#165, **not** a
public solver.

`REML with ordinary random effects (Gaussian mean)` is `implemented` (#439):
`src/gaussian_core.jl` admits a single Gaussian mean intercept `(1 | g)`
under opt-in `method = :REML` (the former 413–423 FE-only hole; σ-RE, slopes,
multi-ranef, and structured / phylo / meta stay `ArgumentError`), and
`src/gaussian_ranef.jl` adds the Patterson–Thompson term
`½ logdet(Xμ′ V⁻¹ Xμ)` on the Woodbury spine. Exercised by
`test/test_reml_ordinary_ranef.jl` (standalone; **not in the default suite yet**)
only; `test/test_reml.jl` retains the random-slope rejection. ML stays the
default. This is not AI-REML, not a TSV flip, and not “parity complete.”

`REML bivariate phylogenetic location-scale (q4, all axes)` is `implemented`:
`src/reml_q4.jl` is included in the module (`src/DRM.jl:38`) and
`test/test_reml_q4_allaxes.jl` is in the default suite
(`test/runtests.jl:230`), asserting the restricted correction reaches all four
axes (mu1, mu2, sigma1, sigma2; issue #18 regression). **This corrects
`docs/src/capabilities.md`**, which still describes `reml_q4` as
"present in `src/experimental/` only; not in the `DRM.jl` include list" --
that was true when the audit page was written but is no longer true; `git log`
shows `src/DRM.jl`'s include list was touched after the audit page's last
commit.

`Chi-bar-square boundary LRT p-value` is `implemented`: `src/chibar.jl` is
included (`src/DRM.jl:99`), exports `chibar_pvalue`/`lrt_boundary`
(`src/DRM.jl:125`), and `test/test_chibar.jl` is in the default suite
(`test/runtests.jl:251`). **This also corrects `docs/src/capabilities.md`**,
which lists chi-bar-square boundary inference as "Absent -- no
implementation."

`AGHQ adaptive-quadrature marginal estimator` is `missing`: the "Marginal
method selection" table in `docs/src/capabilities.md` lists only `:LA`
(implemented) and `:VA` (stub); no AGHQ symbol appears in `src/DRM.jl`'s
export list, `ROADMAP.md`, `HANDOVER.md`, or `README.md`.
`Variational (VA/ELBO) marginal estimator` is `planned`: `src/variational.jl`
exists, `_fit_va` deliberately `error`s and points at issue #136, and
`test/test_variational.jl` asserts only the method-selection plumbing, not a
working VA fit.

## Bivariate structure and missing data

| Capability | Status |
|---|---|
| Bivariate structured random effect on all four axes (q4 PLSM) | implemented |
| Cross-family bivariate (different families for y1 y2) | missing |
| Missing-response handling (native, per fitted route) | missing |
| Missing-predictor imputation (mi()) | missing |
| R to Julia bridge (engine=julia) | implemented |

`Bivariate structured random effect on all four axes (q4 PLSM)` is the
flagship verified engine (`src/sparse_phy.jl`, `src/takahashi_selinv.jl`,
`src/sparse_aug_plsm.jl`, `src/fit_q4_sparse_tmb.jl`), with `Sigma_a` stored
on the fit. Providers: phylo tree (`test/test_gaussian_bivariate_phylo.jl`) and
level-indexed `relmat` / `animal` / fixed-range `spatial` via
`make_problem_from_Q` (`test/test_gaussian_bivariate_q4_structured.jl`, #189).
`Cross-family bivariate` is `missing`: `docs/src/capabilities.md` states the
bivariate path is Gaussian-only and no cross-family bivariate model exists;
confirmed by the single `gaussian_bivariate.jl` bivariate source file.

`Missing-response handling (native, per fitted route)` is `missing` **as
named** -- drmTMB's row means a native masked likelihood across 18 fitted
routes. DRM.jl does have a real, tested, but functionally different utility
(`src/missing_data.jl`, included at `src/DRM.jl:101`, five `test/test_missing_*.jl`
files): explicit listwise (complete-case) deletion only. Its own file header
states "DRM.jl has NO native missing-data handling" and explicitly puts FIML
for missing responses and multiple imputation for missing predictors
out of scope (tracked under issue #49). Because listwise deletion is not the
same capability as drmTMB's native per-route masked likelihood, this row is
reported `missing` rather than `implemented`; `Missing-predictor imputation
(mi())` is `missing` for the same reason (imputation is explicitly out of
scope in the same file).

`R to Julia bridge (engine=julia)` is `implemented`: `src/bridge.jl` exports
`drm_bridge`/`drm_bridge_inference` (`src/DRM.jl` export list), and
`test/test_bridge.jl` asserts the bridge output equals native `drm` output.

## Snapshot

- 46 capabilities, all `implemented`/`rejected`/`planned`/`missing` per the
  mapping above; 40 `implemented`, 1 `rejected` (`:natgrad`), 1 `planned`,
  4 `missing`. (Prior snapshot said 37/1 while the table still listed two
  `rejected` rows; this recount flips the ordinary-RE REML chip and leaves
  `:natgrad` as the only `rejected` row.)
- Sources read: `src/DRM.jl` (include list + export list), `README.md`,
  `docs/src/capabilities.md`, `docs/src/families.md`, `test/runtests.jl`
  (default-suite include list), and targeted `grep`/`git log` against
  `src/gaussian_core.jl`, `src/gaussian_ranef.jl`,
  `test/test_reml_ordinary_ranef.jl`, `src/reml_q4.jl`, `src/chibar.jl`,
  `src/missing_data.jl`, `src/skewnormal.jl`, and `src/variational.jl` to
  verify claims the docs page did not make or got stale on.
- `docs/src/capabilities.md` is a real, evidence-cited audit but is **stale**
  in three places corrected above (SkewNormal, `reml_q4`, chi-bar-square);
  trust the code citations in this file over that page where they disagree.
