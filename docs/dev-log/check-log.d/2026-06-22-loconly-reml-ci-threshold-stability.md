# 2026-06-22 - Location-only Gaussian REML CI threshold stability

Goal:

- Stabilize the exact-Gaussian location-only REML diagnostic row-contract test
  after Julia CI exposed that the tiny three-replicate recovery grid used
  point-bias tolerances that were too tight for a diagnostic-only gate.

Checks:

```sh
julia --project=. test/test_location_only_reml_mme.jl
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|ai_reml_ready = true" src/location_only.jl test/test_location_only_reml_mme.jl docs/dev-log/check-log.d/2026-06-22-loconly-reml-ci-threshold-stability.md docs/dev-log/after-task/2026-06-22-loconly-reml-ci-threshold-stability.md docs/dev-log/scout/2026-06-22-loconly-reml-external-comparator.md
```

Result:

- The focused test passed locally: 386/386 assertions.
- `git diff --check` was clean.
- The claim-boundary scan hit only the quoted scan command in this check-log
  and the paired after-task report.

Boundary:

- The change widens only two tiny-grid point-bias tolerances in the test, with
  an explicit note that the grid is a diagnostic row-contract gate, not a
  promotion-grade recovery or coverage study. No implementation path, R bridge,
  q4 route, non-Gaussian route, external comparator, or public AI-REML optimizer
  claim was promoted.
