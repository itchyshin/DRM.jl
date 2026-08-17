# S2 — remaining partials (rows 4–6)

**Persona:** Hopper (conductor recon on Cursor Grok; no Task child).
**Date:** 2026-08-16. **Read-only.** No `src/`. No TSV flip. `#49` stays PARKED.
**TSV:** drmTMB `origin/main` `d9fddfa28` (unchanged vs `097bed1e2`).

## 4. `gaussian_response_mask`

| Field | Value |
|---|---|
| claim_status | `partial` |
| class | **parked-adjacent** (fixture/audit gap; do not unpark `#49`) |
| claim_boundary | "Gaussian-only response masks; missing predictors and non-Gaussian response masks remain gated." |
| next_action | Keep mask tests Gaussian-only until non-Gaussian observed-data likelihoods are audited. |
| existing fixture | Julia observed-rows path: `test/test_missing_listwise.jl` (header still cites `#49`). Also `test/test_missing_response_bivariate.jl`, `test/test_missing_response_nongaussian.jl` (gates). **NONE** as a Workflow G same-target `expected.toml` for `miss_control(response = "include")`. |
| twin map | **YES** (`miss_control(response = "include")`; vignette `missing-data`). Predictor `mi()` / `impute` is a **different** surface — `#49` PARKED. |
| collision | Soft: `#49` parked. Do not treat this inventory row as permission to unpark. `#425` owns `src/binomial.jl` / missing-adjacent engine files — do not touch. |
| later implement? | No. Adjacent to `#49`. Not the recommended slice. |

## 5. `biv_q4_phylo_reml`

| Field | Value |
|---|---|
| claim_status | `partial` |
| class | **fixture-gap** (same-target bridge parity; engine already exists) |
| claim_boundary | "Requires the full four-axis phylogenetic location-scale grammar; native TMB has separate q4 recovery evidence, but this Julia row does not establish same-target bridge parity, interval reliability, or HSquared AI-REML support." |
| next_action | Bank fit-specific CI/status parity before release language. |
| existing fixture | Julia REML path **implemented**: `test/test_reml_q4_allaxes.jl` (Scoreboard B: implemented). Bridge export explicitly refuses a parity claim: `test/test_bridge_q4_direct_export.jl` asserts `"no R-via-Julia q4 bridge parity"`. **NONE** as a native-vs-Julia same-target coef+logLik fixture. |
| twin map | **YES** (`drmTMB(..., REML = TRUE)` + four-axis `phylo()` + `biv_gaussian()`). Do not invent AI-REML / interval coverage as the twin. |
| collision | none of the open PRs own this ID. Do not conflate with ordinary-RE REML (Scoreboard B **rejected** — not an Arc 1 row). |
| later implement? | **YES — recommended first later implement** (new G0). Same-target fixture on an already-implemented q4 REML path. Not a TSV flip. Not `#428`/`#136`/`#49`/`engine_control_surface`. |

## 6. `plain_binomial_nonphylo`

| Field | Value |
|---|---|
| claim_status | `partial` |
| class | **TSV-claim** |
| claim_boundary | "Live R Workflow G binomial-trials cell vs DRM.jl `expected.toml`; still experimental, not a CRAN default." |
| next_action | Keep Workflow G live R gate green; do not claim CRAN-default Julia. |
| existing fixture | `test/parity/fixtures/binomial-trials/expected.toml` (+ meta, drmTMB **0.6.0**). Neighbour FE cells in `docs/dev-log/evidence/parity-fixtures.tsv` (`fe_poisson` / `fe_nbinom2` / `fe_gamma` PARITY_PASS on 0.7.0) are **not** this ID. |
| twin map | **YES** (`stats::binomial()` via `drmTMB()`; NEWS 0.7.0 Workflow G `#499`) |
| collision | Soft: `#425` A10 owns `src/binomial.jl`. Inventory must not edit that file. |
| later implement? | No — fixture exists; promotion is a drmTMB claim. |

## Batch verdict

Row 5 is the only same-target **fixture-gap** on an already-implemented engine
path. Rows 4 and 6 are not the first later slice (`#49` fence; TSV-claim).
