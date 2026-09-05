# S1 — Phase 1.5 admitted trio (rows 1–3)

**Persona:** Hopper (conductor recon on Cursor Grok; no Task child).
**Date:** 2026-08-16. **Read-only.** No `src/`. No TSV flip.
**TSV:** `git show origin/main:inst/extdata/julia-capabilities.tsv` on drmTMB
`d9fddfa28`. Diff vs eleven-rows tip `097bed1e2`: **empty** (no status flip).
**Twin map:** `docs/dev-log/evidence/2026-08-16-arc1-hopper-twin-map.md`.
**Collisions:** none of these three IDs are owned by an open PR
(`docs/dev-log/evidence/2026-08-16-arc1-lane-collisions.md`).

Class vocabulary: `TSV-claim` · `fixture-gap` · `smoke-only` · `owned` · `fence` · `parked-adjacent`.

## 1. `base_gaussian_location_scale`

| Field | Value |
|---|---|
| claim_status | `partial` |
| class | **TSV-claim** |
| claim_boundary | "Phase 1.5 Hopper admitted cell (Route C): offline result-shape + optional live TMB parity; CRAN readers still use TMB  -  vignette keeps Julia deferred/experimental." |
| next_action | Keep coefficient and likelihood parity tests tied to exact bridge payloads. Coef/logLik re-measured 2026-08-15 (coef 4.564e-06, logLik 4.584e-09, tol 1e-4). |
| existing fixture | `test/parity/fixtures/gaussian-locscale/expected.toml` (+ `expected.meta.toml`, drmTMB **0.6.0** Workflow G). Live numbers: `docs/dev-log/evidence/parity-fixtures.tsv` row `base_gaussian_location_scale` **PARITY_PASS**. Julia result-shape: `test/test_bridge.jl`. |
| twin map | **YES** (`drmTMB()` + `bf(y ~ x, sigma ~ z)` + `gaussian()`) |
| collision | none |
| later implement? | No — promoting this row is a drmTMB TSV claim (STOP GATE `#1049`/`#1050`), not a DRM.jl cell. |

## 2. `biv_gaussian_residual`

| Field | Value |
|---|---|
| claim_status | `partial` |
| class | **TSV-claim** |
| claim_boundary | "Phase 1.5 Hopper admitted cell (Route B): residual rho12 result-shape + optional live logLik parity; not a phylo or cross-family claim." |
| next_action | Keep residual rho12 result-shape and Route B parity tests; do not promote beyond experimental. |
| existing fixture | `test/parity/fixtures/gaussian-bivariate-rho12/expected.toml` (+ meta, drmTMB **0.6.0**). Julia: `test/test_bridge.jl` bivariate flatten. |
| twin map | **YES** (`biv_gaussian()` + `rho12()`) |
| collision | none. Do not conflate with `#428` latent-rho / cross-family. |
| later implement? | No — TSV-claim. Residual rho12 ≠ `cross_family_latent`. |

## 3. `gaussian_phylo_mean`

| Field | Value |
|---|---|
| claim_status | `partial` |
| class | **TSV-claim** |
| claim_boundary | "Phase 1.5 Hopper admitted cell (Route A): first phylo-mean (sigma ~ 1) marshalling/result-shape + optional live TMB parity; not loc-scale phylo or non-Gaussian phylo." |
| next_action | Keep first phylo-mean result-shape and Route A parity tests; do not widen to sigma-phylo here. |
| existing fixture | Julia result-shape: `test/test_bridge.jl` (phylo-mean flatten, `sigma ~ 1`). **No** Workflow G `expected.toml` for this phylo cell. Route A live TMB parity lives in drmTMB tests (read-only; not vendored). |
| twin map | **YES** (`phylo()`; Gaussian phylo `mu` inference-ready on the R side) |
| collision | none. Do not widen to sigma-phylo or non-Gaussian phylo. |
| later implement? | No — TSV-claim. Widening would invent a different row. |

## Batch verdict

Rows 1–3 are already Phase 1.5 admitted cells. Inventory class = **TSV-claim**
for all three. None is the recommended first later DRM.jl implement slice.
