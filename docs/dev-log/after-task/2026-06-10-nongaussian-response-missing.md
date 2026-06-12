# After-Task Report: Non-Gaussian Response-Missing Rows

## Scope

This slice extends response-missing support beyond the Gaussian bridge slice. It
covers univariate DRM.jl family routes where a missing response row contributes
no likelihood information but the predictors are still available for full-row
prediction output.

Covered families in the new gate are Student, Poisson, Poisson with a random
intercept, negative binomial, truncated negative binomial, beta, gamma,
lognormal, binomial/Bernoulli, binomial `cbind(successes, failures)`,
beta-binomial, zero-one beta, Tweedie, and cumulative logit.

Predictor-missing support is still outside this slice. Bivariate residual
Gaussian response missing was covered by the previous bridge slice. Bivariate
q=4 / phylogenetic location-scale response missing still needs a sparse latent
kernel observed-cell mask, so it remains a separate task.

## Implementation

A shared helper now detects missing response rows using the same `missing` /
`NaN` response convention introduced for Gaussian models. For non-Gaussian
univariate models, the helper:

1. builds an observed-response mask from the formula response column;
2. fits the same family/formula to the observed rows only;
3. reconstructs full-length fitted means, observed-response vectors, and scale
   outputs by calling the existing prediction machinery on the original data;
4. returns `NaN` residuals for rows whose response was absent.

Two response-column count families, binomial and beta-binomial, require both
response cells to be observed; if either successes or failures is missing, the
row is omitted from the likelihood and gets `NaN` residual output.

Zero-one beta needed an explicit reconstruction of the unconditional mean
`(1 - zoi) * beta_mu + zoi * coi`, because its stored `fitted` convention is
the response mean rather than only the interior beta mean. Cumulative logit
needed explicit full-row reconstruction because its cutpoints are model-level
parameters rather than per-row scale values.

## Verification

Commands run:

```sh
julia --project=. -e 'using DRM; println("load ok")'
julia --project=. test/test_missing_response_nongaussian.jl
julia --project=. test/test_missing_response.jl
julia --project=. test/test_bridge.jl
```

Results:

- `test/test_missing_response_nongaussian.jl`: 118 passed.
- `test/test_missing_response.jl`: 27 passed across univariate and bivariate
  Gaussian response-missing rows.
- `test/test_bridge.jl`: 46 passed.
- `git diff --check`: clean.

A full `julia --project=. test/runtests.jl` attempt was also started. It passed
through the load, Gaussian, bivariate Gaussian, existing missing-response, new
non-Gaussian missing-response, ordinary non-Gaussian family, sparse-Laplace,
phylogenetic non-Gaussian, and location-scale fit sections. It was manually
stopped after several quiet CPU-bound minutes in
`test/test_locscale_profile.jl:45`, inside the unrelated location-scale profile
Hessian path. No failure was observed before the manual stop.

## Rose Audit

Verdict: scope is honest enough for this PR. The implementation claims only
response-missing support for the tested univariate non-Gaussian routes and the
Julia-side Poisson bridge primitive. It does not claim predictor-missing support
or full R `engine = "julia"` exposure for all non-Gaussian families. The R-side
drmTMB bridge still needs its own family-gating and parity tests before users
should see these non-Gaussian routes from R.
