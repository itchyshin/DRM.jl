# After Task: Location-Only Gaussian REML Post-Gate Diagnostics

## Goal

Complete the next exact-Gaussian HSquared-transfer slices after the first
supplied-variance REML helper: optimizer experiment, PEV diagnostics,
validation/status rows, bridge payload draft fields, and micro scaling smoke.

## Implemented

`src/location_only.jl` now has `_loconly_reml_optimizer_diagnostic()`, a
developer-only LBFGS experiment that uses finite-difference gradients of the
restricted objective. It records the optimizer, best start, best objective,
gradient norm, all start records, `claim_status = :optimizer_experiment`, and
`ai_reml_ready = false`.

The same file now has `_loconly_takahashi_pev_diagnostic()`, which exposes the
Takahashi selected-inverse diagonal of `M^{-1}` and the leaf posterior
variances before any uncertainty extractor is considered.

Added `_loconly_reml_validation_status()` and
`_loconly_reml_bridge_payload_schema()` as internal anchors for status and
future R bridge provenance. The schema keeps `r_bridge_status = "planned"` and
`claim_status = "internal_diagnostic"`.

## Mathematical Contract

The target remains the exact Gaussian location-only phylogenetic mean model.
The restricted objective is the sparse Woodbury marginal negative log
likelihood after profiling `beta`, plus `0.5 logdet(X'V^{-1}X)`. The PEV
diagnostic reports the diagonal of the posterior covariance `M^{-1}` for the
augmented phylogenetic random effect. The optimizer experiment is a numerical
finite-difference experiment; it is not an average-information update.

## Files Changed

- `src/location_only.jl`
- `test/test_location_only_reml_mme.jl`
- `docs/dev-log/check-log.d/2026-06-21-loconly-reml-postgate.md`
- `docs/dev-log/after-task/2026-06-21-loconly-reml-postgate.md`
- `docs/dev-log/validation-status/2026-06-21-loconly-gaussian-reml-mme.tsv`

## Checks Run

```sh
julia --project=. test/test_location_only_reml_mme.jl
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|AI-REML optimizer" src/location_only.jl test/test_location_only_reml_mme.jl docs/dev-log/check-log.d/2026-06-21-loconly-reml-postgate.md docs/dev-log/after-task/2026-06-21-loconly-reml-postgate.md docs/dev-log/validation-status/2026-06-21-loconly-gaussian-reml-mme.tsv
```

The focused test passed: 88/88 assertions in 6.2 seconds.

## Tests Of The Tests

The PEV diagnostic is checked against `diag(inv(Matrix(M)))` on the same tiny
fixture used for the dense REML oracle. The optimizer diagnostic starts from two
known finite points and must improve or match the supplied true-parameter
restricted objective while retaining `ai_reml_ready = false`. The scaling smoke
uses balanced trees with 8, 16, and 32 leaves, checks finite REML components,
Takahashi traces, and leaf posterior variances, and records elapsed time only as
developer evidence.

## Consistency Audit

The change is internal, exact-Gaussian, and location-only. It does not export new
symbols, change formula grammar, change q4, or touch non-Gaussian/Laplace paths.
The bridge schema is a draft payload, not an R object field.

## GitHub Issue Maintenance

No GitHub issue was edited or commented on. The matching local issue-comment
draft is maintained from the drmTMB side so the maintainer can decide whether to
post it to `DRM.jl#291` or `drmTMB#555`.

## What Did Not Go Smoothly

The word "optimizer" is tempting here, but the implementation is deliberately a
diagnostic finite-difference LBFGS experiment. The test therefore asserts the
negative claim (`ai_reml_ready = false`) instead of pretending the experiment is
an AI-REML implementation.

## Team Learning

The useful HSquared transfer unit is now visible: exact Gaussian objective,
dense oracle, selected-inverse traces and diagonals, explicit status fields, and
claim-bounded optimizer evidence. The label can wait.

## Known Limitations

No same-estimand external package comparator has been added beyond the dense GLS
oracle. No public optimizer, R bridge field, interval extractor, q4 route, or
10k-scale claim is implemented.

## Next Actions

Add a true same-estimand external comparator if one is acceptable as a
dependency-free test fixture, then decide whether the finite-difference
optimizer experiment should evolve into an analytic-score or AI-update
implementation.
