# 2026-06-22 - Location-only Gaussian REML derivative FD status

Goal:

- Turn the exact-Gaussian location-only REML score finite-difference checks into
  a row-shaped fixture diagnostic.

Checks:

```sh
julia --project=. test/test_location_only_reml_mme.jl
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|ai_reml_ready = true" src/location_only.jl test/test_location_only_reml_mme.jl docs/dev-log/check-log.d/2026-06-22-loconly-reml-derivative-fd-status.md docs/dev-log/after-task/2026-06-22-loconly-reml-derivative-fd-status.md
```

Result:

- The focused test passed locally: 506/506 assertions.
- `git diff --check` was clean.
- The claim-boundary scan hit only the quoted scan command in this check-log
  and the paired after-task report.

Boundary:

- The derivative rows are exact-Gaussian fixture-level score diagnostics. They
  do not promote optimizer readiness, bridge support, q4, non-Gaussian/Laplace
  routes, interval coverage, or public AI-REML claims.
