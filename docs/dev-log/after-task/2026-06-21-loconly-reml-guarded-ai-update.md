# After Task: Location-Only Gaussian REML Guarded AI Update Experiment

## Goal

Add a guarded two-parameter average-information update experiment for the
exact-Gaussian location-only REML pilot and check its endpoint against the
existing optimizer diagnostics.

## Implemented

`src/location_only.jl` now has `_loconly_reml_ai_update_optimizer_diagnostic()`.
The helper starts from one or more log-SD pairs, evaluates the sparse-Woodbury
restricted score and sparse average-information matrix, takes a Newton-style
average-information step, and halves the step until the restricted objective
decreases. It records per-iteration score norm, step norm, objective before and
after, halving count, information eigenvalue/condition diagnostics, ridge added,
and status.

The diagnostic compares cleanly in tests against the finite-difference,
dense-score, and sparse-score optimizer diagnostics. It still reports
`ai_reml_ready = false`.

## Mathematical Contract

The experiment targets the exact Gaussian restricted likelihood for
`V = sigma^2 I + sigma_phy^2 S Q_cond^{-1} S'`. The score and information matrix
come from the sparse-Woodbury diagnostics already checked against dense oracles.
This is not a q4 derivation and not a non-Gaussian method.

## Files Changed

- `src/location_only.jl`
- `test/test_location_only_reml_mme.jl`
- `docs/dev-log/check-log.d/2026-06-21-loconly-reml-guarded-ai-update.md`
- `docs/dev-log/after-task/2026-06-21-loconly-reml-guarded-ai-update.md`
- `docs/dev-log/validation-status/2026-06-21-loconly-gaussian-reml-mme.tsv`

## Checks Run

```sh
julia --project=. test/test_location_only_reml_mme.jl
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|AI-REML optimizer" src/location_only.jl test/test_location_only_reml_mme.jl docs/dev-log/check-log.d/2026-06-21-loconly-reml-guarded-ai-update.md docs/dev-log/after-task/2026-06-21-loconly-reml-guarded-ai-update.md docs/dev-log/validation-status/2026-06-21-loconly-gaussian-reml-mme.tsv
```

The focused test passed: 229/229 assertions.

## Tests Of The Tests

The guarded update endpoint must agree with the finite-difference, dense-score,
and sparse-score optimizer diagnostics to `1e-5`, expose accepted-step trace
records, report a small final score norm, and fail cleanly for singular
fixed-effect information.

## Consistency Audit

The helper is internal and exact-Gaussian. It does not export symbols, wire the
R bridge, change q4, or touch non-Gaussian/Laplace paths.

## GitHub Issue Maintenance

No GitHub issue was edited or commented on.

## What Did Not Go Smoothly

No implementation correction was needed; the focused test passed on the first
run after adding the guarded update helper and tests.

## Team Learning

The sparse score and sparse average-information diagnostics are sufficient to
run a guarded two-parameter update on the tiny fixture, but the evidence still
needs simulation and bridge gates before it becomes a user-facing estimator.

## Known Limitations

No simulation coverage, bridge provenance field, external comparator package,
large-tree stress test, q4 derivation, or full-tree interval claim is included.

## Next Actions

Add a small Monte Carlo recovery grid for this exact-Gaussian cell and use it to
separate optimizer stability evidence from any future interval or bridge claim.
