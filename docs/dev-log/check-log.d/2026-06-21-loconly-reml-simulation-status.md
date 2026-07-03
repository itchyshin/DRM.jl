# 2026-06-21 — Location-only Gaussian REML simulation-status rows

Goal:

- Add one machine-readable simulation-status surface that keeps stable
  recovery, condition-grid, weak-signal boundary, and larger interior stress
  diagnostics row-separated for the exact-Gaussian location-only REML pilot,
  then harden the row contract through slice 20 with writer, validator,
  optional stress, and weak-signal grid helpers.

Checks:

```sh
julia --project=. test/test_location_only_reml_mme.jl
julia --project=. tools/loconly-reml-simulation-status.jl --output docs/dev-log/validation-status/2026-06-21-loconly-reml-simulation-status.tsv
tmp=$(mktemp -d)/loconly-status-medium.tsv; julia --project=. tools/loconly-reml-simulation-status.jl --with-medium-stress --output "$tmp" && wc -l "$tmp"
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|AI-REML optimizer" src/location_only.jl test/test_location_only_reml_mme.jl docs/dev-log/check-log.d/2026-06-21-loconly-reml-simulation-status.md docs/dev-log/after-task/2026-06-21-loconly-reml-simulation-status.md docs/dev-log/validation-status/2026-06-21-loconly-gaussian-reml-mme.tsv docs/dev-log/validation-status/2026-06-21-loconly-reml-simulation-status.tsv
```

Result:

- Added `_loconly_reml_simulation_status()`, returning four rows:
  `stable_recovery`, `condition_grid`, `weak_signal_boundary_probe`, and
  `larger_interior_stress`.
- Added `_loconly_reml_simulation_status_schema()`,
  `_loconly_reml_validate_simulation_status()`, and
  `_loconly_reml_write_simulation_status_tsv()` so the status surface has a
  tested schema and a regenerable TSV writer.
- Added optional `medium_interior_stress`, broader recovery-grid, and
  weak-signal condition-grid helpers; these remain diagnostic-only.
- Added
  `docs/dev-log/validation-status/2026-06-21-loconly-reml-simulation-status.tsv`
  as the durable row artifact.
- The focused test passed: 348/348 assertions.
- The default TSV writer produced four rows. The optional medium-stress script
  path produced five rows in a temporary TSV.

Boundary:

- The rows have `claim_status = simulation_diagnostic`,
  `coverage_status = not_evaluated`, and `ai_reml_ready = false`. They do not
  claim interval coverage, R bridge support, q4 support, non-Gaussian support,
  10k-scale intervals, or Ayumi readiness.
