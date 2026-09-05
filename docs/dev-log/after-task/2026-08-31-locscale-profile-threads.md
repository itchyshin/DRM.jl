# Current assessment: precision gradient improved; inference gate remains open

## 1. Goal

Resume programme#563/S11 without weakening the original finite-profile fixture;
read the three supplied location-scale papers for terminology and model scope.

## 2. Implemented

Pending numerical source change: direct log-Cholesky precision derivatives with
exact normalization G*(1,0,1), hardened against unnecessary intermediate overflow.
Independent four-terminal Gamma reference fixture and regression are written and
wired into test/runtests.jl. These source/test edits are CARRIED-OVER, not accepted
for integration: neighbouring profile tests still error before profiling.
Coefficient threading itself is not implemented.

Completed reading note: ../2026-08-31-location-scale-literature.md. Supplied local
PDF paths were absent; public primary versions were read instead. The note maps
residual-scale random effects and covariate-dependent group-effect variance,
log variance versus log SD, and the Gaussian scope of the R-squared literature.
Rose reviewed and two wording/conditioning corrections were applied.

## 3a. Decisions and Rejected Alternatives

Preserve the estimator, seed, formula, parameter layout, original convergence
criteria, requested standard errors, and original finite-CI test. No optimizer
budget increase, false unbounded-interval claim, or se=false test substitution.
A se=false diagnostic may isolate point fitting from covariance construction;
it cannot satisfy the requested-inference gate.

## 4. Files Touched

Pending: src/locscale_grad.jl, test/test_locscale_precision_derivatives.jl,
test/fixtures/locscale_precision/locscale_gamma_l21.toml, test/runtests.jl.
Durable reading, references, scripts, logs, review and source snapshots are under
docs/dev-log/. LOOP/checkpoint.md records current state. The original threading
test is unchanged/untracked/unwired. Protected Gaussian and tutorial paths were
not edited; drmTMB source remains unchanged.

## 5. Checks Run

Independent all-four directional expansion:51.816s, normal exit,128/256-bit,
two starts, Richardson halving and individual +/- objective checks retained.
Initial production regression:8pass4fail0error. Direct derivative green:24/24.
Rose's extreme-zero-c regression:24pass4fail before hardening; hardened green
28/28 in10.572s (sourcec0369528,test60d13d50, fixture8c117983).

Neighbour inner/marginal/gradient/fit module passed in34.945s at pre-hardening
source3025e2e2. It must be rerun at final source. Serial and four-thread profile
status suites each76pass1error in _ls_vcov,14.450s/14.112s. The unchanged original
finite-CI fixture on hardened source errors in the same SE path,11.906s,0pass1error.
Cache EPERM attempts were retained as support failures, never counted as passes.
No full suite, benchmark, remote campaign or performance win is claimed.

## 6. Tests of the Tests

Both numerical regressions failed before their respective patches. Independent
reference uses a separate whitened likelihood and controls for density, prior,
normalization and finite differences; deliberate missing/full-logdet damage is
rejected. The new finite-profile classifier accepts only the two named missing
thread metadata failures and rejects the original12pass4fail log, extra failures,
wrong totals and runtime errors. Current profile error is correctly rejected.

## 7a. Issue Ledger

Programme#563, S11, local covariance repair gates and globalG0-G8 remain open.
No issue was closed and no collaborator was messaged.

## 8. Consistency Audit

Independent gradient accuracy at four fixed states is not proof of successful
fitting or inference. The current SE exception predates this patch in an earlier
retained run; a changed outer terminal point may expose it again. No conclusion
about final fit validity follows without the bounded stencil diagnostic.
The papers describe Gaussian MELS models, not validation of Gamma log-shape.

## 9. What Did Not Go Smoothly

Retained oracle support/stencil/globalization failures and the corrected
expansion coordinate packing remain in the evidence. Rose caught intermediate
overflow despite a passing initial regression. The profile fixture now stops
earlier in Wald covariance construction; this is an open failure, not progress
on its finite-CI acceptance. Sandbox cache errors required narrowly approved
cache-writing checks. Initial Mission Control preflight used a repository name
instead of a directory; corrected full-path preflight ran before the lease.

## 10. Known Residuals

Diagnose base fit versus Hessian finite-difference probes. Repair inference only
under a reviewed contract; then rerun exact current-source neighbours and original
finite CIs. Threading, bootstrap, bridge/native parity, performance, documentation
publication and repository recovery still remain. No release/integration claim.

## 11. Team Learning

