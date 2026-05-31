
# Robust continuous responses {#Robust-continuous-responses}

::: tip Status — Stable

Mirrors drmTMB's [Robust continuous responses](https://itchyshin.github.io/drmTMB/articles/robust-student.html). **In DRM.jl today:** the Student-t family `Student()` — a formula per parameter for the location `μ`, scale `σ`, and degrees of freedom `ν`. Fixed effects, maximum likelihood.

:::

When a few observations sit far from the trend, a Gaussian fit chases them — the mean tilts and `σ` inflates. The **Student-t** family gives the residuals heavier tails, so outliers are downweighted instead of dominating. The shape parameter `ν` (degrees of freedom) controls how heavy: small `ν` is very robust, and `ν → ∞` returns to Gaussian.

## Fitting a Student-t model {#Fitting-a-Student-t-model}

Give each parameter its own formula, exactly like the Gaussian model — `nu ~ 1` estimates a single degrees-of-freedom value:

```julia
using DRM, Random
using Distributions: TDist
Random.seed!(20260614)

n = 2000
x = randn(n)
# location-scale t errors (heavy-tailed): true ν = 5
y = 0.5 .+ 0.7 .* x .+ 0.8 .* rand(TDist(5.0), n)
dat = (; y, x)

fit = drm(bf(@formula(y ~ x), @formula(sigma ~ 1), @formula(nu ~ 1)), Student(); data = dat)
coef(fit, :mu)              # location coefficients
```


```ansi
2-element Vector{Float64}:
 0.5010757552926148
 0.7116232787930301
```


`σ` and `ν` are on the log scale (both must stay positive), so read them back through `exp`:

```julia
exp(coef(fit, :sigma)[1])   # residual scale
exp(coef(fit, :nu)[1])      # estimated degrees of freedom (≈ 5 ⇒ heavy tails)
```


```ansi
5.336378088942579
```


A small `ν` (say &lt; 10) is the signal that robustness is earning its keep; a large `ν` says the data are effectively Gaussian and you could simplify.

::: tip Scale, not variance

For the t the residual _variance_ is `σ² · ν/(ν−2)` (and is undefined for `ν ≤ 2`). `σ` here is the scale parameter, not the SD — quote it as such when comparing to a Gaussian fit.

:::

## See also {#See-also}
- [When variance carries signal](location-scale.md) — the Gaussian location–scale model.
  
- [What can I fit today?](../model-guides/model-map.md) — the family/feature matrix.
  
