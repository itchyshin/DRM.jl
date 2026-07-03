# After Task: Location-Only Gaussian REML FD And Local-Profile Stability

## Goal

Continue the exact-Gaussian location-only REML pilot while the maintainer is
away by adding finite-difference stability, local-profile sanity, optimizer
accounting, and PEV summary diagnostics.

## Implemented

`src/location_only.jl` now has `_loconly_reml_fd_stability_diagnostic()`, which
computes finite-difference gradients and Hessians across multiple step sizes and
reports maximum pairwise disagreement. It also has
`_loconly_reml_local_profile_diagnostic()`, which checks one-dimensional
residual and phylogenetic log-SD slices around a supplied point.

`_loconly_reml_optimizer_diagnostic()` now carries local-profile evidence,
FD-stability evidence, number of starts, number of finite optimizer records,
number of accepted records, and best start-to-optimum improvement.

`_loconly_takahashi_pev_diagnostic()` now reports posterior-variance min/max,
mean leaf posterior variance, and the weighted leaf posterior trace.

## Mathematical Contract

All diagnostics evaluate the same exact Gaussian restricted objective. The local
profile check is a small numerical sanity check around a supplied point. The
finite-difference stability check is a numerical diagnostic, not an analytic
score derivation and not an average-information update.

## Files Changed

- `src/location_only.jl`
- `test/test_location_only_reml_mme.jl`
- `docs/dev-log/check-log.d/2026-06-21-loconly-reml-fd-profile-stability.md`
- `docs/dev-log/after-task/2026-06-21-loconly-reml-fd-profile-stability.md`
- `docs/dev-log/validation-status/2026-06-21-loconly-gaussian-reml-mme.tsv`

## Checks Run

```sh
julia --project=. test/test_location_only_reml_mme.jl
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|AI-REML optimizer" src/location_only.jl test/test_location_only_reml_mme.jl docs/dev-log/check-log.d/2026-06-21-loconly-reml-fd-profile-stability.md docs/dev-log/after-task/2026-06-21-loconly-reml-fd-profile-stability.md docs/dev-log/validation-status/2026-06-21-loconly-gaussian-reml-mme.tsv
```

The focused test passed: 137/137 assertions in 7.1 seconds.

## Tests Of The Tests

The new tests require PEV summaries to match direct calculations, finite
difference gradients/Hessians to stay stable over three step sizes at the
optimizer point, the local profile to have its minimum at the fitted point along
both axes, and optimizer accounting fields to match the two-start fixture.

## Consistency Audit

The work remains exact-Gaussian and internal. It does not export symbols, change
formula grammar, wire the R bridge, or touch q4, Laplace, non-Gaussian, or Ayumi
paths.

## GitHub Issue Maintenance

No GitHub issue was edited or commented on.

## What Did Not Go Smoothly

The first focused run failed because the test used `mean()` without importing
`Statistics`. The test import now includes `Statistics`.

## Team Learning

Before an analytic score or AI update, the numerical scaffold should first say
whether finite differences, one-dimensional profile slices, and optimizer
accounting are coherent.

## Known Limitations

No analytic restricted score and no average-information update is implemented.
No full DRM.jl test suite was run.

## Next Actions

Use these diagnostics as the baseline for deriving and testing an analytic
restricted score for the two variance-component log-SD parameters.
