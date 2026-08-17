# Hopper remasure — live R↔Julia parity ledger (2026-08-16)

Date: 2026-08-16 · persona: **Hopper** (read-only scout) · no spawned subagents
Lane: Hopper remasure on Dropbox `docs/a3c-design` (write this note only)
Tool: catch-up worktree `tools/parity_ledger.py` (newer than Dropbox checkout)
drmTMB: **read-only** `git show origin/main:…` — no checkout, no worktree

## Command

```bash
cd /Users/z3437171/local-scratch/lanes/DRM.jl-catchup
python3 tools/parity_ledger.py \
  --drmtmb "/Users/z3437171/Dropbox/Github Local/drmTMB" \
  --ref origin/main
```

`--root` defaulted to the catch-up tree (`handover/2026-08-16-cursor` @ `d9214fd4`).
That tree's `src/DRM.jl` export set is **identical** to `DRM.jl origin/main`
(`394b62d9`, 154 exports). The Dropbox `docs/a3c-design` checkout is **not**
that surface (146 exports) — see *Which tree* below.

No `DRM_PARITY_TESTS`, no Rscript fixtures, no Julia suite.

## Raw countdown (measured)

```
drmTMB 0.7.0 @ origin/main (9e42d2c94)
  exports: 59   DRM.jl exports: 154

BRIDGE CAPABILITY ROWS (11) -- the campaign's countdown
  experimental    4  phylo_count_large_p, phylo_gamma_beta_binomial, general_covariance_structured, cross_family_latent
  partial         6  base_gaussian_location_scale, biv_gaussian_residual, gaussian_phylo_mean, gaussian_response_mask, biv_q4_phylo_reml, plain_binomial_nonphylo
  unsupported     1  engine_control_surface

GATES CLOSED BY INTENTIONAL ERROR (14)
  base_weights                       weights = ...
  base_impute                        impute = list(...)
  base_control                       control = list(...)
  base_missing_predictor_model       missing = miss_control(predictor = "model")
  base_missing_response_nongaussian  missing = miss_control(response = "include") with poisson()
  base_unsupported_family            family = beta_binomial() through engine = "julia"
  biv_invalid_partial_phylo          bivariate phylo on only one axis or on three axes
  biv_rho12_phylo                    phylo() term in rho12
  structured_unsupported_family      relmat() with beta()
  structured_sigma_predictor         structured relmat() with sigma ~ x
  structured_precision_slot          relmat(..., Q = Q)
  xfam_missing_route                 cross-family response missingness
  xfam_rho12_formula                 cross-family rho12 formula
  xfam_dispersionless_sigma          cross-family sigma formula on dispersionless axis

ACCOUNTED FOR IN WRITING (18) -- not owed, and why
  biv_associate          delivered as associate_pairs() -- the staged frozen-margin route (A3c)
  biv_lognormal          delivered as LogNormal() with a bivariate formula (A3a, parity-verified)
  biv_student            delivered as Student() with a bivariate formula (A3b, parity-verified)
  categorical            an imputation family (drm_impute_family), not a response family -- #49 PARKED
  centile_chart          R post-fit function fed by the drm_bridge dpars payload (A2a)
  corpair                BLOCKED: StatsModels' @formula cannot express keyword args or string literals, so drmTMB's syntax is not representable; and the fitted route needs the labelled covariance-block grammar (1|p|id), absent in DRM.jl
  exceedance             R post-fit function fed by the drm_bridge dpars payload (A2a)
  fitted_distribution    R post-fit function fed by the drm_bridge dpars payload (A2a)
  impute_model           missing-data surface -- #49 PARKED
  imputed                missing-data surface -- #49 PARKED
  make_mesh              R-side geospatial prep (sf, CRS validation) before any fit -- owner-confirmed
  meta_vcov_bivariate    BLOCKED: meta_V is diagonal-only and the bivariate route ignores metav, so the output would have no consumer
  mi                     missing-data surface -- #49 PARKED
  miss_control           missing-data surface -- #49 PARKED
  qq_plot                R post-fit function fed by the drm_bridge dpars payload (A2a)
  rho_latent             delivered as fit.rho_latent, surfaced through mf_summary()
  spatial_coords         R-side geospatial prep before any fit -- owner-confirmed
  worm_plot              R post-fit function fed by the drm_bridge dpars payload (A2a)

drmTMB EXPORTS WITH NO DRM.jl TWIN (0) -- genuinely owed

COUNTDOWN: 0 export gaps (18 raw, 18 accounted for) · 11 unsupported capability rows · 14 closed gates

CLOSURE: PASS — every one of 11 capability rows is supported or carries a written claim_boundary; all 14 closed gates carry evidence + review_due
```

Exit code **0**.

## vs handover / GOAL claims

| Claim | Source | Live measure |
|---|---|---|
| `COUNTDOWN: 0 export gaps (17 raw, 17 accounted for) · 11 unsupported capability rows · 14 closed gates` | handover 2026-08-16 | **0** gaps · **18** raw · **18** accounted · **11** non-`supported` rows · **14** gates |
| `CLOSURE: PASS` | handover + `LOOP/GOAL.md` | **PASS** (re-measured) |
| Anchor `f5ec53634` | GOAL / A0 | drmTMB still **0.7.0**; `origin/main` is now **`9e42d2c94`** (111 commits past `f5ec53634`) |
| Lane-start `22` export gaps | `LOOP/GOAL.md` (catch-up) | **0** owed on catch-up / `origin/main` |

The **17 → 18** raw/accounted drift is **not** a new owed export. drmTMB
`NAMESPACE` at `f5ec53634` and `origin/main` is the same 59 names. The extra
accounted row is ledger-class bookkeeping (`DELIBERATELY_NOT_PORTED`), not a
missing twin. Owed gaps stay **0**.

