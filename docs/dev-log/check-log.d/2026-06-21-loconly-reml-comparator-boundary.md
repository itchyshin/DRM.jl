# 2026-06-21 — Location-only Gaussian REML comparator and boundary hardening

Goal:

- Run the next 20 exact-Gaussian hardening slices after the post-gate
  diagnostics: dense REML comparator helpers, boundary classifier, optimizer
  observed-Hessian gates, diagnostic payload, posterior-variance shrinkage
  checks, and refreshed status evidence.

Checks:

```sh
julia --project=. test/test_location_only_reml_mme.jl
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|AI-REML optimizer" src/location_only.jl test/test_location_only_reml_mme.jl docs/dev-log/check-log.d/2026-06-21-loconly-reml-comparator-boundary.md docs/dev-log/after-task/2026-06-21-loconly-reml-comparator-boundary.md docs/dev-log/validation-status/2026-06-21-loconly-gaussian-reml-mme.tsv
```

Result:

- Added dense developer REML components and a sparse-vs-dense comparator
  diagnostic for the same exact Gaussian estimand.
- Added boundary classification for interior, near-zero variance, singular
  fixed-effect information, and non-finite objective states.
- Enriched the finite-difference optimizer diagnostic with observed Hessian
  eigenvalue status, dense-comparator evidence, and boundary status.
- Added a combined diagnostic payload tying boundary, dense comparator, trace,
  PEV, information, validation-status, and bridge-schema fields together.
- The focused test passed: 122/122 assertions in 7.0 seconds.

Boundary:

- The comparator is a dense same-estimand GLS/REML oracle, not an external
  package dependency. This remains internal exact-Gaussian evidence only: no
  AI-REML implementation, no R bridge promotion, and no q4/non-Gaussian/Ayumi
  claim.
