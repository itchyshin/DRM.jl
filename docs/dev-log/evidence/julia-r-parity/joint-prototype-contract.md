# S9 prepared joint missing-predictor prototype contract

**Status:** implemented Julia-only prepared prototype, with local numerical
checks and an in-process optimizer smoke only. No `mi()` frontend, R bridge admission, native fit parity, or
completion of any native missing-predictor obligation is claimed. This document
specifies the smallest shared prepared-data layer for two exact ML prototypes.

## Scope and data contract

A prepared model has one response `y` and one potentially missing predictor
`x`, each on the original `n` input rows. It receives no raw R expression and
no formula parsing:

- `y`: numeric or missing;
- `x`: numeric-or-missing for `predictor = :gaussian`, or `{0,1}`-or-missing
  for `predictor = :bernoulli`;
- `X_response`: complete numeric `n × p` design excluding `x`, with an explicit
  column-name vector;
- `X_sigma`: complete numeric residual-scale design with an explicit column-name
  vector; arbitrary fixed-effect columns are supported by the same row-wise
  likelihood;
- `X_predictor`: complete numeric `n × q` predictor-model design with explicit
  column names;
- `original_row`: unique positive integers of length `n`, preserving source-row
  identity and order.

The response linear predictor is

\[
  \eta_i = X_{\mathrm{response},i}\beta + \gamma x_i,
  \qquad \sigma_i = \exp(X_{\sigma,i}\delta).
\]

No weights, offsets, response/predictor random
terms, structured terms, `meta_V`, multiple missing predictors, bivariate
responses, REML, profile/bootstrap, or predictor-dependent response scale are
part of either prototype.

The supplied predictor model is either

\[
 x_i \sim N(m_i,\tau^2),\quad m_i=X_{\mathrm{predictor},i}\alpha,\quad
 \tau=\exp(\kappa),
\]

or

\[
 x_i\sim\operatorname{Bernoulli}(p_i),\quad
 p_i=\operatorname{logit}^{-1}(X_{\mathrm{predictor},i}\alpha).
\]

The parameter vector is ordered and named as
`(:mu => [beta..., "mi(x)"], :sigma => delta,
 :mi_x => alpha, :logsd_mi_x => [kappa])` for the Gaussian predictor, and omits
`:logsd_mi_x` for Bernoulli. `kappa` is the raw log standard deviation, not the
native public-scale `sigma_mi` parameter. This gives `DrmFit.blocks`, `coefnames`, `coef`,
`vcov`, `loglik`, AIC/BIC, and convergence one unambiguous representation.

## Exact marginal likelihood layer

Every row is classified and retained as exactly one of `:complete`,
`:x_missing_y_observed`, `:x_observed_y_missing`, or `:both_missing`.
Normalisation constants are always included.

| Row state | Gaussian predictor contribution | Bernoulli predictor contribution |
| --- | --- | --- |
| x and y observed | `log N(x; m, tau²) + log N(y; eta(x), sigma²)` | `log Bern(x; p) + log N(y; eta(x), sigma²)` |
| x missing, y observed | `log N(y; X_response beta + gamma*m, sigma² + gamma²*tau²)` | `logsumexp(log(1-p)+log N(y; eta(0),sigma²), log(p)+log N(y; eta(1),sigma²))` |
| x observed, y missing | `log N(x; m, tau²)` | `log Bern(x; p)` |
| both missing | `0` | `0` |

The Gaussian closed form and Bernoulli finite-state sum are two methods of one
internal row-contribution interface. The interface returns the scalar log
contribution and, after fitting, the conditional first two moments of `x`; it
must not expose a generic quadrature abstraction in this slice.

## Conditional moments and missing-data status

For observed `x`, return `E[x | available data] = x`, variance zero, and
status `:observed`. For an x-missing Gaussian row with observed y,

\[
 v_i=(\tau^{-2}+\gamma^2\sigma_i^{-2})^{-1},\qquad
 \bar x_i=v_i\{m_i/\tau^2+\gamma(y_i-X_{\mathrm{response},i}\beta)/\sigma_i^2\}.
\]

Return `(mean = xbar, variance = v, status = :gaussian_posterior)`. If y is
also missing, return `(m, tau², :predictor_only)`.

For an x-missing Bernoulli row with observed y, let the two log weights be the
same values used by the likelihood and set
`q1 = q = exp(logw1 - logsumexp(logw0, logw1))` and evaluate
`q0*q1` from stable complementary logits. Return `(q, q0*q1,
:bernoulli_posterior)`; when y is missing, return `(p, p0*p1,
:predictor_only)`. A modal category, if later needed, is derived from this
probability and must specify its tie rule; it is not the primary prototype
estimand.

