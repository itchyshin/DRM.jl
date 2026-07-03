# After Task: Exact-Gaussian Diagnostics Documenter Page

## Goal

Add a Documenter-facing diagnostic page for the exact-Gaussian row-contract
transfer lane without promoting public optimizer, bridge, or interval-coverage
claims.

## Implemented

Added:

- `docs/src/diagnostics-and-validation/exact-gaussian-diagnostics.md`

Updated:

- `docs/make.jl`
- `docs/src/developer-notes/source-map.md`

The new page records the current location-only REML row-contract donor, the
two-structured Gaussian sparse candidate, the local evidence gates, and the
claim boundaries. The source map now lists `location_only.jl` as loaded
diagnostic code and removes it from the stale not-yet-wired examples.

## Checks Run

```sh
julia --project=docs -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.instantiate()'
cd docs
julia --project=. --startup-file=no - <<'JL'
using Documenter
using DocumenterVitepress
using DRM
makedocs(...)
JL
cd ..
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|ai_reml_ready = true" docs/make.jl docs/src/diagnostics-and-validation/exact-gaussian-diagnostics.md docs/src/developer-notes/source-map.md docs/dev-log/check-log.d/2026-06-22-exact-gaussian-diagnostics-documenter.md docs/dev-log/after-task/2026-06-22-exact-gaussian-diagnostics-documenter.md
```

Result:

- The docs environment was instantiated after developing the local checkout into
  the ignored docs manifest.
- The no-deploy `makedocs` build completed and Vitepress rendered successfully.
- Existing warnings remained: absolute links in `index.md`, unlisted docstrings,
  missing optional logo/favicon assets, chunk-size warning, and npm audit noise.
- `git diff --check` was clean.
- The claim-boundary scan hit only the quoted scan command in this after-task
  report and the paired check-log entry.

## Consistency Audit

This is a Documenter diagnostic page. It does not promote the location-only
diagnostic lane to public AI-REML readiness, relabel the two-structured Gaussian
ML route as REML/AI-REML, promote q4, promote the R bridge, evaluate interval
coverage, touch non-Gaussian/Laplace routes, or change Ayumi-facing text.

## GitHub Issue Maintenance

No GitHub issue was edited or commented on.

## Next Actions

Use the page as the visible developer boundary before adding machine-readable
status rows for the two-structured Gaussian sparse route.
