# Location-scale inner arithmetic: causal diagnosis, not closure

## 1. Goal

Continue approved programme#563/S11 toward valid requested standard errors,
finite profile intervals and coefficient threading without changing estimators,
fixtures or convergence criteria. The complete Julia/R parity programme stays
active; this is a numerical dependency, not a replacement goal.

## 2. Implemented

Added reviewed Float64 sparse specializations for the joint objective and
gradient, retaining product residuals and compensated sums. Generic AD/type
paths and unsupported-arithmetic fallbacks remain. Precision construction,
kernels, Hessian, mathematical objective and acceptance controls are unchanged.
The earlier precision-gradient repair remains pending too. Expanded the numerical
regression to fourteen checks and wired it into runtests. Source changes remain
CARRIED-OVER pending full inference closure, not landed production claims.

## 3a. Decisions and Rejected Alternatives

A failed cold solve is not proof of mathematical infeasibility. No production
warm mode exists in the fit receipt: warm[] is private to the fitting closure.
Use explicitly labelled failed/certified-neighbour/reference starting points.
Do not suppress the SE exception, loosen tolerance, turn failed intervals into
unbounded intervals, or substitute se=false for the required inference workflow.
Gradient-only compensation has mixed results and is not adopted as a repair.
Whitening is a reviewed but unselected alternative with integration obligations.

## 4. Files Touched

src/locscale_inner.jl; new test/test_locscale_compensated_gradient.jl; conditional ignored gate ledger;
LOOP/checkpoint.md; numerical evidence/check-log/report under docs/dev-log/.
Earlier src/locscale_grad.jl and test/runtests.jl changes remain carried.
No drmTMB source edit or protected Gaussian/tutorial path edit.

## 5. Checks Run

Final-helper neighbour module covgrad002:155/155,33.147s, unchanged source/test
hashes. Independent exact-theta reference172237Z:7.867s,128/256-bit and three
starts agree, largest objective difference3.31e-28. Original cold solve fails;
certified-neighbour/reference starts succeed at the same parameters.

New test baseline172849Z:1pass3fail0error,4.853s. It detects gradient error
7.65e-10 (limit1e-12), failed cold acceptance, and independently excessive residual.

Process-local compensated-gradient experiment173220Z:4.624s,44actual candidate
calls,0genericfallbacks, frozenP/source hashes unchanged. It improves near-mode
arithmetic to about1e-14 error and certifies the prior failed terminal iterate,
but zero start still fails and has residual7.19e-6. The integrity status0 does
not mean the proposed remedy succeeded. A fixed-direction objective check is
completed as 174337Z:4.054s, no outer fit. At the saved compensated cold
terminal point the full Newton step gives raw Float64 objective change
+1.97822e-10, but independent256-bit fixedP change -5.73358e-13. Its
independent gradient L2=2.74793e-10 meets the unchanged bound1.32258e-9.
Half/quarter steps also show sign reversal. The full step is outside the
existing local rounding-polish radius. This supports an objective-arithmetic
experiment without widening that radius or weakening certification. No new outer refit in these diagnostics.

Expanded numerical baseline174641Z:4pass6fail0error,5.664s. General loading/AD
neighbours both pass; original cold/gradient/residual failures and three objective
arithmetic/descent failures are retained. This is not a missing-symbol-only red.

Controlled fresh-process baseline/gradient/objective/both comparison:4.79/4.78/
4.53/4.53s, no fallbacks and unchanged source/P. Objective-only and combined
certify all four starts independently. Combined coldL2=8.69634e-10; accumulated
objective error below2.4e-15. Baseline falsely accepted the neighbor-start final
point (BigL2=1.38853e-9 >1.32258e-9), motivating an explicit refusal regression.

Production94f54c74: first13/13,10.406s; final14/14,6.098s after Rose requested a
primal generalQ/loading objective check. Precision references still28/28,4.601s.
Inner/neighbour module155/155,34.426s; serial/four-thread expected-status suites
completed with194/198 displayed checks,19.308/18.907s. Their totals admit
documented failed-profile statuses, not finite-interval evidence. Input hashes unchanged per run.

