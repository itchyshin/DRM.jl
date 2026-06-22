# 2026-06-22 - Location-only Gaussian REML external comparator probe script

Goal:

- Add a developer-only package/version probe script for the exact-Gaussian
  location-only REML external-comparator lane without adding a dependency or
  running an external fit.

Checks:

```sh
julia --project=. test/test_location_only_reml_mme.jl
julia --project=. tools/loconly-reml-external-comparator-probe.jl --output docs/dev-log/validation-status/2026-06-22-loconly-reml-external-comparator-probe.tsv
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|ai_reml_ready = true" src/location_only.jl test/test_location_only_reml_mme.jl tools/loconly-reml-external-comparator-probe.jl docs/dev-log/check-log.d/2026-06-22-loconly-reml-external-comparator-probe-script.md docs/dev-log/after-task/2026-06-22-loconly-reml-external-comparator-probe-script.md docs/dev-log/scout/2026-06-22-loconly-reml-external-comparator.md docs/dev-log/validation-status/README.md docs/dev-log/validation-status/2026-06-22-loconly-reml-external-comparator-probe.tsv
```

Result:

- The focused test passed locally: 459/459 assertions.
- The probe script wrote one row to
  `docs/dev-log/validation-status/2026-06-22-loconly-reml-external-comparator-probe.tsv`
  and recorded local `phylolm` version 2.6.5.
- `git diff --check` was clean.
- The claim-boundary scan hit only the quoted scan command in this check-log
  and the paired after-task report.

Boundary:

- The artifact records package availability/version only. It keeps
  `fit_status = not_run`, `same_estimand_status =
  requires_fixture_reproduction`, `dependency_status = not_added`,
  `coverage_status = not_evaluated`, and `ai_reml_ready = false`. No external
  fit, dependency, bridge support, q4 route, non-Gaussian route, coverage claim,
  or public AI-REML optimizer claim was added.
