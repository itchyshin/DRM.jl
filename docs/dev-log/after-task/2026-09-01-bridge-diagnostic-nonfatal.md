# After-task: bridge diagnostic non-fatal fallback

## 1. Goal
Repair PR #573's Julia 1.10 CI failure: the new bridge diagnostic crashed a
valid q2 relmat/animal fit when its optional ForwardDiff gradient reached a
CHOLMOD Float64-only sparse factorization.

## 2. Implemented
`_bridge_diagnostic` now catches a non-interrupt error from optional gradient
evaluation and returns its documented unavailable state. It continues to report
the fit's own convergence state. A user interrupt is rethrown.

## 3a. Decisions and rejected alternatives
Do not fabricate a zero gradient, mark the fit non-converged, or remove the
diagnostic. The gradient is optional route metadata; a valid point fit must not
fail because an AD representation is unavailable.

## 4. Files touched
`src/bridge.jl`, this after-task receipt, and its check-log row.

## 5. Checks run
The completed GitHub Actions Julia 1.10 log identified the precise q2 error:
CHOLMOD rejected a `SparseMatrixCSC{ForwardDiff.Dual}` during
`_bridge_diagnostic`. On Julia 1.12, the complete focused
`test/test_bridge_q2_direct_export.jl` file passed 177/177 in about 38 seconds,
including the previously failing relmat/animal bridge block.

## 6. Tests of the tests
The CI job failed before this change in exactly the relmat/animal block. That
block calls `drm_bridge`, so it exercises the public flattening path that now
contains the fallback.

## 7a. Issue ledger
This repairs CI for the diagnostics addition in PR #573. It does not close
Ayumi's profile/bootstrap or bridge-control issue; no collaborator message,
release, registration, cleanup, or remote compute action occurred.

## 8. Consistency audit
The diagnostic remains route-aware and does not compare its scale with TMB's
optimizer gradient. No estimator, public fit value, GPL/MIT boundary, or R
bridge calling contract changed.

## 9. What did not go smoothly
The GitHub run was still active because its rolling matrix job had not finished,
so normal `gh run view --log` was unavailable. Fetching the completed job log
directly exposed the error.

## 10. Known residuals
The rolling CI and the updated CI run remain outstanding. This does not prove
that all stored objectives support AD gradients, nor does it supply
profile/bootstrap calibration or R-facing interval evidence.

## 11. Team learning
Post-fit diagnostics are observers. They must degrade to an explicit unavailable
status rather than alter the success of a valid fitting route.

## 12. Cross-product coverage
This covers q2 relmat/animal bridge flattening with an unavailable optional
gradient. It does not cover q4, LSS, sigma-phylo, profile/bootstrap, missing
predictors, R controls, performance, DRAC/Totoro, deployment, or reconciliation.
