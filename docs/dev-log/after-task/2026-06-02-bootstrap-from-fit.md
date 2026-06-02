# After-task: fit-based bootstrap entry points

Issue: #131

Date: 2026-06-02

## Summary

Bootstrap workflows can now start from an existing `DrmFit`:

- `bootstrap_result(fit; data, ...)`
- `bootstrap_summary(fit; data, ...)`
- `bootstrap_ci(fit; data, ...)`

This matches the GLLVM.jl pattern: if the point estimate has already been fit,
do not pay for that base fit again before starting the simulated refits.

## What Changed

- Added fit-based bootstrap dispatch for Gaussian and non-Gaussian univariate
  `DrmFit`s.
- Kept all existing formula/family bootstrap methods unchanged.
- Required `data` on the fit-based methods because `DrmFit` does not store the
  original data.
- Kept `K`, `A`, and `tree` pass-through for Gaussian fit-based bootstrap, in
  line with the existing Gaussian formula method.
- Added bootstrap CPU/provenance fields:
  - `julia_threads`
  - `blas_threads`
  - `elapsed` for the simulated-refit phase

## Measured Result

Fixture: deterministic Poisson random-intercept model `y ~ x + (1 | g)`, seed
8103, `n = 600`, `G = 30`, `threads = 4`, `BLAS.set_num_threads(1)`.

Protocol: compare the user workflow `fit = drm(...); bootstrap_result(...)`.
The old workflow uses `bootstrap_result(formula, family; ...)`, which refits the
base model internally. The new workflow uses `bootstrap_result(fit; ...)`, which
starts directly from the already-computed point estimate.

Five timed reruns:

| B | formula workflow median | fit workflow median | speedup | used |
|--:|------------------------:|--------------------:|--------:|:-----|
| 1 | 0.029908s | 0.024904s | 1.201x | 1/1 both |
| 12 | 0.074035s | 0.068708s | 1.078x | 12/12 both |

Point-estimate deltas and bootstrap-summary estimate deltas were `0.000e+00`.

## Verification

- `julia --project=. test/test_bootstrap.jl`
- `julia --project=. test/test_bootstrap_nongaussian.jl`
- `julia --project=. -e 'using Pkg; Pkg.test()'`
- threaded timing fixture above

## Rose Audit

- This is a Julia workflow speed claim only, not an R/drmTMB comparison.
- The formula/family bootstrap methods are unchanged.
- The fit-based path is univariate only; bivariate and formula-less internal
  fits throw an explicit `ArgumentError`.
- No private uploaded paper or GPL source was used.
