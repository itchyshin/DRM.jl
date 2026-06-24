# 2026-06-22 - Location-only Gaussian REML boundary grid status

Goal:

- Bank a row-shaped near-zero variance boundary grid for the exact-Gaussian
  location-only REML diagnostic lane.

Checks:

```sh
julia --project=. test/test_location_only_reml_mme.jl
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|ai_reml_ready = true" src/location_only.jl test/test_location_only_reml_mme.jl docs/dev-log/check-log.d/2026-06-22-loconly-reml-boundary-grid-status.md docs/dev-log/after-task/2026-06-22-loconly-reml-boundary-grid-status.md
```

Result:

- The focused test passed locally: 550/550 assertions.
- `git diff --check` was clean.
- The claim-boundary scan hit only the quoted scan command in this check-log
  and the paired after-task report.

Boundary:

- The boundary grid is simulation-diagnostic evidence only. It keeps
  `coverage_status = not_evaluated` and `ai_reml_ready = false`; it does not
  promote a public optimizer, bridge support, q4, non-Gaussian/Laplace routes,
  interval coverage, or public AI-REML readiness.
