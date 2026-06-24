# After Task: Location-Only Gaussian REML Dense-Score Optimizer Diagnostic

## Goal

Add the first analytic restricted-score diagnostic for the exact-Gaussian
location-only REML pilot and compare a dense-score optimizer experiment against
the finite-difference optimizer diagnostic.

## Implemented

`src/location_only.jl` now has `_loconly_reml_dense_score_diagnostic()`, which
evaluates the dense Gaussian REML score
`0.5 * (tr(P dV) - y' P dV P y)` for the residual and phylogenetic log-SD
parameters and compares it with finite differences of the sparse restricted
objective.

Added `_loconly_reml_dense_score_optimizer_diagnostic()`, a developer-only LBFGS
experiment using the dense analytic score. It reports dense-comparator evidence,
boundary status, start records, score norm, and `ai_reml_ready = false`.

## Mathematical Contract

The score is dense and exact for the Gaussian REML objective with
`V = sigma^2 I + sigma_phy^2 S Q_cond^{-1} S'`. It is not yet the sparse
Takahashi score and not an average-information update.

## Files Changed

- `src/location_only.jl`
- `test/test_location_only_reml_mme.jl`
- `docs/dev-log/check-log.d/2026-06-21-loconly-reml-dense-score-optimizer.md`
- `docs/dev-log/after-task/2026-06-21-loconly-reml-dense-score-optimizer.md`
- `docs/dev-log/validation-status/2026-06-21-loconly-gaussian-reml-mme.tsv`

## Checks Run

```sh
julia --project=. test/test_location_only_reml_mme.jl
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|AI-REML optimizer" src/location_only.jl test/test_location_only_reml_mme.jl docs/dev-log/check-log.d/2026-06-21-loconly-reml-dense-score-optimizer.md docs/dev-log/after-task/2026-06-21-loconly-reml-dense-score-optimizer.md docs/dev-log/validation-status/2026-06-21-loconly-gaussian-reml-mme.tsv
```

The focused test passed: 161/161 assertions in 7.9 seconds.

## Tests Of The Tests

The score diagnostic is checked against finite differences at the supplied
fixture point. The dense-score optimizer is checked against the finite-difference
optimizer on the same starts, and must remain dense-comparator consistent with
an interior boundary label and small score norm.

## Consistency Audit

The code is internal and exact-Gaussian. It does not export symbols, wire the R
bridge, change q4, or touch non-Gaussian/Laplace paths.

## GitHub Issue Maintenance

No GitHub issue was edited or commented on.

## What Did Not Go Smoothly

No implementation failure after the dense score patch; the focused test passed
on the first run.

## Team Learning

The dense REML score gives a clean intermediate rung between finite-difference
diagnostics and a future sparse analytic score.

## Known Limitations

The score currently uses dense `V`, dense `Q_cond^{-1}`, and dense projection
`P`; it is not suitable for large trees. No average-information update is
implemented.

## Next Actions

Port the dense score identity onto sparse Woodbury/Takahashi quantities and
compare it against this dense diagnostic on tiny fixtures.
