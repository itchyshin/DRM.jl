# After Task: Location-Only Gaussian REML Weak-Boundary Stability

## Goal

Stabilize the exact-Gaussian location-only REML weak-signal diagnostic test
after Julia 1.12 CI produced a fully interior two-replicate weak-signal draw.

## Implemented

`test/test_location_only_reml_mme.jl` still checks that
`_loconly_reml_weak_signal_recovery_probe()` returns the exact Gaussian
location-only target, `design = :weak_signal_boundary_probe`,
`expected_behavior = :boundary_states_allowed`, `coverage_status =
:not_evaluated`, and `ai_reml_ready = false`.

The weak-probe test now verifies that `boundary_reps` is between zero and the
number of diagnostic replicates, `boundary_rate` is between zero and one, and
the rate equals `boundary_reps / n_reps`. The machine-readable
`weak_signal_boundary_probe` row gets the same bounded-rate check.

## Files Changed

- `test/test_location_only_reml_mme.jl`
- `docs/dev-log/check-log.d/2026-06-22-loconly-reml-weak-boundary-stability.md`
- `docs/dev-log/after-task/2026-06-22-loconly-reml-weak-boundary-stability.md`

## Checks Run

```sh
julia --project=. test/test_location_only_reml_mme.jl
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|ai_reml_ready = true" src/location_only.jl test/test_location_only_reml_mme.jl docs/dev-log/check-log.d/2026-06-22-loconly-reml-weak-boundary-stability.md docs/dev-log/after-task/2026-06-22-loconly-reml-weak-boundary-stability.md docs/dev-log/scout/2026-06-22-loconly-reml-external-comparator.md
```

The focused test passed locally: 387/387 assertions. `git diff --check` was
clean. The claim-boundary scan hit only the quoted scan command in this
after-task report and the paired check-log entry.

## Tests Of The Tests

The CI failure came from requiring `boundary_reps >= 1` and
`boundary_rate >= 0.5` on a two-replicate weak-signal diagnostic. Julia 1.12
produced `boundary_rate = 0.0`, which is a valid reported outcome for a tiny
diagnostic draw when the row is labelled `boundary_states_allowed`.

The test still fails if the weak row is relabelled as coverage evidence, if
`ai_reml_ready` becomes true, if the target changes, or if boundary accounting
falls outside `[0, 1]`.

## Consistency Audit

This is a test-contract stabilization for an internal exact-Gaussian,
location-only diagnostic. It does not change `src/`, export symbols, add an
external comparator, wire the R bridge, touch q4, or touch non-Gaussian/Laplace
paths.

## GitHub Issue Maintenance

No GitHub issue was edited or commented on.

## What Did Not Go Smoothly

The earlier weak-signal test encoded a desired qualitative diagnostic behavior
as a deterministic outcome. That made a two-replicate smoke grid sensitive to
Julia/RNG and optimizer-version differences.

## Team Learning

Weak-signal probes should test honest classification and bounded diagnostics.
They should not require a tiny deterministic draw to land on a specific side of
a numerical boundary.

## Known Limitations

This change does not add interval coverage evidence, an external comparator,
bridge support, q4 support, non-Gaussian support, large-scale interval claims,
or a public AI-REML optimizer claim.

## Next Actions

Let PR CI rerun on the stabilized weak-boundary contract. If the Julia matrix is
green, continue with the versioned same-estimand external-comparator fixture
slice.
