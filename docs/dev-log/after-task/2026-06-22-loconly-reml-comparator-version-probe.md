# After Task: Location-Only Gaussian REML Comparator Version Probe

## Goal

Bank the external-comparator package/version probe contract for the
exact-Gaussian location-only phylogenetic REML diagnostic lane without choosing
or adding an external dependency.

## Implemented

`src/location_only.jl` now defines
`_loconly_reml_external_comparator_version_probe_schema()`,
`_loconly_reml_external_comparator_version_probe_rows()`, and
`_loconly_reml_validate_external_comparator_version_probe()`.

The version-probe row records the unselected phylolm-style REML candidate,
fixture id, fixture version, required same-estimand evidence, blocker, and next
gate. It stays `dependency_status = :not_added`,
`candidate_version = :unprobed`, and `artifact_status = :probe_plan_defined`.

`_loconly_reml_external_comparator_status()` now includes the version-probe
schema, rows, validation, and `version_probe_status = :defined_not_run`.

## Files Changed

- `src/location_only.jl`
- `test/test_location_only_reml_mme.jl`
- `docs/dev-log/scout/2026-06-22-loconly-reml-external-comparator.md`
- `docs/dev-log/check-log.d/2026-06-22-loconly-reml-comparator-version-probe.md`
- `docs/dev-log/after-task/2026-06-22-loconly-reml-comparator-version-probe.md`

## Checks Run

```sh
julia --project=. test/test_location_only_reml_mme.jl
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|ai_reml_ready = true" src/location_only.jl test/test_location_only_reml_mme.jl docs/dev-log/check-log.d/2026-06-22-loconly-reml-comparator-version-probe.md docs/dev-log/after-task/2026-06-22-loconly-reml-comparator-version-probe.md docs/dev-log/scout/2026-06-22-loconly-reml-external-comparator.md
```

The focused test passed locally: 429/429 assertions. `git diff --check` was
clean. The claim-boundary scan hit only the quoted scan command in this
after-task report and the paired check-log entry.

## Tests Of The Tests

The focused test pins the version-probe schema, checks that the probe row uses
the fixture id and fixture version from `loconly-gaussian-phylo-reml-v1`, and
verifies the required evidence gates for the restricted likelihood target and
covariance target.

The negative test changes the probe row to `dependency_status = :added` and
requires validation to reject it.

## Consistency Audit

This slice is still an internal diagnostic row for the exact Gaussian
location-only phylogenetic mean REML target. It does not add a package, run an
external comparator, wire the R bridge, touch q4, touch non-Gaussian/Laplace
paths, claim interval coverage, or mark AI-REML ready.

## GitHub Issue Maintenance

No GitHub issue was edited or commented on.

## Known Limitations

No package/version has been probed. The next row should add an optional
developer-only runner that can compare a concrete external package against the
versioned fixture.
