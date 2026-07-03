# After Task: Location-Only Gaussian REML Comparator And Boundary Hardening

## Goal

Complete the next 20 local exact-Gaussian hardening slices for the
location-only phylogenetic REML pilot without widening the AI-REML claim.

## Implemented

`src/location_only.jl` now has dense developer REML components for the same
Gaussian location-only estimand, plus `_loconly_dense_comparator_diagnostic()`
to compare sparse and dense `nll`, `beta`, and fixed-effect information.

Added `_loconly_reml_boundary_status()` to classify interior, near-zero
variance, singular fixed-effect information, and non-finite objective states.
The singular-design branch now checks fixed-effect design rank directly so a
failed profile solve still reports the right boundary class.

The finite-difference optimizer diagnostic now reports an observed Hessian,
observed-Hessian eigenvalues, positive-definite status, dense-comparator
evidence at the optimum, and boundary status. Added
`_loconly_reml_diagnostic_payload()` to bundle boundary, comparator, trace, PEV,
information, validation, and bridge-schema diagnostics for a supplied point.

## Mathematical Contract

The dense comparator evaluates the same restricted objective:
`nll_REML = nll_ML(beta_hat; sigma, sigma_phy) +
0.5 logdet(X'V^{-1}X)`, with `V = sigma^2 I + sigma_phy^2 S Q_cond^{-1} S'`.
It is intentionally dense and developer-only.

## Files Changed

- `src/location_only.jl`
- `test/test_location_only_reml_mme.jl`
- `docs/dev-log/check-log.d/2026-06-21-loconly-reml-comparator-boundary.md`
- `docs/dev-log/after-task/2026-06-21-loconly-reml-comparator-boundary.md`
- `docs/dev-log/validation-status/2026-06-21-loconly-gaussian-reml-mme.tsv`

## Checks Run

```sh
julia --project=. test/test_location_only_reml_mme.jl
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|AI-REML optimizer" src/location_only.jl test/test_location_only_reml_mme.jl docs/dev-log/check-log.d/2026-06-21-loconly-reml-comparator-boundary.md docs/dev-log/after-task/2026-06-21-loconly-reml-comparator-boundary.md docs/dev-log/validation-status/2026-06-21-loconly-gaussian-reml-mme.tsv
```

The focused test passed: 122/122 assertions in 7.0 seconds.

## Tests Of The Tests

The dense comparator is independent of the sparse Woodbury path. Boundary tests
cover near-zero variance, singular fixed-effect design, and invalid non-finite
inputs. Optimizer tests now require the finite-difference optimum to remain
dense-comparator consistent and to expose a positive-definite observed Hessian
on the deterministic interior fixture. The PEV shrinkage check verifies that
duplicating observations reduces or preserves the leaf posterior variances.

## Consistency Audit

The work is internal and exact-Gaussian. It does not export a new symbol, change
formula grammar, wire an R bridge field, change q4, or touch non-Gaussian or
Laplace code paths.

## GitHub Issue Maintenance

No GitHub issue was edited or commented on. The local issue-comment draft in
drmTMB remains the handoff artifact for maintainer review.

## What Did Not Go Smoothly

The singular-design fixture initially classified as `nonfinite_objective`
because the profile solve failed before returning a fixed-effect information
matrix. The boundary classifier now checks `rank(X) < k` first.

## Team Learning

A dense same-estimand comparator is more useful than an external name at this
stage. It catches algebra drift while keeping the dependency surface empty.

## Known Limitations

No true average-information update is implemented. The optimizer remains a
finite-difference experiment with `ai_reml_ready = false`. No full DRM.jl test
suite was run.

## Next Actions

Choose between an analytic restricted-score implementation and a genuine
average-information update as the next engine slice.
