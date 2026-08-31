> Current status: S11 threading implementation is not yet made. The original
> carried Gamma fixture failed numerical expectations before the code change.
> This report records the pilot and diagnosis, not a completed inference repair.

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
