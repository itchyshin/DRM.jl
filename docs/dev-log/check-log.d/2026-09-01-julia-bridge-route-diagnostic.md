# Route-aware Julia bridge diagnostic

| Check | Result | Evidence |
|---|---|---|
| New diagnostic contract | pass | standalone `julia --project --startup-file=no -e ...` checked an ordinary Gaussian bridge fit |
| Unavailable-route behavior | pass | synthetic `DrmFit` without a stored objective returned `status = "unavailable"`, a reason, and no fabricated gradient |
| Diff hygiene | pass | `git diff --check` |

The payload defines `max_abs_gradient_of_stored_negative_loglikelihood`, with a threshold of `1e-3`. It is a DRM.jl diagnostic, not a numeric substitute for TMB's raw optimizer gradient. Profile and bootstrap rows retain their independent status contracts.
| Julia 1.12 focused contract | pass | same standalone available-route check on Julia 1.12.6 |
| Complete bridge file on Julia 1.12 | pass | `test/test_bridge.jl`: 128/128 existing bridge assertions, 11/11 diagnostic assertions, 4/4 Student regression assertions; 60.9 s |