Requested builders/readers Terra/high, independent Rose review Sol/high through
explicit native briefs. Actual active agent-hours are not instrumented. The
literature's scale distinction is useful for public documentation, but does not
license importing equations into an unrelated non-Gaussian inference route.

Golden Set: unchanged Gamma fixture, four frozen nuisance states and the extreme
zero-c finite derivative case. Reference tolerances were not relaxed.

Memory receipt: no Codex memory files were used or edited. Evidence and reading
are retained in the repository; Mission Control has a separately leased local
status update and served-content verification.

## 12. Cross-Product Coverage

This work does NOT close native-R/direct-Julia/bridge parity, calibrated profile
or bootstrap inference, threading, all-workflow performance, documentation
publication, worktree cleanup or the programme. No public push/merge/release.

---

## Historical progress receipts (superseded status wording preserved)

> Current status: S11 threading implementation is not yet made. The original
> carried Gamma fixture failed numerical expectations before the code change.
> This report records the pilot and diagnosis, not a completed inference repair.
> Current advance: covariance-gradient construction shows large roundoff errors
> at all four retained endpoints; a direct analytic formula is promising.
> The independent high-precision reference now passes both pilot points.
> All-four-endpoint directional comparisons are the next required check.

## 1. Goal

Implement coefficient-level parallel profile intervals while preserving the
likelihood, estimator, per-coefficient optimizer state, sequential endpoint
chains and status meanings. This is part of approved Julia/R parity programme#563.

## 2. Implemented

No production or test changes. Ownership/history review found no pending
implementation in18divergent inference-file refs. The original test remains
unwired; its finite-bound expectations remain required.

## 3a. Decisions and Rejected Alternatives

Do not classify any nonzero test exit as the expected threading failure.
Do not treat failed endpoints as evidence of an unbounded interval. Preserve
seed/formula/data and fit/profile budgets and tolerances while diagnosing.

## 4. Files Touched

Child owns only the ignored threading gate ledger during diagnosis; the
inference/test files are unchanged. Root retains receipts under
`docs/dev-log/evidence/julia-r-parity/locscale-profile-threads-20260831/`.
Protected Gaussian and tutorial files remain untouched.

## 5. Checks Run

Original four-thread/BLAS1 pilot:12pass4fail0errors,13.5s test time and17.28s
wrapper time. Two failures concern missing threading metadata; two demand finite
profile bounds. The unchanged-fixture diagnostic exits0 in14.60s. The fit has
converged=false; both mean coefficients return failed lower/upper endpoints,
all with nuisance reason:not_converged and unbounded=false. All source/test
hashes match. A single exact four-target replay is authorized with60s cap to
classify the optimizer termination; its result is pending.

## 6. Tests of the Tests

The initial loose shell classifier incorrectly printed expected-red despite
four failures. The stronger classifier rejects the retained bad log without a
fit (status1/failures4). Initial runner bytes were overwritten before archival;
its original SHA and raw Julia log survive. This is explicitly weaker than
retaining the exact original runner, and that missing artifact is not hidden.

## 7a. Issue Ledger

Programme#563, S11 and all globalG0–G8 remain open. No issue closure or
collaborator message was sent. Threading, correct finite intervals and matched
native-R/direct-Julia/bridge evidence remain obligations.

## 8. Consistency Audit

The previous inner-arithmetic repairc7e5b823 passed its own registered regression
and independent oracles. This different Gamma fixture does not contradict those
bounded results; it prevents a general convergence or full inference claim.

## 9. What Did Not Go Smoothly

A supposed lightweight threading fixture already has a nonconverged baseline
fit. Its boundary-like Cholesky state is a lead, not a proven cause. The first
classifier was too permissive; no source implementation was accepted from it.

## 10. Known Residuals

Exact fit/nuisance nonconvergence mechanism, coefficient threading, finite-bound
regression, independent review, and matched timing remain incomplete. No full
suite, calibration or performance claim is made.

## 11. Team Learning

Requested child routingTerra/high through explicit fresh brief; actual runtime
model not independently extracted in this receipt. Preserve failure mechanisms
separately before optimizing. Active agent-hours are not instrumented. No new
remote jobs/allocations or Codex memory edits.

Golden Set: the unchanged Gamma fixture and all four retained constrained terminal states.

Memory receipt: no Codex memory files changed; durable receipts are retained in the repository.

## 12. Cross-Product Coverage

This bounded direct-Julia diagnostic does NOT cover native-R or bridge
parity, calibrated inference, global performance, worktree recoverability or
complete documentation.

### Corrected termination receipt

