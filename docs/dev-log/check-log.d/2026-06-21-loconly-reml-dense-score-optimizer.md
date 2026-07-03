# 2026-06-21 — Location-only Gaussian REML dense-score optimizer diagnostic

Goal:

- Add a dense analytic restricted-score diagnostic and a dense-score optimizer
  experiment for the exact-Gaussian location-only REML pilot.

Checks:

```sh
julia --project=. test/test_location_only_reml_mme.jl
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|AI-REML optimizer" src/location_only.jl test/test_location_only_reml_mme.jl docs/dev-log/check-log.d/2026-06-21-loconly-reml-dense-score-optimizer.md docs/dev-log/after-task/2026-06-21-loconly-reml-dense-score-optimizer.md docs/dev-log/validation-status/2026-06-21-loconly-gaussian-reml-mme.tsv
```

Result:

- Added `_loconly_reml_dense_score_diagnostic()`, the dense analytic restricted
  score for log residual SD and log phylogenetic SD.
- Added `_loconly_reml_dense_score_optimizer_diagnostic()`, a developer-only
  LBFGS experiment using that dense score.
- The focused test passed: 161/161 assertions in 7.9 seconds.

Boundary:

- The dense score is an exact-Gaussian developer diagnostic. The optimizer
  remains an experiment with `ai_reml_ready = false`; no sparse analytic score,
  average-information update, R bridge field, q4, non-Gaussian, or Ayumi claim
  is promoted.