`julia-capabilities.tsv` `claim_status` values are **unchanged** since
`f5ec53634`. Three `next_action` cells grew measured numbers (Gaussian loc-scale
coef/logLik; structured-vs-gate pointer; FE Poisson/NB2/Gamma logLik). No row
flipped to `supported`.

## The 11 non-`supported` capability rows

The ledger's phrase **"11 unsupported capability rows"** means
`claim_status != "supported"` (script: `sum(… != 'supported')`). It is **not**
11 rows with status `unsupported`. Split: **6 partial · 4 experimental · 1
unsupported**. **Zero** rows are `supported`.

`claim_boundary` text is from `git show origin/main:inst/extdata/julia-capabilities.tsv`
(one line each, as written).

| capability_id | claim_status | claim_boundary |
|---|---|---|
| `base_gaussian_location_scale` | partial | Phase 1.5 Hopper admitted cell (Route C): offline result-shape + optional live TMB parity; CRAN readers still use TMB — vignette keeps Julia deferred/experimental. |
| `biv_gaussian_residual` | partial | Phase 1.5 Hopper admitted cell (Route B): residual rho12 result-shape + optional live logLik parity; not a phylo or cross-family claim. |
| `gaussian_phylo_mean` | partial | Phase 1.5 Hopper admitted cell (Route A): first phylo-mean (`sigma ~ 1`) marshalling/result-shape + optional live TMB parity; not loc-scale phylo or non-Gaussian phylo. |
| `gaussian_response_mask` | partial | Gaussian-only response masks; missing predictors and non-Gaussian response masks remain gated. |
| `biv_q4_phylo_reml` | partial | Requires the full four-axis phylogenetic location-scale grammar; native TMB has separate q4 recovery evidence, but this Julia row does not establish same-target bridge parity, interval reliability, or HSquared AI-REML support. |
| `plain_binomial_nonphylo` | partial | Live R Workflow G binomial-trials cell vs DRM.jl `expected.toml`; still experimental, not a CRAN default. |
| `phylo_count_large_p` | experimental | Large-p phylogenetic random-intercept route; Workflow G FE count cells also route via live `expected.toml` parity (#499). |
| `phylo_gamma_beta_binomial` | experimental | Finite-and-sane bridge smoke evidence only; no native TMB parity or non-phylo binomial bridge promotion. |
| `general_covariance_structured` | experimental | Requires covariance/relatedness matrix `K` and `sigma ~ 1`; beta, precision `Q`, and sigma predictors stay gated. |
| `cross_family_latent` | experimental | Latent-rho development route; public docs must not present rho12 formulas or release-ready cross-family inference. |
| `engine_control_surface` | unsupported | Do not document user-selectable Julia optimizer controls until a real R API is designed. |

## What COUNTDOWN 0 does and does not mean

**Does mean (measured):** no drmTMB `NAMESPACE` export lacks a DRM.jl twin after
aliases + the written `DELIBERATELY_NOT_PORTED` list. Closure invariant holds:
every capability row is `supported` **or** has a non-empty `claim_boundary`;
every intentional-error gate has `evidence` + `review_due`.

**Does not mean:** R↔Julia parity is complete, or `engine = "julia"` is a CRAN
default, or any capability row is `supported`. The campaign opened with 11
registry rows and still has 11; none have been promoted. "0" is an **export-name
countdown**, not a capability-readiness countdown. `LOOP/GOAL.md` still requires
native-vs-Julia fixtures before a cell is "caught up" in the D-111 sense.

## Handover OWED items vs parity claims

From `docs/dev-log/handover/2026-08-16-cursor-handover.md` (catch-up tree):

| OWED | Affects a parity *capability* claim? |
|---|---|
| 1. Lane preflight | No — process. |
| 2. Red CI / Documenter logs / `gh-pages` races | No — docs/CI. The dead-`@ref` that broke #423 is the same class as OWED 6. |
| 3. #428 A11 mixed-family formula (`feat/a11-cross-family-formula`) | **Yes — `src/`.** This is `cross_family_latent`. TSV `next_action`: "Resolve the mixed-family API mismatch before any public promotion." |
| 4. #429 stacked on #423 (A12 recovery) | Recovery evidence for the known-`V` meta path — not a ledger row flip by itself. |
| 5. Re-run the ledger after each merge | This note. Scoreboard hygiene, not a new cell. |
| 6. Undocumented `@ref` / missing `@docs` (16 exported symbols) | **Docs, not a capability gap.** VitePress dies on a literal `./@ref`; it does not change `claim_status`. |
| 7. Then pick up the 11 non-`supported` rows | The capability frontier. Owner picks the slice. |

## Which tree (do not mix)

| DRM.jl root | Exports | Ledger countdown |
|---|---|---|
| catch-up worktree / `origin/main` (identical export set) | 154 | **0** owed (18 raw, 18 accounted) |
| Dropbox `docs/a3c-design` | 146 | **4** owed: `drm_phylo_penalty`, `drm_phylo_penalty_sweep`, `profile_targets`, `structured_effects` |

Those four twins landed in #414 / #415 on `main`. Measuring the Dropbox design
branch and calling it the G0 scoreboard would be a false 4-gap regression.

## Recommended next capability slice (recommendation only — owner picks)

**`cross_family_latent` via #428 (A11).** It is the only open `src/` PR whose
registry `next_action` is an API mismatch that blocks promotion. The sole
literal-`unsupported` row (`engine_control_surface`) is a design fence, not a
port. The six `partial` rows are already admitted Phase 1.5 cells; promoting any
of them is a **drmTMB TSV edit** (STOP GATE — do not merge unattended), not a
DRM.jl export gap.

Do not start that slice from this remasure. Owner chooses.
