# After Task: Location-Only Gaussian REML Tiny Recovery Grid

## Goal

Add a deterministic tiny recovery grid for the exact-Gaussian location-only
REML pilot so the guarded update experiment has first point-recovery evidence.

## Implemented

`src/location_only.jl` now has `_loconly_reml_recovery_grid_diagnostic()`. It
simulates data from
`y = X beta + u_species + epsilon`,
with `u ~ N(0, sigma_phy^2 Sigma_phy)` and
`epsilon ~ N(0, sigma^2 I)`, fits the guarded average-information update
experiment, and reports convergence rate, mean estimates, bias, RMSE, MCSE for
bias, boundary counts, and replicate records.

The output includes compact ADEMP-style fields for aim, data-generating
mechanism, estimands, method, and performance measures.

## Mathematical Contract

The simulation target is the exact Gaussian location-only phylogenetic mean
cell. It evaluates point-estimate recovery for `sigma` and `sigma_phy`; it does
not evaluate interval coverage or q4/non-Gaussian behavior.

## Files Changed

- `src/location_only.jl`
- `test/test_location_only_reml_mme.jl`
- `docs/dev-log/check-log.d/2026-06-21-loconly-reml-recovery-grid.md`
- `docs/dev-log/after-task/2026-06-21-loconly-reml-recovery-grid.md`
- `docs/dev-log/validation-status/2026-06-21-loconly-gaussian-reml-mme.tsv`

## Checks Run

```sh
julia --project=. test/test_location_only_reml_mme.jl
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|AI-REML optimizer" src/location_only.jl test/test_location_only_reml_mme.jl docs/dev-log/check-log.d/2026-06-21-loconly-reml-recovery-grid.md docs/dev-log/after-task/2026-06-21-loconly-reml-recovery-grid.md docs/dev-log/validation-status/2026-06-21-loconly-gaussian-reml-mme.tsv
```

The focused test passed: 252/252 assertions.

## Tests Of The Tests

The test uses a fixed seed, known `sigma`/`sigma_phy`, 10 species, 3
observations per species, and 3 replicates. It requires all fits to be accepted,
all boundaries to be interior, finite bias/RMSE/MCSE fields, small final score
norms, and broad bias sanity thresholds.

## Consistency Audit

The diagnostic is internal and exact-Gaussian. It does not export symbols, wire
the R bridge, change q4, or touch non-Gaussian/Laplace paths.

## GitHub Issue Maintenance

No GitHub issue was edited or commented on.

## What Did Not Go Smoothly

The first draft used a very sparse data cell and correctly exposed weak-signal
boundary behavior in two replicates. The routine test cell was resized to 10
species with 3 observations per species so the optimizer-recovery test is stable
while staying small.

## Team Learning

Recovery diagnostics should start with a stable interior cell before adding
weak-signal boundary cells; otherwise the test conflates optimizer recovery with
identifiability stress.

## Known Limitations

The grid is intentionally tiny. It does not support coverage claims, large-tree
performance claims, bridge claims, or q4/non-Gaussian generalization.

## Next Actions

Add a condition-grid wrapper with one interior cell and one weak-signal boundary
cell, keeping each row labelled as diagnostic rather than promotion evidence.
