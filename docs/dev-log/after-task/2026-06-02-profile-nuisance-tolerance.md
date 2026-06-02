# After-task: stored-gradient profile nuisance tolerance

Issue: #127

Date: 2026-06-02

## Summary

Stored-gradient profile nuisance solves now use tolerances matched to profile
endpoint and curve computation. The previous path asked each inner LBFGS solve
for near-machine precision at every bracket/Newton point. That precision was
not visible in profile endpoints, but it dominated runtime after #120 and #125
made gradients available.

## What Changed

- Changed the stored-gradient `_profile_optimize` branch to use:
  - `iterations = 40`
  - `g_tol = 1e-6`
  - `x_abstol = 1e-8`
- Left finite-difference and value-only fallback paths unchanged.

## Measured Result

Fixture: Gaussian `y ~ x + (1 | g) + (1 | h), sigma ~ 1`, deterministic seed
9302, `n = 1200`, `G = 30`, `H = 30`, `BLAS.set_num_threads(1)`.

Baseline is `origin/main` after #125 (`7e361d9`).

| target | baseline | tolerance branch | notes |
|:-------|---------:|-----------------:|:------|
| `confint(fit; method = :profile)` | 1.1859s | 0.7720s | objective calls 2175 -> 1116; gradient calls 859 -> 723 |
| `confint(..., parm = :resd)` | 0.5575s | 0.3732s | objective calls 1016 -> 541; gradient calls 399 -> 348 |
| `profile_curve(fit, beta_x; npoints = 31)` | 0.4756s | 0.2636s | objective calls 976 -> 399; gradient calls 301 -> 216 |
| `profile_curve(fit, resd_g; npoints = 31)` | 0.6822s | 0.4105s | objective calls 1325 -> 574; gradient calls 467 -> 376 |

Endpoint parity:

- `confint(fit; method = :profile)` endpoints were identical to the baseline
  path to 9 displayed decimals on the timing fixture.

## Verification

- `julia --project=. test/test_profile_ci.jl`
- `julia --project=. test/test_visualization.jl`
- `julia --project=. -e 'using Pkg; Pkg.test()'`
- targeted timing/call-count fixtures above

## Rose Audit

- Speed claims compare the same deterministic fixture before and after this
  tolerance change.
- This change only applies when a stored objective gradient is available; the
  finite-difference/value-only fallback safety paths are unchanged.
- No R/drmTMB speed claim is made.
- No private uploaded paper or GPL source was used.
