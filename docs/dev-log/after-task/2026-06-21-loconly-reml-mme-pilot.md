# Location-Only Gaussian Sparse-MME REML Pilot

## Goal

Implement the first narrow HSquared transfer slice in DRM.jl: a supplied-variance
restricted objective for an exact Gaussian sparse-precision cell, and a
selected-inverse trace diagnostic that can be checked against a dense oracle.

## Implemented

`src/location_only.jl` now has `_loconly_reml_components()` and
`_loconly_reml_nll()` for the location-only Gaussian phylogenetic mean model.
At supplied residual and phylogenetic standard deviations, the helper profiles
`beta`, evaluates the existing sparse Woodbury ML objective, and adds the
Patterson-Thompson penalty `0.5 logdet(X'V^{-1}X)` using the repo's existing
REML constant convention.

The same file also has `_loconly_takahashi_trace_diagnostic()`, which reports
`trace_mode = :takahashi_selinv` plus `Tr(Q_cond M^{-1})` and
`Tr(S M^{-1} S')` for the current supplied variances.

Added `_loconly_ai_information_diagnostic()`, a developer diagnostic that
reports the candidate Gaussian average-information quadratic, a finite-difference
observed Hessian of the same supplied-variance restricted objective, and their
relative difference. This is a diagnostic comparison, not a claim that the two
matrices are identical everywhere.

`test/test_location_only_reml_mme.jl` builds a small phylogenetic Gaussian
fixture, compares the sparse supplied-variance REML objective against a dense
`V = sigma^2 I + sigma_phy^2 C` oracle, compares the Takahashi traces against an
explicit dense inverse of `M`, checks the AI-vs-observed diagnostic, and adds
boundary fixtures for zero/weak phylogenetic signal, near-singular tree
precision, and degenerate fixed-effect information.

## Files Touched

- `src/location_only.jl`
- `test/runtests.jl`
- `test/test_location_only_reml_mme.jl`
- `docs/dev-log/check-log.d/2026-06-21-loconly-reml-mme-pilot.md`
- `docs/dev-log/after-task/2026-06-21-loconly-reml-mme-pilot.md`

## Checks Run

```sh
sed -n '1,260p' AGENTS.md
sed -n '1,140p' HANDOVER.md
sed -n '1,140p' ROADMAP.md
sed -n '1,220p' docs/dev-log/coordination-board.md
gh pr list --repo itchyshin/DRM.jl --state open --limit 20 --json number,title,headRefName,baseRefName,author,updatedAt,url
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia --project=. test/test_location_only_reml_mme.jl
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|AI-REML optimizer" src/location_only.jl test/test_location_only_reml_mme.jl docs/dev-log/check-log.d/2026-06-21-loconly-reml-mme-pilot.md docs/dev-log/after-task/2026-06-21-loconly-reml-mme-pilot.md
```

The focused test passed: 36/36 assertions in 5.2 seconds after the
AI-information and boundary fixture additions.
`git diff --check` passed. The claim-boundary scan found only expected guardrail
wording: "not a public estimator claim" and "not yet an AI-REML optimizer".

## Tests of the Tests

The dense oracle is independent of the sparse helper. It constructs the dense
leaf covariance, profiles `beta` by dense GLS, evaluates the dense ML objective,
adds the same `0.5 logdet(X'V^{-1}X)` restricted penalty, and checks the sparse
helper at 1e-8 tolerance. The trace checks compare `exact_traces()` and the new
diagnostic against `inv(Matrix(M))` on the tiny fixture. The AI-information test
does not assert an identity; it requires a finite symmetric candidate AI matrix,
a finite symmetric finite-difference observed Hessian, and relative disagreement
below 0.1 on the deterministic fixture.

## Consistency Audit

The change is internal and Gaussian-only. It does not export new symbols, change
formula grammar, change q4, or touch non-Gaussian/Laplace paths. The only open
GitHub PR during the lane check was `#296`, which is q4 ML diagnostics and does
not overlap this location-only Gaussian file.

## Known Residuals

This is not yet an AI-REML optimizer. The next slices are same-estimand
external comparator checks, selected-inverse diagonal/PEV diagnostics, a tiny
optimizer-selection experiment, validation-status rows, and any bridge payload
schema work that the maintainer decides to expose.

## Team Learning

The clean transfer point from HSquared is smaller than the label: exact Gaussian
MME algebra, dense-oracle parity, selected-inverse trace checks, and status
provenance. That is enough for a first Gaussian REML pilot and still says
nothing about q4 or non-Gaussian AI-REML.
