## 1. Goal

Require an actually stationary inner mode before reporting a successful non-Gaussian location-scale Laplace solve, within programme #563.

## 2. Implemented

Implementation is under review. The bounded contract preserves the current budget, tolerance, loadings and return tuple while checking final stationarity after the last update, including finite coordinates, gradient and norm arithmetic.

## 3a. Decisions and Rejected Alternatives

A successful Hessian factorization is insufficient to certify a mode. Keep the default 200 iterations and 1e-9 scaled-gradient criterion. A last-step update that reaches stationarity should succeed; exhaustion far from stationarity must fail. Do not change the estimator, likelihood or optimizer policy to make the checks pass.

## 4. Files Touched

Builder owns src/locscale_inner.jl, the new test/test_locscale_inner_status.jl, its runtests include and ignored Unlazy ledger. Root owns this report, evidence and checkpoint. Neither denied Gaussian file is touched. Four preflight refs were inspected; their foundational loading/damping/inverse work is already present, with no existing exhaustion fix to reuse.

## 5. Checks Run

Current source2ab0c168 passes33 focused controls but fails broader regressions. Three files completed: newstatus33, originalinner16 and originalmarginal6 assertions. In the next gradient file, four assertions pass and two fail (Gamma IID and NB2 phylogenetic); the fit file is not reached. Both one/four-thread profile batches error during the Gamma fit's covariance calculation with nonfinite Hessian entries (76 assertions pass before one error). All runs terminated and input hashes match. Local gates: G0met; G1–G3failed; G4unmet. This candidate is not ready to commit as a fix. The exact-fixture diagnostic completed in8.9s: three perturbed solves stall just above tolerance while finite and PD. Full undamped trials meet stationarity with2–3ULP represented objective increases. The strengthened gradient test retained the same two failures in29.46s; seven assertions passed in that file. Source/test hashes were unchanged. Rose approved implementation of a bounded4ULP Newton-polish exception; acceptance is still pending.

## 6. Tests of the Tests

Historical strictly convex controls return ok=true while gradients exceed the criterion; a stationary control remains valid. New tests include convergence on the final update, zero-budget stationary/nonstationary states, nonfinite state/gradient, a real Gamma success/refusal pair and four-dimensional finite-entry overflow. Preserve each failed draft and do not equate defect-reproduction exit0 with correctness.

## 7a. Issue Ledger

Parent programme #563 and all global gates remain open. This slice does not close native-R/direct-Julia/bridge numerical parity or calibrated inference.

## 8. Consistency Audit

The candidate also adds a narrowly guarded local Newton-polish exception, pending tests. Ordinary descent remains the default; the exception must reach the unchanged stationarity criterion with a finite, tiny full undamped step and positive-definite trial curvature. This is not a claim of exact objective monotonicity.  Existing marginal likelihood and gradient functions already consume the ok flag; rejected inner states must continue through their existing failure paths. This code-level defect has not been shown to cause the previously observed Gamma profile failures.

## 9. What Did Not Go Smoothly

Early focused-test drafts had a definition failure and an over-strong assertion about the returned state after an invalid gradient; both are retained separately. The first candidate missed norm overflow despite finite entries. Independent review caught it before the broader runs. A first full-step diagnostic accidentally reused NB variables for Gamma; that Gamma section is invalid and retained alongside a corrected Gamma run. Base analytic gradients were finite; only the failed perturbed points return NaN. The enormous finite differences arise from the existing1e18 failure sentinel, not evidence of an analytic derivative formula error.

## 10. Known Residuals

The certificate received Rose approval, but three required regression gates failed. The existing gradient tests use NaN != 0 in preliminary assertions, so their printed passes alone do not prove finite analytic gradients. Local slice acceptance remains unmet. Valid profile endpoints, bootstrap calibration, threading, every-workflow performance, cleanup and documentation visual/deployment obligations remain open.

## 11. Team Learning

Root Sol/medium, builder Terra/high, Rose Sol/high; active agent-hours not instrumented. Golden Set: exact convex kernel controls plus existing response-family likelihood/gradient tests. Memory receipt: no Codex memory changed. No DRAC or Totoro campaign launched.

## 12. Cross-Product Coverage

This does NOT cover general optimizer convergence, full numerical inference parity, bootstrap/profile calibration, performance superiority, publication or programme completion.


### Continuing checkpoint: guarded polish and damping repair

Candidate608c24c8 restored the original nine gradient assertions and all30
independent perturbed-point certificates (150checks plus2runnerchecks). The
full module still failed the NB2 recovery test: exact outer gradient48.7476
versus required0.001 and mean-effectSD0.3 versus recovery target0.5. Eight
smoke assertions and four recovery assertions passed; two recovery checks
failed. Both profile batches still error in Gamma covariance construction.
No full inference acceptance follows from restored pointwise derivatives.

Rose found a new candidate regression: an unchanged trial stopped all damping
retries. A consistent anisotropic quadratic exposed it (49pass2fail); candidate
572f46bb preserves higher-damping directions (51pass focused). Rose approves
that source correction, while integrated acceptance remains open. The current
read-only diagnostic targets the exact failed fits and warm Hessian perturbations.
No broad test rerun or larger compute campaign has been launched on that source.


### Arithmetic checkpoint

Read-only128/256bit full-endpoint evaluation confirms that both exact rejected
steps decrease the mathematical joint objective, while Float64 term/predictor
arithmetic reverses the sign. BigFloat sums of rounded terms stay positive;
compensating only the outer sum is insufficient. Saved endpoints, scripts,
failed attempts, order/constant controls and hashes are retained. The next
stable-integral comparison is a prototype only; source572f46bb is still not
accepted. No production allowance/tolerance/budget change or source expansion.

Historical negative control of the independent30point verifier:138pass,
12expectedfail,9.18s, explicitly loading preserved2ab0 into an isolated process.
The source on disk was unchanged572f46bb; no production edits occurred.


### Stable comparison prototype

The smooth-identity prototype matches full high-precision NLL differences in
sign and magnitude and rejects opposite uphill steps. Quadratic/quartic controls
show the need for sufficient quadrature. BigFloat Hessian evaluation fails
explicitly because trigamma(BigFloat) is unsupported; this is retained, not
silently downgraded. Quadrature agreement is an error estimate, not a rigorous
bound. Rose agrees the approved programme requires finite numerical validation,
not a newly invented universal libm proof; a bounded estimated-error contract
is being prepared before any production comparison change.
