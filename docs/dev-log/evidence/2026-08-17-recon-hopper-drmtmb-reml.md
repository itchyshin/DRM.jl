# Hopper recon — drmTMB ordinary Gaussian REML (`(1 | g)`)

**Role:** Hopper (R↔Julia translator). **Read-only** of the twin. **No GPL source
vendored** — this note records the *user-facing contract* and *algorithmic idiom*
only. Line citations are locators, not paste.

**Date:** 2026-08-17. **G0 in view:** ordinary Gaussian mean-RE REML in DRM.jl
(`method = :REML` for Gaussian mean `(1 | g)`).

**Twin checkout:** `/Users/z3437171/Dropbox/Github Local/drmTMB` @
`claude/handover-freshness-0718` (`68960066f`). DRM.jl @ `docs/a3c-design`
(`bcd2c9dc`).

---

## 1. Twin repo path found (or not)

**Found.** Sibling checkout:

`/Users/z3437171/Dropbox/Github Local/drmTMB`

Primary locators (main tree, not `.worktrees/`):

| What | Path |
|---|---|
| User argument + default | `R/drmTMB.R` (`REML = FALSE` formals; roxygen `@param REML`) |
| Rd contract | `man/drmTMB.Rd` (`REML` item) |
| Estimator switch | `R/drmTMB.R` — `drm_apply_estimator_spec()` |
| Admission / rejection gates | `R/drmTMB.R` — `drm_validate_reml_spec()` |
| First-slice design | `docs/design/168-gaussian-reml-first-slice.md` |
| Likelihood wording | `docs/design/03-likelihoods.md` § First-Slice Gaussian REML |
| Idiom note (later expansion) | `docs/design/221-native-reml-finish.md` |
| Comparator tests | `tests/testthat/test-comparators.R` |
| Validation card | `docs/dev-log/validation-cards/gaussian-ordinary-re-lme4.md` |
| Capability census row | `docs/dev-log/dashboard/capability-census/gaussian.tsv` |

There is **no** live `docs/design/capability-status.md` on this drmTMB checkout
(only historical / worktree mentions). The census TSV is the live row.

C++ (`src/drmTMB.cpp`) has **no separate REML objective**. The only `REML`
hit is a comment that under REML the fixed effects sit in TMB's Laplace
`random` block, so `vcov()` reads the joint `sdreport` covariance. That is
consistent with the R-side idiom below; it is **not** an AI-REML or
Patterson–Thompson kernel in C++.

---

## 2. drmTMB user contract

**Spelling.** Top-level logical `REML` on `drmTMB(...)`.

- Default: `REML = FALSE` → estimator `"ML"`.
- Opt-in: `REML = TRUE` → estimator `"REML"`, `fit$REML = TRUE`.
- There is **no** `method = "REML"` argument on `drmTMB()` itself.
  `method = "REML"` appears only as a **metafor** comparator argument in
  known-`V` tests (`test-comparators.R`), not as the drmTMB API.

**Julia-native spelling (already established in DRM.jl, do not rename):**
`drm(...; method = :REML)` with default `:ML`. Match the *semantics*
(opt-in restricted likelihood; ML default for model selection), not the
R argument name.

**Which RE structures get REML (Gaussian, ordinary):**

Admitted on the native `engine = "tmb"` Gaussian surface (first slice + later
gate relaxations; current Rd + `drm_validate_reml_spec` + census):

- Ordinary **mean** random intercepts `(1 | g)` and numeric slopes
  (independent and correlated). This is the first-slice cell and the
  locked G0 twin.
- Later admissions (out of G0): ordinary **sigma** REs; matched
  mean–scale blocks; predictor-dependent `sigma ~ x`; `meta_V()` known
  sampling covariance; selected `phylo` / bounded `spatial` / `animal` /
  `relmat` shapes; some bivariate exceptions. **Do not inherit these
  into the G0 claim.**

Still rejected under REML (relevant fences):

- Ordinary direct `sd()` scale formulae.
- Gaussian row aggregation; sparse fixed-effect `mu`; explicit missing-data
  engines; `REML` + `penalty` (MAP) together.
