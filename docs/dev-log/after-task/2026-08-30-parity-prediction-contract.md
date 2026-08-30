# S10 prediction repair checkpoint — #563

## 1. Goal
Repair R-facing prediction scale/design behavior using existing Julia capabilities, while keeping full parity obligations open.

## 2. Implemented
Coefficient-based stored fixed-effect and newdata prediction; canonical per-dpar links; scale newdata support; no-intercept/factor/default formula handling; ordinary/structured and meta_V marker stripping; explicit unsupported conditional/offset/input refusals. R documentation and regression tests updated. Four-case native/bridge harness, separate same-coefficient oracle and deliberate fault control retained.

## 3a. Decisions and Rejected Alternatives
Rejected generic raw-response inversion: Julia payloads may be fixed-only, lognormal stores median, and rho uses a different guard. Reconstruct FE predictors; do not invent absent conditional modes. Retain factor mismatch and4e-6 threshold; no post-hoc optimizer/fixture substitution. Stage prediction-only code, excluding unfinished zero-one-beta admission/constructor changes.

## 4. Files Touched
R repository: prediction/helper section of R/julia-bridge.R; man/predict.drmTMB_julia.Rd; tests/testthat/test-julia-prediction-scales.R, test-julia-predict-newdata.R and three prediction expectations in test-julia-bridge.R; this after-task report. Julia repository: tools/parity_prediction.R; docs/dev-log/evidence/julia-r-parity/prediction-contract-pilot/ receipts, hashes, logs and report; after-task/check-log.d entries; LOOP/checkpoint.md; ignored S10 acceptance leaves. No Julia src edits. Existing ZOB and red S5 changes remain separately uncommitted.

## 5. Checks Run
Selected candidate:26 new prediction assertions,15 existing prediction assertions,122 bridge assertions; one live opt-in skip excluded. Separate cross-family pure suite passes with its live skips excluded. Native/Julia four-case run19.455s:32/32 same-coefficient oracle exact;3/4 independent-fit cases pass4e-6, factor case fails max6.260969e-6. Final loaded candidate hash9e7b2edad435d0fcd423866ef388426842002c67b40a288e5977fd05fc8d6ad1. Julia1.10/threads1/BLAS1 measured. Negative run19.366s rejects32/32 shifted outputs. R parse and source diff whitespace checks pass; no remote compute.

## 6. Tests of the Tests
Original live run fails wrong stored sigma/link (~1.1 difference) and newdata sigma refusal. Legacy fixture intentionally retains inconsistent stored slots to prove new predictions use coefficients. Missing/nonfinite inputs, incompatible coefficient designs, offsets and absent conditional modes tested. Deliberate+0.1 prediction fault fails every same-coefficient and independent-fit comparison; negative evidence gate passes32/32 rejection.

## 7a. Issue Ledger
Programme https://github.com/itchyshin/DRM.jl/issues/563 remains open. No fullS10/G2/G3 closure: factor stopping discrepancy, conditional payloads, full post-fit surface and protected engine edits remain outstanding.

## 8. Consistency Audit
Rose independently reviewed the selected code, retested26+15assertions, checked candidate hashes and corrected meta_V classification. All97reachable modifying commits yield3exact prediction-body variants; no existing solution found for these gaps. Memory receipt: continued the approved routed programme; lane preflight and all-ref checks confirmed ownership. Foreign Claude branch changes only AGENTS/handover archive, excluded. Golden Set: not rerun here; no global memory-regression claim.

## 9. What Did Not Go Smoothly
Initial runtime failed Julia depot-lock permission, then ran through approved local cache access. First fourth-case fixture used invalid positional meta_V(v); retained then corrected to meta_V(V=v). Three legacy tests encoded obsolete/inconsistent stored slots; retained failure and updated expectations without hiding fixture inconsistency. Luna's4variant count included surrounding text; exact extraction confirms3, recorded. Full fitted-model gate stays red despite correct adapter.

## 10. Known Residuals
ConditionalRE predictions refuse when modes absent; refusals are safer behavior, not completed parity. Quantiles, offsets, missing-row restoration and full family/provider/inference matrix remain open. Native rho prediction versus raw correlation accessors needs cross-surface validation. Rfactor6.26e-6 mismatch>4e-6 persists. No protected Julia engine edit, remote run, release, push or merge.

## 11. Team Learning
Distinguish distribution parameters from response means/medians and from conditional predictions. meta_V belongs to covariance metadata. Use native prediction at matched coefficients as an adapter oracle while retaining independently fitted baselines. Derived oracle success cannot close a failed fit-parity gate. Evidence is in repository reports; no Codex memory write.

## 12. Cross-Product Coverage
Covers R bridge fixed-effect prediction design/link handling with4liveGaussian cases, pure transformed-family/metadata tests and negative controls. This does NOT cover full direct-Julia/native-R parity, stored conditionalRE reconstruction, every family/provider, all user operations, benchmark wins, deployment or repository cleanup. Original programme G0–G8 remain open.
