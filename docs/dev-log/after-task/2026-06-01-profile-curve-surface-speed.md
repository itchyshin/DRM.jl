# After-task — profile diagnostics + warm profile surface

**Date:** 2026-06-01 · **Branch:** `codex/profile-curve-surface-speed` · **Closes:** #102

## Landed

- `profile_curve(fit, k)` returns backend-free 1-D profile-likelihood diagnostic
  data: grid values, likelihood-ratio deviance, the MLE, the chi-square cutoff,
  and coefficient metadata.
- `parameter_surface(fit, k1, k2)` now warm-starts the nuisance optimisation as
  it walks the 2-D grid, using a snake traversal so adjacent profile solves reuse
  the previous optimum.
- `bench/profile_inference_quick.jl` now records profile-curve timing and a
  cold-vs-warm profile-surface comparison.

## Verified

- `julia --project=. test/test_visualization.jl` — 23/23 pass.
- `julia --project=. -e 'using Pkg; Pkg.test()'` — full suite pass.
- `julia --project=docs docs/make.jl` — local docs build pass; existing site
  warnings only.
- `julia --project=bench --threads=4 bench/profile_inference_quick.jl` —
  fixed Gaussian `parameter_surface` n=11: 0.0124s warm vs 0.1856s cold
  (14.99x), max deviance delta 2.274e-13.

## Rose Notes

- The speed claim is local DRM.jl-only and measured on the benchmark fixture, not
  an R-vs-Julia claim.
- The new helper returns plot data only; no plotting dependency is added.
