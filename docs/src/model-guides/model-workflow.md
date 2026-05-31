# Checking and using fitted models

!!! note "Status — First slice (Wald inference)"
    Mirrors drmTMB's [Checking and using fitted models](https://itchyshin.github.io/drmTMB/articles/model-workflow.html).
    **In DRM.jl today:** coefficient extraction, Wald standard errors, Wald
    confidence intervals, fitted values, residuals, and `simulate`. Profile /
    bootstrap intervals and `predict` (new data) are on the roadmap.

Once you have a fit, pull coefficients and quantify their uncertainty.

```@example wf
using DRM, Random
Random.seed!(5)
n = 1500
x = randn(n)
y = 0.4 .+ 0.7 .* x .+ exp.(-0.2 .+ 0.3 .* x) .* randn(n)
fit = drm(bf(@formula(y ~ x), @formula(sigma ~ x)), Gaussian(); data = (; y, x))

coef(fit, :mu)        # mean coefficients
stderror(fit)         # Wald standard errors (all coefficients)
```

Wald confidence intervals for every coefficient (drmTMB's default interval
method), one row per coefficient:

```@example wf
confint(fit; level = 0.95)
```

Each row carries its parameter (`:mu` / `:sigma`), coefficient name, point
estimate, and interval bounds. Intervals are on each parameter's working scale —
`μ` on the response scale, `σ` on `log σ` — so for a residual-SD ratio you
exponentiate the `σ` bounds.

!!! tip "What scale is the interval on?"
    A `σ` row gives an interval for a `log σ` coefficient. `exp(lower)` and
    `exp(upper)` give the interval for the multiplicative effect on the residual
    SD. See [Which scale are you modelling?](which-scale.md).

## Fitted values and residuals

```@example wf
ŷ = fitted(fit)            # fitted means (Xβ̂)
res = residuals(fit)       # observed − fitted
(n = length(res), sum_resid = round(sum(res), digits = 6))
```

For a bivariate model, `fitted` / `residuals` return one vector per response,
keyed `Dict(:mu1 => …, :mu2 => …)`.

## Simulating from a fitted model

`simulate` draws a parametric replicate — the building block of a parametric
bootstrap:

```@example wf
y_rep = simulate(fit; rng = MersenneTwister(1))   # one replicate response vector
length(y_rep)
```

## See also

- [Get started](../get-started.md) · [When variance carries signal](../tutorials/location-scale.md)
- Profile and bootstrap intervals, `predict`, and `simulate` — see the
  [roadmap](https://github.com/itchyshin/DRM.jl/blob/main/ROADMAP.md).
