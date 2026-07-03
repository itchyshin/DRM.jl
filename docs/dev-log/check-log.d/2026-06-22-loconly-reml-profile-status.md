# 2026-06-22 - Location-only Gaussian REML profile status

Goal:

- Record a row-shaped local profile-axis sanity diagnostic for the
  exact-Gaussian location-only REML fixture.

Checks:

```sh
julia --project=. test/test_location_only_reml_mme.jl
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|ai_reml_ready = true" src/location_only.jl test/test_location_only_reml_mme.jl docs/dev-log/check-log.d/2026-06-22-loconly-reml-profile-status.md docs/dev-log/after-task/2026-06-22-loconly-reml-profile-status.md
```

Result:

- The focused test passed locally: 572/572 assertions.
- `git diff --check` was clean.
- The claim-boundary scan hit only the quoted scan command in this check-log
  and the paired after-task report.

Boundary:

- The row is a profile-axis sanity diagnostic. It keeps
  `coverage_status = not_evaluated` and `ai_reml_ready = false`; it does not
  promote profile-likelihood intervals, interval coverage, a public optimizer,
  bridge support, q4, non-Gaussian/Laplace routes, or public AI-REML readiness.
