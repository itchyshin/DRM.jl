# Joint missing-predictor prototype: fixture and symbolic alignment

This S9 prototype uses the two retained native-R datasets in
`missing-predictor-oracle/native-mi-oracle-003.json`. It does not regenerate a
more favourable dataset or silently replace the native fitted parameters.
Both are independent-row ML models, with one missing predictor and Gaussian
response. They do not cover the other required predictor families or providers.

Write `a_i = X_i beta`, `m_i = U_i gamma`, and `eta_i = U_i gamma` for the
Gaussian mean or Bernoulli logit. The response model is
`y_i | x_i ~ Normal(a_i + b*x_i, sigma_i^2)`. The Gaussian predictor model is
`x_i ~ Normal(m_i, tau_i^2)`; the binary model has `P(x_i=1)=logistic(eta_i)`.

| Symbol | Prepared quantity | Original DGP | Checked quantity | DGP truth |
|---|---|---|---|---|
| a_i | response design times beta | 0.4 + 0.3*z_i | retained fitted a vector | intercept 0.4, slope 0.3 |
| b | predictor loading coefficient | b*x_i | retained fitted b | 1.2 |
| sigma_i | exp(response log-SD design) | 0.8*Normal(0,1) | retained fitted sigma | 0.8 |
| m_i | Gaussian predictor design times gamma | 0.2 + 0.6*z_i | retained fitted m vector | intercept 0.2, slope 0.6 |
| tau_i | exp(predictor log-SD design) | 0.7*Normal(0,1) | retained fitted tau | 0.7 |
| eta_i | Bernoulli predictor design times gamma | Bernoulli(logistic(-0.2+0.5*z_i)) | retained fitted probability | intercept -0.2, slope 0.5 |

These are same-parameter likelihood and conditional-summary checks, not parameter
recovery. Truth is listed to connect the original DGP to the mathematical model;
the numerical reference uses the native fitted parameters recorded in the JSON.

For observed x retain its predictor density, and include the response density
only when y is observed. For missing x integrate it out; when both are missing,
the row integrates to one and contributes exactly zero log-likelihood.

For missing Gaussian x and observed y, with V=sigma^2+b^2*tau^2:
posterior mean is m + b*tau^2/V*(y-a-b*m), and posterior variance is
tau^2*sigma^2/V. For missing y use the predictor prior. For observed x return
its observed value with conditional variance zero. The binary posterior is
the normalized two-state prior times response likelihood; its variance is
p_post*(1-p_post). These are conditional summaries at fixed parameters, not
multiple-imputation draws or uncertainty in the fitted parameters.

The independently written R exporter will use numerical integration for the
Gaussian conditional moments, explicit state summation for Bernoulli moments,
and the previously verified joint likelihood oracle. All row IDs and masks are
retained. Synthetic endpoint/extreme cases and derivative checks belong to the
Julia tests, with finite-logit fitting separated from probability endpoint tests.

Acceptance: retained native and Julia log-likelihood agree within 1e-6 at common
parameters; row likelihoods and conditional moments agree within 1e-8;
both-missing rows have exactly zero contribution; observed rows are not reordered.
Damaged moments, likelihoods or row maps must fail the verification harness.
Numerical integration/export is a bounded local calculation, estimated <10 seconds.
