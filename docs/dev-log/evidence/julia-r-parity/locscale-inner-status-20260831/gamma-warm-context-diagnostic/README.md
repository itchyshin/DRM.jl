# Exact Gamma covariance failure — unresolved

The actual `_ls_vcov` call receives engine covariance coordinates
`[logL11, L21, logL22]`; public `fit.theta` instead stores
`[logL11, logL22, L21]` in its covariance tail. Earlier trace002 used the wrong
order and is invalid for this failure. Trace003 uses the captured engine order
and agrees with direct source replay001. No production/copy contradiction remains.

The captured public context is `locscale_gamma_vcov_actual_context-001.jls`.
Among12 observed-information perturbations, only `theta[1] - 1e-5` fails.
Direct inner success is false; prior Cholesky succeeds. Its gradient norm is
2.360009e-9 against the unchanged1.322563e-9 bound. The resulting failed gradient
contaminates all six Hessian columns after symmetrization; this is one failed
mode evaluation, not six independent failures.

The full undamped trial is finite, stationary and PD, with displacement4.602e-11.
Its raw objective increase is3.510e-12, about494ULPs. The stable estimate is
-5.39416e-20 with estimated error4.56462e-19, leaving positive margin4.02520e-19.
Refusal follows the frozen contract. It does not prove true mathematical ascent.

Next: compare exact captured endpoints with full-input high-precision likelihood
and gradient arithmetic, and split the error-scale contributions. No constant,
tolerance, budget, estimator or source change is authorized by this refusal alone.
The arithmetic001 script/log in the manifest were copied before final process
confirmation; require the separate final-hash receipt before treating them as
completed evidence. Other primary terminal evidence: warm-intercept005,
actual-context-replay001 and corrected trace003. Failed earlier attempts remain.

## Completed arithmetic follow-up

Final003 is terminal (3.2s within60s), with hashes checked in `arithmetic-final/`.
Full lifted128/256bit NLL evaluations agree on delta=-5.4686167e-20. Float64
base/trial gradient norms2.360009e-9/4.180413e-11 and high-precision norms
2.370693e-9/5.403298e-11 agree on nonstationary base and stationary trial.

Two effects must be distinguished. The raw objective sign error is already in
Float64 term evaluation: summing those rounded terms in BigFloat stays positive.
Separately, Q8's error of approximately7.446e-22 matches the prior directional
rounding error. Its conservative margin is dominated by the prior's3.210021e-5
uncancelled magnitude; the data contribution is2.045045e-8. These are reasons to
investigate more accurate arithmetic, not to change the current constants.

The next read-only prototype retains FMA product residuals and compensated
components through the signed directional sum. Rose approved that investigation,
not production changes. Any precision-aware error estimate needs an explicit
operation-based contract and new controls; retain all original five cases and
this sixth case. Current integration gates remain failed.
