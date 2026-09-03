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
| Tweedie random intercept (mean) | implemented |

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

`Tweedie random intercept (mean)` is `implemented` (#563 S8): an ordinary
`(1 | g)` random intercept on `mu` via 32-node Gauss–Hermite quadrature
(`src/tweedie.jl` `_fit_tweedie_ranef`, the same scheme as the Poisson/Gamma
`(1 | g)` routes), same-target checked against drmTMB 0.7.0
(`test/test_tweedie_ranef.jl`, fixture
`test/parity/fixtures/tweedie-mu-ranef/`). Matches drmTMB's own scope exactly:
the correlated random slope `(1 + x | g)`, random effects on `sigma`/`nu`, and
structured (phylo/relmat/animal/spatial) markers on `mu` stay `rejected` in
both packages (drmTMB's `validate_tweedie_mu_random_terms()` /
`validate_tweedie_random_terms()`); the independent-slope route
`(0 + x | g)`, which drmTMB *does* support, is not wired in DRM.jl yet.

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
| AGHQ adaptive-quadrature marginal estimator | implemented |
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
`test/test_reml_ordinary_ranef.jl`, which is **in the default suite**
(`test/runtests.jl`, wired by #445 "Option A" after #439/#440 landed);
`test/test_reml.jl` retains the random-slope rejection. ML stays the
default. This is not AI-REML, not a TSV flip, and not “parity complete.”

`REML bivariate phylogenetic location-scale (q4, all axes)` is `implemented`:
`src/reml_q4.jl` is included in the module (`src/DRM.jl:55`) and
`test/test_reml_q4_allaxes.jl` is in the default suite
(`test/runtests.jl`), asserting the restricted correction reaches all four
axes (mu1, mu2, sigma1, sigma2; issue #18 regression). **This corrects
`docs/src/capabilities.md`**, which still describes `reml_q4` as
"present in `src/experimental/` only; not in the `DRM.jl` include list" --
that was true when the audit page was written but is no longer true; `git log`
shows `src/DRM.jl`'s include list was touched after the audit page's last
commit.

`Model comparison suite (LRT/anova/AICc/weights/update)` is `implemented`, but the
`weights` member needs reading carefully, because two things in this ledger point
different ways and a scanning reader will take the wrong one.

- It is **not** Akaike / model weights. Neither DRM.jl nor drmTMB computes those,
  despite `weights` sitting in a list next to `AICc` — which is precisely the
  reading the row name invites. There is no `akaike_weights` in either package.
- It is `StatsAPI.weights`: **prior, per-observation** weights. `src/comparison.jl`
  returns `ones(nobs(fit))` unconditionally, because DRM.jl fits do not store prior
  weights at all. Its docstring says so plainly.
- drmTMB's `weights.drmTMB` returns a real stored vector (`object$model$weights`,
  `R/methods.R`), which it genuinely uses — its bootstrap reads it
  (`R/profile.R`) and `associate_pairs()` guards on `any(weights != 1)`.

So the accessor is at parity in *name* and not in *substance*, and the gap is
already recorded elsewhere in this ledger: the `base_weights` gate is closed as an
`intentional_error` on the grounds that "DRM.jl bridge payload has no weights
slot". Passing `weights = ...` through `engine = "julia"` is refused.

Kept `implemented` because every named member exists and is exported, which is this
file's stated bar. Flagged because a row can meet the bar and still leave a reader
believing something false — and the fix for that is prose, not a status change.

`Chi-bar-square boundary LRT p-value` is `implemented`: `src/chibar.jl` is
included (`src/DRM.jl:129`), exports `chibar_pvalue`/`lrt_boundary`
(`src/DRM.jl:160`), and `test/test_chibar.jl` is in the default suite
(`test/runtests.jl`). **This also corrects `docs/src/capabilities.md`**,
which lists chi-bar-square boundary inference as "Absent -- no
implementation."

`AGHQ adaptive-quadrature marginal estimator` is `implemented` (2026-08-24
audit, PR #449 / commit `93c3db6b`, merged 2026-08-18): `src/aghq_1d.jl` is
included at `src/DRM.jl:75` and wires a public front end on `drm()`
(`marginal = :AGHQ`, Poisson `(1 | g)` only — `src/poisson.jl:35-37,176-177`).
`test/test_aghq_1d.jl` is in the default suite (`test/runtests.jl`) and
exercises the quadrature kernel, the public fit path, and the fail-loud
guards on every unsupported structure (phylo, crossed, correlated slope,
other families, `:REML`, `associate_pairs`). This corrects the prior
`missing` cell: the same PR that landed the code also wrote the `missing`
row and its "not ADEMP-certified" rationale, but by this file's own ladder
(source + a registered test) that is source-and-test evidence for
`implemented`, not for `missing`. Scope stays exactly what #448 shipped —
Poisson `(1 | g)` only, `:REML` not wired to `:AGHQ`, tensor/multi-d AGHQ on
phylo Laplace out of scope — this flip changes the status word only, not the
scope.

`Variational (VA/ELBO) marginal estimator` stays `planned` here, but the
citation needs correcting: `test/test_variational.jl` is not plumbing-only
(anchors exercise real ELBO fits), and the public `marginal = :VA` front end
works — not just the generic `_fit_va` stub — for Poisson / Binomial /
NegBinomial2 / Gamma / Beta `(1 | g)` (`src/poisson.jl:26`,
`src/binomial.jl:38`, `src/negbinomial.jl:69`, `src/gamma.jl:34`,
`src/beta.jl:35`), each with its own registered test
(`test/test_va_poisson_elbo.jl`, `test/test_va_frontend_families.jl`,
`test/test_variational_binomial.jl`, `test/test_variational_nb2.jl`,
`test/test_variational_gamma.jl`; `test/runtests.jl`). Per
`docs/dev-log/check-log.d/2026-08-09-136-va-rung2-3.md`, the project's own
guide banner was corrected from "Planned" to "Experimental" for this reason,
and that entry explicitly notes "Does not close #136." This audit leaves the
chip word alone: issue #136 stays open (phylo, crossed, correlated slopes,
zi/hu, and 136e remain unwired, per `src/variational.jl`'s own docstrings),
and the owner's 2026-08-24 flip authorization named AGHQ specifically, not
VA. Treat this row with the same care as `:natgrad` and `#49` below: real
code exists for a real subset, but this audit does not upgrade the chip past
what the open issue supports without a separate, explicit call.

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
`Cross-family bivariate` stays `missing` here, but the citation needs
correcting: `docs/src/capabilities.md`'s "single `gaussian_bivariate.jl`
bivariate source file" claim is stale. `src/mixed_family.jl` (shared-latent
GHQ across two different families) is included at `src/DRM.jl:101`, and
`src/mixed_family_postfit.jl` at `src/DRM.jl:102`; a formula front end
(`drm(f::BivariateDrmFormula, fams::Tuple; data, …)`, commit `0095fefd`) now
reaches it instead of hand-built design matrices. Tests are real and
registered in the default suite: `test/test_mixed_family.jl` (Gaussian x
Poisson and Gaussian x Gaussian recovery-style tests), `test/test_mixed_family_postfit.jl`,
and `test/test_cross_family_formula.jl` (`test/runtests.jl`). By
this file's literal ladder (source + a registered test) that reads as
qualifying for `implemented`. It stays `missing` on this audit because the
PR that landed the formula front end recorded an explicit non-promotion
call: `docs/dev-log/check-log.d/2026-08-16-a11-cross-family-formula.md` --
"No promotion — the row stays `experimental`; this removes its stated
blocker, which is drmTMB's call to act on." That decision has not been
revisited since, and the owner's 2026-08-24 authorization named AGHQ
specifically. This audit leaves the chip alone and flags the tension for the
owner rather than flipping it unilaterally (detail in the evidence file).

`Missing-response handling (native, per fitted route)` stays `missing`, with
two citation corrections. First, `src/missing_data.jl` is included at
`src/DRM.jl:131`, not `:101` (`:101` is `mixed_family.jl`, above). Second,
"explicit listwise (complete-case) deletion only" undersells what exists:
`_fit_observed_response_rows` (`src/gaussian_core.jl:740`) is a shared helper
used by twelve family files (`beta.jl`, `betabinomial.jl`, `binomial.jl`,
`cumulative.jl`, `gamma.jl`, `gaussian_core.jl`, `lognormal.jl`,
`negbinomial.jl`, `poisson.jl`, `tweedie.jl`, `student.jl`,
`zeroonebeta.jl`) that auto-drops missing/NaN-response rows inside `drm()`
itself, with a warning, for every one of those families -- no separate
`drm_listwise` call needed. Separately, `leaf_nll` in `src/sparse_aug_plsm.jl:37`
(the flagship q4 bivariate phylo engine, wired via `src/fit_q4_sparse_tmb.jl`
at `src/DRM.jl:40`) takes per-cell `o1`/`o2` observed flags and evaluates the
correct univariate marginal when only one axis is observed -- a genuine
masked partial likelihood, not row deletion. Registered tests:
`test/test_missing_response.jl`, `test/test_missing_response_nongaussian.jl`
(fourteen families), and `test/test_missing_response_bivariate.jl` (FD-vs-exact
gradient with masked cells, plus a missing-at-random fit check)
(`test/runtests.jl`). This is still short of drmTMB's named row --
a native masked likelihood across 18 fitted routes -- because outside the q4
bivariate engine the native mechanism is auto-triggered listwise deletion,
the same underlying operation as `drm_listwise`, not a masked likelihood;
issue #49 remains open and its own file header states FIML for missing
responses is explicitly out of scope. This audit leaves the chip as `missing`
given #49 is parked and the owner's 2026-08-24 authorization did not name
this row, but corrects the stale citations and the "listwise deletion only"
undercount above. `Missing-predictor imputation (mi())` is `missing` on
direct evidence: no `mi(` function, export, or reference exists anywhere in
`src/` (grep-confirmed); `missing_data.jl`'s own header puts multiple
imputation for missing predictors explicitly out of scope under the same
issue #49.

`R to Julia bridge (engine=julia)` is `implemented`: `src/bridge.jl` exports
`drm_bridge`/`drm_bridge_inference` (`src/DRM.jl` export list), and
`test/test_bridge.jl` asserts the bridge output equals native `drm` output.

## Snapshot

- 46 capabilities, all `implemented`/`rejected`/`planned`/`missing` per the
  mapping above; 41 `implemented`, 1 `rejected` (`:natgrad`), 1 `planned`,
  3 `missing`. (2026-08-24 chip audit flips `AGHQ adaptive-quadrature
  marginal estimator` `missing` -> `implemented`: PR #449 / commit
  `93c3db6b` landed source wired into `src/DRM.jl` plus a test registered in
  `test/runtests.jl`, meeting this file's own ladder. The same audit
  re-examined `Cross-family bivariate`, `Missing-response handling (native,
  per fitted route)`, and `Variational (VA/ELBO) marginal estimator`, found
  source+test evidence undercounted in each, corrected the stale citations,
  and left all three chips unflipped for documented reasons -- see
  `docs/dev-log/evidence/2026-08-24-chip-audit.md`. Prior snapshot said 37/1
  while the table still listed two `rejected` rows; that recount flipped the
  ordinary-RE REML chip and left `:natgrad` as the only `rejected` row.)
- Sources read: `src/DRM.jl` (include list + export list), `README.md`,
  `docs/src/capabilities.md`, `docs/src/families.md`, `test/runtests.jl`
  (default-suite include list), and targeted `grep`/`git log` against
  `src/gaussian_core.jl`, `src/gaussian_ranef.jl`,
  `test/test_reml_ordinary_ranef.jl`, `src/reml_q4.jl`, `src/chibar.jl`,
  `src/missing_data.jl`, `src/skewnormal.jl`, `src/variational.jl`,
  `src/aghq_1d.jl`, `src/mixed_family.jl`, and `src/sparse_aug_plsm.jl` to
  verify claims the docs page did not make or got stale on.
- `docs/src/capabilities.md` is a real, evidence-cited audit but is **stale**
  in three places corrected above (SkewNormal, `reml_q4`, chi-bar-square);
  trust the code citations in this file over that page where they disagree.
