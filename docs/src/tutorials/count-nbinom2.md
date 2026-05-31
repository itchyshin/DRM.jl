# Count abundance and extra zeros

!!! note "Status — Stable (Poisson + NB2)"
    Mirrors drmTMB's [Count abundance and extra zeros](https://itchyshin.github.io/drmTMB/articles/count-nbinom2.html).
    **In DRM.jl today:** the **Poisson** family `Poisson()` and the
    **negative-binomial** family `NegBinomial2()` (overdispersed counts). The
    `zi` zero-inflation modifier for **extra zeros** is the next Phase-2 slice.

Counts — abundances, visit tallies, event counts — are non-negative integers, so
a Gaussian model is the wrong shape. The **Poisson** family models the log of the
expected count.

## A Poisson abundance model

```@example count
using DRM, Random
import Distributions          # `Poisson` below is DRM's family; qualify the distribution
Random.seed!(20260615)

n = 3000
x = randn(n)
λ = exp.(0.3 .+ 0.5 .* x)                       # log-mean increases with x
y = Float64.([rand(Distributions.Poisson(λi)) for λi in λ])
dat = (; y, x)

fit = drm(bf(@formula(y ~ x)), Poisson(); data = dat)
coef(fit, :mu)              # coefficients on log λ
```

The slope is a **log rate ratio**: a one-unit increase in `x` multiplies the
expected count by `exp(β)`.

```@example count
exp(coef(fit, :mu)[2])      # rate ratio per unit x (≈ exp(0.5) ≈ 1.65)
```

Fitted values are returned on the response (count) scale:

```@example count
extrema(fitted(fit))        # fitted means λ̂ = exp(Xβ̂)
```

!!! tip "When Poisson is too tight"
    Poisson forces variance = mean. Real counts are often **overdispersed**
    (variance > mean). The negative-binomial family `NegBinomial2()` relaxes that
    — read on. (The `zi` zero-inflation modifier for **extra zeros** is a later
    Phase-2 slice.)

## Overdispersion: the negative-binomial (NB2) family

`NegBinomial2()` adds a dispersion (size) parameter `θ` in the `sigma` slot. The
variance is `μ + μ²/θ`, so smaller `θ` means heavier overdispersion and `θ → ∞`
returns to Poisson.

```@example count
Random.seed!(20260616)
θ = 2.5
μnb = exp.(0.4 .+ 0.5 .* x)
ynb = Float64.([rand(Distributions.NegativeBinomial(θ, θ / (θ + μi))) for μi in μnb])
datnb = (; y = ynb, x)

fitnb = drm(bf(@formula(y ~ x), @formula(sigma ~ 1)), NegBinomial2(); data = datnb)
exp(coef(fitnb, :sigma)[1])     # estimated dispersion θ (≈ 2.5 ⇒ real overdispersion)
```

A finite, smallish `θ` is the signal that the counts are overdispersed and a
plain Poisson would understate the uncertainty.

## See also

- [What can I fit today?](../model-guides/model-map.md) — the family/feature matrix.
- [Choosing response families](../model-guides/distribution-families.md).
