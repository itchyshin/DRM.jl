# 2026-06-21 — Location-only Gaussian REML post-gate diagnostics

Goal:

- Execute the post-transfer exact-Gaussian slices for the location-only
  phylogenetic mean cell: optimizer experiment, same-estimand comparator,
  selected-inverse PEV diagnostic, validation/status schema, micro scaling
  smoke, and bridge payload draft fields.

Checks:

```sh
julia --project=. test/test_location_only_reml_mme.jl
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|AI-REML optimizer" src/location_only.jl test/test_location_only_reml_mme.jl docs/dev-log/check-log.d/2026-06-21-loconly-reml-postgate.md docs/dev-log/after-task/2026-06-21-loconly-reml-postgate.md docs/dev-log/validation-status/2026-06-21-loconly-gaussian-reml-mme.tsv
```

Result:

- Added `_loconly_takahashi_pev_diagnostic()` to expose selected-inverse
  posterior variances for all kept nodes and the observed leaf nodes.
- Added `_loconly_reml_optimizer_diagnostic()`, a finite-difference
  LBFGS experiment over the supplied-variance restricted objective. It records
  `claim_status = :optimizer_experiment` and `ai_reml_ready = false`.
- Added `_loconly_reml_validation_status()` and
  `_loconly_reml_bridge_payload_schema()` as internal status/schema anchors.
- The focused test passed: 88/88 assertions in 6.2 seconds.

Boundary:

- The dense same-estimand comparator is the direct `V = sigma^2 I +
  sigma_phy^2 C` GLS oracle in `test/test_location_only_reml_mme.jl`.
- This is exact-Gaussian developer evidence only. It does not export a user
  API, does not promote an R bridge row, does not implement AI-REML, and does
  not change q4, Laplace, non-Gaussian, Ayumi-facing, or 10k-scale interval
  claims.