The first four-target replay recorded wrong top-level Optim fields; retained
results still show finite above-tolerance gradients and13–41iterations. The
corrected replay exits0 in13.88s and records allfour ls_failed=true with
NoXChange. None hit iteration/time/call limits. Exact state and four raw Optim
results are serialized (d8727b67ae76c66fcc76cdd9f672b1f2bed72c165bf47e526caf50f769998434).
Rose independently confirms the interpretation and recommends pointwise
covariance precision checks before optimizer changes. The diagnostic does not
show finite limits absent; the original numerical obligation stays open.

### Fixed-point and directional checks

The fixed-point check exits0 in8.04s. Repeated cold and copied-mode starts agree,
with certified inner residual about1.51e-10. The largest free gradient is L21,
about-3.58e-6. Pointwise two-by-two covariance identities agree closely, but this
does not bound cancellation in the complete marginal gradient.

The directional check exits0 in6.19s; all28perturbed evaluations certify inner
mode success. Finite differences over steps1e-2through1e-8 have no stable agreement
window with the analytic derivative. The result is ambiguous; neither loosening
convergence nor declaring a specific gradient defect is justified. Rose is
reviewing an independent whitened likelihood oracle contract for the same saved
fixture, before any further evaluator or optimizer change.

Separate documentation source commit2f16c544 repairs the general anchor heading
P2 after fresh build/render and actual browser checks. MissionControl6140368
is locally committed and its served fields match; the exact status lease was
released. No numerical source edit, deployment or remote job occurred.

### Four-endpoint covariance arithmetic diagnosis

The retained `covariance-arithmetic-review.md`, scripts, logs and JSON receipts
separate downstream arithmetic error from true-gradient validation. First check
6.53s; direct-derivative comparison4.94s. Both normal exit, no outer fits,
production sources unchanged. L21 discrepancies from lifting fixed Float64
intermediates range3.9e-6 to7.8e-4. Direct analytic precision derivatives reduce
Float64-vs256-bit recombination discrepancies to about1e-8 on these cases.
Rose confirms the contraction algebra and limits: upstream mode/inverse errors
remain, and this alone is not independent marginal-gradient validation.

The independent whitened reference now passes density, derivative, prior and
nonzero-B Laplace normalization controls (including deliberate missing/full
logdet damage), plus lower-terminal128/256-bit/two-start checks. Its moderate-L
interior control exposed nonPD Hessian during the undamped search, before final
mode acceptance. Keep that control; add independent dampedNewton/Armijo
globalization, preserving final undampedPD, residual gates,100iterations and
crossprecision comparison. No production solver/tolerance/fixture change.
Earlier support failures (missing imports, parse ambiguity, missing BigFloat
trigamma) and the failed numeric stencil are retained, not successful runs.

### Independent two-point reference accepted for bounded expansion

The retained163817Z run exits0 in7.73s. Both pilot points pass all controls,
zero/production-seed starts, undampedPD, residual and128/256-bit gates. Largest
objective precision difference4.46e-29; largest logdet mode-correction3.33e-30.
Rose independently reviewed snapshot405f28114a2d665cf40bc8c4ec46ec324422a00a141250849e35bead4dace73d
and authorizes bounded all-four-L21 directional comparisons. The accepted
iterations used backtracking but never needed damping: damping is not tested
by this pilot. The supplementary case-receipt JLS is DERIVED_FROM_LOG_STRING,
not an original in-run binary BigFloat artifact. The raw log is authoritative;
the upcoming expansion serializes numerical objects within the executed script.
No production-gradient accuracy or profile-repair claim follows yet.

### Wald discriminator: completed, failure mechanism remains open

One support attempt stopped before fitting because bare Gamma() was ambiguous;
its script/log/status remain retained. Corrected run171108Z exits0 in11.873s
under30s cap, input hashes unchanged; result25084fd208dbbe9f863331b19b70c2ed7f3407d2135095a8cc0e07dcda3647a3.
This is a diagnostic pass, NOT a successful model-fit or inference gate.
The se=false diagnostic fit returns converged=false. At the exact engine point
[0.6370343555,0.2441002825,1.4752130749,-1.6628786423,-0.0960812841,-9.1260347739],
the cold inner solve fails, objective reports its Inf failure sentinel, and
gradient is nonfinite. Seven of twelve +/-1e-5 probes are finite; H is nonfinite.

Do not equate this solver failure with a mathematically infinite marginal or
proof that no acceptable warm-start mode exists. Next inspect cold versus the
stored fit mode at the exact point (no outer refit), then repair returned-fit
and inference handling under the existing contract. Suppressing the covariance
exception alone would not satisfy convergence/finite-profile requirements.
