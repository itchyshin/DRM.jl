# S10 conditional prediction and selected-state checkpoint — #563

## 1. Goal
Restore a bounded conditional-prediction contract across the R bridge and native R, and diagnose the remaining fixed-effect stopping discrepancy without changing the frozen baseline.

## 2. Implemented
The R bridge retains existing Gaussian mean random-intercept BLUPs and validated first-seen group maps. Stored mu is conditional; newdata remains zeroRE. Typed numeric/logical labels survive transport. Native construction reads the saved pre-SE full parameter snapshot, preventing Hessian perturbations from leaking into stored random effects. Independent Gaussian stopping and conditional-state diagnostics, regression tests, and fail-closed receipt checks are retained. Julia src is untouched.

## 3a. Decisions and Rejected Alternatives
Preserve the selected snapshot through parList's explicit par argument; reject mutating re-pin and extra fitting. Do not convert numeric group columns to character because they may also be fixed predictors. Keep the original4e-6 native-fit tolerance. Tighter controls/restarts and se=FALSE are diagnostics, not substitute baselines. Exclude all unfinished zero-one-beta changes from the checkpoint. Python acceptance uses explicit failures, never removable asserts.

## 4. Files Touched
R: R/drmTMB.R, selected hunks of R/julia-bridge.R, man/predict.drmTMB_julia.Rd, tests/testthat/test-julia-conditional-prediction.R, test-selected-state-prediction.R and this report. Julia: tools/parity_stopping_diagnostic.R, parity_stopping_negative.R, parity_conditional_prediction.R, parity_conditional_native_state.R, check_conditional_receipt.py, test_conditional_receipt.py; stopping-diagnostic and conditional-prediction evidence directories; after-task/check-log.d/checkpoint and ignored acceptance leaves. Existing S5 red tests and R ZOB changes remain separate.

## 5. Checks Run
All four frozen native FE fits reproduce exactly; independent likelihood errors≤1.08e-12, gradient errors≤3.26e-14 and FD errors<1e-7. Two native state diagnostics1.803s confirm exact selected-snapshot/no-SE agreement without original-environment mutation. Eight native regression fits cover twoML random-intercept cases, FE control and aREML neighbour; pass after correction. Final3case live run19.423s:24/24dense adapter comparisons pass(max1.4433e-15),2/3independentfitcasespass; varying-scale newdata mu1.08595e-5>4e-6 remainsFAIL. MeasuredJulia1thread/BLAS1. Pure conditional+three neighbour suitespass; one opt-in live skip excluded. No remote compute.

## 6. Tests of the Tests
Native predictions failed before snapshot correction. Old bridge lacks4conditional outputs; old string serialization refuses numeric groups in2outputs. Deliberate+.01analytic gradients fail8checks. Receipt checker rejects6shifted conditional means and1missing row;8normal/optimized subprocess outcomes reject damaged/missing evidence without a success token. Rose independently reran those8outcomes. All failures retained.

## 7a. Issue Ledger
Programme https://github.com/itchyshin/DRM.jl/issues/563 remains open. Full G0–G8, fullS10 surface, original FE factor stopping failure and varying-scale independent-fit mismatch remain outstanding. No release or universal parity claim.

## 8. Consistency Audit
Rose/Sol-high approved the math, native snapshot fix and final typed-label adapter, verified bothRhashes and86Julia sourcehashes, and approved the corrected checker after independently testing it. Terra/high implemented the scoped R adapter; Luna/low audited native control/state routing and430reachable native file revisions. Foreign Claude AGENTS/archive lane is disjoint. Existing lease renewed for both isolated worktrees. Memory receipt: continued the already approved programme and on-disk ledgers; no Codex memory file was changed. Golden Set: not rerun for this code slice; no global memory-regression claim.

## 9. What Did Not Go Smoothly
Initial oracle used the fixed coefficient slot for a random SD; corrected to raw retained resd_g. Tight native controls returned singular convergence in3FEcases rather than solving the discrepancy. A late LSS regex broke puretests; replaced with exactmu/sigma admission. Oracle vector names caused metadata-only test failures. Rose caught numeric string formatting and removable Python assert checks; both repaired with retained negative evidence.

## 10. Known Residuals
Bridge REML/missing-response/slopes/structured/nonGaussian conditional routes remain unvalidated or refused. Native shared par extraction also affects missing-data and marginalized outputs beyond the regression set. Tight/restarted FE estimates are diagnostic, not certified optima. OriginalFE factor6.26097e-6>4e-6 and new varying-scale newdata1.08595e-5>4e-6 failures persist. Protected Julia sparse-conversion edit remains unapproved; no retry or workaround was attempted. No benchmark campaign, deployment or destructive cleanup.

## 11. Team Learning
Separate transport correctness, statistical estimation, and stored post-fit state. A default TMB parList call can combine optimizer fixed parameters with perturbed random parameters. Preserve the saved full state without mutation. Group labels are data types, not display strings. Evidence validators must remain active under optimized Python. Active agent-hours were not instrumented; no fabricated hour total.

## 12. Cross-Product Coverage
This checkpoint covers Gaussian FE stopping diagnostics, a narrow R-facing conditional adapter, native ML/REML Gaussian state regressions, and executable receipt validation. It does not cover the complete capability denominator, all user methods, missing-predictor engine, all performance wins, all-page documentation/deployment, Mission Control reconciliation or full worktree recovery. Full programme stays active.
