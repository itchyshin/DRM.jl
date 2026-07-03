# 2026-06-22 - Location-only Gaussian REML weak-boundary stability

Goal:

- Stabilize the exact-Gaussian location-only REML weak-signal diagnostic test
  after Julia 1.12 CI produced a fully interior two-replicate weak-signal draw.

Checks:

```sh
julia --project=. test/test_location_only_reml_mme.jl
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|ai_reml_ready = true" src/location_only.jl test/test_location_only_reml_mme.jl docs/dev-log/check-log.d/2026-06-22-loconly-reml-weak-boundary-stability.md docs/dev-log/after-task/2026-06-22-loconly-reml-weak-boundary-stability.md docs/dev-log/scout/2026-06-22-loconly-reml-external-comparator.md
```

Result:

- The focused test passed locally: 387/387 assertions.
- `git diff --check` was clean.
- The claim-boundary scan hit only the quoted scan command in this check-log
  and the paired after-task report.

Boundary:

- The weak-signal row still reports `expected_behavior =
  :boundary_states_allowed`, boundary counts, boundary rate, convergence rate,
  `coverage_status = :not_evaluated`, and `ai_reml_ready = false`. The test no
  longer requires that a two-replicate diagnostic draw must include a boundary
  event on every Julia/RNG combination.
