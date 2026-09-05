# Native missing-predictor prediction repair contract

Prediction returns a distributional parameter at fitted latent summaries. It
must stop using initial imputation placeholders. Coefficients, likelihood,
optimizer output, observed rows, offsets and other conditional random effects
are unchanged by this repair.

For a Gaussian identity response with independent Gaussian missing predictors,
let the missing predictors have prior mean m and diagonal covariance D, slope
vector b, and residual variance s². After subtracting fixed observed-predictor
contributions a from the response,

    E[x | y, theta] = m + D b (y - a - b' m) / (s² + b' D b).
    E[y_rep | y, theta] = a + b' E[x | y, theta].

For a missing response, use m. A one-predictor Gaussian posterior mode equals
its mean; two missing predictors have posterior dependence but the linear
response mean still uses their individual conditional means. Other retained
latent effects are held at their fitted conditional values.

For a binary predictor, posterior odds equal prior odds times the Gaussian
response likelihood ratio. For ordinal/categorical predictors, form posterior
state probabilities and average state-specific design rows:

    Xbar_i = sum_s p_is X_i(s).

A modal category or expected ordinal score does not determine the expected
contrast row. Preserve fitted levels and contrast columns. Native state-design
rows are observation-major then state; validate dimensions, probabilities and
row identity before use. New binary data use fitted encoding, never the levels
present in just the incoming batch.

For nonlinear inverse links, inverse_link(E[eta]) generally differs from
E[inverse_link(eta)]. A plug-in parameter prediction must not be described as
integrated response expectation. Reusing posterior-weighted designs likewise
does not propagate imputation uncertainty through coefficient covariance or
establish interval coverage.

Rose Sol/high approved this contract subject to regression tests, metadata
validation, preserved fit state/storage controls and explicit scope. Native
optimizer mismatch and the required frozen4e-6 comparisons remain separate.
