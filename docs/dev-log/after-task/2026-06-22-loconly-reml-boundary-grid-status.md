# After Task: Location-Only Gaussian REML Boundary Grid Status

## Goal

Bank a row-shaped near-zero variance boundary grid for the exact-Gaussian
location-only REML diagnostic lane.

## Implemented

`src/location_only.jl` now has a boundary-grid status schema, status helper, and
validator:

- `_loconly_reml_boundary_grid_status_schema()`
- `_loconly_reml_boundary_grid_status()`
- `_loconly_reml_validate_boundary_grid_status()`

The status helper wraps the weak-signal condition grid into explicit boundary
rows for `low_phylo_signal` and `near_zero_phylo_signal`. Each row records
accepted counts, convergence rate, boundary rate, and failure-reason counts.
The grid keeps `expected_behavior = :boundary_states_allowed`,
`claim_status = :simulation_diagnostic`, `coverage_status = :not_evaluated`,
and `ai_reml_ready = false`.

## Files Changed

- `src/location_only.jl`
- `test/test_location_only_reml_mme.jl`
- `docs/dev-log/check-log.d/2026-06-22-loconly-reml-boundary-grid-status.md`
- `docs/dev-log/after-task/2026-06-22-loconly-reml-boundary-grid-status.md`

## Checks Run

```sh
julia --project=. test/test_location_only_reml_mme.jl
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|ai_reml_ready = true" src/location_only.jl test/test_location_only_reml_mme.jl docs/dev-log/check-log.d/2026-06-22-loconly-reml-boundary-grid-status.md docs/dev-log/after-task/2026-06-22-loconly-reml-boundary-grid-status.md
```

The focused test passed locally: 550/550 assertions.
`git diff --check` was clean. The claim-boundary scan hit only the quoted scan
command in this after-task report and the paired check-log entry.

## Tests Of The Tests

The focused test pins the boundary-grid schema, checks both weak-signal rows,
requires bounded boundary rates, and rejects a row whose `boundary_rate` is
outside `[0, 1]`.

## Consistency Audit

This is boundary-behavior diagnostic evidence only. It does not evaluate
coverage, promote a public optimizer, promote the R bridge, touch q4, touch
non-Gaussian/Laplace routes, or mark AI-REML ready.

## GitHub Issue Maintenance

No GitHub issue was edited or commented on.

## Next Actions

Extend the boundary grid with additional near-zero variance and singular-design
cells if a later evidence gate needs broader failure-mode accounting.
