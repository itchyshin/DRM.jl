# 2026-06-22 - Location-only Gaussian REML comparator version probe

Goal:

- Bank the external-comparator package/version probe contract for the
  exact-Gaussian location-only REML lane without choosing or adding an external
  dependency.

Checks:

```sh
julia --project=. test/test_location_only_reml_mme.jl
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|ai_reml_ready = true" src/location_only.jl test/test_location_only_reml_mme.jl docs/dev-log/check-log.d/2026-06-22-loconly-reml-comparator-version-probe.md docs/dev-log/after-task/2026-06-22-loconly-reml-comparator-version-probe.md docs/dev-log/scout/2026-06-22-loconly-reml-external-comparator.md
```

Result:

- The focused test passed locally: 429/429 assertions.
- `git diff --check` was clean.
- The claim-boundary scan hit only the quoted scan command in this check-log
  and the paired after-task report.

Boundary:

- The probe is an internal exact-Gaussian location-only REML diagnostic
  contract. It records required same-estimand evidence and keeps the candidate
  package/version unprobed. No dependency, bridge support, q4 route,
  non-Gaussian route, coverage claim, or public AI-REML optimizer claim was
  added.
