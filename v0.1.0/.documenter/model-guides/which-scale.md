
# Which scale are you modelling? {#Which-scale-are-you-modelling?}

::: tip Status — Stable

Mirrors drmTMB's [Which scale are you modelling?](https://itchyshin.github.io/drmTMB/articles/which-scale.html). **In DRM.jl today:** all of them — the residual scale `σ` (including a random effect _on_ `σ`), a group-level random-intercept SD, and known sampling variances via `meta_V`.

:::

"Variance" can mean different things, and DRM.jl keeps them separate:

|             Quantity |                                What it is |                 How you model it |
| --------------------:| -----------------------------------------:| --------------------------------:|
|     **Residual `σ`** | within-unit spread of `y` around its mean |          the `sigma ~ …` formula |
|   **Group-level SD** | between-group spread of random intercepts |    a `(1 \| g)` term on the mean |
| **Known sampling V** |        measurement uncertainty you supply |  `meta_V(v)` in the mean formula |
|   **Scale-level RE** |  between-group spread of the _dispersion_ | a `(1 \| g)` term on `sigma ~ …` |


## Residual σ vs group SD, side by side {#Residual-σ-vs-group-SD,-side-by-side}

```julia
using DRM, Random
Random.seed!(3)

G = 60; m = 25; n = G * m
g = repeat(1:G, inner = m)
x = randn(n)
b = 0.8 .* randn(G)                      # between-group: SD 0.8
y = 1.0 .+ 0.3 .* x .+ b[g] .+ 0.5 .* randn(n)   # within-group residual: SD 0.5
dat = (; y, x, g)

fit = drm(bf(@formula(y ~ x + (1 | g)), @formula(sigma ~ 1)), Gaussian(); data = dat)

exp(coef(fit, :sigma)[1])     # residual (within-group) SD ≈ 0.5
```


```ansi
0.4879987840647729
```


```julia
re_sd(fit)[:g]                # group-level (between-group) SD ≈ 0.8
```


```ansi
0.8074566248245835
```


The two are genuinely different parameters: `σ` is how much observations vary _within_ a group; `re_sd` is how much group means vary _around_ the overall mean. A mean random effect leaves the marginal model Gaussian, so this is fit in closed form (no approximation).

::: tip Tip

Modelling how the _residual_ spread changes with a predictor? That's `sigma ~ x` — see [When variance carries signal](../tutorials/location-scale.md).

:::

## See also {#See-also}
- [Get started](../get-started.md) · [What can I fit today?](model-map.md)
  