- Non-Gaussian families except a separate binomial Cox–Reid slice (not this
  G0).
- Slope-only / labelled / multi-slope / matched mean–scale
  **non-phylogenetic** structured providers outside their exact row gates.

**Model-selection contract (shared with DRM.jl):** ML remains the default.
Use `REML = FALSE` for LRT / AIC / BIC across different fixed-effect
formulas. REML comparisons are for variance structures inside a **fixed**
mean structure. DRM.jl already guards this in `src/comparison.jl`.

**Julia engine on the R side:** experimental `engine = "julia"` forwards
`REML = TRUE` only for supported Gaussian **bridge** cells (FE loc-scale,
σ-phylo loc-scale, bivariate q=4 phylo). Ordinary `(1 | g)` REML is a
**native TMB** cell today, not a documented Julia-bridge cell.

---

## 3. Implementation idiom (R-side vs C++; no GPL paste)

REML is an **R-side estimator switch**, not a second C++ likelihood.

`drm_apply_estimator_spec(spec, REML)` leaves the Gaussian joint template
unchanged. When `REML` is false it labels the estimator `"ML"` and passes
the model's latent names through to TMB. When `REML` is true it validates
the spec, labels the estimator `"REML"`, and **appends the mean fixed-effect
coefficient vector** (`beta_mu`, or `beta_mu1`/`beta_mu2` if bivariate) to
TMB's Laplace `random` set. If a sigma variance component is present it
also appends the scale fixed-effect vector so the restriction covers
`beta_sigma`. TMB then integrates those coefficients with the ordinary
random effects. For a linear Gaussian that Laplace step **is** the
restricted (Patterson–Thompson) likelihood: the `|X'V⁻¹X|` term appears as
the Laplace correction. `vcov` for REML reads the full `sdreport` matrix
because the fixed effects are no longer in `cov.fixed`. `logLik` df is
aligned with `lme4` (optimized variance parameters plus the integrated
fixed effects).

**What DRM.jl must match:** the **statistical target** (integrate β_μ out
of the Gaussian marginal; restricted logLik; ML default). **What is
Julia-native:** do **not** port the TMB `random = c(latents, beta_mu)`
construction. DRM.jl already has Woodbury / exact Gaussian RE on
`src/gaussian_ranef.jl` and FE REML on the location-scale path. Ordinary
`(1 | g)` REML is Patterson–Thompson on that spine.

Comparator (twin, not to copy): `tests/testthat/test-comparators.R` —
`drmTMB(..., REML = TRUE)` vs `lme4::lmer(..., REML = TRUE)` for random
intercepts and correlated slopes (fixef, residual σ, RE SDs, restricted
logLik, df). Validation card
`docs/dev-log/validation-cards/gaussian-ordinary-re-lme4.md` records
point/objective agreement at 1e-4 and **explicitly withholds SE / interval
/ coverage** claims for this route.

---

## 4. capability-status / docs row

**drmTMB live census**
(`docs/dev-log/dashboard/capability-census/gaussian.tsv`):

| family | dpar | effect | estimator | status | evidence_tier |
|---|---|---|---|---|---|
| gaussian | mu | `ordinary_re_intercept` | ML | implemented | **supported** |
| gaussian | mu | `ordinary_re_intercept` | REML | implemented | **point_fit_recovery** |

Notes on that REML row: 40-replicate bias sim
(`tests/testthat/test-reml-bias-simulation.R`); not a q-series board cell;
direct `sd(id) ~ x` heterogeneity remains **rejected** under REML.

Ledger IDs on the validation card (UNVERIFIED as live board cells here —
card is `REPO-VERIFIED` of imported `mc-0264`/`mc-0265`/`mc-0268`/`mc-0269`
legacy evidence): intercept ML / intercept REML / slope ML / slope REML.

**DRM.jl card today** (`docs/design/capability-status.md`):

