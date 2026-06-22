# 2026-06-21 — Location-only Gaussian REML condition recovery grid

Goal:

- Add a tiny condition-grid wrapper for the exact-Gaussian location-only REML
  recovery diagnostic so multiple cells stay row-separated.

Checks:

```sh
julia --project=. test/test_location_only_reml_mme.jl
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|AI-REML optimizer" src/location_only.jl test/test_location_only_reml_mme.jl docs/dev-log/check-log.d/2026-06-21-loconly-reml-condition-grid.md docs/dev-log/after-task/2026-06-21-loconly-reml-condition-grid.md docs/dev-log/validation-status/2026-06-21-loconly-gaussian-reml-mme.tsv
```

Result:

- Added `_loconly_reml_recovery_condition_grid_diagnostic()`, a row-separated
  wrapper around the tiny recovery grid.
- The focused test passed: 267/267 assertions.

Boundary:

- This is a tiny point-recovery condition diagnostic only. It does not claim
  interval coverage, R bridge support, q4 support, non-Gaussian support,
  10k-scale intervals, or Ayumi readiness.
