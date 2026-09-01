# After-task report — route-aware Julia bridge diagnostic

## Scope
Implement DRM.jl #569's direct-Julia diagnostic contract for `drm_bridge()`.

## Changed
- Added a primitive `diagnostic` payload to ordinary `drm_bridge()` results.
- Reports availability, reason, gradient scale, threshold, maximum gradient, and convergence flag.
- Added regression tests for both an available Gaussian route and a deliberately objective-less unavailable route.

## Boundary
The payload does not claim numeric equality with TMB's raw optimizer gradient. It does not collapse profile or bootstrap status into point-fit convergence.

## Evidence
The targeted standalone contract check passes for both states. The complete bridge test file was started but exceeded the interactive observation window because it runs existing inference fixtures; the PR CI remains the full-suite gate.

## Follow-up
Add the R reconstruction and `check_drm()` display in the paired drmTMB control-surface slice, then validate it through the JuliaCall bridge.

## Rolling-runtime check
The focused contract also passed on locally installed Julia 1.12.6. This rules out a basic Julia 1.x compatibility failure in this change; it does not substitute for the full CI suite.
