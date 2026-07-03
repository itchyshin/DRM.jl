# 2026-06-21 — Location-only Gaussian REML tiny recovery grid

Goal:

- Add a deterministic tiny recovery grid for the exact-Gaussian location-only
  REML pilot and report convergence, bias, RMSE, MCSE for bias, and boundary
  counts for the guarded update experiment.

Checks:

```sh
julia --project=. test/test_location_only_reml_mme.jl
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|AI-REML optimizer" src/location_only.jl test/test_location_only_reml_mme.jl docs/dev-log/check-log.d/2026-06-21-loconly-reml-recovery-grid.md docs/dev-log/after-task/2026-06-21-loconly-reml-recovery-grid.md docs/dev-log/validation-status/2026-06-21-loconly-gaussian-reml-mme.tsv
```

Result:

- Added `_loconly_reml_recovery_grid_diagnostic()`, a small deterministic
  simulation diagnostic for the exact-Gaussian location-only cell.
- The focused test passed: 252/252 assertions.

Boundary:

- This is a tiny point-recovery diagnostic only. It does not claim interval
  coverage, R bridge support, q4 support, non-Gaussian support, 10k-scale
  intervals, or Ayumi readiness.
