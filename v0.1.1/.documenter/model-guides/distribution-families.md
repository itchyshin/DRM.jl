
# Choosing response families {#Choosing-response-families}

::: tip Status — Stable

Mirrors drmTMB's [Choosing response families](https://itchyshin.github.io/drmTMB/articles/distribution-families.html). **In DRM.jl today:** Gaussian, Student-t, LogNormal, Gamma, Poisson, negative-binomial (NB2) + truncated, beta, beta-binomial, zero-one-inflated beta, Tweedie, and cumulative-logit (ordinal) — plus the `zi` / `hu` count modifiers. **This is drmTMB's complete family set.**

:::

Pick the family from the _shape_ of your response, then give each of its parameters a formula with `bf`.

|                             Response looks like… |              Family |           Mean link |          Second parameter (`sigma` slot) |
| ------------------------------------------------:| -------------------:| -------------------:| ----------------------------------------:|
|                           Real-valued, symmetric |        `Gaussian()` |            identity |                    residual SD `σ` (log) |
|              Real-valued, heavy tails / outliers |         `Student()` |            identity |            scale `σ` (log) + d.o.f. `nu` |
|                    Strictly positive, continuous |           `Gamma()` |                 log |                         shape `α = 1/σ²` |
|                    Positive **with exact zeros** |         `Tweedie()` |                 log |     √dispersion `σ` + power `nu` ∈ (1,2) |
| Strictly positive, right-skewed (multiplicative) |       `LogNormal()` | identity on `log y` |                 SD of `log y`, `σ` (log) |
|                         Counts (variance ≈ mean) |         `Poisson()` |                 log |                                        — |
|                            Counts, overdispersed |    `NegBinomial2()` |                 log |                     dispersion `θ` (log) |
|                          Counts with extra zeros | + `zi ~ …` modifier |        logit on `π` |          (on `Poisson` / `NegBinomial2`) |
|                             Proportions in (0,1) |            `Beta()` |               logit |                     precision `φ = 1/σ²` |
|                          Successes out of trials |    `BetaBinomial()` |               logit | overdispersion `φ = 1/σ²` (`cbind(s,f)`) |
|             Proportions on `[0,1]` incl. 0 and 1 |     `ZeroOneBeta()` |               logit |               `φ = 1/σ²` + `zoi` / `coi` |
|                        Ordered categories `1..K` | `CumulativeLogit()` |   logit (cutpoints) |                    K−1 ordered cutpoints |


Each family's `sigma` slot is its natural dispersion handle — the same `sigma ~ …` formula machinery, with a family-specific link/mapping.

## Example: a Gamma model for positive data {#Example:-a-Gamma-model-for-positive-data}

`Gamma()` suits durations, sizes, and concentrations — strictly positive and right-skewed. The mean uses a log link; the `sigma` slot is the **coefficient of variation**, mapped to the shape `α = 1/σ²`:

```julia
using DRM, Random
import Distributions          # `Gamma` below is DRM's family; qualify the distribution
Random.seed!(20260618)

n = 3000
x = randn(n)
α = 8.0                                          # shape (CV = 1/√α ≈ 0.35)
μ = exp.(0.5 .+ 0.4 .* x)                         # log-linear mean
y = Float64.([rand(Distributions.Gamma(α, μi / α)) for μi in μ])
dat = (; y, x)

fit = drm(bf(@formula(y ~ x), @formula(sigma ~ 1)), Gamma(); data = dat)
exp(coef(fit, :mu)[2])           # multiplicative effect of x on the mean
```


```ansi
1.4759201588595423
```


```julia
exp(-2 * coef(fit, :sigma)[1])   # recovered shape α = 1/σ² (≈ 8)
```


```ansi
7.790491838404592
```


`LogNormal()` is the other positive-continuous option — use it when the data are _multiplicative_ (the log is symmetric). Its `μ` formula is the mean of `log y`, and `σ` the SD of `log y`:

```julia
yln = exp.(0.5 .+ 0.3 .* x .+ 0.4 .* randn(n))    # log y ~ Normal
fitln = drm(bf(@formula(y ~ x), @formula(sigma ~ 1)), LogNormal(); data = (; y = yln, x))
(intercept = coef(fitln, :mu)[1], sd_logy = exp(coef(fitln, :sigma)[1]))   # ≈ (0.5, 0.4)
```


```ansi
(intercept = 0.49684791157847247, sd_logy = 0.40815372367572883)
```


For positive data with **exact zeros** (biomass, rainfall, total loss), `Tweedie()` adds a point mass at 0. The power `nu` ∈ (1,2) is estimated; `sigma` is the √dispersion (`φ = σ²`):

```julia
function rtw(μi, φ, p)                              # compound Poisson–Gamma draw
    λ = μi^(2 - p) / (φ * (2 - p)); γ = φ * (p - 1) * μi^(p - 1)
    N = rand(Distributions.Poisson(λ))
    N == 0 ? 0.0 : rand(Distributions.Gamma(N * (2 - p) / (p - 1), γ))
end
ytw = [rtw(exp(0.5 + 0.3 * xi), 2.0, 1.5) for xi in x]
fittw = drm(bf(@formula(y ~ x), @formula(sigma ~ 1), @formula(nu ~ 1)), Tweedie(); data = (; y = ytw, x))
(zeros = count(==(0.0), ytw), p = 1 + 1 / (1 + exp(-coef(fittw, :nu)[1])))   # power ≈ 1.5
```


```ansi
(zeros = 822, p = 1.513313291250232)
```


For **ordered categories** (Likert-type ratings, severity classes), `CumulativeLogit()` models `Pr(y ≤ k) = logistic(θ_k − η)` with ordered cutpoints. The response is coded `1, 2, …, K`; the location intercept is dropped (the cutpoints absorb it):

```julia
θo = [-1.0, 0.0, 1.2]; Ko = 4
yo = map(x) do xi
    u = rand(); η = 0.8 * xi; cat = Ko
    for j in 1:(Ko-1)
        (u < 1 / (1 + exp(-(θo[j] - η)))) && (cat = j; break)
    end
    cat
end
fito = drm(bf(@formula(y ~ x)), CumulativeLogit(); data = (; y = Float64.(yo), x))
coef(fito, :mu)[1]      # slope ≈ 0.8
```


```ansi
0.8544359188380164
```


## See also {#See-also}
- [When variance carries signal](../tutorials/location-scale.md) — Gaussian.
  
- [Robust continuous responses](../tutorials/robust-student.md) — Student-t.
  
- [Count abundance and extra zeros](../tutorials/count-nbinom2.md) — Poisson / NB2.
  
- [Proportions and success rates](../tutorials/proportion-beta-binomial.md) — beta.
  
- [What can I fit today?](model-map.md) — the live capability matrix.
  
