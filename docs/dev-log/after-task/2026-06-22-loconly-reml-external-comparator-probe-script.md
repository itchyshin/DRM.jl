# After Task: Location-Only Gaussian REML External Comparator Probe Script

## Goal

Add a developer-only package/version probe script for the exact-Gaussian
location-only phylogenetic REML external-comparator lane without adding an
external dependency or running an external fit.

## Implemented

`src/location_only.jl` now has a probe-result schema, validator, status helper,
and TSV writer:

- `_loconly_reml_external_comparator_probe_result_schema()`
- `_loconly_reml_external_comparator_probe_status()`
- `_loconly_reml_validate_external_comparator_probe_status()`
- `_loconly_reml_write_external_comparator_probe_tsv()`

`tools/loconly-reml-external-comparator-probe.jl` probes a developer R
environment for an optional candidate package version and writes a
machine-readable artifact. The script does not import the package into DRM.jl,
add it to `Project.toml`, or run a comparator fit.

The local artifact
`docs/dev-log/validation-status/2026-06-22-loconly-reml-external-comparator-probe.tsv`
recorded `phylolm` version 2.6.5 with `fit_status = not_run`,
`same_estimand_status = requires_fixture_reproduction`, `dependency_status =
not_added`, `coverage_status = not_evaluated`, and `ai_reml_ready = false`.

## Files Changed

- `src/location_only.jl`
- `test/test_location_only_reml_mme.jl`
- `tools/loconly-reml-external-comparator-probe.jl`
- `docs/dev-log/validation-status/2026-06-22-loconly-reml-external-comparator-probe.tsv`
- `docs/dev-log/validation-status/README.md`
- `docs/dev-log/scout/2026-06-22-loconly-reml-external-comparator.md`
- `docs/dev-log/check-log.d/2026-06-22-loconly-reml-external-comparator-probe-script.md`
- `docs/dev-log/after-task/2026-06-22-loconly-reml-external-comparator-probe-script.md`

## Checks Run

```sh
julia --project=. test/test_location_only_reml_mme.jl
julia --project=. tools/loconly-reml-external-comparator-probe.jl --output docs/dev-log/validation-status/2026-06-22-loconly-reml-external-comparator-probe.tsv
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|ai_reml_ready = true" src/location_only.jl test/test_location_only_reml_mme.jl tools/loconly-reml-external-comparator-probe.jl docs/dev-log/check-log.d/2026-06-22-loconly-reml-external-comparator-probe-script.md docs/dev-log/after-task/2026-06-22-loconly-reml-external-comparator-probe-script.md docs/dev-log/scout/2026-06-22-loconly-reml-external-comparator.md docs/dev-log/validation-status/README.md docs/dev-log/validation-status/2026-06-22-loconly-reml-external-comparator-probe.tsv
```

The focused test passed locally: 459/459 assertions. The probe script wrote one
row to the validation-status TSV and recorded local `phylolm` version 2.6.5.
`git diff --check` was clean. The claim-boundary scan hit only the quoted scan
command in this after-task report and the paired check-log entry.

## Tests Of The Tests

The focused test pins the probe-result schema, validates the status row, writes
the TSV to a temporary directory, and rejects a row that tries to mark
`fit_status = fit_run`.

## Consistency Audit

This is still exact-Gaussian location-only developer evidence. It records a
local optional package version, not a same-estimand external fit. It does not
add an external dependency, change public API, promote the R bridge, touch q4,
touch non-Gaussian/Laplace paths, evaluate coverage, or mark AI-REML ready.

## GitHub Issue Maintenance

No GitHub issue was edited or commented on.

## Next Actions

Use the versioned fixture and the recorded local `phylolm` version to build a
developer-only external fit comparison. That next gate must compare the same
restricted likelihood target, covariance target, point estimates, and boundary
status before any broader claim changes.
