# 2026-06-22 - Location-only Gaussian REML variance-component status

Goal:

- Record row-shaped variance-component point-status output for the
  exact-Gaussian location-only REML fixture without interval or coverage claims.

Checks:

```sh
julia --project=. test/test_location_only_reml_mme.jl
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|ai_reml_ready = true" src/location_only.jl test/test_location_only_reml_mme.jl docs/dev-log/check-log.d/2026-06-22-loconly-reml-variance-component-status.md docs/dev-log/after-task/2026-06-22-loconly-reml-variance-component-status.md
```

Result:

- The focused test passed locally: 600/600 assertions.
- `git diff --check` was clean.
- The claim-boundary scan hit only the quoted scan command in this check-log
  and the paired after-task report.

Boundary:

- The rows are variance-component point-status diagnostics. They keep
  `interval_status = not_evaluated`, `coverage_status = not_evaluated`, and
  `ai_reml_ready = false`; they do not promote intervals, interval coverage, a
  public optimizer, bridge support, q4, non-Gaussian/Laplace routes, or public
  AI-REML readiness.
