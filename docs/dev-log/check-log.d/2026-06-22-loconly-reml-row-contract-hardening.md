# 2026-06-22 - Location-only Gaussian REML row-contract hardening

Goal:

- Harden the exact-Gaussian location-only REML simulation-status row contract
  after banking the first row surface, without promoting q4, non-Gaussian,
  bridge, coverage, public optimizer, or Ayumi-facing claims.

Checks:

```sh
julia --project=. test/test_location_only_reml_mme.jl
julia --project=. tools/loconly-reml-simulation-status.jl --output docs/dev-log/validation-status/2026-06-21-loconly-reml-simulation-status.tsv
tmp=$(mktemp -d)/loconly-status-medium.tsv; julia --project=. tools/loconly-reml-simulation-status.jl --with-medium-stress --output "$tmp" && wc -l "$tmp"
tmp=$(mktemp -d)/loconly-status-large.tsv; julia --project=. tools/loconly-reml-simulation-status.jl --with-large-stress --output "$tmp" && wc -l "$tmp"
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|ai_reml_ready = true" src/location_only.jl test/test_location_only_reml_mme.jl docs/dev-log/check-log.d/2026-06-22-loconly-reml-row-contract-hardening.md docs/dev-log/after-task/2026-06-22-loconly-reml-row-contract-hardening.md docs/dev-log/validation-status/README.md docs/dev-log/scout/2026-06-22-loconly-reml-external-comparator.md
```

Result:

- The focused test passed: 370/370 assertions.
- The default TSV writer produced four rows.
- The optional medium-stress writer produced five rows in a temporary TSV,
  six lines including the header.
- The optional large-stress writer produced five rows in a temporary TSV,
  six lines including the header, with the extra row reported as
  `large_interior_stress_skipped` because no explicit runtime budget was
  supplied.
- `git diff --check` was clean.

Boundary:

- The row contract remains exact-Gaussian and diagnostic-only. Optional stress
  rows are not coverage evidence and do not change `ai_reml_ready = false`.
