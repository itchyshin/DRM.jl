# Two-Gaussian prepared kernel checkpoint — #563

## 1. Goal
Extend the shared Julia joint missing-predictor engine toward all native-R
capabilities, without replacing frozen comparisons or weakening their tolerance.
This implements the prepared dependency for two independent Gaussian predictors;
direct formula and R bridge admission remain required next.

## 2. Implemented
Added a prepared model/fit overload for an n-by-2 predictor matrix and two
possibly different complete predictor designs. It retains all response/predictor
masks, observed predictor densities, likelihood constants, exact marginal
Gaussian integration and full conditional 2-by-2 covariance. Missing response
rows retain observed predictor information. Imputed SEs include conditional
variance and full raw-parameter covariance contributions, with explicit status.
Inputs are copied before fitting. Public imputation requires a variable name.
Module and test runner include the new code; a runnable developer example was
added with the frontend limitation visible.

## 3a. Decisions and Rejected Alternatives
Rose found that the remaining earlier single-predictor native differences reflect
ordinary documented optimizer stopping; they do not establish a native bug.
Native defaults, original failing receipts and the4e-6 criterion remain intact.
The new kernel is a typed overload of the shared prepared operations, preserving
the existing one-predictor interface. Independent prior predictors are not
conditionally independent after observing y: their full covariance is retained.
Gaussian imputation SE is first-order prediction error, not exact parameter
integration, multiple-imputation draws or interval coverage.

## 4. Files Touched
Julia: new src/joint_missing_two_predictor.jl, module/test wiring, its focused
tests, four Python/Julia reference/fit checkers plus damaged-input tests,
generated numerical fixtures, one developer reference page, evidence, this
report/check-log and LOOP checkpoint. R: one native reference exporter and
its generated numerical/RDS evidence. RDS stays only in the GPL R repository;
Julia contains original math/code and generated numerical outputs, never GPL
implementation source. Denied sparse source files and unrelated S5/ZOB work
are untouched.

## 5. Checks Run
Frozen native default fit:160rows, all8masks,0.618seconds. Independent dense
joint-normal density/Schur oracle verifies3parameter points: NLLerror7.50e-12,
gradienterror1.23e-8, conditionalmean2.22e-16 and imputationSE5.11e-13.
Supervised targeted Julia tests plus existing one-predictor kernel/uncertainty
neighbours pass. The source review and runtime gate use kernelfec1668b.
Independent Julia default-start fit receipt passes fixed-point checks, dense
likelihood/gradient/Hessian checks, H*V identity, full conditional covariance,
fixed-native-V and fitted-V imputation summaries, status and snapshot checks.
Fittedgradient2.93e-9. All strict native 4e-6 comparisons for this two-Gaussian prepared fixture pass: theta1.127707e-6,
LL1.305e-10, mean1=3.443e-7,mean2=3.876e-7,SE1=2.155e-7,SE2=5.737e-8.
The Julia runner takes21.788seconds including compilation/evaluation/fit work;
this is NOT a matched warm-workflow benchmark or a speed comparison.
Edited developerpage source generation passes2examples in8.487seconds.

## 6. Tests of the Tests
Absent-API red is retained. Rose found representable large scales overflowing
when squared and posterior variance/mean lost through cancellation; stable
hypot/weighted formulas now pass those cases. Tests exercise differing predictor
design widths, actual parameter/full-covariance permutation, independent dense
conditional finite-difference Jacobians and missing uncertainty statuses.
Reference checker initially accepted unverified provenance/defaults and damaged
offdiagonals; these are now checked. Rose then found computedNaN hidden by max;
computed quantities now require finiteness. All25 reference damage controls and
17 fitted-receipt damages pass normally and underPython-O. No checks rely on
assert statements that disappear under optimized Python.

## 7a. Issue Ledger
https://github.com/itchyshin/DRM.jl/issues/563 remains open. No complete S9,
programmeG0-G8, native ledger row or public bridge capability is closed. All24
original missing-predictor obligations remain required. The approved plan is
docs/dev-log/plans/2026-08-30-julia-r-parity.md, not inherited LOOP/ultra-plan.md.

## 8. Consistency Audit
Terra/high built the kernel; Sol/high Rose independently reviewed math, source
and evidence. Root created native/dense oracles, fixed checkers, strengthened
Jacobian/permutation tests, wired the module and supervised final runtime gates.
Golden Set: frozen160row native reference with8masks and3parameter points,
independent fitted receipt, small edge cases and existing one-predictor tests.
Rose final bounded verdict is APPROVE, with exact hashes in evidence. It does
not cover the unfinished frontends, performance, recovery or whole-site renders.
Active agent-hours were not instrumented; no invented actual-hours figure is
reported. Machine timings above are measured local bounded checks only.

Bounded Melissa reconciliation (Terra/high, read-only) found no material
scope drop or programme-closure claim. This does not close programme G8.

## 9. What Did Not Go Smoothly
Two worker commands lost their observation handles after yielding. Root checked
actual processes with escalated ps: neither Julia process remained alive. Their
partial output is not counted as full success. Root took exclusive runtime
ownership and ran final bounded supervised commands. A cache-access failure was
resolved by scoped execution permission; no cache lock was removed. Checker
holes and kernel arithmetic defects were repaired before their success claims.

## 10. Known Residuals
Two-predictor direct formula and R bridge preparation/adapters remain unwired.
The current evidence is one identifiable fixed-Gaussian fixture, not full model
admission, recovery, interval coverage or every case/scale. Earlier single-
predictor default comparisons remain red and are preserved. Their current-source
full-bridge receipts need regeneration during final integration because this
module addition changes the source manifest. No fullPkg.test/R CMD check,
visual/deployed-site proof, cleanup or release was performed. No Totoro/DRAC
jobs are running; Mac short checks, Totoro<=150cores and DRAC allocations remain
the plan, with measured pilots plus approval above30minutes.

## 11. Team Learning
Use standard-deviation-scale arithmetic and independent conditional precision
identities to test extreme Gaussian cases. Validate computed quantities for
finiteness before aggregating maximum errors. A lost observation handle is not
proof of success; establish process state before restarting.

## 12. Cross-Product Coverage
The prepared Julia kernel is verified against generated native-R outputs.
This slice does NOT cover direct two-predictor formula admission, R bridge
transport, REML, structured effects, or mixed finite-state predictors; those
surfaces remain required under the approved programme.
Neither package has complete programme parity or performance evidence. Existing
single-predictor failures and all original obligations remain open.

## 13. Next Action and Handoff
Continue the same active goal from the isolated pair on codex/julia-r-parity.
Wire two bare distinct Gaussian mi terms through the direct frontend and R
prepared transport, preserving original formula column order, both covariance
axes, natural-SD coefficients, two variable summaries and refusal neighbours.
Then extend the registered fixture denominator and inference. All remaining
capability, LSS evidence, performance, recovery, documentation and Melissa
obligations in LOOP/checkpoint.md remain required. This is a local checkpoint,
not a handoff or programme completion claim.
