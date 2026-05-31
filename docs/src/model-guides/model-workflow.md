# Checking and using fitted models

!!! note "Status — First slice (Wald inference)"
    Mirrors drmTMB's [Checking and using fitted models](https://itchyshin.github.io/drmTMB/articles/model-workflow.html).
    **In DRM.jl today:** coefficient extraction, Wald standard errors, and Wald
    confidence intervals. Profile / bootstrap intervals, `predict`, `simulate`,
    and residuals are on the roadmap.

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

## See also

- [Get started](../get-started.md) · [When variance carries signal](../tutorials/location-scale.md)
- Profile and bootstrap intervals, `predict`, and `simulate` — see the
  [roadmap](https://github.com/itchyshin/DRM.jl/blob/main/ROADMAP.md).
