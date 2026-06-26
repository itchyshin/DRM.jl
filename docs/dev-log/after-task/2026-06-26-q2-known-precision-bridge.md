# After Task: q2 Known-Precision Bridge Primitive

## 1. Goal

Add a narrow Julia-side target for the drmTMB relmat `Q` bridge lane without
pretending that formula, slope, q4, or public R-via-Julia support is done.

## 2. Implemented

`src/bridge.jl` now has a private diagnostic primitive,
`drm_bridge_q2_known_precision()`. It accepts `Y`, `X`, a 1-based `group` index,
and a user-supplied precision matrix `Q`. The primitive constructs the q2
coevolution problem through `make_coevo_problem_from_precision(Q, ...)`, fits
the existing exact-Gaussian ML q2 residual-correlation target, and returns the
same q2 point-export shape used by the q2 bridge contracts.

The payload records `input_scale = "precision"`, `precision_source = "Q"`, and
the supplied precision matrix on the returned dictionary. The claim boundary
states that `Q` is consumed as a precision matrix without implicit Q-to-K
conversion.

## 3a. Decisions and Rejected Alternatives

The primitive targets the complete-response q2 exact-Gaussian model

```text
Y_i = X_i beta + u_group(i) + epsilon_i
u ~ N(0, Lambda kron Q^-1)
epsilon_i ~ N(0, D)
```

where the caller supplies the level-level precision `Q`, `Lambda` is the 2 x 2
among-axis covariance for `mu1` and `mu2`, and `D` is the residual covariance
that carries `rho12`. The primitive does not invert `Q` to create a covariance
payload before construction.

I rejected adding public formula support for `Q` in this slice because the
drmTMB support-cell blocker includes structured slope cells, and DRM.jl does
not yet have a slope-capable relmat q-series route. A private precision
primitive is the smallest honest target for the R bridge preflight.

## 4. Files Touched

- `src/bridge.jl`
- `test/test_bridge_q2_direct_export.jl`
- `docs/dev-log/check-log.d/2026-06-26-q2-known-precision-bridge.md`
- `docs/dev-log/after-task/2026-06-26-q2-known-precision-bridge.md`

## 5. Checks Run

```sh
julia --project=. test/test_bridge_q2_direct_export.jl
julia --project=. test/test_bridge.jl
julia --project=. test/test_bridge_q4_direct_export.jl
git diff --check
```

The q2 direct-export test passed 141/141 assertions. The new q2
known-precision test contributes 16 assertions, including equality to a direct
`make_coevo_problem_from_precision()` fit and the `input_scale` /
`precision_source` payload fields. The bridge boundary test passed 51/51
assertions. The q4 direct-export regression passed 36/36 assertions.
`git diff --check` was clean.

## 6. Tests of the Tests

The new test compares the private bridge primitive against a direct precision
problem built with the same `Q`, rather than against the known-covariance helper.
It also checks malformed response shape and non-positive-definite precision
failures.

## 7a. Issue Ledger

No issue was edited. This branch is stacked on DRM.jl#298, which is itself
stacked on DRM.jl#297.

## 8. Consistency Audit

The new primitive is not exported and is not wired into the public formula
bridge. The claim boundary explicitly rejects formula support, structured slope
support, broad q2 bridge support, q2 REML, q4, AI-REML, interval reliability,
and coverage.

## 9. What Did Not Go Smoothly

Running JuliaFormatter on the touched files reformatted a large amount of
pre-existing bridge code. I restored the original file shape and kept only the
intended q2 precision insertion so the stacked PR remains reviewable.

## 10. Known Residuals

This is not broad R-via-Julia bridge support. It does not add formula syntax for
`Q`, structured slopes, q1 or q4 precision bridge cells, q2 REML, q4 REML,
AI-REML, interval reliability, interval coverage, non-Gaussian precision
support, or public optimizer controls.

The drmTMB relmat `Q` support cells should remain blocked for one-slope support
until DRM.jl has a slope-capable structured route or a separate exact slope
fixture primitive.

## 11. Team Learning

The drmTMB relmat `Q` lane has two separate blockers: exact precision transport
and structured slope support. This slice moves only the first blocker for a q2
direct fixture primitive. It should not be used as evidence for the one-slope
support cells until a slope-capable route exists.

Use this primitive as the Julia-side target for the drmTMB relmat `Q` bridge
preflight. The next R-side slice should keep one-slope support cells blocked
until DRM.jl has a slope-capable structured route or a separate exact slope
fixture primitive.
