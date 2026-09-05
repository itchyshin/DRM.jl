# After-task: sparse Gaussian LSS ML profile gradient

## 1. Goal
Retain the exact sparse Gaussian location-scale-scale (LSS) ML score on the
fitted object so profile solves use the stored-gradient route rather than
finite differences. This is one bounded response to the retained profile-cost
diagnostic; programme gates G0–G8 remain open.

## 2. Implemented
The sparse phylogenetic Gaussian LSS fitter now attaches an ML-only `nllgrad!`
callback. Every callback evaluation requests a fresh factor and scratch arrays,
so concurrent profile arms cannot reuse the optimiser's mutable Cholesky
workspace. An invalid sparse evaluation writes `NaN` into the gradient rather
than a misleading zero gradient. REML continues deliberately without a stored
score and takes the existing finite-difference profile route.

## 3a. Decisions and Rejected Alternatives
Do not change the likelihood, estimator, optimisation tolerances, profile
acceptance rule, or public API. Do not attach the ML score to REML before an
exact REML score is implemented. Do not reuse `chol_ref` merely to reduce
allocation: correctness of concurrent profile arms is the contract. A finite
penalty plus zero gradient was rejected after Rose found it could look
stationary to L-BFGS.

## 4. Files Touched
`src/gaussian_sparse_lss.jl` retains the ML callback; `test/test_lss_sparse.jl`
adds the focused gradient, invalid-point, concurrent-callback and profile-route
checks. This receipt and its check-log row are the only documentation changes.

## 5. Checks Run
The pre-repair compact ML fit failed the assertion that `fit.nllgrad` existed.
After the change, a deterministic focused contract compared the stored score
with central differences, verified the stored profile marker, and verified the
REML finite-difference marker. With `JULIA_NUM_THREADS=2`, the isolated new
test block passed **15/15 in 12.3 seconds**; it included two concurrent callback
evaluations, invalid-point rejection, and a profile endpoint-status check.
`python3 tools/check_test_deps.py` passed (237 reachable files; 19 declared
imports).

## 6. Tests of the Tests
The original red assertion proves the callback was absent. The test calls the
callback at an infinite parameter vector, requires all-`NaN` gradient entries,
and sends that callback through `_profile_nuisance_result`, which must reject
the point. This test was added after Rose identified the false-stationary
failure mode. The stored score is also checked directly against central finite
differences and against serial results from two Julia tasks.

## 7a. Issue Ledger
This advances the retained profile-gradient work under the Julia–R parity
programme; it does not close a capability issue. No Ayumi issue, collaborator
message, release, registration, or worktree cleanup action was performed.

## 8. Consistency Audit
Rose reviewed the first implementation, requested the invalid-point repair,
and approved the repaired source and test boundary. The callback is ML-only,
uses private numerical workspace, and changes neither GPL/MIT boundaries nor
the R bridge contract. The focused test asserts endpoint honesty rather than
claiming that every compact profile arm converges.

## 9. What Did Not Go Smoothly
The fresh test environment needed local dependency instantiation before the
focused Julia check could run. The compact threaded profile can still report a
failed endpoint; that status is retained rather than converted into a finite
interval. The full package suite has not run: its measured expectation is
roughly 35–45 minutes and therefore needs the separate >30-minute validation
approval after this successful pre-run test.

## 10. Known Residuals
This does not establish profile-interval recovery, bootstrap reliability,
native-R/bridge profile parity, modelled-missing predictors, weights transport,
or a warm-workflow speed win. The retained 64/128/256-tip finite-difference
profile diagnostic remains open; in particular, its 256-tip constrained solve
did not converge. Dense and multi-component LSS, all non-Gaussian families, and
REML stored gradients are out of scope.

## 11. Team Learning
For a finite-penalty objective, a stored-gradient callback must make an invalid
point unmistakably non-optimisable; a zero gradient can falsely certify a bad
profile nuisance solve. Parallel profile work may share immutable setup only.

## 12. Cross-Product Coverage
This slice does NOT cover REML stored gradients, penalty semantics outside this
callback, the R `engine = "julia"` bridge, missing-predictor providers,
aggregation or bootstrap transport. It does NOT cover profile-interval recovery,
native-R parity, warm performance or large-tree scale. No remote Totoro/DRAC
compute was run. Documentation rendering, deployment, full-suite final-head
verification, safe worktree reconciliation, Mission Control and the Melissa
reconciliation all remain open.
