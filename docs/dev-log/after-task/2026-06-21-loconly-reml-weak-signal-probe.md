# After Task: Location-Only Gaussian REML Weak-Signal Recovery Probe

## Goal

Add a weak-signal recovery probe for the exact-Gaussian location-only REML pilot
that reports boundary states as diagnostic outcomes instead of routine-test
failures.

## Implemented

`src/location_only.jl` now has `_loconly_reml_weak_signal_recovery_probe()`. It
runs a small low-phylogenetic-signal recovery grid and reports boundary count,
boundary rate, convergence rate, the nested recovery diagnostic, and
`expected_behavior = :boundary_states_allowed`.

## Mathematical Contract

The probe still uses the exact Gaussian location-only phylogenetic mean cell.
It intentionally explores a weak-signal point-recovery condition; it does not
evaluate interval coverage or q4/non-Gaussian behavior.

## Files Changed

- `src/location_only.jl`
- `test/test_location_only_reml_mme.jl`
- `docs/dev-log/check-log.d/2026-06-21-loconly-reml-weak-signal-probe.md`
- `docs/dev-log/after-task/2026-06-21-loconly-reml-weak-signal-probe.md`
- `docs/dev-log/validation-status/2026-06-21-loconly-gaussian-reml-mme.tsv`

## Checks Run

```sh
julia --project=. test/test_location_only_reml_mme.jl
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|AI-REML optimizer" src/location_only.jl test/test_location_only_reml_mme.jl docs/dev-log/check-log.d/2026-06-21-loconly-reml-weak-signal-probe.md docs/dev-log/after-task/2026-06-21-loconly-reml-weak-signal-probe.md docs/dev-log/validation-status/2026-06-21-loconly-gaussian-reml-mme.tsv
```

The focused test passed: 277/277 assertions.

## Tests Of The Tests

The probe uses a fixed seed and requires at least one boundary replicate while
not requiring convergence. This makes the weak-signal behavior visible without
turning it into a brittle recovery-success test.

## Consistency Audit

The diagnostic is internal and exact-Gaussian. It does not export symbols, wire
the R bridge, change q4, or touch non-Gaussian/Laplace paths.

## GitHub Issue Maintenance

No GitHub issue was edited or commented on.

## What Did Not Go Smoothly

No implementation correction was needed. The earlier unstable sparse recovery
draft became the design motivation for this explicit weak-signal probe.

## Team Learning

Boundary-prone simulation cells should be labelled as boundary probes and
tested for honest reporting, not for universal convergence.

## Known Limitations

The probe is tiny and intentionally boundary-prone. It does not support
coverage, bridge, q4, non-Gaussian, or 10k-scale claims.

## Next Actions

Add a compact simulation-status table that separates stable recovery,
condition-grid, and weak-signal boundary diagnostics in one machine-readable
row set.
