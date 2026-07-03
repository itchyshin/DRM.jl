# Exact-Gaussian Diagnostics

!!! note "Status - developer evidence"
    This page tracks exact-Gaussian diagnostic lanes that are useful for
    source-code review and future parity work. It is not a public optimizer
    promotion, not an R bridge promotion, and not interval-coverage evidence.

## Current Row-Contract Donor

The location-only phylogenetic mean lane lives in `src/location_only.jl`. Its
current row contract is guarded by `test/test_location_only_reml_mme.jl` and the
validation artifacts under `docs/dev-log/validation-status/`.

| Route | Estimator status | Diagnostic rows | Boundary |
| --- | --- | --- | --- |
| `gaussian_loconly_phylo_reml` | Exact-Gaussian location-only REML diagnostics | comparator plan, external package/version probe, derivative finite-difference status, guarded line-search status, boundary grid, profile-axis sanity, variance-component point status | Internal developer evidence only: no q4 claim, no non-Gaussian claim, no R bridge promotion, no interval coverage claim, and `ai_reml_ready = false`. |

## Second Sparse Candidate

The two-structured Gaussian sparse route lives in `src/gaussian_structured.jl`
and is guarded by `test/test_two_structured_gaussian_sparse.jl`. It fits
Gaussian mean models with two structured random-effect terms by integrating the
augmented latent vector with sparse linear algebra.

```text
y = X beta + Z1 a1 + Z2 a2 + epsilon
a1 ~ N(0, sigma1^2 C1)
a2 ~ N(0, sigma2^2 C2)
epsilon ~ N(0, sigma^2 I)
```

The sparse path uses one sparse Cholesky of

```text
H = blockdiag(sigma1^-2 C1^-1, sigma2^-2 C2^-1) + Z'Z / sigma^2
```

and reads variance-component gradient terms from Takahashi selected-inverse
entries. This makes it a plausible candidate for later row-shaped diagnostics.
At this stage it remains a source-map candidate for the Gaussian ML route, not a
REML or AI-REML claim.

## Evidence Gates

| Artifact | What It Supports | What It Does Not Support |
| --- | --- | --- |
| `docs/dev-log/scout/2026-06-22-exact-gaussian-structured-source-map.md` | Source map from the current REML diagnostic donor to the two-structured Gaussian sparse candidate. | Any new estimator, bridge, coverage, q4, or non-Gaussian claim. |
| `test/test_two_structured_gaussian_sparse.jl` | Dense/sparse agreement, gradient sanity, recovery smoke, and public `algorithm = :sparse` routing for the two-structured Gaussian ML route. | REML/AI-REML status or interval calibration. |
| `test/test_location_only_reml_mme.jl` | Exact-Gaussian location-only REML diagnostic row contracts. | q4 Patterson-Thompson REML, non-Gaussian Laplace routes, or R bridge parity. |

## Claim Boundaries

- REML and AI-REML wording here is exact-Gaussian only.
- q4 Patterson-Thompson REML is not HSquared AI-REML.
- Non-Gaussian Laplace routes keep their own method names.
- R bridge support needs row-specific native R, direct DRM.jl, and R-via-Julia
  evidence before promotion.
- Profile-axis diagnostics are not interval coverage.
- No Ayumi-facing reply or draft is changed by these diagnostics.
