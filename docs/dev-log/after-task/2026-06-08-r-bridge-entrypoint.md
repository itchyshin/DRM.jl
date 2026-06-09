# After-task: R bridge primitive entry point

## Scope

Implemented the DRM.jl-side primitive that the R `drmTMB(..., engine = "julia")`
glue can call through JuliaCall.

## Implemented

- Added `drm_bridge()` in `src/bridge.jl`.
- Exported and included the bridge from `src/DRM.jl`.
- Accepted formula specifications as semicolon-separated strings, vectors of
  strings, keyed dictionaries, or named tuples.
- Converted dictionary or named-tuple data into a named column table.
- Dispatched common family strings to existing DRM.jl family constructors.
- Flattened a fitted `DrmFit` to a plain dictionary containing coefficient
  names and values, covariance matrix, likelihood summaries, convergence state,
  fitted values, residuals, fitted scale, and residual correlations when
  present.

## Evidence

Focused bridge gate:

```sh
julia --project=. test/test_bridge.jl
```

Result: 25 passes, no failures.

The test compares `drm_bridge()` with native DRM.jl Gaussian location-scale and
bivariate Gaussian fits, checks keyed dictionary input, and checks a malformed
keyed formula error.

## Boundary

The primitive can dispatch several existing DRM.jl families, but the companion R
bridge in `drmTMB` currently admits only Gaussian one-response and two-response
fits. Non-Gaussian R admission waits on explicit coefficient-scale parity tests.

## Issue Maintenance

Open issue lookup found `itchyshin/DRM.jl#5` as the Phase 1.5 roadmap tracker and
`itchyshin/drmTMB#499` as the matching R-side bridge tracker. I attempted to post
local progress comments with the test evidence, but the installed GitHub
integration returned 403 `Resource not accessible by integration` for both
repositories. No issue comment was posted.

## What Did Not Go Smoothly

`Pkg.test(test_args = ["test_bridge.jl"])` still invoked the package's full
`runtests.jl`, because the test runner does not filter by `ARGS`. That run was
stopped and replaced with the direct bridge test-file command.

## Next

Add parity-harness round-trip mode through `drm_bridge()`, then decide and test
the non-Gaussian coefficient-scale policy before widening the R bridge.
