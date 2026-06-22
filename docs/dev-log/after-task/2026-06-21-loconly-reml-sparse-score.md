# After Task: Location-Only Gaussian REML Sparse-Score Diagnostic

## Goal

Port the exact-Gaussian restricted-score diagnostic from dense matrices to
sparse Woodbury quantities and keep the dense path as the oracle.

## Implemented

`src/location_only.jl` now has `_loconly_reml_sparse_score_diagnostic()`. It
computes the residual and phylogenetic log-SD score terms using Woodbury
`V^{-1}` solves, sparse `Q_cond` solves, the Takahashi-selected trace already
available for `Tr(S M^{-1} S')`, and explicit trace, quadratic, and correction
term fields.

The worktree also has `_loconly_reml_sparse_score_optimizer_diagnostic()`, a
developer-only LBFGS experiment that uses that sparse score and compares the
result with the dense same-estimand oracle. It reports `ai_reml_ready = false`.

## Mathematical Contract

The score is still the Gaussian REML negative-log-likelihood derivative
`0.5 * (tr(P dV) - y' P dV P y)`, with
`V = sigma^2 I + sigma_phy^2 S Q_cond^{-1} S'`. The implementation avoids the
dense `V` projection used by the previous diagnostic, but it is not an
average-information update and not a q4 or non-Gaussian method.

## Files Changed

- `src/location_only.jl`
- `test/test_location_only_reml_mme.jl`
- `docs/dev-log/check-log.d/2026-06-21-loconly-reml-sparse-score.md`
- `docs/dev-log/after-task/2026-06-21-loconly-reml-sparse-score.md`
- `docs/dev-log/validation-status/2026-06-21-loconly-gaussian-reml-mme.tsv`

## Checks Run

```sh
julia --project=. test/test_location_only_reml_mme.jl
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|AI-REML optimizer" src/location_only.jl test/test_location_only_reml_mme.jl docs/dev-log/check-log.d/2026-06-21-loconly-reml-sparse-score.md docs/dev-log/after-task/2026-06-21-loconly-reml-sparse-score.md docs/dev-log/validation-status/2026-06-21-loconly-gaussian-reml-mme.tsv
```

The focused test passed: 194/194 assertions.

## Tests Of The Tests

The sparse score must match the dense score to `1e-8` and finite differences to
`1e-6` on the tiny balanced-tree fixture. The sparse-score optimizer must agree
with the dense-score optimizer on the objective, and the boundary test exercises
near-zero phylogenetic variance and singular fixed-effect information.

## Consistency Audit

The code is internal, exact-Gaussian, and diagnostic-only. It does not export
symbols, wire the R bridge, alter q4, or touch non-Gaussian/Laplace paths.

## GitHub Issue Maintenance

No GitHub issue was edited or commented on.

## What Did Not Go Smoothly

No algebra correction was needed after the sparse-score patch; the focused test
passed on the first run.

## Team Learning

The restricted-score identity can be moved off the dense projection while
keeping a dense oracle in the test loop. That gives the future update step a
cleaner target.

## Known Limitations

The phylogenetic score still materializes a dense observation-to-node selection
matrix for the tiny diagnostic comparison. It is not a large-tree production
optimizer, and no average-information matrix or bridge exposure is implemented.

## Next Actions

Derive the sparse average-information matrix for the same exact-Gaussian
location-only cell and compare it with the finite-difference observed Hessian
before considering any public bridge provenance change.
