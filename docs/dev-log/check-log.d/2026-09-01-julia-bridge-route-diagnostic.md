# Route-aware Julia bridge diagnostic

| Check | Result | Evidence |
|---|---|---|
| New diagnostic contract | pass | standalone `julia --project --startup-file=no -e ...` checked an ordinary Gaussian bridge fit |
| Unavailable-route behavior | pass | synthetic `DrmFit` without a stored objective returned `status = "unavailable"`, a reason, and no fabricated gradient |
| Diff hygiene | pass | `git diff --check` |

The payload defines `max_abs_gradient_of_stored_negative_loglikelihood`, with a threshold of `1e-3`. It is a DRM.jl diagnostic, not a numeric substitute for TMB's raw optimizer gradient. Profile and bootstrap rows retain their independent status contracts.
