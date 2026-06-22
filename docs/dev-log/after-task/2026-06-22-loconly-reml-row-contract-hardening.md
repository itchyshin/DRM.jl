# After Task: Location-Only Gaussian REML Row-Contract Hardening

## Goal

Harden the exact-Gaussian location-only REML simulation-status row contract
after the first row surface was banked, while keeping the lane internal,
diagnostic-only, and separate from q4, non-Gaussian, R bridge, interval
coverage, public optimizer, Ayumi, and 10k-scale claims.

## Implemented

The row schema is now frozen in the focused test as an explicit tuple, so
schema drift fails loudly. The TSV writer now validates a supplied status before
writing and throws an explicit `simulation-status validation failed` error for
bad row contracts.

`_loconly_reml_simulation_status()` now has an opt-in large-stress path. Calling
with `include_large_stress = true` adds a machine-readable skipped row unless
the caller supplies a runtime budget large enough to run the larger fixture.
The command-line writer exposes the same path through `--with-large-stress` and
`--large-stress-budget-seconds`.

`_loconly_reml_simulation_status_provenance()` maps each row ID to its helper,
focused test, TSV artifact, and claim boundary. The validation-status README
records the row contract, optional stress semantics, and hard claim boundary.
A scout note records the external-comparator shape and recommends no new
dependency until a same-estimand route is chosen.

## Mathematical Contract

The row surface remains restricted to the exact Gaussian location-only
phylogenetic mean cell:

```text
y_i = X_i beta + u_species(i) + epsilon_i
u ~ N(0, sigma_phy^2 Sigma_phy)
epsilon ~ N(0, sigma^2 I)
```

No row evaluates interval coverage. No row applies to q4, Laplace,
non-Gaussian, bivariate location-scale, R bridge, Ayumi, or 10k-scale interval
claims.

## Files Changed

- `src/location_only.jl`
- `test/test_location_only_reml_mme.jl`
- `tools/loconly-reml-simulation-status.jl`
- `docs/dev-log/validation-status/README.md`
- `docs/dev-log/scout/2026-06-22-loconly-reml-external-comparator.md`
- `docs/dev-log/check-log.d/2026-06-22-loconly-reml-row-contract-hardening.md`
- `docs/dev-log/after-task/2026-06-22-loconly-reml-row-contract-hardening.md`

## Checks Run

```sh
julia --project=. test/test_location_only_reml_mme.jl
julia --project=. tools/loconly-reml-simulation-status.jl --output docs/dev-log/validation-status/2026-06-21-loconly-reml-simulation-status.tsv
tmp=$(mktemp -d)/loconly-status-medium.tsv; julia --project=. tools/loconly-reml-simulation-status.jl --with-medium-stress --output "$tmp" && wc -l "$tmp"
tmp=$(mktemp -d)/loconly-status-large.tsv; julia --project=. tools/loconly-reml-simulation-status.jl --with-large-stress --output "$tmp" && wc -l "$tmp"
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|ai_reml_ready = true" src/location_only.jl test/test_location_only_reml_mme.jl docs/dev-log/check-log.d/2026-06-22-loconly-reml-row-contract-hardening.md docs/dev-log/after-task/2026-06-22-loconly-reml-row-contract-hardening.md docs/dev-log/validation-status/README.md docs/dev-log/scout/2026-06-22-loconly-reml-external-comparator.md
```

The focused test passed: 370/370 assertions. The default TSV writer produced
four rows. The optional medium-stress writer produced five rows in a temporary
TSV, six lines including the header. The optional large-stress writer produced
five rows in a temporary TSV, six lines including the header, with
`large_interior_stress_skipped` as the extra row because no explicit runtime
budget was supplied. `git diff --check` was clean.

## Tests Of The Tests

The focused test now compares the schema to a hard-coded tuple, checks that a
malformed row contract is rejected by the validator and writer, verifies the
large-stress skipped row, and checks the provenance mapping for each default
row.

## Consistency Audit

The new optional large-stress path is opt-in and cheap by default. It records a
skipped row when the runtime budget is not explicit, so the status surface can
describe the next stress gate without silently running it or implying it passed.

## GitHub Issue Maintenance

No GitHub issue was edited or commented on. The comparator scout note is local
developer guidance only.

## What Did Not Go Smoothly

The first patch attempt used the wrong local field name for the phylogenetic
MCSE field. The patch was split into smaller edits and applied without changing
unrelated code.

## Team Learning

Machine-readable validation rows need the same discipline as exported APIs:
schema drift, optional runtime expansion, provenance, and malformed-input
behavior should all be tested before downstream dashboards rely on them.

## Known Limitations

The large-stress row is skipped unless an explicit runtime budget is supplied.
No external comparator dependency has been added. The row contract still does
not support coverage, bridge, q4, non-Gaussian, Ayumi-facing, or 10k-scale
claims.

## Next Actions

Choose a same-estimand external comparator only after a small fixture and
versioned comparator path are agreed. Keep larger stress rows optional until a
runtime budget and CI placement are chosen.
