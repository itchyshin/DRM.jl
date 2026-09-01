# Location-scale boundary references and private state

## 1. Goal

Continue approved programme#563/S11 toward the unchanged finite-profile workflow.
Certify the prospective whitening mathematics, then implement a consistent private
representation without mixing it with legacy precision-based consumers.

## 2. Implemented

Independent128/256-bit boundary mode and derivative references at all four saved
endpoints; fixed selected-output Hessian/residual certificates; a portable generated
fixture. Added and reviewed a private, unwired whitening helper with owned warm
seeds. Its focused suite now passes 252 checks; production fitting and inference
have not yet been routed through it.

## 3a. Decisions and Rejected Alternatives

Retain implicit a=B(theta)z as a private state for computations, with original-
coordinate acceptance. Do not round it into a64 and then reuse an uncertified point
in value/gradient/information. Typed warm states are only seeds at a new theta;
each evaluation must solve and certify again. Existing raw-P functions keep their
own contracts. No production neighbor-selection heuristic is selected.

Rose found a concrete shared-consumer risk: locscale_sigma uses the shared old
gradient with a raw-P value. Globally redirecting that gradient alone is invalid.
The new value/gradient/information route must be explicitly paired; unmigrated
sigma/correlation routes stay paired on their existing implementation.

## 4. Files Touched

Evidence under docs/dev-log/evidence/julia-r-parity/locscale-profile-threads-20260831;
this report, check-log and checkpoint. Private helper/test paths have a separate
exact lease. No protected Gaussian/tutorial changes or drmTMB source edit.

## 5. Checks Run

Each independent boundary run includes74reference evaluations:128/256bits,
base plus +/- perturbations at1e-4,half,quarter for all6engine coordinates.
Every evaluation checks zero/saved-start agreement, undamped positive definiteness,
strictGamma clamps and the original-coordinate Euclidean residual. Reference
mode tolerances are1e-25/1e-50. Candidate implicit points are independently checked
at256bits, rather than accepted from Float64 proxy alone.

Pilot lower-slope183728Z39.850s; lower-intercept183848Z38.317s;
upper-intercept183848Z40.566s; upper-slope183950Z35.665s. All status0 under60s
caps, with verified Julia/BLAS1/1 and unchanged source. Maximum Float gradient
error<4e-14, objective error<9e-15, crossprecision objective difference<5e-30,
Richardson-halving discrepancy<3e-16. All four independently verified references
pass; these are fixed outer points, not an optimizer/profile workflow.

Selected-output certificate183958Z3.494s, cap30, status0, runtime1/1: allfour
saved selecteda64 points satisfy intended-L/Q gradient bounds, strictGamma
clamps and undamped-Hessian PD. Crossprecision gradientnorm disagreement<1.9e-31.
The lower-slope margin remains narrow4.96e-11. Objective changes from original
rounded outputs are tiny negative values, about1e-28–6e-26. The original outputs
still fail3/4 certificates; selecting different points does not erase those failures.

Fresh legacy numerical baseline184655Z5.735s, cap30, status1:7pass2fail0error.
At lower slope the original value is the1e18failure sentinel and gradientNaN,
against finite independent reference values. It is a numerical red, not a
missing-symbol failure. All source hashes unchanged. Original finite-CI gate
remains12pass4fail from175604Z; no replacement of that requirement.

## 6. Tests of the Tests

First focused helper run185530Z:247pass1fail,13.146s. The failing dense-inverse
comparison exposed a lost structural zero for an unobserved group with c=0.
A bounded2.6s probe identified P+D dropping the stored off-diagonal zero.
The private helper now preserves required 2x2 symbolic slots without changing
Hessian values, checks their presence in the selected inverse, refuses
nonsymmetric Q and nonfinite transported seeds, and checks raw Hessian
finiteness before rebuilding its pattern. Legacy engine files remain unchanged.

Reviewed rerun190401Z:252/252pass,12.363s, cap60s, runtimeJulia/BLAS1/1,
helperSHA1baf3baf1ef4eea4ad4d539e0c2da4d616978a7ad94b4852694aee3ac8a3f0ec,
testSHA4226d2a690567a860cb2e50263f0022b8f78202d4499d1f3e98b81d7f97a82dc,
both unchanged across execution. Both red/green logs and source/test snapshots
are retained in whitened-state-runner/ with its own manifest. Local G0/G1 pass;
paired integration G2, original finite-profile G3 and final review G4 stay open.

SHA-bound data/helpers; independent Gamma likelihood and guarded BigFloat
trigamma; retained two-start traces; individual objective/numerator crossprecision
checks; Richardson stability and deliberately negated-gradient rejection.
Pilot preserves completed references; subsequent scripts also preserve the
attempted coordinate/step/sign before evaluation. No failures were overwritten.
Portable fixture90469e7c derives only from the independent completed references.

## 7a. Issue Ledger

Programme#563/S11 and globalG0–G8 remain open. A new local private-state ledger
preserves paired-consumer, final-source tests, original finite-profile and review
gates. No issue closure, publication, release, registration or collaborator message.

## 8. Consistency Audit

The transformed derivative includes loading, mode and determinant terms for all
six coordinates; generalQ enters the global adjoint, with local inverse blocks.
No BigFloat/dense inverse is proposed for production. State acceptance belongs
to current outer parameters and model context, not a reusable success flag.
An accepted rounded mode export still needs its own certificate. Public fit
currently returns no latent mode vector, so a private factored representation
can preserve the public API without introducing a new export contract.

## 9. What Did Not Go Smoothly

Root review removed a proposed BigFloat eigvals call (not supported by the loaded
stdlib implementation); the certificate records correctly labelled Cholesky
pivots instead. The first certificate runner omitted --project and failed before
numerics while importing SpecialFunctions. Its log/status/pre-run snapshot are
retained; the corrected runner uses the exact project. No model or threshold
change followed that support failure.
The sandboxed livePR read failed on network access; scoped read-only escalation
verified only two unrelated documentation PRs. The new helper paths have no
existing ref/worktree implementation according to file preflight.

## 10. Known Residuals

Complete paired fitting/profile/information wiring,
final-source focused/neighbour tests, original finite profiles and coefficient
threading. Bootstrap/Rbridge parity, performance, documentation and recovery
remain full-programme obligations. These reference tests do not close them.

## 11. Team Learning

Builder uses the existing Terra/high route; Rose uses the existing Sol/high
independent review route. Active agent-hours are not instrumented. Separate
point representation from estimator/API: avoiding an unnecessary rounded vector
can address numerical loss without weakening the acceptance criterion.
The later literature reading consulted the sigma-convention memory pointer;
no Codex memory files were edited. No remote compute in this slice.

User-supplied Leckie, Zhang/Hedeker and MIXREGLS papers are incorporated as a
research crosswalk, not new API scope or a validation substitute. Exact supplied
paths were missing; public full texts were read. The separate research note
records log-variance/log-SD transformations, conditional/marginal summaries,
R-squared scope, estimator differences and the MIXREGLS p-value erratum.

## 12. Cross-Product Coverage

This work does NOT cover a passing production profile workflow, bootstrap
coverage, coefficient threading, full native-R/direct-Julia/bridge parity,
performance wins, whole-site verification, worktree retirement or programme closure.
