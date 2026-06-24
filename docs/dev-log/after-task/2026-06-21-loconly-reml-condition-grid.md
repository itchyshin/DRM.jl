# After Task: Location-Only Gaussian REML Condition Recovery Grid

## Goal

Add a condition-grid wrapper for the tiny exact-Gaussian recovery diagnostic so
multiple cells are recorded separately rather than collapsed into one summary.

## Implemented

`src/location_only.jl` now has `_loconly_reml_recovery_condition_grid_diagnostic()`.
It runs `_loconly_reml_recovery_grid_diagnostic()` over named cells and returns
row-level convergence, bias, RMSE, MCSE, boundary counts, and the full nested
diagnostic for each condition.

The default tiny grid uses two stable interior cells: a baseline phylogenetic
SD and a higher phylogenetic SD. Weak-signal boundary cells are deliberately left
for a later diagnostic so routine tests do not conflate recovery with
identifiability stress.

## Mathematical Contract

The condition grid still targets the exact Gaussian location-only phylogenetic
mean cell. It evaluates point-estimate recovery for `sigma` and `sigma_phy`
under named simulation conditions; it does not evaluate interval coverage or
q4/non-Gaussian behavior.

## Files Changed

- `src/location_only.jl`
- `test/test_location_only_reml_mme.jl`
- `docs/dev-log/check-log.d/2026-06-21-loconly-reml-condition-grid.md`
- `docs/dev-log/after-task/2026-06-21-loconly-reml-condition-grid.md`
- `docs/dev-log/validation-status/2026-06-21-loconly-gaussian-reml-mme.tsv`

## Checks Run

```sh
julia --project=. test/test_location_only_reml_mme.jl
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|AI-REML optimizer" src/location_only.jl test/test_location_only_reml_mme.jl docs/dev-log/check-log.d/2026-06-21-loconly-reml-condition-grid.md docs/dev-log/after-task/2026-06-21-loconly-reml-condition-grid.md docs/dev-log/validation-status/2026-06-21-loconly-gaussian-reml-mme.tsv
```

The focused test passed: 267/267 assertions.

## Tests Of The Tests

The default condition grid uses two named cells and requires both cells to have
2/2 accepted fits, interior boundary counts, finite bias fields, and nested
diagnostics labelled as simulation diagnostics.

## Consistency Audit

The diagnostic is internal and exact-Gaussian. It does not export symbols, wire
the R bridge, change q4, or touch non-Gaussian/Laplace paths.

## GitHub Issue Maintenance

No GitHub issue was edited or commented on.

## What Did Not Go Smoothly

No implementation correction was needed after adding the condition wrapper. The
earlier lesson remains: weak-signal boundary rows should be their own
diagnostic, not a hidden row inside the stable recovery test.

## Team Learning

Row-separated condition diagnostics make it harder to overread one tiny
simulation result as a general recovery claim.

## Known Limitations

The grid is intentionally tiny and uses only stable interior cells. It does not
support coverage, large-tree, bridge, q4, or non-Gaussian claims.

## Next Actions

Add an explicitly labelled weak-signal/boundary condition grid that is allowed
to report low convergence or boundary states without failing routine tests.
