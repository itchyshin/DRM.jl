# Next bounded repair: inner-mode stationarity

Confirmed by Rose and root on the retained source: exhausting the latent-mode
iteration budget can return ok=true solely because the Hessian factors.
A positive-definite Hessian does not establish a stationary latent mode.

Implementation contract for the next slice:

- Keep the current 200-iteration default and 1e-9 scaled-gradient tolerance.
- Require finite returned coordinates and gradient, the existing stationarity
  criterion, and successful undamped Hessian factorization before ok=true.
- Recheck the gradient after the last update: a point that genuinely converged
  on that update may succeed, while an exhausted nonstationary point must fail.
- Preserve tuple shape and the existing marginal objective/gradient failure
  propagation. Do not alter likelihoods, relax tolerances or increase budgets.
- Inspect the early-convergence branch for the same finite-value requirement.
- Test zero-budget stationary/nonstationary controls, default-budget exhaustion,
  convergence on the final update, and at least one actual response-family
  kernel. Run existing inner/marginal/gradient tests and profile-status gates
  against the repaired source before claiming this slice verified.

Ownership is not yet transferred; no source edit belongs to this investigation.
The two denied Gaussian source files remain untouched. This is not evidence that
inner-mode exhaustion caused the observed Gamma nuisance failures.
