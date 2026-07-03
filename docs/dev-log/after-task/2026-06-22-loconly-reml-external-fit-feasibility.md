# After Task: Location-Only Gaussian REML External Fit Feasibility

## Goal

Check whether the current exact-Gaussian location-only REML fixture can advance
to a same-estimand external `phylolm` fit comparison.

## Implemented

`src/location_only.jl` now has a fit-feasibility schema, status helper, and
validator:

- `_loconly_reml_external_comparator_fit_feasibility_schema()`
- `_loconly_reml_external_comparator_fit_feasibility_status()`
- `_loconly_reml_validate_external_comparator_fit_feasibility()`

The feasibility row records local `phylolm` version 2.6.5, the current fixture
dimensions, and the blocker. The current fixture has 12 observations for 6
species, two rows per species, and within-species covariate variation.
`phylolm` is a tip-level phylogenetic linear model, so running it on this
fixture would not reproduce the same REML target. The row therefore keeps
`fit_status = :not_run`, `same_estimand_status =
:not_same_estimand_current_fixture`, `dependency_status = :not_added`,
`coverage_status = :not_evaluated`, and `ai_reml_ready = false`.

## Files Changed

- `src/location_only.jl`
- `test/test_location_only_reml_mme.jl`
- `docs/dev-log/scout/2026-06-22-loconly-reml-external-comparator.md`
- `docs/dev-log/check-log.d/2026-06-22-loconly-reml-external-fit-feasibility.md`
- `docs/dev-log/after-task/2026-06-22-loconly-reml-external-fit-feasibility.md`

## Checks Run

```sh
julia --project=. test/test_location_only_reml_mme.jl
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|ai_reml_ready = true" src/location_only.jl test/test_location_only_reml_mme.jl tools/loconly-reml-external-comparator-probe.jl docs/dev-log/check-log.d/2026-06-22-loconly-reml-external-fit-feasibility.md docs/dev-log/after-task/2026-06-22-loconly-reml-external-fit-feasibility.md docs/dev-log/scout/2026-06-22-loconly-reml-external-comparator.md
```

The focused test passed locally: 483/483 assertions.
`git diff --check` was clean. The claim-boundary scan hit only the quoted scan
command in this after-task report and the paired check-log entry.

## Tests Of The Tests

The focused test pins the feasibility schema, checks the fixture dimensions,
requires the repeated-observation blocker, and rejects a row that tries to mark
`fit_status = fit_run`.

## Consistency Audit

This slice records negative same-estimand evidence. It prevents a misleading
external-comparator claim for a tip-level model on a replicated-observation
fixture. It does not add a dependency, run `phylolm`, promote the R bridge,
touch q4, touch non-Gaussian/Laplace paths, evaluate coverage, or mark AI-REML
ready.

## GitHub Issue Maintenance

No GitHub issue was edited or commented on.

## Next Actions

Choose a replicate-capable comparator, or define a separate tip-level fixture
whose model target is genuinely the same as the external `phylolm` target.
