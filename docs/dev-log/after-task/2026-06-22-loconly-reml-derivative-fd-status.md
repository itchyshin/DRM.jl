# After Task: Location-Only Gaussian REML Derivative FD Status

## Goal

Turn the exact-Gaussian location-only REML score finite-difference checks into a
row-shaped fixture diagnostic.

## Implemented

`src/location_only.jl` now has a derivative finite-difference status schema,
status helper, and validator:

- `_loconly_reml_derivative_fd_status_schema()`
- `_loconly_reml_derivative_fd_status()`
- `_loconly_reml_validate_derivative_fd_status()`

The status helper rebuilds the `loconly-gaussian-phylo-reml-v1` fixture problem
and records two rows: dense developer score versus finite difference, and
sparse Woodbury score versus finite difference plus dense score. Each row keeps
`claim_status = :internal_diagnostic`, `coverage_status = :not_evaluated`, and
`ai_reml_ready = false`.

## Files Changed

- `src/location_only.jl`
- `test/test_location_only_reml_mme.jl`
- `docs/dev-log/check-log.d/2026-06-22-loconly-reml-derivative-fd-status.md`
- `docs/dev-log/after-task/2026-06-22-loconly-reml-derivative-fd-status.md`

## Checks Run

```sh
julia --project=. test/test_location_only_reml_mme.jl
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|ai_reml_ready = true" src/location_only.jl test/test_location_only_reml_mme.jl docs/dev-log/check-log.d/2026-06-22-loconly-reml-derivative-fd-status.md docs/dev-log/after-task/2026-06-22-loconly-reml-derivative-fd-status.md
```

The focused test passed locally: 506/506 assertions.
`git diff --check` was clean. The claim-boundary scan hit only the quoted scan
command in this after-task report and the paired check-log entry.

## Tests Of The Tests

The focused test pins the derivative-FD schema, requires the dense and sparse
rows in order, validates finite score comparisons, and rejects a row whose
finite-difference discrepancy exceeds tolerance.

## Consistency Audit

This is exact-Gaussian fixture-level score evidence. It does not add a new
optimizer, promote AI-REML readiness, add bridge support, touch q4, touch
non-Gaussian/Laplace paths, or evaluate interval coverage.

## GitHub Issue Maintenance

No GitHub issue was edited or commented on.

## Next Actions

Broaden the derivative row from one fixture point into a small derivative grid
over interior and near-boundary variance-component settings.
