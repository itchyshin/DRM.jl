# 2026-06-22 - Exact-Gaussian diagnostics Documenter page

Goal:

- Add a Documenter-facing diagnostic page for the exact-Gaussian row-contract
  transfer lane without public optimizer, bridge, or interval-coverage claims.

Checks:

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

- The docs environment was instantiated with the local checkout developed into
  the ignored docs manifest.
- The no-deploy `makedocs` build completed and Vitepress rendered successfully.
- Existing warnings remained: absolute links in `index.md`, unlisted docstrings,
  missing optional logo/favicon assets, chunk-size warning, and npm audit noise.
- `git diff --check` was clean.
- The claim-boundary scan hit only the quoted scan command in this check-log
  and the paired after-task report.

Boundary:

- This is a Documenter diagnostic page. It does not promote AI-REML readiness,
  q4, the R bridge, interval coverage, non-Gaussian/Laplace routes, or
  Ayumi-facing text.
