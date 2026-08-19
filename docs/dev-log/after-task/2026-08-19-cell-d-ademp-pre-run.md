# 2026-08-19 — Cell D ADEMP pre-run (scope + stop)

**Lane:** `docs/cell-d-ademp-scope` on Dropbox `DRM.jl` @ `origin/main` (post-#451).
**Persona:** Shannon (this item only). Items 3–5 wait. Item 1 already DONE.
**Does not close** #448 / #450 / #136 / #49 / #420 / #406.

## What landed

Plan: `docs/dev-log/plans/2026-08-19-cell-d-ademp-pre-run.md`.
No `src/` edit. No capability-status flip. No Totoro campaign.

## Pre-run (D-139)

Estimate *before* start: 1-seed public ML + REML at Cell D size = 20–45 s
(1–3 min if compile); full ADEMP = hours → do not start.

Measured (`pathof(DRM)` = this checkout):

| fit | conv | method | σ̂ (1 seed, true 0.7) | wall |
|---|---|---|---|---|
| ML Laplace | true | `:ML` | 0.53442 | 7.24 s (first-fit JIT) |
| Cox–Reid | true | `:REML` | 0.59279 | 0.20 s (warm) |
| AGHQ × phylo | threw | — | — | — |

Total wall **9.40 s**. AGHQ error (re-checked with `Ref`, first `-e` soft-scope
printed a false “no-throw”):

`marginal = :AGHQ … not available for Poisson() with a phylogenetic/structured
random effect. … (1 | g) only.`

**Not recovery.** Do not headline the one-seed σ̂. #451 after-task already:
“Cell D is not a recovery result.”

## Recommendation held

Chip stays missing. ADEMP is a **new G0**. STOP for Shinichi before Totoro.

`PLATFORM: cursor | ON BRANCH: docs/cell-d-ademp-scope | LANE: cell-d-ademp-scope`
`OTHER LANES: claude (census) + #420 + #406`
