
# Mean effects and residual heterogeneity {#Mean-effects-and-residual-heterogeneity}

::: tip Status — Stable (diagonal known variances)

Mirrors drmTMB's [Mean effects and residual heterogeneity](https://itchyshin.github.io/drmTMB/articles/meta-analysis.html). **In DRM.jl today:** Gaussian meta-analysis with **known** per-study sampling variances via `meta_V(v)`, plus estimated between-study heterogeneity τ (the `σ` parameter). Dense / bivariate sampling covariance is planned.

:::

In meta-analysis each study reports an effect `y_i` with a **known** sampling variance `v_i`. The model separates that known measurement uncertainty from the **between-study heterogeneity** τ you want to estimate:

$$y_i \sim \mathcal{N}(x_i^\top\beta,\; v_i + \tau^2).$$

Flag the known-variance column with `meta_V(v)` in the mean formula; τ is the `σ` parameter (`sigma ~ 1` for a single heterogeneity).

```julia
using DRM, Random
Random.seed!(42)

k = 200
x = randn(k)                          # a study-level moderator
v = (0.15 .+ 0.5 .* rand(k)) .^ 2     # KNOWN sampling variances
τ = 0.3                               # between-study heterogeneity (to recover)
y = 0.4 .+ 0.6 .* x .+ τ .* randn(k) .+ sqrt.(v) .* randn(k)
dat = (; y, x, v)

fit = drm(bf(@formula(y ~ x + meta_V(v)), @formula(sigma ~ 1)), Gaussian(); data = dat)
coef(fit, :mu)                        # overall intercept + moderator slope
```


```ansi
2-element Vector{Float64}:
 0.41481738691720593
 0.5666471522976785
```


The between-study heterogeneity τ is the `σ` intercept (on the log scale):

```julia
exp(coef(fit, :sigma)[1])             # τ ≈ 0.3
```


```ansi
0.28710627380993503
```


A `meta_V` model with no moderators (`y ~ 1 + meta_V(v)`) is the classic random-effects meta-analysis; adding moderators (`y ~ x + meta_V(v)`) is meta-regression. Wald intervals via [`confint`](../model-guides/model-workflow.md) apply as usual.

::: tip Known V is not residual σ

`meta_V(v)` is _supplied_ measurement uncertainty; τ (the `σ` parameter) is _estimated_ heterogeneity. See [Which scale are you modelling?](../model-guides/which-scale.md).

:::