| Capability | Status |
|---|---|
| REML (Gaussian fixed-effect location-scale) | implemented |
| **REML with ordinary random effects (Gaussian mean)** | **rejected** |
| REML bivariate phylogenetic location-scale (q4, all axes) | implemented |

The rejected row cites `src/gaussian_core.jl` throwing
`method = :REML` unless the fit is FE loc-scale (no RE / structured / meta).
That is the hole this G0 flips — **on the Julia surface**, not via a
Workflow G fixture.

AI-REML is **not** a drmTMB ordinary-RE row. Design `221-native-reml-finish.md`
treats Cox–Reid / MC / AI-REML as **contingencies**, not the shipped idiom.
DRM.jl `lc_metric` is infrastructure for a possible later AI-REML, not a
public solver (`capability-status.md`).

---

## 5. Existing DRM.jl parity fixtures related to REML

**None.** Workflow G (`test/parity/`) has **no** `REML` string in any
`expected.toml` / `expected.meta.toml`, none in `gen_fixtures.R`, none in
`runparity.jl`.

`test/parity/README.md` states every case is fit by **ML** (the default;
“REML cases tagged explicitly”). No case is so tagged.

Committed fixtures (all ML; drmTMB **0.6.0**):

| Slug | `r_call` (abbrev.) | RE? | REML? |
|---|---|---|---|
| `gaussian-locscale` | `y ~ x, sigma ~ x`, `gaussian()` | no | no |
| `gaussian-bivariate-rho12` | biv FE + `rho12 ~ 1` | no | no |
| `meta-analysis-V` | `y ~ x + meta_V(V = v)` | no (known V) | no (ML default) |
| `count-poisson`, `count-nbinom2`, `nbinom2-dispersion`, `binomial-trials`, `proportion-beta`, `positive-gamma`, `positive-lognormal`, `robust-student` | FE families | no | no |
| `xfam-external-gllvm` | gllvm, not drmTMB REML | n/a | n/a |

There is **no** `(1 | g)` fixture at all, ML or REML. Therefore this G0 is
**not** a parity-complete claim even after a Julia path exists.

---

## 6. What this G0 must NOT claim

1. **Parity complete / Workflow G.** No REML+(1|g) fixture exists. Shipping
   Julia `method = :REML` for `(1 | g)` does not close Workflow G and must
   not be worded as drmTMB numeric parity.
2. **TSV / `meta_V` supported.** Twin *does* admit known-`V` REML (first
   slice + metafor comparators). DRM.jl G0 fence is mean `(1 | g)` only.
   The existing `meta-analysis-V` fixture is **ML**. Do not flip TSV /
   `supported` on the back of this slice.
3. **AI-REML / HSquared AI-REML.** Twin ordinary-RE REML is TMB Laplace
   restriction of β_μ, not average-information REML. DRM.jl `lc_metric` is
   not a public AI-REML solver. Do not mint that claim.
4. **Broader twin admissions.** Do not inherit sigma-RE REML, random
   slopes, structured providers, binomial Cox–Reid, bivariate exceptions,
   or `engine = "julia"` REML forwarding.
5. **SE / interval / coverage** for ordinary RE REML. Twin validation card
   withholds those; G0 bar is a path + small-n recovery vs ML, not
   inference_ready.
6. **Default change.** ML stays default. Do not sell REML as the
   model-selection estimator.

---

## 7. Co-opt vs n/a verdict

**CO-OPT the user contract and the statistical target. n/a for porting the
TMB implementation.**

drmTMB already does this exact cell: `REML = TRUE`, default ML, ordinary
Gaussian mean `(1 | g)` (and slopes) via R-side Laplace restriction of
β_μ, validated against `lme4`. DRM.jl should **match** opt-in REML + ML
default + restricted-likelihood target, implemented **Julia-natively** on
the existing Gaussian RE spine. Do **not** copy R/C++. Do **not** claim
Workflow G parity, TSV support, or AI-REML.

The DRM.jl card `REML with ordinary random effects (Gaussian mean)` is
honestly `rejected` today; flipping it to `implemented` is a Julia-surface
engine claim, gated by tests on this repo, not by a twin fixture.