`DrmFit.means[:mu]` may store the response conditional fitted mean formed from
these `x` means, but it must carry companion per-row status metadata so it is
never mistaken for an unconditional population mean. `obs[:mu]` stores y with
its existing missing representation. A dedicated `joint_missing_summary(fit)`
accessor is required before a public `imputed()` analogue is claimed.

The first prototype reports conditional-moment point estimates only:
`uncertainty_status = :not_implemented`. Its covariance is the **inverse**
observed information, `inv(H)` for `H = ∇² nll`, only when the AD Hessian is
finite and positive definite. Otherwise it uses a NaN covariance matrix and
records `covariance_status = :hessian_unavailable` or
`:hessian_not_positive_definite`. Optimizer convergence and
its termination status remain separate from Hessian availability. It makes no
Wald, profile, bootstrap, or coverage claim.

## Fit/result integration

Define a new Julia-only prepared input type, e.g. `PreparedJointModel`, and a
small `JointMissingMetadata` payload with original rows, row states, observed
masks, predictor family, conditional moments, and uncertainty/status fields.
The fitter returns `PreparedJointFit`, a narrow wrapper around an existing
`DrmFit` plus `JointMissingMetadata`; it does not overload `ranef`:

- `family` is a new `PreparedJointGaussian` or
  `PreparedJointBernoulli` tag;
- `nobs` is the number of observed response rows, matching the native missing
  data convention, while metadata separately records all `n` rows and the
  number contributing a predictor-only density;
- `formula = nothing` for the prepared prototype, so generic formula-based
  `predict` refuses rather than inventing new-data semantics;
- `nll` is retained for later profiling work but no inference method is exposed
  yet; `ranef` retains its random-effect meaning and is not a missing-data
  metadata carrier.

The wrapper is intentional: existing `DrmFit` fields cover coefficients,
likelihood, covariance, observed response, scales, and convergence, but not
original-row/missing-predictor metadata. It does not forward generic
`confint`, `simulate`, or `AIC` methods until those contracts are separately
validated.

The implemented Julia-only surface is:

```julia
model = prepared_joint_model(y, x, Xmu, Xsigma, Xpredictor;
    predictor = :gaussian, mu_names, sigma_names, predictor_names, original_row)
prepared_joint_rowloglik(model, theta)
prepared_joint_nll(model, theta)
prepared_joint_conditional_moments(model, theta)
result = fit_prepared_joint(model; g_tol = 1e-8)
joint_missing_summary(result)
```

`prepared_joint_conditional_moments` is a fixed-parameter conditional-variance
calculation. It is not the native R `imputed()` standard error, which may also
reflect parameter uncertainty. `joint_missing_summary` returns copies of the
prepared masks, original rows, point moments, and statuses; it is deliberately
not an `imputed()` compatibility method.

## Direct and R paths, deliberately separate

1. **S9 implementation path:** direct Julia constructor
   `prepared_joint_model(...)` and `fit_prepared_joint(...)`; it accepts only
   the prepared designs and arrays above.
2. **Later direct public path:** extend `bf()`/`drm()` with an explicit Julia
   missing-predictor marker only after grammar, error, result, and predictor
   model contracts are approved.
3. **Later R path:** R validates `mi()` and `impute_model()`, builds the exact
   prepared arrays and original-row metadata, and calls a narrow bridge wrapper.
   It must not serialize arbitrary R formulas into Julia or claim that the R
   route admits all native missing-data variants.

## Next implementation files and boundaries

The implementation is isolated in `src/joint_missing_predictor.jl`, with
focused local tests in `test/test_joint_missing_predictor.jl`, and is included/exported from
`src/DRM.jl`. A later public-formula change belongs in `src/gaussian_core.jl`
and a later bridge marshaller in the R repository's `R/julia-bridge.R`; neither
is part of the prepared prototype.

Do not edit `src/gaussian_structured.jl` or `src/gaussian_sparse_lss.jl`. They
are both outside this model and explicitly denied for this programme.

## Relation to the native 24-cell ledger

The two prototypes correspond only to the fixed-effect Gaussian response with
one Gaussian predictor (`mp-gaussian-gaussian`, excluding its grouped and
structured native variants) and one Bernoulli predictor
(`mp-gaussian-bernoulli`). They do not complete those cells' native metadata or
conditional-summary contracts, and they do not cover the other 22 rows:
ordered/categorical/proportion/count/positive/semi-continuous predictor models;
non-Gaussian response families; NB2 with a Gaussian predictor; response masks
as a joint R/Julia route; or any recovery, interval, coverage, or optimizer-
accuracy evidence. The 24 rows remain an obligation denominator, not an
admission list.

## Source basis

This contract is derived from the immutable native-obligation ledger and its
independent same-parameter oracle, plus DRM.jl's current `DrmFit` and Gaussian
formula-routing structures at Julia HEAD `ea90aafe`. The R oracle’s two native
reference fits established only matching likelihood values at common fitted
parameters; it explicitly does not establish Julia admission or optimizer
accuracy.
