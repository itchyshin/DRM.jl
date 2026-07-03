# 2026-06-22 - Location-only Gaussian REML external fit feasibility

Goal:

- Check whether the current exact-Gaussian location-only REML fixture can
  advance to a same-estimand external `phylolm` fit comparison.

Checks:

```sh
julia --project=. test/test_location_only_reml_mme.jl
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|ai_reml_ready = true" src/location_only.jl test/test_location_only_reml_mme.jl tools/loconly-reml-external-comparator-probe.jl docs/dev-log/check-log.d/2026-06-22-loconly-reml-external-fit-feasibility.md docs/dev-log/after-task/2026-06-22-loconly-reml-external-fit-feasibility.md docs/dev-log/scout/2026-06-22-loconly-reml-external-comparator.md
```

Result:

- The focused test passed locally: 483/483 assertions.
- `git diff --check` was clean.
- The claim-boundary scan hit only the quoted scan command in this check-log
  and the paired after-task report.

Boundary:

- The current fixture has replicated species rows and observation-level
  covariate variation, so a tip-level `phylolm` fit would not be a
  same-estimand comparator. The row stays `fit_status = not_run`,
  `same_estimand_status = not_same_estimand_current_fixture`,
  `dependency_status = not_added`, `coverage_status = not_evaluated`, and
  `ai_reml_ready = false`.
