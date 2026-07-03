# Exact-Gaussian Structured Source Map

## Purpose

S019 maps the next exact-Gaussian sparse candidate for the R/Julia finish run.
It does not implement a new estimator, promote the R bridge, or relax the
Gaussian-only REML boundary.

## Source Map

| Row | Route | Source | Existing Evidence | Transfer Use | Boundary |
| --- | --- | --- | --- | --- | --- |
| `loconly_gaussian_phylo_reml` | location-only phylogenetic mean REML diagnostic | `src/location_only.jl` | `test/test_location_only_reml_mme.jl`; validation TSVs under `docs/dev-log/validation-status/` | Current row-contract donor for schema, status, comparator, derivative, profile, and variance-component diagnostics. | Exact-Gaussian location-only REML diagnostics only; no R bridge, q4, non-Gaussian, interval-coverage, or public AI-REML readiness claim. |
| `two_structured_gaussian_sparse` | Gaussian mean with two structured random effects | `src/gaussian_structured.jl` | `test/test_two_structured_gaussian_sparse.jl`; `docs/dev-log/check-log/2026-06-07-sparse-two-structured.md` | Candidate for later row-contract mirroring because it already uses a sparse augmented Gaussian route, Woodbury identities, and Takahashi selected inverse diagnostics. | ML/source-map candidate only in this slice; no REML/AI-REML label, no bridge promotion, and no interval or coverage claim. |

## Why This Is The Second Candidate

`test/test_two_structured_gaussian_sparse.jl` describes the model

```text
y = X beta + Z1 a1 + Z2 a2 + epsilon
a1 ~ N(0, sigma1^2 C1)
a2 ~ N(0, sigma2^2 C2)
epsilon ~ N(0, sigma^2 I)
```

The sparse path integrates the augmented latent vector with one sparse
Cholesky of

```text
H = blockdiag(sigma1^-2 C1^-1, sigma2^-2 C2^-1) + Z'Z / sigma^2
```

and obtains variance-component gradient terms from Takahashi selected inverse
entries. That makes it structurally close enough to receive row-shaped
diagnostics later, but this slice only records the source map.

## Exclusions

- q4 Patterson-Thompson REML is not relabelled as HSquared AI-REML.
- Non-Gaussian Laplace routes are not relabelled as REML/AI-REML.
- The R bridge remains unpromoted until row-specific native R, direct DRM.jl,
  and R-via-Julia parity evidence exists.
- No interval coverage claim is made.
- No Ayumi-facing reply or draft is changed.

## Next Gate

S020 should decide whether to add a Documenter developer note that mirrors this
map while preserving the same boundaries. A later implementation slice can then
define machine-readable row status for the two-structured Gaussian sparse route.
