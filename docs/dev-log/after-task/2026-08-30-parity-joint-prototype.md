# S9 prepared joint missing-predictor checkpoint — #563

## 1. Goal
Implement the first shared Gaussian-response missing-predictor likelihood layer,
with Gaussian and Bernoulli predictor prototypes and retained independent evidence.
The approved full Julia–R parity programme remains active.

## 2. Implemented
Added a prepared-array model, exact row likelihoods for all four response/predictor
missingness masks, fixed-parameter conditional moments, AD-based ML fitting,
guarded inverse-Hessian covariance and separate optimizer/uncertainty statuses.
Fitted objects snapshot caller data; summary arrays are copied. The new source is
included/exported and its focused tests are wired into test/runtests.jl.
Added a scoped developer reference and a runnable supplied-parameter example.

## 3a. Decisions and Rejected Alternatives
One prepared mathematical layer is designed to serve both future frontends,
if later admitted. No GPL source is
copied: native generated numbers and independent Gaussian integration/two-state
summation provide the reference. Predictor-only rows retain their density; rows
with neither variable observed contribute exactly zero. Conditional variance at
fixed parameters is not a native imputation SE or an MI draw. Generic inference
forwarding remains absent. No frozen native estimate or tolerance was replaced.

## 4. Files Touched
New engine src/joint_missing_predictor.jl; module src/DRM.jl; S9-only test include
in test/runtests.jl; test/test_joint_missing_predictor.jl and its native TOML fixture.
New tools: export_joint_predictor_reference.R, joint_reference_to_toml.py,
check_joint_predictor_reference.jl, check_joint_predictor_receipt.py,
test_joint_predictor_receipt.py, check_joint_predictor_fit.jl,
check_joint_predictor_fit_receipt.py and test_joint_predictor_fit_receipt.py.
Docs: reference/engine-internals.md; three joint-contract/R-surface evidence notes;
joint-prototype evidence directory; this report; check-log entry; LOOP checkpoint
and arc status. Exact retained paths/hashes are listed in the evidence manifest.
R source is unchanged in this slice. Existing S5 red test/include and R ZOB edits
are excluded from the checkpoint.

## 5. Checks Run
Focused suite: 63 assertions, including one nondegenerate optimizer smoke,
quadrature, both-family gradient/Hessian directions, masks, invalid inputs and
extreme arithmetic. Returned leaf gates were independently rerun.
Common-parameter native002: both160-row fixtures pass all320 row likelihoods,
640 conditional mean/variance values and both total native log-likelihoods.
Largest native total error1.4211e-12 (<1e-6); largest row error7.994e-15 (<1e-8).
Default-start fit002: both converged,10.391s combined; gradients6.739e-10 Gaussian
and2.351e-11 Bernoulli; H*V identity errors <=5.552e-16.
Independent Python likelihood checks pass at the fitted parameters. Rose also
verified finite-difference gradients (errors <=2.218e-10) and Hessian directions
(scaled errors <=6.715e-7, tolerance1e-5), without refitting.
Native fitted-parameter comparison: Gaussian2.755e-6 PASS, Bernoulli1.00151e-5
FAIL against4e-6. The failure is retained as an unmet gate.
Strict full Documenter source build:52 pages,123 examples,120.471s; no deployment.
Julia and BLAS each used one thread. No Totoro/DRAC compute or speed claim.

## 6. Tests of the Tests
The API test failed before the implementation existed. Numerical regressions
cover dominant binary mixture weights, Gaussian posterior cancellation and
intermediate overflow, nonfinite all-missing parameters, singular covariance,
caller mutation and reserved labels. Receipt checkers reject11 damaged
common-parameter receipts and13 damaged fit receipts, both normally and with
Python -O. Fit controls require the intended error, not an unrelated failure.
Native admission remains separate from receipt provenance and optimizer checks.

## 7a. Issue Ledger
https://github.com/itchyshin/DRM.jl/issues/563 remains open. All programme G0–G8
remain open. The24 native missing-predictor obligations are not closed by two
prepared prototypes; formula and bridge admission remain required for these too.

## 8. Consistency Audit
Terra/high implemented the prepared engine/tests and fit verifier; Sol/high
independently reviewed mathematical/numerical code and receipt integrity;
Luna/low checked the native imputed() surface and developer documentation.
A bounded Melissa reconciliation (Terra/high) verified that all24 obligations,
the Bernoulli failure and unmeasured programme gates remain visible; two
wording clarifications were applied. This is not the final G8 audit.
The coordinator owns wiring, independent fixtures, live checks and retention.
Of86 original Julia source files at f47789646f27221ba4fad29a8ba1b3b8a790b521,
85 remain byte-identical; only the module wiring changed, plus one new source.
Memory receipt: existing programme checkpoint, routed project constraints and
symbolic-alignment discipline shaped the work; no Codex memory files changed.
Golden Set: not run for this bounded code slice; no memory-regression claim.

## 9. What Did Not Go Smoothly
Rose found cancellation in dominant binary mixture likelihoods and Gaussian
posterior means, unsafe intermediate products, weak noiseless fit tests and
mutable retained data. These were repaired before the final reference run.
The initial fit verifier incorrectly compared new fitted-theta rows to rows at
native theta. The coordinator caught this before acceptance; the final verifier
computes from data at the receipt theta. Further review made row outputs and
native provenance mandatory and isolated each negative-control failure reason.
An unqualified internal helper in the contract example was corrected.
Sandbox cache/registry failures and earlier numerical/test logs are retained.
Historical native001 used an earlier candidate; its hashes/log are diagnostic,
not final-source proof. Final native002 and fit002 bind the committed source.

## 10. Known Residuals
Bernoulli default-fit parity fails; investigate native stopping/controls without
replacing the frozen baseline. Gaussian native imputed SE meaning needs separate
verification. No formula marker, bridge admission, grouped predictor, additional
predictor family, multiple predictor, native interval/MI contract or REML is added.
Full Pkg.test(), cross-platform validation, final rendered-site review and complete
performance campaign have not run in this slice. Protected precision-source
edits remain denied and untouched; no workaround. Mission Control still reflects
the prior component checkpoint and needs the next scoped evidence refresh.

## 11. Team Learning
A two-state mixture needs stable summation of both full log weights; an accurate
log-odds expression alone does not preserve its likelihood normalizer. Check
posterior formulas where large terms cancel, using independent higher-precision
oracles. Separate common-parameter likelihood agreement, optimization quality,
native stopping agreement and uncertainty interpretation. Actual agent-hours
are not instrumented; run seconds are not agent-hours.

## 12. Cross-Product Coverage
Covers prepared fixed-effect Gaussian-response ML with one Gaussian/Bernoulli
predictor, all four masks, conditional moments and observed-information covariance
on two datasets. This does NOT cover the full24-cell native obligation list,
frontends, bridge/post-fit contracts, inference/parallel/performance gates,
worktree retirement or publication-quality rendering on every page. Source
build success is not evidence of deployed content. No release, registration,
collaborator message, destructive cleanup, push or merge occurred.
