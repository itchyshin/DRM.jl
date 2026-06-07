# After-task: coevolution accessors

## Scope

First implementation slice for issue #188: turn the q=4 fitted group-level
covariance `Σ_a` into a labelled post-fit readout without changing the q=4 engine
or residual `rho12` path.

## Changes

- Added `coevolution(fit; level = 0.95, method = :wald)`.
- The readout returns:
  - raw `covariance` (`Σ_a`);
  - labelled axes `(:l1, :l2, :s1, :s2)`;
  - phylogenetic SDs `l1`, `l2`, `s1`, `s2`;
  - six group-level correlations `l1l2`, `s1s2`, `l1s2`, `l2s1`, `l1s1`, `l2s2`;
  - a labelled 4x4 correlation matrix;
  - table-style `rows`;
  - Wald intervals when the fit carries a finite full q4 `vcov`.
- Documented that the `s1`/`s2` axes are random effects on the log-sigma scale,
  and that these are group-level summaries, not residual `rho12`.
- Added targeted tests for the 4x4 layout, Wald intervals, missing-vcov behavior,
  and residual-only bivariate non-regression.

## Honesty / Caveats

- This lands point summaries plus Fisher-z/log-SD Wald intervals only.
- Profile and bootstrap CIs from the #188 design remain open follow-up work.
- `method = :none` is the point-summary path for q4 fits run with
  `q4_vcov = false`.

## Rose audit

- Claim-vs-evidence: public docs claim only point + Wald support.
- Scope honesty: no claim that profile/bootstrap CIs landed.
- Residual/group-level separation: `coevolution` throws on residual-only bivariate
  fits and explicitly directs users to `rho12`/`corpairs`.
- License boundary: no drmTMB source vendored; implementation uses only local
  `Σ_a` outputs.

## Evidence

Targeted local Julia test passed:

```sh
julia --project=. -e 'using DRM; include("test/test_coevolution.jl")'
```

Combined follow-up with the already-wired #15 gate also passed:

```sh
julia --project=. -e 'using DRM; include("test/test_coevolution.jl"); include("test/test_qgate_alloc_inner.jl")'
```

Docs build passed:

```sh
julia --project=docs -e 'using Pkg; Pkg.develop(PackageSpec(path=pwd())); Pkg.instantiate(); include("docs/make.jl")'
```

The docs build emitted pre-existing warnings from `docs/src/tutorials/animal-models.md`
(`ranef(fit)[:id]` examples) and absolute links on `docs/src/index.md`; it exited
successfully and did not report a new `coevolution` doc failure.
