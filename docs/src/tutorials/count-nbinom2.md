# Count abundance and extra zeros

!!! note "Status — First slice (Poisson)"
    Mirrors drmTMB's [Count abundance and extra zeros](https://itchyshin.github.io/drmTMB/articles/count-nbinom2.html).
    **In DRM.jl today:** the **Poisson** family `Poisson()` for counts (log link
    on the mean). Negative-binomial (`nbinom2`) for overdispersion and the `zi`
    zero-inflation modifier are the next Phase-2 slices.

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
    (variance > mean) or have **extra zeros**. The negative-binomial family
    (`nbinom2`) and the `zi` zero-inflation modifier — both arriving next in
    Phase 2 — relax those assumptions.

## See also

- [What can I fit today?](../model-guides/model-map.md) — the family/feature matrix.
- [Choosing response families](../model-guides/distribution-families.md).
