# After Task: Location-Only Gaussian REML Simulation-Status Rows

## Goal

Add a compact, machine-readable simulation-status surface for the
exact-Gaussian location-only REML pilot, so stable recovery, condition-grid,
weak-signal boundary, and larger interior stress diagnostics cannot be blurred
into one informal status sentence. Then harden that surface through slice 20:
schema, validator, TSV writer, optional medium stress row, broader recovery
grid, weak-signal condition grid, seed/runtime fields, and failure-reason
counts.

## Implemented

`src/location_only.jl` now has `_loconly_reml_simulation_status()`. It returns
four row records with target, estimator, design, claim status, coverage status,
replicate counts, convergence rate, boundary rate, point-recovery summaries,
runtime, seed, evidence, and next gate.

The row contract now also has:

- `_loconly_reml_simulation_status_schema()`
- `_loconly_reml_validate_simulation_status()`
- `_loconly_reml_write_simulation_status_tsv()`
- `expected_behavior`
- `failure_reason_counts`
- `mcse_status = :diagnostic_only`
- `runtime_budget_seconds`
- `seed_registry`
- optional `medium_interior_stress`
- `_loconly_reml_broader_recovery_grid_diagnostic()`
- `_loconly_reml_weak_signal_condition_grid_diagnostic()`

`tools/loconly-reml-simulation-status.jl` regenerates the default TSV and can
write an optional five-row TSV with `--with-medium-stress`.

The row artifact is banked at
`docs/dev-log/validation-status/2026-06-21-loconly-reml-simulation-status.tsv`.
The existing local validation-status TSV now names the machine-readable status
rows and the larger interior stress row.

## Mathematical Contract

The rows use the exact Gaussian location-only phylogenetic mean cell only:

```text
y_i = X_i beta + u_species(i) + epsilon_i
u ~ N(0, sigma_phy^2 Sigma_phy)
epsilon ~ N(0, sigma^2 I)
```

They report point-recovery and boundary diagnostics for the guarded
average-information update experiment. They do not evaluate interval coverage
and do not apply to q4 or non-Gaussian routes.

## Files Changed

- `src/location_only.jl`
- `test/test_location_only_reml_mme.jl`
- `tools/loconly-reml-simulation-status.jl`
- `docs/dev-log/check-log.d/2026-06-21-loconly-reml-simulation-status.md`
- `docs/dev-log/after-task/2026-06-21-loconly-reml-simulation-status.md`
- `docs/dev-log/validation-status/2026-06-21-loconly-gaussian-reml-mme.tsv`
- `docs/dev-log/validation-status/2026-06-21-loconly-reml-simulation-status.tsv`

## Checks Run

```sh
julia --project=. test/test_location_only_reml_mme.jl
julia --project=. tools/loconly-reml-simulation-status.jl --output docs/dev-log/validation-status/2026-06-21-loconly-reml-simulation-status.tsv
tmp=$(mktemp -d)/loconly-status-medium.tsv; julia --project=. tools/loconly-reml-simulation-status.jl --with-medium-stress --output "$tmp" && wc -l "$tmp"
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|AI-REML optimizer" src/location_only.jl test/test_location_only_reml_mme.jl docs/dev-log/check-log.d/2026-06-21-loconly-reml-simulation-status.md docs/dev-log/after-task/2026-06-21-loconly-reml-simulation-status.md docs/dev-log/validation-status/2026-06-21-loconly-gaussian-reml-mme.tsv docs/dev-log/validation-status/2026-06-21-loconly-reml-simulation-status.tsv
```

The focused test passed: 348/348 assertions. The default TSV writer produced
four rows. The optional medium-stress script path produced five rows in a
temporary TSV.

## Tests Of The Tests

The status-schema test requires four expected row IDs, exact target and
estimator labels, `coverage_status = :not_evaluated`, nonnegative runtimes,
explicit seeds and evidence paths, bounded boundary rates, and row-specific
next gates. The weak-signal row must retain a boundary rate of at least 0.5,
while the larger interior stress row must accept both replicates.

The expanded test now also verifies the schema fields, row order, validator,
TSV writer header, optional medium stress row, broader recovery-grid helper,
weak-signal condition-grid helper, seed registry, runtime budget field,
failure-reason count field, and diagnostic-only MCSE status.

## Consistency Audit

The helper and tool script are internal and exact-Gaussian. They do not export
symbols, wire the R bridge, change q4, or touch non-Gaussian/Laplace paths.

## GitHub Issue Maintenance

No GitHub issue was edited or commented on.

## What Did Not Go Smoothly

The first focused rerun failed because the TSV header assertion compared a
vector read from file with a tuple schema. The assertion now compares vectors.
The first tool-script run failed because a string separator was over-escaped;
the script now uses the correct Julia string.

## Team Learning

Simulation evidence should be row-shaped and writer-backed as soon as there is
more than one diagnostic condition. That keeps stable interior recovery,
weak-signal boundary behavior, and stress-smoke evidence from being promoted
under one label.

## Known Limitations

The row set and optional stress path are tiny and diagnostic-only. They do not
support coverage, bridge, q4, non-Gaussian, Ayumi-facing, or 10k-scale claims.

## Next Actions

Use the TSV writer as the stable interface for future broadening. Larger
exact-Gaussian stress rows should stay optional until a separate runtime budget
and CI strategy are chosen.
