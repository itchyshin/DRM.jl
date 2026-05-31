
# Changing residual coupling with rho12 {#Changing-residual-coupling-with-rho12}

::: tip Status — Stable

Mirrors drmTMB's [Changing residual coupling with rho12](https://itchyshin.github.io/drmTMB/articles/bivariate-coscale.html). **In DRM.jl today:** bivariate Gaussian location–scale with a predictor-dependent residual correlation `ρ12` (fixed effects, ML).

:::

With two responses, the interesting structure is often the **residual correlation** ρ12 — how `y1` and `y2` co-vary _after_ accounting for their means. DRM.jl lets ρ12 depend on predictors, with its own formula, exactly as drmTMB.

## A correlation that changes with a covariate {#A-correlation-that-changes-with-a-covariate}

We simulate two standard responses whose residual correlation rises with `x`, then recover that structure. ρ12 is modelled on the `atanh` scale (so it always stays in `(-1, 1)`):

```julia
using DRM, Random
Random.seed!(11)

n = 3000
x = randn(n)
ρ = tanh.(0.2 .+ 0.6 .* x)          # true residual correlation, rising with x
z1 = randn(n); z2 = randn(n)
y1 = z1
y2 = ρ .* z1 .+ sqrt.(1 .- ρ .^ 2) .* z2
dat = (; y1, y2, x)

fit = drm(bf(mu1 = @formula(y1 ~ x), mu2 = @formula(y2 ~ x),
             sigma1 = @formula(sigma1 ~ 1), sigma2 = @formula(sigma2 ~ 1),
             rho12 = @formula(rho12 ~ x)), Gaussian(); data = dat)

coef(fit, :rho12)        # atanh(ρ12): (Intercept), x  — ≈ [0.2, 0.6]
```


```ansi
2-element Vector{Float64}:
 0.21505118410323484
 0.5545828782999984
```


The coefficients are on the `atanh` scale. Back on the correlation scale, the residual correlation at `x = 0` is:

```julia
tanh(coef(fit, :rho12)[1])     # ρ12 at x = 0  (≈ tanh(0.2) ≈ 0.197)
```


```ansi
0.2117962254985607
```


and it increases with `x` (positive `atanh` slope). The means (`mu1`, `mu2`) and the scales (`sigma1`, `sigma2`) each have their own formula too — here the scales were held constant (`~ 1`).

::: tip Group-level vs residual correlation

`rho12` is the **residual** coupling of the two responses. Correlations that come from a shared phylogeny / spatial field / study are _group-level_ covariance summaries, reported separately — not `rho12`.

:::

## See also {#See-also}
- [When variance carries signal](location-scale.md) — the single-response location–scale model.
  
- The verified **q=4 phylogenetic** bivariate location–scale engine (the speed headline) — see [`HANDOVER.md`](https://github.com/itchyshin/DRM.jl/blob/main/HANDOVER.md); its public `phylo()` front end lands in a later slice.
  
