# Location-scale whitening: arithmetic and derivative diagnostics

## 1. Goal

Continue programme #563/S11 toward the original finite-profile and requested-SE
workflow. Diagnose current near-boundary failures without changing the model,
convergence thresholds, fixture or required outputs. Global G0–G8 remain open.

## 2. Implemented

Scratch diagnostics only: fixed precision components, fixed-point whitening,
moderate-model transformed derivatives, and a bounded transformed-mode prototype.
No additional production source/test edit in this slice. Previously pending
arithmetic repairs remain carried over, not accepted production changes.

## 3a. Decisions and Rejected Alternatives

Do not replace precision construction solely because its entries look more
accurate. Direct construction improved entries but worsened its action on all
four saved modes. Test whitening before forming ill-conditioned matrices instead.
Intended L/Q and frozen rounded P64 are distinct reference targets. A certificate
at an implicit transformed point cannot certify its rounded returned a64.

## 4. Files Touched

Diagnostic sources, snapshots, receipts and manifests under
docs/dev-log/evidence/julia-r-parity/locscale-profile-threads-20260831; this report,
its check-log row and LOOP/checkpoint.md. Scratch work lives under the matching
/private/tmp/drm-parity-20260830/profile-threads-s11 directories. No protected
Gaussian/tutorial edits, drmTMB source edits, or source override.

## 5. Checks Run

Precision-components181130Z: 6.642s, cap20, status0, source unchanged. Direct
precision relative entry errors improve to about2e-16–7e-16, but mode-action
errors increase at every saved endpoint; direct construction alone is rejected.
Covariance derivative entry rounding contributes up to8.06e-8 in contractions.
This does not establish that every observed outer residual is arithmetic error.

Fixed-point whitening181517Z:7.699s, cap30, status0, source unchanged. Intended
L/Q surrogate errors versus256-bit frozen-kernel reference are below6e-15;
original-coordinate errors reach1.705e-9. H condition numbers change from
1.2e6–7.6e6 to2.1–5.0. Frozen-P64 whitening and point round trips are recorded
separately. These are fixed-point arithmetic results, not mode/solver evidence.

Moderate transformed derivatives, artifact label182400Z:6.983s, cap60, status0.
Four Gamma/NB2 canonical/general-Q-and-loading cells, all seven parameters,
central differences at1e-4/1e-5/1e-6: maximum errors1.23e-7/1.06e-9/5.38e-9.
Original-coordinate objective agreement is within7.11e-15, gradient agreement
within5.37e-13. All base and perturbed inner solves satisfy the diagnostic's
strict mode checks and interior-clamp requirement. Dense inverse is used only
as a small-model reference; no sparse-performance claim follows. This is not
the independent high-precision near-boundary derivative gate.

Transformed solver182505Z:6.816s, cap60, status0, source unchanged. After at
most two inner solves per saved endpoint, all mapped Float certificates pass,
but independent intended-L/Q residuals at the actual returned a64 fail3/4:
1.757e-9,3.033e-9,4.473e-9 exceed respective bounds1.564e-9,1.646e-9,1.486e-9.
The fourth passes. All implicit BigL*z certificates pass; that does not certify
the actual returned point. This run did not record explicit Julia/BLAS thread
pinning and its script snapshot is post-run; it is not parallel evidence.

Fixed-state neighbor enumeration182759Z:3.334s, cap30, status0, pinned1/1threads.
Nine adjacent Float pairs per group, independent256-bit gradient, Q=I verified.
All four assembled candidates meet the full original-coordinate gradient bound:
3.368e-10,9.519e-10,1.43675e-9,4.230e-11. Largest coordinate change5.55e-17.
The lower-slope margin is narrow (bound1.48640e-9). Correctly rounding BigL*z
alone still fails two points. This demonstrates gradient-feasible nearby
representable points; no new solver, undamped-Hessian certificate at those
neighbor points or production neighbor-selection algorithm is established.

Mission Control localcommit98bde473 updates only the two curated status fields.
Served values match, foreign staging is preserved, and its exact lease is released.

## 6. Tests of the Tests

Source/input hashes and finite-point/clamp/undamped-Hessian checks are retained.
Moderate derivative checks reject a deliberately negated gradient and omitted
nonidentity-Q normalization. Frozen-kernel identity holds in256-bit arithmetic
to about1e-71; intended and frozen-P targets are explicitly separated.
Solver prototype acceptance must inspect both original-coordinate and independent
actual-returned-point certificates; a status0 diagnostic process is insufficient.

## 7a. Issue Ledger

Programme#563/S11 remains open. The unchanged original finite-profile gate was
last12pass4fail: two finite-endpoint failures and two threading-metadata failures.
No issue closed; no public statement, push, merge, release or deployment.

## 8. Consistency Audit

Rose independently derived every loading/mode/logdet term and found no missing
term in the proposed transformed gradient. General fixed Q enters the global
adjoint solve; local diagonal inverse blocks suffice for observation terms.
Smooth derivatives require predictors inside the applicable family clamp.
Gamma uses logshape and a30 clamp; the15 scale clamp is family-specific.

## 9. What Did Not Go Smoothly

The matrix diagnostic launch initially named a nonexistent working directory;
the tool failed before process creation. The solver diagnostic first expected
input.data instead of input.design and stopped before any solve. Root then found
diagnostic point-conversion defects: a double loading transformation in the
predictor check, a rounded supposedly implicit point, and an identically zero
round-trip expression. Correct these before interpreting any solver result.
Root initially suggested the generic15 psi clamp; source inspection corrected
that suggestion for Gamma, whose actual bound is30. No numerical limit changed.
The worker launched its corrected solver before adding requested thread pins
and pre-run snapshot. The original failed schema script snapshot is unavailable;
its failed log/status are retained. The corrected receipt embeds its full script,
and an explicitly named post-run snapshot is retained without claiming it was
captured before execution. Do not use this as a timing or thread-safety receipt.

## 10. Known Residuals

Independent boundary mode/objective and derivative validation, production
integration, valid default-SE fit and original finite profiles, coefficient
threading, bootstrap, full R/bridge parity, performance, documentation and recovery.

## 11. Team Learning

Builder route Terra/high; independent mathematical review Sol/high. Actual
agent-hours are not instrumented and are not inferred from token counters.
Separating representation, factorization, solver and returned-point errors
prevents a small arithmetic improvement being mistaken for an inference fix.
No Codex memory files used or edited. No remote compute in this slice.

## 12. Cross-Product Coverage

This work does NOT cover finite profile intervals, bootstrap coverage, direct/R
bridge parity completion, coefficient threading, performance wins, whole-site
documentation verification, safe worktree retirement or programme completion.
