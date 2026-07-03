# After Task: Location-Only Gaussian REML Sparse Average-Information Diagnostic

## Goal

Add the sparse average-information diagnostic for the exact-Gaussian
location-only REML pilot and keep it checked against the dense diagnostic and
finite-difference observed Hessian.

## Implemented

`src/location_only.jl` now has `_loconly_reml_sparse_ai_information_diagnostic()`.
It applies the two derivative matrices through sparse Woodbury projection
rather than a dense `V` projection, symmetrizes the 2 by 2 information matrix,
and reports dense-AI agreement plus relative error against the finite-difference
observed Hessian.

The combined diagnostic payload now includes `sparse_information`.

## Mathematical Contract

The diagnostic computes the same Gaussian REML average-information expression
as the dense helper for
`V = sigma^2 I + sigma_phy^2 S Q_cond^{-1} S'`. It is a matrix diagnostic, not
a variance-component update step and not a q4 or non-Gaussian derivation.

## Files Changed

- `src/location_only.jl`
- `test/test_location_only_reml_mme.jl`
- `docs/dev-log/check-log.d/2026-06-21-loconly-reml-sparse-ai.md`
- `docs/dev-log/after-task/2026-06-21-loconly-reml-sparse-ai.md`
- `docs/dev-log/validation-status/2026-06-21-loconly-gaussian-reml-mme.tsv`

## Checks Run

```sh
julia --project=. test/test_location_only_reml_mme.jl
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|AI-REML optimizer" src/location_only.jl test/test_location_only_reml_mme.jl docs/dev-log/check-log.d/2026-06-21-loconly-reml-sparse-ai.md docs/dev-log/after-task/2026-06-21-loconly-reml-sparse-ai.md docs/dev-log/validation-status/2026-06-21-loconly-gaussian-reml-mme.tsv
```

The focused test passed: 205/205 assertions.

## Tests Of The Tests

The sparse information matrix must match the dense information matrix to
`1e-8`, remain symmetric, keep relative error against the observed Hessian
below `0.1`, appear in the combined payload, and fail explicitly for singular
fixed-effect information.

## Consistency Audit

The code remains internal and exact-Gaussian. It does not export symbols, wire
the R bridge, change q4, or touch non-Gaussian/Laplace paths.

## GitHub Issue Maintenance

No GitHub issue was edited or commented on.

## What Did Not Go Smoothly

No implementation correction was needed; the focused test passed on the first
run after adding the sparse information diagnostic.

## Team Learning

The same projection helper used by the sparse score gives a compact way to
evaluate average-information products without building dense `P`.

## Known Limitations

There is still no production update step, step-halving, simulation evidence, R
bridge provenance field, or 10k-scale interval claim.

## Next Actions

Build a guarded two-parameter average-information update experiment and compare
its endpoint with the finite-difference, dense-score, and sparse-score optimizer
diagnostics before any stronger estimator language is used.
