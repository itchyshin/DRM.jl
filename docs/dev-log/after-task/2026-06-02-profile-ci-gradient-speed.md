# After-task: fast crossed sparse-Laplace profile CIs

Issue: #120

Date: 2026-06-02

## Summary

Crossed sparse-Laplace profile-likelihood intervals now reuse the fitted
objective gradient instead of falling back to finite-difference nuisance
optimization. This keeps the profile-likelihood target unchanged, but removes
the main cost multiplier from random-effect SD profile intervals.

## What Changed

- Added an optional `nllgrad` callback to `DrmFit`.
- Extended `_withnll` so fitters can attach `(g, θ) -> g` gradient callbacks
  alongside the scalar `nll`.
- Updated `confint(..., method = :profile)` to use stored gradients for:
  - nuisance optimization at fixed profile values;
  - endpoint slopes in the guarded-Newton root finder.
- Updated `profile_curve` and `parameter_surface` to use the same stored-gradient
  path for profile diagnostic data.
- Attached the existing crossed sparse-Laplace gradients to Poisson/Binomial/NB2/
  Gamma/Beta crossed fits.

## Measured Result

Crossed Poisson `(1|g) + (1|h)`, targeting only `parm = :resd`.
Protocol: fit once, warm `confint(..., method = :profile, parm = :resd)` once,
`GC.gc()`, then time a second profile-CI call with `BLAS.set_num_threads(1)`.
Baseline is `origin/main` at `c438b90`, the correctness-only crossed-profile
slice before this optimization.

| fixture | baseline | gradient profile | speedup | notes |
|:--------|---------:|-----------------:|--------:|:------|
| n=420, G=8, H=7 | 1.2865s | 0.0263s | 48.9x | endpoints unchanged to displayed precision |
| n=1000, G=20, H=20 | not re-run | 0.0901s | not claimed | optimized path remains sub-0.1s after warm-up |
| n=5000, G=50, H=50 | not re-run | 0.3869s | not claimed | larger cell stays sub-second |

Small-fixture interval parity:

| term | old lower | new lower | old upper | new upper |
|:-----|----------:|----------:|----------:|----------:|
| g | -1.15065040 | -1.15065041 | -0.06476735 | -0.06476736 |
| h | -1.43719817 | -1.43719817 | -0.22979541 | -0.22979540 |

## Verification

- `julia --project=. test/test_profile_ci.jl`
- `julia --project=. test/test_visualization.jl`
- `julia --project=. -e 'using Pkg; Pkg.test()'`
- `julia --project=docs -e 'using Pkg; Pkg.develop(PackageSpec(path = pwd())); Pkg.instantiate()' && julia --project=docs docs/make.jl`
- targeted timing fixtures above

## Rose Audit

- The only speedup claim in this report is the clean n=420 baseline-to-branch
  comparison measured under the same warm protocol. Larger optimized timings are
  reported as branch timings only because the old n=1000 path was previously
  too slow for the interactive cutoff.
- No drmTMB/R speed claim is made for profile CIs in this slice.
- No private uploaded paper or GPL source was used.
