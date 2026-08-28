# The user-journey sweep — "Julia from R", verified at the user's seat

*2026-08-28, owner-charged: real users consume DRM.jl through drmTMB's `engine="julia"`, the owner
personally hit "bugs and snags" doing so, and the curated parity fixtures cannot see that class of
problem. Instrument: `tools/user_journey_sweep.R`; banked rows:
`docs/dev-log/evidence/user-journey-sweep.tsv` (final run against drmTMB branch
`claude/predict-newdata-name-alignment`, PR #1099).*

## Final tally (29 journeys)

| status | n | meaning |
|---|---|---|
| `OK_MATCH` | **25** | fits on both engines, fixed effects name-matched < 1e-3 (measured 1e-6..1e-11), full post-fit workflow (print/summary/coef/fixef/vcov/confint/residuals/predict) clean |
| `JULIA_REFUSED` | 2 | weights, probit — intentional gates with clear, actionable messages |
| `BOTH_ERROR` | 1 | unknown column — both engines err well |
| `NO_NATIVE_COMPARATOR` | 1 | cross-family (drmTMB native accepts only gaussian×gaussian) |

Coverage: basic/σ-covariate Gaussian, factors, `*` and `:` interactions, `I()`, `poly()`,
`scale()`, `-1`, `(x+z)^2`, Poisson/Gamma/Beta/binomial-cbind, `meta_V`, missing-y drop+include,
REML, phylo Gaussian (factor AND character species), phylo Poisson, phylo+include, relmat,
bivariate Gaussian, Student with `nu`, cross-family.

## What the sweep caught (its purpose, fulfilled)

1. **One real user-facing bug, found and fixed**: `predict(newdata)` on factor covariates and
   interactions refused with "could not align the newdata design" — Julia's StatsModels names
   coefficients `"g: b"` / `"x & z"` where R's `model.matrix` says `"gb"` / `"x:z"`, so the
   alignment intersect found nothing. Fixed in drmTMB PR #1099 (red-first test asserting
   cross-engine predict equality at 1e-5).
2. **Three instrument bugs the sweep's own rigor exposed**, each a repo-lesson replayed: engine
   coefficient-name conventions broke naive name-matching (biv "mismatch" of 1.3 on identical
   estimates); the Student cell generated Gaussian data so ν sat on a flat ridge (14 vs 17 at
   logLik agreement 1e-5 — the #483 unidentifiable-fixture lesson in our own instrument); the biv
   cell drew `rnorm` inside the per-engine closure, fitting different data per engine (0.065
   "mismatch" = noise). All three fixed in the instrument, which now carries the lessons as
   comments.

## Standing use

The sweep is re-runnable in minutes and complements the parity harnesses: they answer "do the
engines agree at machine precision on curated fixtures"; this answers "does the thing a user
actually types work, match, and fail well". Post-0.7.0 additions welcome: offsets, `zi`/`hu`
journeys, ordered factors, na predictors, new-species prediction UX.
