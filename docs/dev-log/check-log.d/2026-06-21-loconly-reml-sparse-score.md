# 2026-06-21 — Location-only Gaussian REML sparse-score diagnostic

Goal:

- Port the dense restricted-score identity to sparse Woodbury quantities for the
  exact-Gaussian location-only REML pilot, then compare it against the dense
  oracle and finite differences.

Checks:

```sh
julia --project=. test/test_location_only_reml_mme.jl
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|AI-REML optimizer" src/location_only.jl test/test_location_only_reml_mme.jl docs/dev-log/check-log.d/2026-06-21-loconly-reml-sparse-score.md docs/dev-log/after-task/2026-06-21-loconly-reml-sparse-score.md docs/dev-log/validation-status/2026-06-21-loconly-gaussian-reml-mme.tsv
```

Result:

- Added `_loconly_reml_sparse_score_diagnostic()`, a sparse-Woodbury developer
  diagnostic for the residual and phylogenetic log-SD restricted scores.
- Added `_loconly_reml_sparse_score_optimizer_diagnostic()`, a developer-only
  LBFGS experiment using the sparse-Woodbury score.
- The focused test passed: 194/194 assertions.

Boundary:

- The sparse score is an exact-Gaussian developer diagnostic. The optimizer
  remains an experiment with `ai_reml_ready = false`; no average-information
  update, R bridge field, q4, non-Gaussian, 10k-scale interval, or Ayumi claim
  is promoted.
