# After-task: R bridge + sparse L-BFGS companion packaging

Date: 2026-06-09

## Summary

Packaged the DRM.jl companion slice for the drmTMB `engine = "julia"` bridge.
The branch exposes `drm_bridge()` and `drm_bridge_inference()`, wires the bridge
into the module, makes the Gaussian phylogenetic mean `:auto` route use the
all-node sparse L-BFGS fitter, and attaches the stored sparse-gradient path used
by profile/bootstrap inference.

This is a stacked branch on top of `claude/julia-package-register-ready-SuLOC`
because that branch already has open PR #239. The companion PR should be
reviewed as a bridge/inference slice and can be retargeted to `main` after #239
lands.

## Implemented

- `src/bridge.jl` provides the JuliaCall-friendly boundary for R: formula
  strings or keyed dictionaries in, flat dictionaries of primitive values out.
- `drm_bridge()` covers Gaussian one-response, Gaussian two-response, and the
  first Gaussian phylogenetic mean cell needed by the drmTMB article.
- `drm_bridge_inference()` provides the narrow profile/bootstrap primitive for
  the Gaussian phylogenetic SD target.
- Repeated Newick strings are cached at the bridge boundary to reduce repeated
  JuliaCall overhead.
- The sparse L-BFGS phylogenetic mean route stores an exact full-gradient
  callback so profile intervals can use the stored-gradient route.
- `docs/src/r-julia-bridge.md` now states that the bridge is an experimental
  first slice, not merely a planned design.

## Checks

Focused tests passed with BLAS/OpenMP pinned and Julia threads enabled:

```sh
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 /Users/z3437171/.juliaup/bin/julia --project=. --threads=4 test/test_bridge.jl
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 /Users/z3437171/.juliaup/bin/julia --project=. --threads=4 test/test_conjugate_em.jl
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 /Users/z3437171/.juliaup/bin/julia --project=. --threads=4 test/test_profile_ci.jl
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 /Users/z3437171/.juliaup/bin/julia --project=. --threads=4 test/test_bootstrap.jl
```

Results:

```text
test/test_bridge.jl:       46/46 pass
test/test_conjugate_em.jl: 34/34 pass
test/test_profile_ci.jl:   56/56 pass
test/test_bootstrap.jl:    46/46 pass
```

After the first manual GitHub `CI` dispatch on the stacked branch, both Julia
test jobs failed before the bridge tests because the new early algorithm guard
also caught the pre-existing `algorithm = :sparse` two-structured
heteroscedastic path. The guard was narrowed to `:em` and `:sparse_lbfgs`, and
the dense heritability tests were pinned to `algorithm = :gls` because those
tests are correlation-scale delta/Wald anchors rather than sparse all-node
Brownian-scale anchors.

Additional local focused checks after that correction:

```sh
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 /Users/z3437171/.juliaup/bin/julia --project=. --threads=4 test/test_two_structured_gaussian_sparse.jl
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 /Users/z3437171/.juliaup/bin/julia --project=. --threads=4 test/test_heritability.jl
```

Results:

```text
test/test_two_structured_gaussian_sparse.jl: 46/46 pass
test/test_heritability.jl:                  34/34 pass
```

A local full `Pkg.test` was started after the correction and passed through the
previous failing sparse and heritability sections, but was interrupted in the
unrelated `test_locscale_profile.jl` tail after the first location-scale profile
test had already taken about 10.5 minutes. The rerun GitHub CI matrix should be
treated as the full-suite gate for this branch.

The docs build completed:

```sh
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 /Users/z3437171/.juliaup/bin/julia --project=docs docs/make.jl
```

Documenter/VitePress finished successfully. Known warnings remain: two
pre-existing `docs/src/tutorials/animal-models.md` examples attempt
`ranef(fit)[:id]`, `docs/src/index.md` has absolute local links that Documenter
warns about, and many public docstrings are not yet included in manual pages.
No bridge-page dead link stopped the VitePress build.

`git diff --check` passed.

## Scope Audit

The user-facing R contract remains narrow: the R bridge should expose the
current default Julia route for the admitted model cell, not an algorithm menu.
DRM.jl can keep richer native routes, but R parity requires separate tests
before broadening beyond Gaussian fixed-effect and the first Gaussian
phylogenetic mean bridge.

No drmTMB GPL source was copied into DRM.jl. The bridge code is fresh Julia
glue and uses generated model outputs/strings as the parity boundary.

## Known Limitations

The bridge primitive does not yet claim non-Gaussian parity, broader
phylogenetic formulas, multiple structured effects, `Ainv`/`K`/spatial
marshalling, persistent Julia fit handles, or general post-fit uncertainty.
The profile/bootstrap primitive is intentionally limited to the Gaussian
phylogenetic SD target.

The default sparse all-node phylogenetic Gaussian route reports the Brownian
phylogenetic SD scale and stores only partial covariance information in this
slice. Dense correlation-scale derived ratios such as the current
`heritability()` delta/Wald examples therefore remain pinned to
`algorithm = :gls`; sparse-route derived-ratio semantics should be a separate
design/test slice.

## Next

Open the companion DRM.jl PR against the registry-ready branch, link it to
issues #5 and #19, and cross-link it from the drmTMB PR #508. Once PR #239
lands, retarget the companion PR to `main` if GitHub does not do that cleanly
automatically.
