# After Task: Location-Only Gaussian REML Profile Status

## Goal

Bank a row-shaped local profile-axis sanity diagnostic for the exact-Gaussian
location-only REML fixture.

## Implemented

`src/location_only.jl` now has a profile-status schema, status helper, and
validator:

- `_loconly_reml_profile_status_schema()`
- `_loconly_reml_profile_status()`
- `_loconly_reml_validate_profile_status()`

The status helper rebuilds the `loconly-gaussian-phylo-reml-v1` fixture problem,
runs the guarded sparse average-information update from two starts, and then
records a local one-step profile diagnostic on the residual and phylogenetic
log-standard-deviation axes. The two rows require finite objective values and a
center point that is no larger than the neighboring one-step axis points.

The diagnostic keeps `claim_status = :internal_diagnostic`,
`coverage_status = :not_evaluated`, and `ai_reml_ready = false`.

## Files Changed

- `src/location_only.jl`
- `test/test_location_only_reml_mme.jl`
- `docs/dev-log/check-log.d/2026-06-22-loconly-reml-profile-status.md`
- `docs/dev-log/after-task/2026-06-22-loconly-reml-profile-status.md`

## Checks Run

```sh
julia --project=. test/test_location_only_reml_mme.jl
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|ai_reml_ready = true" src/location_only.jl test/test_location_only_reml_mme.jl docs/dev-log/check-log.d/2026-06-22-loconly-reml-profile-status.md docs/dev-log/after-task/2026-06-22-loconly-reml-profile-status.md
```

The focused test passed locally: 572/572 assertions.
`git diff --check` was clean. The claim-boundary scan hit only the quoted scan
command in this after-task report and the paired check-log entry.

## Tests Of The Tests

The focused test pins the profile-status schema, checks the residual and
phylogenetic log-standard-deviation rows, requires finite local profile values,
requires the center to be the axis minimum among the one-step neighbors, and
rejects a row that reports `center_is_axis_min = false`.

## Consistency Audit

This is a local profile-axis sanity diagnostic only. It does not evaluate
interval coverage, promote profile-likelihood intervals, promote a public
optimizer, promote the R bridge, touch q4, touch non-Gaussian/Laplace routes, or
mark AI-REML ready.

## GitHub Issue Maintenance

No GitHub issue was edited or commented on.

## Next Actions

Keep profile diagnostics internal until a later slice defines explicit
likelihood-grid and interval-coverage gates.
