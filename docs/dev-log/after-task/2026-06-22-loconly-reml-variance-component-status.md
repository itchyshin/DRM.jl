# After Task: Location-Only Gaussian REML Variance-Component Status

## Goal

Bank row-shaped variance-component point-status output for the exact-Gaussian
location-only REML fixture without adding interval or coverage claims.

## Implemented

`src/location_only.jl` now has a variance-component status schema, status
helper, and validator:

- `_loconly_reml_variance_component_status_schema()`
- `_loconly_reml_variance_component_status()`
- `_loconly_reml_validate_variance_component_status()`

The status helper rebuilds the `loconly-gaussian-phylo-reml-v1` fixture problem,
runs the guarded sparse average-information update from two starts, and reports
two finite point rows: residual variance and phylogenetic variance. Each row
records the log-standard-deviation parameter, standard-deviation estimate,
variance estimate, point status, boundary status, and the explicit absence of
interval and coverage evidence.

The status keeps `point_status = :finite_optimizer_diagnostic`,
`interval_status = :not_evaluated`, `claim_status = :internal_diagnostic`,
`coverage_status = :not_evaluated`, and `ai_reml_ready = false`.

## Files Changed

- `src/location_only.jl`
- `test/test_location_only_reml_mme.jl`
- `docs/dev-log/check-log.d/2026-06-22-loconly-reml-variance-component-status.md`
- `docs/dev-log/after-task/2026-06-22-loconly-reml-variance-component-status.md`

## Checks Run

```sh
julia --project=. test/test_location_only_reml_mme.jl
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|ai_reml_ready = true" src/location_only.jl test/test_location_only_reml_mme.jl docs/dev-log/check-log.d/2026-06-22-loconly-reml-variance-component-status.md docs/dev-log/after-task/2026-06-22-loconly-reml-variance-component-status.md
```

The focused test passed locally: 600/600 assertions.
`git diff --check` was clean. The claim-boundary scan hit only the quoted scan
command in this after-task report and the paired check-log entry.

## Tests Of The Tests

The focused test pins the variance-component status schema, checks residual and
phylogenetic component rows, requires finite positive standard-deviation and
variance estimates, checks variance equals squared standard deviation, requires
interior boundary status, and rejects a row that reports an evaluated interval
status.

## Consistency Audit

This is a variance-component point-status diagnostic only. It does not evaluate
interval coverage, promote intervals, promote a public optimizer, promote the R
bridge, touch q4, touch non-Gaussian/Laplace routes, or mark AI-REML ready.

## GitHub Issue Maintenance

No GitHub issue was edited or commented on.

## Next Actions

Use this row shape as the direct-Julia side of a later R-via-Julia parity table
only after the R bridge has its own row-specific status evidence.
