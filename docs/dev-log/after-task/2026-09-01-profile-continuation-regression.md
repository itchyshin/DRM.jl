# After-task: bounded stored-profile continuation

## 1. Goal
Repair a final-head regression exposed by the Julia–R parity profile-gradient
slice: the crossed-Poisson profile-curve test rejected grid point 9 because a
stored-gradient nuisance solve reached a finite value but exhausted its bounded
iteration budget.

## 2. Implemented
When a stored-gradient nuisance attempt is finite but reports
not_converged, the profiler now continues once from that candidate with the
same stored-gradient L-BFGS method and the same 40-iteration bound. The retry
must itself converge; otherwise its rejected result is returned.

## 3a. Decisions and Rejected Alternatives
Do not accept a finite non-converged point, increase the global iteration cap,
or substitute a different optimisation method. A direct 80-iteration prototype
was rejected because it did not fix the exact test sequence reliably. The
continuation is bounded at two 40-step stored-gradient attempts and is limited
to a finite primary candidate.

## 4. Files Touched
src/inference.jl contains the bounded continuation. This receipt and its
check-log row retain the regression evidence. No public API, bridge, fixture,
or documentation page changed.

## 5. Checks Run
The final-head package run reproduced the error in test/test_profile_ci.jl:
the profile curve failed at crossed-Poisson grid index 9 with
lbfgs_stored, not_converged. An exact-sequence diagnostic showed the first
40-step solve was finite but rejected; a second 40-step solve from its reported
minimizer converged to 523.3617868341913. With compiled modules disabled,
test/test_profile_ci.jl passed 9/9 for the crossed-Poisson block (and all four
testsets), and test/test_profile_nuisance_status.jl passed 70/70.
python3 tools/check_test_deps.py and git diff --check pass.

## 6. Tests of the Tests
The unchanged public crossed-Poisson curve test was the RED reproduction.
The diagnostic distinguishes a finite value from accepted convergence, proving
why no finite-value shortcut is permitted. The existing 70-assertion nuisance
status suite verifies direct/non-finite, exception, fallback and failed-arm
status paths; it passes after the continuation.

## 7a. Issue Ledger
This is a regression repair required before the sparse-LSS profile-gradient
commit can be pushed under programme #563. It closes no programme capability
cell. No Ayumi response, release, registration, cleanup, or remote compute was
performed.

## 8. Consistency Audit
The retry uses the same objective, gradient, method, line-search bound and
acceptance rule. Its fallback metadata makes the continuation visible.
It cannot convert a non-finite or non-converged result into success. Rose review
and a full final-head suite rerun remain required before a completion claim.

## 9. What Did Not Go Smoothly
The initial full suite stopped at the profile curve after otherwise passing its
earlier blocks. A simple 80-iteration default appeared to work in an isolated
one-off but failed in the exact test sequence, so it was reverted rather than
committed. The failure depended on the curve's reference-objective evaluation
refreshing the fitted workspace.

## 10. Known Residuals
This does not establish general profile recovery, bootstrap parity, R bridge
transport, or performance. A second bounded solve can add work to a difficult
stored-gradient profile arm; no timing claim is made. Any retry that still does
not converge remains a failed endpoint or visualisation error under existing
contracts.

## 11. Team Learning
A reproducible profile failure needs the exact call order: evaluating a fitted
objective can change the numerical workspace even when fitted coefficients are
unchanged. Preserve the strict acceptance gate, then use a bounded continuation
only when its own convergence is checked.

## 12. Cross-Product Coverage
This slice does NOT cover REML gradients, finite-difference and Nelder-Mead
non-convergence, bridge engine=julia transport, missing predictors,
aggregation, bootstrap or scale. It does NOT cover native-R parity, large-tree
performance, rendered documentation, worktree cleanup, Mission Control, or
Melissa reconciliation.
