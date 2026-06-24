# 2026-06-21 — Location-only Gaussian REML guarded AI update experiment

Goal:

- Add a guarded two-parameter average-information update experiment for the
  exact-Gaussian location-only REML pilot and compare its endpoint against the
  finite-difference, dense-score, and sparse-score optimizer diagnostics.

Checks:

```sh
julia --project=. test/test_location_only_reml_mme.jl
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|AI-REML optimizer" src/location_only.jl test/test_location_only_reml_mme.jl docs/dev-log/check-log.d/2026-06-21-loconly-reml-guarded-ai-update.md docs/dev-log/after-task/2026-06-21-loconly-reml-guarded-ai-update.md docs/dev-log/validation-status/2026-06-21-loconly-gaussian-reml-mme.tsv
```

Result:

- Added `_loconly_reml_ai_update_optimizer_diagnostic()`, a guarded
  average-information update experiment with finite objective descent,
  step-halving, conditioning checks, per-iteration trace records, and
  `ai_reml_ready = false`.
- The focused test passed: 229/229 assertions.

Boundary:

- This is an exact-Gaussian optimizer experiment only. It does not promote an R
  bridge field, q4 route, non-Gaussian route, 10k-scale interval, or Ayumi
  claim.
