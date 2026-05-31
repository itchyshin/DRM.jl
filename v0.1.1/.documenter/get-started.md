
# Get started {#Get-started}

::: tip Status — Stable

Mirrors drmTMB's [Distributional regression with drmTMB](https://itchyshin.github.io/drmTMB/articles/drmTMB.html). **In DRM.jl today:** the full Gaussian surface — location–scale, bivariate `ρ12`, random effects (on the mean _and_ the scale), structured effects, meta-analysis, and Wald / profile / bootstrap inference — fits by maximum likelihood through the `drm` / `bf` front end. This page starts with the simplest first fit; [What can I fit today?](model-guides/model-map.md) is the full map.

:::

Start here when you want to fit a first model and check that the fitted object matches your scientific question. DRM.jl gives each distributional parameter its own formula: the mean **μ** and the residual scale **σ**.

## Install {#Install}

```julia
using Pkg
Pkg.develop(path = "/path/to/DRM.jl")   # while pre-release
```


## Fit your first model {#Fit-your-first-model}

We simulate growth that depends on a covariate `x` in **both** its mean and its spread, then recover that structure:

```julia
using DRM, Random
Random.seed!(1)

n = 200
x = randn(n)
μ    = 1.0 .+ 0.5 .* x          # mean increases with x
logσ = -0.3 .+ 0.4 .* x         # spread ALSO increases with x
y = μ .+ exp.(logσ) .* randn(n)
dat = (; y, x)

fit = drm(bf(@formula(y ~ x), @formula(sigma ~ x)), Gaussian(); data = dat)
```


```ansi
DrmFit (Gaussian location–scale, 200 obs, converged; logLik = -219.94)
  mu: 1.038, 0.511
  sigma: -0.312, 0.389
```


The mean coefficients (≈ `1.0`, `0.5`):

```julia
coef(fit, :mu)
```


```ansi
2-element Vector{Float64}:
 1.0379700811961696
 0.5106461545447535
```


The scale coefficients act on **log σ** (≈ `-0.3`, `0.4`):

```julia
coef(fit, :sigma)
```


```ansi
2-element Vector{Float64}:
 -0.31223475325778544
  0.3886402088449883
```


A positive σ-slope means the residual spread grows with `x`. On the response scale, a one-unit increase in `x` multiplies the residual SD by `exp(slope)`:

```julia
exp(coef(fit, :sigma)[2])      # residual-SD ratio per unit x
```


```ansi
1.4749737733366457
```


## Which scale am I modelling? {#Which-scale-am-I-modelling?}

`σ` here is the **residual** scale (the spread of `y` around its mean) — distinct from a group-level random-effect SD or a known sampling variance. See [Which scale are you modelling?](model-guides/which-scale.md).

## Where to go next {#Where-to-go-next}
- [When variance carries signal](tutorials/location-scale.md) — a fuller location–scale walkthrough.
  
- [What can I fit today?](model-guides/model-map.md) — the full status map.
  
