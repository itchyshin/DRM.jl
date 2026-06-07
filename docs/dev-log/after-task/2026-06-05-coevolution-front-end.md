# After-task: coevolution front end

Issue: #187. Design anchor: #190. Accessor storage contract: #192.

## What changed

- Added a bivariate Gaussian structured-marker route: the same
  `phylo(1 | group)` marker must appear on `mu1`, `mu2`, `sigma1`, and
  `sigma2`.
- The no-marker bivariate path remains the residual-correlation model with
  `rho12`; no `rho12` behavior is changed.
- The structured branch builds the q=4 `AugProblem` and `Q_cond`, calls
  `fit_q4_sparse_tmb`, and packages the result as a `DrmFit`.
- `Σ_a` is stored as `fit.ranef.Sigma_a` with axes
  `(:mu1, :mu2, :sigma1, :sigma2)`. `ranef(fit)` still returns the effect
  dictionary for public BLUP access.
- The internal q=4 covariance coefficients live in a `:phylocov` block so
  `predict_parameters` ignores them.
- `check_drm()` now uses `fit.nllgrad` when present, matching the stored-gradient
  profile path and avoiding ForwardDiff through float-only sparse objectives.
- The bivariate tutorial and `drm` docstrings now document the public q=4 route
  without advertising #188 labelled coevolution accessors before they land.

## Verification

Focused q=4 front end:

```sh
julia --project=. -e 'using Test; include("test/test_gaussian_bivariate_phylo.jl")'
```

Result: q=4 front-end 13/13 and validation 4/4.

Residual-only no-regression:

```sh
julia --project=. -e 'using Test; include("test/test_gaussian_bivariate.jl")'
```

Result: 6/6.

Stored-gradient diagnostic path:

```sh
julia --project=. -e 'using Test; include("test/test_check_drm.jl")'
```

Result: 14/14.

Engine gradient gate:

```sh
julia --project=. -e 'using Test; include("test/test_qgate_fd_gradient.jl")'
```

Result: FD-vs-exact gradient gate passed at `≤ 1e-6`.

q4 baseline no-regression:

```sh
julia --project=bench bench/run_sparse_tmb_nd.jl
```

Result: logLik Julia `-256.5177` vs drmTMB `-256.5200` (`|Δ| = 0.0023`);
converged; best wall `1.066s` vs drmTMB `2.48s`.

Full package suite:

```sh
julia --project=. -e 'using Pkg; Pkg.test()'
```

Result: passed. R parity skipped as designed unless `DRM_PARITY_TESTS=1`.

Docs:

```sh
julia --project=docs -e 'using Pkg; Pkg.develop(PackageSpec(path = pwd())); Pkg.instantiate()'
julia --project=docs docs/make.jl
```

Result: rendered and VitePress build completed. Existing warnings remain outside
this slice: `animal-models.md` ranef example keys, homepage absolute links,
undocumented internal docstrings, and npm audit warnings.

Hygiene:

```sh
git diff --check
```

Result: clean.

## Rose audit

- Claim-vs-evidence: the PR may claim the #187 public route is implemented and
  locally verified. It must not claim #188 labelled coevolution summaries or CIs.
- Scope honesty: q=4 support is `Gaussian()` bivariate phylogenetic
  location-scale only; all four location/scale markers are required; only
  `phylo(1 | group)` is accepted in this route.
- License boundary: no drmTMB GPL source was vendored; parity uses generated
  fixture outputs and local Julia checks.
