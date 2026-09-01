# Gaussian stopping-accuracy diagnostic (not baseline replacement)

For the existing four fixed-effect Gaussian fixtures, write
mu_i = X_i beta, t_i = exp(2 Z_i gamma), v_i = t_i + a_i,
r_i = y_i - mu_i. Known sampling variance a_i is zero except in the
meta_V(V=v) case (a_i=0.02). ML negative log likelihood:

L = sum_i [log(2*pi)/2 + log(v_i)/2 + r_i^2/(2*v_i)].

Gradients:
dL/dbeta = -X' (r/v),
dL/dgamma = Z' [(t/v) * (1-r^2/v)].

| Symbol | Model/formula | Data input | Extraction | Truth/meaning |
|---|---|---|---|---|
| beta | y~x or y~x+g | Frozen data from prediction-green-003.json | coef(fit)$mu | Fixed mean coefficients |
| gamma | sigma~x, sigma~x+g, or sigma~1 | Same frozen data | coef(fit)$sigma | Log residual/heterogeneity SD |
| a | meta_V(V=v) only | Frozen v=0.02, else zero | Explicit known-variance vector | Not a fitted variance component |
| y | Gaussian response | Frozen original sample; no new DGP | receipt$data$y | Same data as failed parity case |

Compare analytic likelihood/gradient with native TMB at its fitted parameters;
check the analytic gradient by central finite differences (step1e-6,
absolute tolerance1e-6). Require the default native coefficients to reproduce
the frozen baseline within1e-12. Try one predeclared diagnostic control for
ALL four cases: nlminb rel.tol=1e-12, x.tol=1e-12, iter.max=eval.max=1000.
Retain both results and all failures. Existing4e-6 prediction tolerance remains.
A tighter-control success is diagnostic only; substitution_allowed=false.
No engine/source/default-control changes; no performance or full-parity claim.

Follow-up after receipt001: tight controls retain the default coefficients but
return singular convergence for three cases. For every case, run two explicit
diagnostic restarts from the default coefficient vector: one using the analytic
objective/gradient above, one using the native TMB objective/gradient. Both use
the same predeclared tight controls. Preserve statuses, improvement, gradients
and coefficient differences. These diagnostic optimizations do not replace
either original independently fitted baseline.
