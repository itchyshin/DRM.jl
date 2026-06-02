# After-task: crossed sparse-Laplace profile CIs for RE SDs

Issue: #118

Date: 2026-06-02

## Summary

`confint(fit; method = :profile, parm = :resd)` now profiles random-effect SD
parameters for crossed sparse-Laplace fits. This fixes the crossed Poisson
failure where the fitted objective was valid on `Float64` but not
ForwardDiff-through-mode safe.

## What Changed

- Added `parm` filtering to `confint`, so users can target parameter blocks such
  as `:resd` without profiling every fixed effect.
- Added profile nuisance optimization fallback:
  - use ForwardDiff LBFGS when the fitted objective is dual-number safe;
  - otherwise use finite-difference LBFGS;
  - if finite-difference line search fails, retry with value-only Nelder-Mead.
- Applied the same fallback to `profile_curve` and `parameter_surface` so the
  diagnostic plot data stays consistent with profile intervals.
- Added a regression test for crossed Poisson `(1|g) + (1|h)` random-effect SD
  profile intervals.

## Evidence

Targeted crossed Poisson fixture (`n = 420`, `G = 8`, `H = 7`):

| term | log-SD estimate | log-SD lower | log-SD upper | SD estimate | SD lower | SD upper |
|:-----|----------------:|-------------:|-------------:|------------:|---------:|---------:|
| g | -0.6774 | -1.1507 | -0.0648 | 0.5079 | 0.3164 | 0.9373 |
| h | -0.9084 | -1.4372 | -0.2298 | 0.4032 | 0.2376 | 0.7947 |

Measured time for the two targeted `:resd` intervals: `2.7605s`.

## Verification

- `julia --project=. test/test_profile_ci.jl`
- `julia --project=. test/test_visualization.jl`
- `julia --project=. -e 'using Pkg; Pkg.test()'`
- `git diff --check`

All passed locally.

## Limitations

This is a correctness and robustness slice, not a speed-optimized profile-CI
slice. A larger crossed Poisson targeted smoke (`n = 1000`, `G = 20`, `H = 20`)
was stopped after more than 45 seconds. The next inference-speed slice should
avoid repeated outer/nuisance work for RE-SD endpoints and benchmark profile CI
cost against fit cost.

## Rose Audit

- Claims are measured from local runs; no extrapolated profile-CI speedup is
  claimed.
- No private uploaded paper or GPL source was used.
- Public API change is additive: `parm` filtering on `confint`.