UNCHANGED finiteCI test175604Z remains12pass4fail0error,15.310s: lines52/78
finite endpoints and63/64 threading metadata. Strict wrapper rejects it. New
public default-SE fit/profile receipt175800Z,13.280s, confirms fit.converged=false.
Three endpoint nuisance solves are not stationary; lower-slope endpoint is not
converged and its cold inner solve fails. Exact parameters, gradients, precision
eigenvalues and endpoint statuses retained. No tolerance/fixture change.

Mission Control updated in local-only commite6d6e6a; only next_safe_action and
active_lane changed, served fields match, foreign staging unchanged, lease released.

## 6. Tests of the Tests

Independent128/256-bit objectives/modes and start-agreement have explicit gates;
input artifacts and helper source are SHA-verified. Baseline precedes the
process-local method override; latest-world invocation plus actual-call counts
proves the candidate ran. Generic fallbacks are counted. Independent residuals
are Euclidean, with the original tol*(1+norm(a)) bound. Source/P equality is
checked before and after. All support failures and negative outcomes are retained.

## 7a. Issue Ledger

Programme#563 and S11 stay open. Neither local acceptance ledger is closed.
Focused/neighbor/status receipts now pass, but the required original finite-CI
gate remains red and final-source integration checks remain required.
No issue closure, collaborator message, release or deployment.

## 8. Consistency Audit

Precision construction and gradient arithmetic are separate: fixedP64 versus
exact-parameter precision changes residuals by about1.458e-9 at this point.
Compensation cannot repair that precision. A valid Float64 fixedP point exists,
so the threshold is attainable here; failure of one rounded mode would not prove
unattainability. GeneralQ factorization costs depend on fill-in even where local
contractions are linear in n+nnzQ. No broad speed/correctness claim follows.

## 9. What Did Not Go Smoothly

Reference diagnostic first received denseQ where production requires sparseQ.
Root static review also corrected helper-loading world age, lifting terms only
after Float64 aggregation, missing explicit agreement gates, and cold/warm
sentinel comparisons. An idle child initially received send_message, which does
not restart it; followup_task resumed it. No duplicate numerical run was launched.
The objective-direction first attempt failed from another helper-import
world-age error before evaluating points. Root also found its intended override
was never installed, corrected both issues at top level and asserted four
actual candidate calls with zero fallbacks. The corrected retry is retained
alongside the failed script/log, not substituted for it.
A later diagnostic wrapper retained a stale scratch directory and stopped
before spawning Julia; root corrected the path and retained both attempts.
The compensated gradient did not solve the cold-start failure; its negative
result remains decisive evidence rather than being presented as a successful fix.

## 10. Known Residuals

Precision construction and near-boundary nuisance optimization; default-SE fit/convergence; original finite-CI obligation; profile
threading; bootstrap and R/bridge parity; performance and documentation/recovery.
The reviewed arithmetic change passes its focused checks but does not close
the original profile/inference obligation. New exact endpoint states are the
next diagnostic inputs; do not recycle old fitted points as current evidence.

## 11. Team Learning

Requested execution Terra/high; independent mathematical reviews Sol/high.
Actual active agent-hours are not instrumented. Use independent componentwise
error comparisons before adding numerical guards. Preserve exact inputs and
state labels; success of diagnostic instrumentation is not success of a solver.

Golden Set: retained exacttheta25084fd2, reference1001c0ac, four labelled starts,
and compensated intervention9e0f655a, alongside the original inference fixture.

Memory receipt: no Codex memory used or edited. All durable state is in the
repository and the existing approved programme checkpoint; no remote campaign.

Milestone efficiency checker returned1: its day-wide report includes repeated
compactions and guardian sessions exceeding25calls (latest listed43). This is
not a passing efficiency gate and is not billing evidence. The approved disk-
goaled programme uses its checkpoint-and-roll exception; preserve this checkpoint
for the next bounded continuation, not a wider new exploration in this context.

## 12. Cross-Product Coverage

This work does NOT cover full native-R/direct-Julia/bridge parity, valid
profile/bootstrap coverage, coefficient threading, a performance win, complete
Documenter publication, safe worktree retirement or programme completion.
