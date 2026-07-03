# 2026-06-21 — Location-only Gaussian REML sparse average-information diagnostic

Goal:

- Add a sparse average-information diagnostic for the exact-Gaussian
  location-only REML pilot and compare it against the dense AI diagnostic and
  finite-difference observed Hessian.

Checks:

```sh
julia --project=. test/test_location_only_reml_mme.jl
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|AI-REML optimizer" src/location_only.jl test/test_location_only_reml_mme.jl docs/dev-log/check-log.d/2026-06-21-loconly-reml-sparse-ai.md docs/dev-log/after-task/2026-06-21-loconly-reml-sparse-ai.md docs/dev-log/validation-status/2026-06-21-loconly-gaussian-reml-mme.tsv
```

Result:

- Added `_loconly_reml_sparse_ai_information_diagnostic()`, a sparse-Woodbury
  developer diagnostic for the Gaussian REML average-information matrix.
- Included sparse information diagnostics in the combined developer payload.
- The focused test passed: 205/205 assertions.

Boundary:

- This is an exact-Gaussian information diagnostic only. It does not implement a
  variance-component update, R bridge field, q4 route, non-Gaussian route,
  10k-scale interval, or Ayumi claim.
