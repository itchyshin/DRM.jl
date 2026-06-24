# After Task: Location-Only Gaussian REML Line-Search Status

## Goal

Record a row-shaped guarded line-search diagnostic for the exact-Gaussian
location-only REML optimizer experiment.

## Implemented

`src/location_only.jl` now has a line-search status schema, status helper, and
validator:

- `_loconly_reml_line_search_status_schema()`
- `_loconly_reml_line_search_status()`
- `_loconly_reml_validate_line_search_status()`

The status helper rebuilds the `loconly-gaussian-phylo-reml-v1` fixture problem,
runs the guarded sparse average-information update from two starts, and records
whether the guarded line search was accepted. The row keeps `claim_status =
:optimizer_experiment`, `coverage_status = :not_evaluated`, and
`ai_reml_ready = false`. Its readiness reason explicitly says that no
simulation, bridge, or coverage gate is implemented.

## Files Changed

- `src/location_only.jl`
- `test/test_location_only_reml_mme.jl`
- `docs/dev-log/check-log.d/2026-06-22-loconly-reml-line-search-status.md`
- `docs/dev-log/after-task/2026-06-22-loconly-reml-line-search-status.md`

## Checks Run

```sh
julia --project=. test/test_location_only_reml_mme.jl
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|ai_reml_ready = true" src/location_only.jl test/test_location_only_reml_mme.jl docs/dev-log/check-log.d/2026-06-22-loconly-reml-line-search-status.md docs/dev-log/after-task/2026-06-22-loconly-reml-line-search-status.md
```

The focused test passed locally: 531/531 assertions.
`git diff --check` was clean. The claim-boundary scan hit only the quoted scan
command in this after-task report and the paired check-log entry.

## Tests Of The Tests

The focused test pins the line-search schema, requires an accepted guarded
line-search row on the fixture, checks the score tolerance and interior boundary
status, and rejects a row that tries to mark the readiness flag true.

## Consistency Audit

This is an optimizer-experiment diagnostic. It does not promote a public
optimizer, bridge support, q4, non-Gaussian/Laplace routes, interval coverage,
or public AI-REML readiness.

## GitHub Issue Maintenance

No GitHub issue was edited or commented on.

## Next Actions

Broaden the line-search row into a small condition grid so accepted steps,
halving counts, and blocker reasons are visible beyond the single fixture.
