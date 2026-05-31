
# Checking and using fitted models {#Checking-and-using-fitted-models}

::: tip Status — Stable (Gaussian post-fit + inference)

Mirrors drmTMB's [Checking and using fitted models](https://itchyshin.github.io/drmTMB/articles/model-workflow.html). **In DRM.jl today:** coefficient extraction, Wald standard errors, Wald **and profile-likelihood** confidence intervals, fitted values, residuals, `predict` (new data), `simulate`, and **parametric bootstrap** intervals (`bootstrap_ci`).

:::

Once you have a fit, pull coefficients and quantify their uncertainty.

```julia
using DRM, Random
Random.seed!(5)
n = 1500
x = randn(n)
y = 0.4 .+ 0.7 .* x .+ exp.(-0.2 .+ 0.3 .* x) .* randn(n)
fit = drm(bf(@formula(y ~ x), @formula(sigma ~ x)), Gaussian(); data = (; y, x))

coef(fit, :mu)        # mean coefficients
stderror(fit)         # Wald standard errors (all coefficients)
```


```ansi
4-element Vector{Float64}:
 0.022288731088698478
 0.019641780488133715
 0.018257479230049008
 0.018428125720313257
```


Wald confidence intervals for every coefficient (drmTMB's default interval method), one row per coefficient:

```julia
confint(fit; level = 0.95)
```


```ansi
4-element Vector{@NamedTuple{param::Symbol, coef::String, estimate::Float64, lower::Float64, upper::Float64}}:
 (param = :mu, coef = "(Intercept)", estimate = 0.39349561099036484, lower = 0.34981050079541753, upper = 0.43718072118531215)
 (param = :mu, coef = "x", estimate = 0.6948983766847261, lower = 0.6564011943357424, upper = 0.7333955590337098)
 (param = :sigma, coef = "(Intercept)", estimate = -0.20618165608600256, lower = -0.24196565782538676, upper = -0.17039765434661835)
 (param = :sigma, coef = "x", estimate = 0.2767183623681545, lower = 0.24059989965376422, upper = 0.3128368250825448)
```


Each row carries its parameter (`:mu` / `:sigma`), coefficient name, point estimate, and interval bounds. Intervals are on each parameter's working scale — `μ` on the response scale, `σ` on `log σ` — so for a residual-SD ratio you exponentiate the `σ` bounds.

For a **profile-likelihood** interval (drmTMB's `method = "profile"`), pass `method = :profile`. It inverts the likelihood-ratio statistic — re-optimising the nuisance parameters at each fixed value — so it is asymmetric and exact under the LR statistic where Wald is only a quadratic approximation. Use Wald for speed; profile when a parameter's likelihood is skewed (a scale or variance term):

```julia
confint(fit; method = :profile)
```


```ansi
4-element Vector{@NamedTuple{param::Symbol, coef::String, estimate::Float64, lower::Float64, upper::Float64}}:
 (param = :mu, coef = "(Intercept)", estimate = 0.39349561099036484, lower = 0.3497629684475744, upper = 0.4371944612919295)
 (param = :mu, coef = "x", estimate = 0.6948983766847261, lower = 0.6564190809230628, upper = 0.7334746345561233)
 (param = :sigma, coef = "(Intercept)", estimate = -0.20618165608600256, lower = -0.2415438548696413, upper = -0.1699657106509167)
 (param = :sigma, coef = "x", estimate = 0.2767183623681545, lower = 0.2406065581669386, upper = 0.3128428539020196)
```


::: tip What scale is the interval on?

A `σ` row gives an interval for a `log σ` coefficient. `exp(lower)` and `exp(upper)` give the interval for the multiplicative effect on the residual SD. See [Which scale are you modelling?](which-scale.md).

:::

## Fitted values and residuals {#Fitted-values-and-residuals}

```julia
ŷ = fitted(fit)            # fitted means (Xβ̂)
res = residuals(fit)       # observed − fitted
(n = length(res), sum_resid = round(sum(res), digits = 6))
```


```ansi
(n = 1500, sum_resid = 12.76284)
```


For a bivariate model, `fitted` / `residuals` return one vector per response, keyed `Dict(:mu1 => …, :mu2 => …)`.

Predict the mean on **new** data (population level — random/structured effects integrated out):

```julia
predict(fit, (; x = [-1.0, 0.0, 1.0]))    # μ̂ at three new x values
```


```ansi
3-element Vector{Float64}:
 -0.30140276569436125
  0.39349561099036484
  1.088393987675091
```


## Simulating from a fitted model {#Simulating-from-a-fitted-model}

`simulate` draws a parametric replicate — the building block of a parametric bootstrap:

```julia
y_rep = simulate(fit; rng = MersenneTwister(1))   # one replicate response vector
length(y_rep)
```


```ansi
1500
```


## Bootstrap confidence intervals {#Bootstrap-confidence-intervals}

`bootstrap_ci` automates the parametric bootstrap — simulate `B` replicates, refit each, and take percentile intervals. It takes the same arguments as `drm` (plus `B`), since it refits internally:

```julia
bootstrap_ci(bf(@formula(y ~ x), @formula(sigma ~ x)), Gaussian();
             data = dat, B = 500, level = 0.95)
```


Returns the same `(param, coef, estimate, lower, upper)` rows as `confint`. Use Wald (`confint`) for speed; bootstrap when you want fewer distributional assumptions.

## See also {#See-also}
- [Get started](../get-started.md) · [When variance carries signal](../tutorials/location-scale.md)
  
- Profile and bootstrap intervals, `predict`, and `simulate` — see the [roadmap](https://github.com/itchyshin/DRM.jl/blob/main/ROADMAP.md).
  
