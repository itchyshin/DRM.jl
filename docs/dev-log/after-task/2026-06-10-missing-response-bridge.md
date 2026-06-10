# After-Task Report: Gaussian Response-Missing Bridge Slice

## Scope

This slice adds response-missing support to the DRM.jl side of the R bridge for
Gaussian models. It covers:

- univariate fixed-effect Gaussian location-scale models;
- residual bivariate Gaussian models with `mu1`, `mu2`, `sigma1`, `sigma2`, and
  `rho12`;
- the primitive `drm_bridge()` boundary used by `drmTMB(engine = "julia")`.

Predictor-missing routes remain outside this slice. They need model construction
and `mi()`/imputation plumbing rather than only an observed-response likelihood.

## Implementation

`_design()` now separates the real response from the formula-building response.
When the response column contains `missing` or `NaN`, StatsModels receives a
numeric placeholder column for schema/model-matrix construction, while the
returned response vector keeps `NaN` at missing cells.

For univariate Gaussian fixed-effect fits, missing response rows are omitted
from the likelihood and coefficient estimation. The returned `DrmFit` keeps
full-length fitted values, scales, and residuals; residuals at missing response
rows are `NaN`, and `nobs(fit)` counts only observed response rows.

For residual bivariate Gaussian fits, the likelihood now uses the observed-cell
factorization:

- rows with both responses observed use the bivariate normal density;
- rows with only `y1` observed use the `y1` marginal normal density;
- rows with only `y2` observed use the `y2` marginal normal density;
- rows with neither response observed contribute nothing.

At least one complete two-response row is required to identify `rho12`.

The bivariate q=4 phylogenetic location-scale engine now rejects missing
response cells early with a specific `ArgumentError`. That engine needs a
separate sparse-kernel mask slice because the latent augmented-tree likelihood
currently assumes a complete two-response vector.

## Verification

Commands run:

```sh
julia --project=. test/test_missing_response.jl
julia --project=. test/test_gaussian_bivariate_phylo.jl
julia --project=. test/test_bridge.jl
julia --project=. test/test_gaussian_core.jl
julia --project=. test/test_gaussian_bivariate.jl
```

All focused tests passed.

A live R bridge smoke from `/tmp/drmtmb-julia-engine-pr` used
`DRM_JL_PATH=/Users/z3437171/Dropbox/Github Local/DRM.jl` after installing
`JuliaCall`. It matched native TMB log-likelihoods to `4.831691e-13`
(univariate Gaussian) and `2.915925e-10` (residual bivariate Gaussian), with
full-length fitted output and `NaN` residuals at missing response cells.

## Remaining Work

The next missing-data slices are:

1. q=4 phylogenetic location-scale observed-cell masks inside the sparse latent
   kernel;
2. univariate structured/random-effect Gaussian response-missing likelihoods;
3. predictor-missing `mi()` support through the R bridge, once the Julia side has
   matching predictor-model machinery.
