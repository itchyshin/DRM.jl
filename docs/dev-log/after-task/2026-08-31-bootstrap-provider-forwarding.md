# Bootstrap covariance providers across Julia and R

## 1. Goal

Advance S10/S11 by preserving `K`, `A`, `tree`, and `coords` through point fits,
marginal bootstrap simulation, refits, direct Julia bridge calls, and the real R
`engine = "julia"` route. Global programme G0-G8 remain open.

## 2. Implemented

Every Julia `bootstrap_ci`, `bootstrap_summary`, and `bootstrap_result` surface
now accepts `coords` alongside K/A/tree. Formula- and fit-based Gaussian and
generic routes preserve the provider through fitting, marginal simulation and
refits. Coordinate-spatial marginal draws reconstruct the fitted exponential
kernel from the fitted range with the same diagonal jitter as fitting.
`drm_bridge_inference` now forwards all four providers.

The R bridge retains the already-built structured payload, forwards its provider
through its generated fixed-effect inference helper, and passes it again to
both bootstrap branches. Point fitting and provider conversion are unchanged.

## 3a. Decisions and Rejected Alternatives

Do not replace raw coordinates with identity or a guessed fixed range, condition
on fitted random effects, silently drop a provider, alter seeds/convergence, or
claim mock routing as numerical evidence. Gaussian spatial from R still follows
its existing native-compatible conversion to K and a relmat formula.

## 4. Files Touched

Julia: `src/inference.jl`, `src/bridge.jl`, new focused test, runtests wiring,
this report, check-log, evidence, local unlazy ledger and LOOP checkpoint. R:
`R/julia-bridge.R`, focused structured-inference test and its separate report.

## 5. Checks Run

The pre-fix Julia test failed on unsupported `coords`. Final Julia provider test
passes 19/19 at four Julia threads with BLAS1 and includes a fitted-range
numerical simulation oracle, serial/threaded equality, plus actual direct
bridge bootstraps for coords, relmat K and animal A. Existing structured
bootstrap neighbours pass; retained warnings concern pre-existing boundary
Hessians, so no warning-free claim. R pure tests pass 48 expectations and the
focused adjacent suite passes; four older live-Julia cases remain explicit skips.

An actual source-loaded R Gaussian relmat fit, public profile, and public
bootstrap interval pass with B=2, 2/2 refits, BLAS1, and zero numerical
differences from direct `DRM.drm_bridge_inference` calls on the same payload and
seed. Source paths and exact logs/hashes are retained.

## 6. Tests of the Tests

The original Julia source produces a MethodError for `coords`. Review found a
second R defect after the first green mock: the generated fit received the
provider but both bootstrap calls dropped it. A strengthened source-plumbing
check failed one-of-two branches before repair and passes two-of-two afterward.
The numerical coordinate oracle would fail identity, fixed-range, or raw-log-
range reconstruction. Evidence integrity receives a deliberate-damage check.

## 7a. Issue Ledger

Programme issue #563 remains open. This closes no release or programme gate.

## 8. Consistency Audit

The Julia public bridge and R generated helper now expose the same provider set.
R spatial remains K after its pre-existing conversion, so no raw-coordinate R
claim is introduced. Direct Julia covers raw coords. Rose and Melissa receipts
are retained separately; their verdict applies only to this slice.

## 9. What Did Not Go Smoothly

The first focused green exposed the missing coordinate covariance reconstruction.
A test assertion initially omitted the `estimate` field, and a Julia keyword
splat was accidentally positional; both failed before final evidence. The first
actual R run stopped because `identical()` compared matrix attributes, although
all values matched exactly; the corrected oracle compares dimensions and every
unclassed value at tolerance zero. These are retained as test-development
failures, not production regressions.

## 10. Known Residuals

Only relmat profile/bootstrap have a live R numerical receipt here. Animal and
converted spatial are routing/mocks. B=2 is not coverage, and a same-engine
direct call is not native-R parity. Calibrated intervals, performance,
remaining families/providers, Gamma public scaling, missing predictors, original
LSS obligations, docs, recovery and all global programme gates remain open.

## 11. Team Learning

Provider plumbing has three distinct stages: initial fit, marginal simulation,
and every refit. A mock at the language boundary can prove only the first handoff;
the generated helper itself needs a guard, followed by one actual public call.
For coordinate spatial models, storing only the fit is insufficient unless the
fitted range can reconstruct the covariance used for new marginal draws.

## 12. Cross-Product Coverage

Direct Julia: Gaussian coords, relmat K and animal A fixed-effect bootstrap;
formula/fit result/summary/CI surfaces for coords. R: pure routing for relmat,
animal and converted Gaussian spatial; actual relmat profile/bootstrap. This
slice does NOT cover live R animal/spatial, non-Gaussian provider cross-product,
native-R parity, profile or bootstrap calibration, performance or full G0-G8.

## 13. Next Action and Routing

After bounded review and checkpoint, exercise actual R animal and converted
spatial and one non-Gaussian K route, then finish coherent Gamma public-scale
normalization. One coordinator; R builder Terra/high; Rose Sol/high; Melissa
Terra/high. No remote compute, publication, release or cleanup in this slice.
