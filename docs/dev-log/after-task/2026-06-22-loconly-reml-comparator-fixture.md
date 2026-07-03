# After Task: Location-Only Gaussian REML Comparator Fixture

## Goal

Add a versioned same-estimand fixture for the exact-Gaussian location-only REML
external-comparator lane without adding an external package dependency.

## Implemented

`src/location_only.jl` now has
`_loconly_reml_external_comparator_fixture_schema()`,
`_loconly_reml_external_comparator_fixture()`, and
`_loconly_reml_validate_external_comparator_fixture()`.

The fixture version is `loconly-gaussian-phylo-reml-v1`. It is a small
deterministic balanced-tree data bundle with species IDs, design matrix,
response vector, dense phylogenetic covariance target, known variance-component
point, and dense GLS REML reference values. The fixture records
`coverage_status = :not_evaluated` and `ai_reml_ready = false`.

`_loconly_reml_external_comparator_status()` now includes fixture status,
schema, fixture contents, and fixture validation. The phylolm-style candidate
row remains `dependency_status = :not_added`, but its `artifact_status` is now
`:fixture_defined` and its next gate is `:external_package_version_probe`.

## Files Changed

- `src/location_only.jl`
- `test/test_location_only_reml_mme.jl`
- `docs/dev-log/scout/2026-06-22-loconly-reml-external-comparator.md`
- `docs/dev-log/check-log.d/2026-06-22-loconly-reml-comparator-fixture.md`
- `docs/dev-log/after-task/2026-06-22-loconly-reml-comparator-fixture.md`

## Checks Run

```sh
julia --project=. test/test_location_only_reml_mme.jl
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|ai_reml_ready = true" src/location_only.jl test/test_location_only_reml_mme.jl docs/dev-log/check-log.d/2026-06-22-loconly-reml-comparator-fixture.md docs/dev-log/after-task/2026-06-22-loconly-reml-comparator-fixture.md docs/dev-log/scout/2026-06-22-loconly-reml-external-comparator.md
```

The focused test passed locally: 407/407 assertions. `git diff --check` was
clean. The claim-boundary scan hit only the quoted scan command in this
after-task report and the paired check-log entry.

## Tests Of The Tests

The focused test pins the fixture schema, validates the fixture status row,
checks that the future phylolm-style comparator is still dependency-free, and
recomputes the dense GLS REML reference from the fixture's `X`, `y`, species
IDs, and `Sigma_phy`.

The test also rejects a fixture whose target is changed to `:q4_phylo`.

## Consistency Audit

This is a developer fixture for the exact Gaussian location-only phylogenetic
mean REML target only. It does not change `src/` public exports, add an external
dependency, add a script, wire the R bridge, touch q4, or touch
non-Gaussian/Laplace paths.

## GitHub Issue Maintenance

No GitHub issue was edited or commented on.

## What Did Not Go Smoothly

Nothing material. The slice stayed bounded to a deterministic fixture and row
contract.

## Team Learning

External comparator selection should start from a versioned same-estimand
fixture. A package name is not evidence until it reproduces the same restricted
likelihood target, covariance target, and boundary label on that fixture.

## Known Limitations

No external package has been selected or added. The fixture is not coverage
evidence, not bridge evidence, not q4 evidence, not non-Gaussian evidence, and
not a public optimizer claim.

## Next Actions

Probe a concrete optional developer comparator package/version against
`loconly-gaussian-phylo-reml-v1`, or keep the dense GLS oracle as the only
covered comparator evidence.
