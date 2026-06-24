# 2026-06-22 - Location-only Gaussian REML comparator fixture

Goal:

- Add a versioned same-estimand fixture for the exact-Gaussian location-only
  REML external-comparator lane without adding an external package dependency.

Checks:

```sh
julia --project=. test/test_location_only_reml_mme.jl
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|ai_reml_ready = true" src/location_only.jl test/test_location_only_reml_mme.jl docs/dev-log/check-log.d/2026-06-22-loconly-reml-comparator-fixture.md docs/dev-log/after-task/2026-06-22-loconly-reml-comparator-fixture.md docs/dev-log/scout/2026-06-22-loconly-reml-external-comparator.md
```

Result:

- The focused test passed locally: 407/407 assertions.
- `git diff --check` was clean.
- The claim-boundary scan hit only the quoted scan command in this check-log
  and the paired after-task report.

Boundary:

- The fixture is internal, deterministic, exact-Gaussian, and location-only. It
  records a dense covariance target and dense GLS REML reference values for a
  future external comparator to match. No external dependency, optional script,
  bridge support, q4 route, non-Gaussian route, coverage claim, or public
  AI-REML optimizer claim was added.
