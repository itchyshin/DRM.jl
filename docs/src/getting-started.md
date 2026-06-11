# Getting started

!!! note "Status — Stable"
    A standalone first-fit walkthrough. Everything on this page runs against the
    verified Gaussian front end (`drm` / `bf`) and the post-fit accessors
    (`coef`, `loglik`, `confint`, `summary`). For the drmTMB-article mirror see
    [Get started](get-started.md); for the full capability map see
    [What can I fit today?](model-guides/model-map.md).

DRM.jl is *distributional* regression: instead of a single linear predictor for
the mean, you give **each parameter of the response distribution its own
formula**. The simplest case puts a formula on the mean **μ** and a formula on
the residual scale **σ**, so the spread of the data can change with covariates
just like the mean does.

This page takes you from a clean Julia session to a fitted model and shows how to
read what came back.

## Install

DRM.jl is pre-release, so develop it from a local checkout:

```julia
using Pkg
Pkg.develop(path = "/path/to/DRM.jl")   # or Pkg.add(url = "https://github.com/itchyshin/DRM.jl")
using DRM
```

The two verbs you will use the most are exported at the top level:

- `bf(...)` — bundle one formula per distributional parameter (alias
  `drm_formula`), exactly like drmTMB / brms.
- `drm(formula, family; data = ...)` — fit the model by maximum likelihood.

## Fit your first distributional regression

We simulate data whose mean **and** spread both depend on a covariate `x`, then
recover that structure. The mean rises with `x`; the residual standard deviation
also rises with `x` (heteroscedasticity), so a mean-only model would be
mis-specified.

```@example getstarted
using DRM, Random
Random.seed!(20260610)

n    = 400
x    = randn(n)
μ    = 1.0 .+ 0.5 .* x            # mean increases with x
logσ = -0.4 .+ 0.3 .* x           # log residual SD ALSO increases with x
y    = μ .+ exp.(logσ) .* randn(n)
dat  = (; y, x)

fit = drm(bf(@formula(y ~ x), @formula(sigma ~ x)), Gaussian(); data = dat)
```

`bf(@formula(y ~ x), @formula(sigma ~ x))` is the whole idea in one line: the
first formula sets the response and the **μ** sub-model; the second sets the
**σ** sub-model. (Drop the `sigma` formula and it defaults to `sigma ~ 1`, a
constant scale — ordinary homoscedastic regression.)

## Read the coefficients

`coef(fit, :param)` returns the coefficient block for one distributional
parameter. The mean block is on the **response scale** and should recover
`(1.0, 0.5)`:

```@example getstarted
coef(fit, :mu)
```

The scale block acts on **log σ**, so it should recover `(-0.4, 0.3)`:

```@example getstarted
coef(fit, :sigma)
```

A positive σ-slope means the residual spread grows with `x`. Because the σ link
is logarithmic, exponentiating a slope turns it into a **multiplicative effect on
the residual SD** per unit of `x`:

```@example getstarted
exp(coef(fit, :sigma)[2])      # residual-SD ratio per one-unit increase in x
```

Calling `coef(fit)` with no parameter concatenates every block into one vector
(μ first, then σ) — the raw parameter vector the optimiser returns.

## Read the model fit

`loglik(fit)` is the maximised log-likelihood; `aic` / `bic` build on it for
model comparison, and `nobs` / `dof` report the sample size and number of
estimated parameters:

```@example getstarted
(loglik = loglik(fit), aic = aic(fit), bic = bic(fit), nobs = nobs(fit), dof = dof(fit))
```

Always check that the optimiser actually converged before trusting any of the
above:

```@example getstarted
is_converged(fit)
```

`summary(fit)` prints a drmTMB-style coefficient table — estimates, standard
errors, z statistics, p-values, and 95% Wald intervals — for every block at once.
Row names are prefixed with the parameter (`mu: …`, `sigma: …`) so they stay
unique:

```@example getstarted
summary(fit)
```

## Confidence intervals

`confint(fit)` returns one row `(param, coef, estimate, lower, upper)` per
coefficient, on each block's working scale (μ on the response scale, σ on
`log σ`). The default is a 95% Wald interval:

```@example getstarted
confint(fit)
```

For a coefficient near a boundary, or whenever you want intervals that do not
assume a quadratic log-likelihood, ask for the **profile-likelihood** interval
instead — it re-optimises the other parameters at each fixed value and is exact
under the likelihood-ratio statistic:

```@example getstarted
confint(fit; method = :profile)
```

## Where to go next

- [Get started](get-started.md) — the drmTMB-article mirror, with the recent
  prediction / random-effect additions.
- [Choosing response families](families.md) — the full list of response
  families and how to fit each one.
- [What can I fit today?](model-guides/model-map.md) — the live capability map.
- [When variance carries signal](tutorials/location-scale.md) — a deeper
  location–scale walkthrough.
