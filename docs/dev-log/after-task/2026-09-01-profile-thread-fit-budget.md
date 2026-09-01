## 1. Goal

Evaluate a narrow repair for DRM.jl#570: runner-sensitive failed profile endpoints caused by a nonconverged public location-scale point fit.

## 2. Implemented

The public location-scale frontend now passes a bounded 2,000-iteration budget to its existing fit routine, retaining its previous gradient tolerance and all convergence checks. The threaded-profile test now asserts that its point fit converged before treating finite profile limits as a requirement.

## 3a. Decisions and Rejected Alternatives

Do not accept failed or non-finite endpoints as passing profile intervals. Do not change profile root rules, endpoint status semantics, estimators, or tolerances. The hypothesis is limited to giving the same public fitter a bounded continuation budget.

## 4. Files Touched

src/locscale_frontend.jl; test/test_locscale_profile_threads.jl; this report; and the matching check-log.

## 5. Checks Run

The local focused invocation reached package loading but cannot run because the macOS Julia depot lacks `ForwardDiff`; it did not execute any test. CI is the execution gate. The pre-repair CI evidence is retained in DRM.jl#570: source `baef2b56` passed once and later failed on the same Julia 1.10 test with a nonconverged fit and two failed finite-endpoint assertions.

## 6. Tests of the Tests

The added `is_converged(fit)` assertion encodes the condition that the existing finite-endpoint assertions already require implicitly. The prior CI failure proves that condition can be false for the current fixture; a successful CI result after the budget change is required before this hypothesis is accepted.

## 7a. Issue Ledger

DRM.jl#570 tracks the defect. This slice does not close bootstrap, cross-engine profile parity, interval calibration, engine-control, or performance obligations.

## 8. Consistency Audit

Compared the successful and failing Julia 1.10 CI logs. Both use the same source commit and OpenBLAS package version; the failure occurs after the point fit, during the finite profile assertions. The change leaves the profile implementation untouched and improves only the public fit baseline it receives.

## 9. What Did Not Go Smoothly

The local test environment is incomplete (`ForwardDiff` is absent), so no local numerical result exists. The old Totoro directories discovered for a possible replay are not valid Git checkouts. No remote compute campaign was started.

## 10. Known Residuals

CI must establish whether the extra bounded iterations resolve the runner-sensitive failure. If it does not, issue #570 remains open and the next work must instrument the exact point-fit termination rather than weaken profile validation.

## 11. Team Learning

Finite profile endpoints require a converged point fit. A test should make that precondition explicit, and changing a bounded optimization budget is distinct from relaxing a convergence or interval criterion.

## 12. Cross-Product Coverage

This covers only the public Gaussian/Gamma LSS fit baseline used by one threaded profile regression. It does not establish point parity, profile or bootstrap calibration, all families, bridge behavior, parallel performance, or programme completion.
