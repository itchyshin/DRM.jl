# Two independent Gaussian predictors: exact joint contract

Approved programme #563, S9. Prepared kernel is a dependency toward direct Julia
and R bridge parity, not a replacement for those public admissions. All other
24 native missing-predictor obligations remain required.

For row i, x_j ~ Normal(m_j, tau_j²), m_j=Xp_j alpha_j, j=1,2,
independent conditional on complete exogenous designs. The response is Gaussian:
y | x ~ Normal(a + b1*x1 + b2*x2, sigma²), a=Xmu beta,
sigma=exp(Xsigma delta). Native/public predictor SDs are tau_j; raw coordinates
are kappa_j=log(tau_j). Exactly two independent Gaussian predictors here.

Raw parameter order: beta, b1, b2, delta, alpha1, kappa1, alpha2, kappa2.
Each predictor can have a different complete design and different missing mask.
Missing y rows retain any observed predictor densities. Fully missing rows
have log likelihood zero. Normalization constants are retained in all rows.

For missing subset M, D=diag(tau_M²), response variance v=sigma²+b_M'Db_M,
response mean a+sum_observed b_j*x_j+b_M'm_M. Add the log density of every
observed predictor. If y is observed, missing predictors have conditional mean
u=m_M+Db_M*(y-response_mean)/v and covariance C=D-Db_M*b_M'D/v.
If y is missing, u=m_M and C=D. Observed predictors retain their values and
zero mathematical conditional variance/covariance; public imputed SE remains
unavailable, preserving native semantics.

Both predictors missing does NOT mean their posterior is independent. The
conditional covariance off diagonal is -tau1²*tau2²*b1*b2/v; its sign reverses
if exactly one slope changes sign. Retain the full per-row 2x2 covariance.

Native-compatible Gaussian imputation standard errors use first-order prediction
error: C + J*V_theta*J', J=du/dtheta, with the full raw-coordinate covariance.
Public marginal SEs take the diagonal. This is not exact integration over
parameter uncertainty and does not establish interval coverage. Observed rows
remain SE-unavailable; se=false must not erase fit-level uncertainty failures.

Independent reference uses a different formulation: build the full joint
Normal(y,x1,x2), evaluate its observed-coordinate density by Cholesky, and
condition via the full covariance Schur complement. Evaluate all eight masks at
three parameter points, including two fixed perturbations from the native fit.
A finite-difference Jacobian with native fixed-parameter covariance independently
checks both marginal imputation SEs. No Julia fitted curvature enters this
native-reference oracle. Rose Sol/high approved this math before implementation.

Required checks include all eight masks, nonzero/offdiagonal sign, distinct
design widths, predictor permutation, full cross-block synthetic covariance,
small/large scales, zero slopes, AD/FD gradients and Hessians, invalid/missing
inputs, covariance/status failure, and input snapshot isolation. Native fit
comparison uses unchanged4e-6 tolerance; any remaining optimizer difference stays
red. No solver default, estimator, starts or comparator replacement is licensed.
