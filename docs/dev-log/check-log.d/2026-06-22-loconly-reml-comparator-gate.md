# 2026-06-22 - Location-only Gaussian REML comparator gate

Goal:

- Add a no-dependency external-comparator gate for the exact-Gaussian
  location-only REML row contract, while keeping the internal dense GLS oracle
  as the only covered comparator evidence.

Checks:

```sh
julia --project=. test/test_location_only_reml_mme.jl
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|ai_reml_ready = true" src/location_only.jl test/test_location_only_reml_mme.jl docs/dev-log/check-log.d/2026-06-22-loconly-reml-comparator-gate.md docs/dev-log/after-task/2026-06-22-loconly-reml-comparator-gate.md docs/dev-log/scout/2026-06-22-loconly-reml-external-comparator.md
```

Result:

- The focused test passed: 386/386 assertions.
- `git diff --check` was clean.
- The claim-boundary scan hit only the quoted scan command in this check-log
  and the paired after-task report.

Boundary:

- The comparator gate is exact-Gaussian and developer-only. No external
  dependency, optional script, coverage claim, bridge claim, q4 claim, or
  public AI-REML optimizer claim was added.
