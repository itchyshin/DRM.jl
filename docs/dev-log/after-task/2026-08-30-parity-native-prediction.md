# Native prediction repair checkpoint — #563

## 1. Goal
Repair native-R prediction defects exposed by the Julia–R parity checks, while
preserving likelihoods, estimators, original failures and the complete programme.

## 2. Implemented
Training prediction now uses finalized missing-predictor summaries, changing
only missing rows. Ordinal/categorical predictors use posterior-weighted state
design rows rather than a modal category or expected score substituted into
contrasts. Two Gaussian predictors retain their separate missing masks. Existing
offsets, random effects and observed rows are preserved.
Binary newdata follows fitted levels, including reversed/single-level batches,
numeric levels such as 1/2 or 2/3, and storage without retained model frames.
Ambiguous numeric aliases such as "01"/"1" require character/factor input.
The R Julia bridge shares this decoder and preserves training NAs until its
internal design preparation. Public help states the plug-in and uncertainty limits.

## 3a. Decisions and Rejected Alternatives
Do not compare predictions against another package function as the sole oracle.
Independent Gaussian/Bernoulli conditional calculations, state designs and a
two-Gaussian joint update provide the checks. A nonlinear inverse link evaluated
at a latent summary is not an integrated response mean. Updating a design does
not propagate its parameter dependence through covariance; no new interval claim.
The native two-predictor admission permits only two independent Gaussians, so no
unsupported finite-state interaction route was invented. No optimizer tolerance,
starting point, estimator or frozen comparator was changed.

## 4. Files Touched
R/methods.R; R/julia-joint-methods.R; two new focused test files and one existing
unknown-level error assertion; three independent R runners; two help pages;
R Julia-engine vignette. Julia repo: R-bridge prose, evidence, check-log, this
report and LOOP checkpoint. Full native fit RDS artifacts stay in the GPL R
repo; only generated numerical receipts/logs and original mathematical prose
are in MIT Julia. No Julia engine source changed. Unrelated ZOB and S5 work stays
unstaged. Mission Control changed exactly three semantic status fields.

## 5. Checks Run
40 native prediction assertions; 12 bridge binary-level assertions; 44 bridge
method, 39 preparation and 8 dispatch assertions pass. Help parses. The existing
fixed-effect-basis, prediction-grid and selected-state suites pass all 15 tests.
Retained two-case prediction replay agrees with independent conditional means.
Three fresh native neighbour fits (60 ordinal, 66 categorical, 160 two-Gaussian
rows) pass; final run 3.002 seconds, largest prediction error 8.882e-16. Both
finite-state fixtures have nondegenerate posterior probabilities.
Final matched public004 run takes 19.853 seconds including startup and both
engines, not a warm benchmark. Both adapters and the independent 320-row output
oracle pass. Large native training errors and Bernoulli newdata exceptions are
repaired. Strict native comparison still FAILS: Gaussian training difference
5.306703e-6; Bernoulli training 7.389749e-6, coefficients 1.001509e-5 and imputed
means 5.171868e-6 exceed the unchanged 4e-6 bound. No full native parity claim.

## 6. Tests of the Tests
Original retained-fit oracle fails the actual stale training/binary newdata
cases. New encoding tests fail on numeric 1/2 and ambiguous labels before repair.
Rose reproduced a storage fallback failure before its fix. Rose also found an
empty fitted-output false pass in the new neighbour checker; strict numeric,
finite, nonempty and exact vector shapes now reject all 10 malformed outputs.
Four damaged retained model states additionally fail, for 14 controls total.
One initial damage targeted a level map the decoder did not consume; that
failed control is retained and the corrected mutation targets both stored maps.
The existing public checker rejects all 20 damages normally and under Python -O.

## 7a. Issue Ledger
https://github.com/itchyshin/DRM.jl/issues/563 remains open. This closes only the
bounded prediction repair, not S10 or any complete programme gate. All G0–G8
remain open. The 24 frozen native missing-predictor obligations are unchanged.

## 8. Consistency Audit
Terra/high implemented native prediction and tests; root independently checked
math, added bridge decoder reuse, evidence and integration. Sol/high Rose found
and independently verified both storage/alias repairs and approved the bounded
implementation: methods SHA9d45acfcce726b68f85a4cb0983cff6a6ed2583236bfd9081270458367151a4b;
bridge methods SHA02e4f887bace7045ddf3f417366c9c22178c4d150e58119bf6c27015e0a2f5da.
Rose did not approve optimizer, covariance or programme parity. Golden Set: the
two frozen 160-row cases, three small native neighbours and existing prediction
suites. Mission Control local commit3cb0951 updates three fields; served JSON
verified. Durable choices are in this report and LOOP, not a Codex memory edit.
Bounded Melissa checkpoint reconciliation PASS: no material omission found;
all original obligations and red native gates remain explicit. This does not
close full programme G8.

## 9. What Did Not Go Smoothly
Frozen initial imputation matrices survived finalization, and raw factor encoding
was lost at newdata construction. Fixing ordinary factor input exposed a fallback
storage path and numeric aliases; tests now cover both. The first independent
neighbour checker omitted fitted-output dimensions, and one damage mutated an
unused metadata slot. Those checks were repaired and retested rather than treated
as evidence of success. Original failures and failed guard runs are retained.

## 10. Known Residuals
Independent finite-difference scores at native solutions are about 2.87e-4
Gaussian and 6.70e-4 Bernoulli. A diagnostic correction using Julia's raw inverse
Hessian approaches Julia's solution, supporting a stopping-resolution explanation.
This is not a refit, default-control fix or replacement baseline. Strict native
parity remains red. Neighbour fits do not validate weights, known covariance,
missing-response masks or random effects; focused existing/replay tests cover
only their stated cases. No new prediction-uncertainty or covariance proof.
No full R CMD check, Julia Pkg.test, rendered/deployed site or performance campaign.
Both denied Julia sparse-engine source files remain unchanged. No cleanup or release.

## 11. Team Learning
Preserve fitted encodings across data representations and storage controls.
For state-valued predictors, average designs rather than category labels.
Require exact output shape before a numerical maximum; empty arrays can produce
false success. Record the mathematical meaning of a diagnostic correction.
All work here was bounded on the Mac; no remote campaign submitted/running.
Totoro pilots remain capped at150sharedcores; DRAC requires allocations. Runs
above30minutes require measured pilots and approval. Agent-hours uninstrumented.

## 12. Cross-Product Coverage
This repair covers native fixed-design missing-predictor prediction and shared
R-bridge binary encoding at the tested scope. It does NOT cover complete native
capability parity, missing-predictor REML, arbitrary family/provider combinations,
profile/bootstrap, imputation uncertainty in prediction intervals, all registered
warm performance wins, whole-site visual/deployment verification or safe cleanup.
The original complete manifest, 24 obligations, LSS/SE/inference/10k/final-head
receipts, recovery proofs, automatic-policy calibration/evaluation split and
Rose/Melissa final programme gates remain required. Branches remain CARRIED-OVER;
no push, merge, publication, registration, collaborator message or release.
