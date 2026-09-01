# Rose independent inner-mode review

Requested reviewer routing: Sol/high. Review owns evidence in this directory only; no production source or test edits.

The historical draft `dbe3e29555704d55e4b1f71673d6b34e23fb737f1da1b7cc137088a6dc894eff` falsely accepted finite nonstationary states when their computed norms overflowed. The extracted solver uses a four-dimensional quadratic with exact gradient and identity Hessian. At `a = fill(1e308, 4)`, each entry is finite but both norms and the scaled threshold are infinite, so the Float64 comparison accepts `Inf <= Inf`. Independent BigFloat evaluation gives scaled score 1, which fails the unchanged threshold 1e-9. Both the zero-iteration certificate and early-return branch reported `ok=true`. A stationary zero vector remains a valid positive control.

Run `python3 docs/dev-log/evidence/julia-r-parity/locscale-inner-status-20260831/probe_norm_overflow.py`. The script verifies its historical source hash, extracts only the two inner-mode helpers, and executes no DRM package load or response-model fit. Exit 0 means the historical defect and valid control were reproduced. Retained replay took 1.326 seconds on Julia 1.10.0; the snapshot did not change. This is not a test of the moving production source.

## Repair review

The frozen repaired source `2ab0c1685547d1814a322d258b0b23022a5637880e71b39c598727fce18f516e` correctly guards finite state/gradient entries, both computed norms, and the scaled bound in both branches. Success still requires the original stationarity criterion and undamped Cholesky. The tolerance and 200-iteration budget remain unchanged. A final Newton update can still legitimately converge. The existing Cholesky exception contract was not expanded into a general malformed-input guarantee.

**Certificate repair: APPROVE. Integrated slice: NOT READY.** The required regression runs are red and cannot be waived by the focused 33-assertion pass. The gradient regression retained four passing and two failing assertions; its `all(ga .!= 0)` assertion does not establish finite gradients because `NaN != 0` is true. Diagnostics must separately retain the analytic gradient, finite-difference gradient, and the inner certificate at every central-difference perturbation.

The Gamma public profile smoke errors before profiling: `_ls_vcov` calls `inv(H)` on a nonfinite finite-difference Hessian (`src/locscale_infer.jl:38`). The retained 76 passing assertions and one error therefore do not establish successful model fitting or valid CI endpoints. The cause of failed inner certificates (for example line-search rounding or a genuinely unresolved mode) remains under investigation, not established by these logs. Preserve the original tests, threshold and budget; do not convert this defect into a claimed analytic-gradient failure or attribute the Gamma failure to the endpoint router.

No full-package, numerical-parity, calibration, speed or programme-completion claim follows.
