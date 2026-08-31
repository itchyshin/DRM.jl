## 1. Goal

Prevent overlapping DRM inference calls from restoring BLAS threads too early,
under the approved Julia–R programme #563 (S11 and parallel-correctness work).

## 2. Implemented

Added a lock and active-scope count to the internal BLAS-pinning helper. The first
active caller saves and pins the global BLAS setting; only the final caller
restores it. The lock covers entry and exit, never model computation. Nested,
inactive and throwing calls retain their intended behavior. No estimator,
likelihood, public signature or coefficient scale changed.

## 3a. Decisions and Rejected Alternatives

Reproduced the defect before changing source. Rejected holding a lock throughout
the fit, which would serialize independent callers. Count scopes that begin with
BLAS already at one. Uncoordinated external BLAS changes remain outside this
helper's contract. No claim of numerical-result corruption or measured speedup.

## 4. Files Touched

- src/inference.jl: helper state and entry/exit management only.
- test/test_inference_blas_pinning.jl and test/runtests.jl: deterministic regression.
- docs/dev-log/evidence/julia-r-parity/blas-pinning-20260831/: raw red and repaired-source evidence.
- This report, matching check-log, and LOOP/checkpoint.md.

The pre-repair package-continuation evidence is recorded separately against its
own source manifest. Neither denied Gaussian source file was changed.

## 5. Checks Run

Original helper: Mac Julia 1.10.0, four Julia threads, 13 passes and one expected
failure in 8.89 seconds. The first task restored BLAS2 while the second was active.
Repaired helper: 17 assertions pass with one and four Julia threads using the
bound unlazy commands. Totoro Julia 1.10.10: five complete files, 181 testset
assertions and one final BLAS-restoration assertion, 58 seconds, exit 0. All 327
source/test hashes match and remain unchanged. Initial and final BLAS counts
were four with four Julia threads. The tests include public profiles, bootstrap,
LSS serial/threaded comparisons and the existing success-bookkeeping regression.

## 6. Tests of the Tests

The original helper failed the coordinated overlapping-task assertion, as
intended; the repaired helper passes without relaxing it. Channels establish the
order deterministically rather than relying on a race occurring by chance.
The test restores the original BLAS setting and releases/fetches tasks in finally.
The outer process timeout bounds unexpected hangs. Exact stage-1 test bytes are
retained and match the original receipt hash. Existing inference tests ran
unchanged. This is not a new general evidence-verifier claim.

## 7a. Issue Ledger

Programme #563 remains open. This resolves the reproduced helper defect locally;
it does not close global G4, G5 or G7. No release, PR publication, collaborator
message or issue closure was sent.

## 8. Consistency Audit

Kept the original 326-file baseline separate from the repaired 327-file source
copy. Earlier package checks are historical evidence, not a full-suite pass on
the repair. BLAS thread management is distinguished from numerical accuracy and
from measured warm-workflow performance. Source and test hashes are retained.

## 9. What Did Not Go Smoothly

The current helper silently lost the pin when the first overlapping call ended.
The first unlazy run exited one only because its manual review gate was pending;
both executable checks passed. Final re-verification initially refused execution
because the continuation changed PATH; the refusal was retained and the same
reviewed commands were re-approved for the new environment. Boundary-Hessian and untrustworthy-SE warnings in
the fit regressions are retained, not suppressed or relabeled as calibrated CIs.

## 10. Known Residuals

Uncoordinated external BLAS mutations remain outside scope. The specialized
location-only profiler has a separate unmeasured pinning gap. Full package
verification, native-R/direct/bridge parity, Ayumi's large-tree profile/bootstrap,
interval calibration, automatic thread policy and every registered warm-workflow
win remain open. Two known LSS boundary assertions remain unresolved. No source
repair was attempted in the two previously denied Gaussian files. Mission Control
refresh is queued: a live Claude lease covers the shared dashboard directory.
The proposed status delta is retained without modifying the leased file.

## 11. Team Learning

Memory receipt: existing programme authority, ownership and compute rules were
used; no Codex memory was changed. Golden Set: deterministic overlap is the
negative control; existing public inference regressions protect neighboring
behavior. Builder Terra/high, independent Rose Sol/high, root Sol/medium.
Active agent-hours are not instrumented. Totoro used 58 wall seconds for this
repair; Mac checks were bounded and no-fit. External queue waits were not needed.

## 12. Cross-Product Coverage

This slice covers the internal helper used by generic profile/bootstrap calls,
its overlap/nesting/error lifetimes, and the named focused regressions at four
Julia threads. It does NOT cover all engines, arbitrary external BLAS mutations,
all platforms, full-suite completion, native-R parity, calibrated coverage,
Ayumi's full tree, or performance wins. All programme G0–G8 gates remain open.
