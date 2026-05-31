# Choosing response families

!!! note "Status — Stable"
    Mirrors drmTMB's [Choosing response families](https://itchyshin.github.io/drmTMB/articles/distribution-families.html).
    **In DRM.jl today:** Gaussian, Student-t, LogNormal, Gamma, Poisson,
    negative-binomial (NB2) + truncated, beta, beta-binomial,
    zero-one-inflated beta, and Tweedie — plus the `zi` / `hu` count modifiers.
    Remaining: `cumulative_logit` (ordinal) — Phase 2.

Pick the family from the *shape* of your response, then give each of its
parameters a formula with `bf`.

| Response looks like… | Family | Mean link | Second parameter (`sigma` slot) |
|---|---|---|---|
| Real-valued, symmetric | `Gaussian()` | identity | residual SD `σ` (log) |
| Real-valued, heavy tails / outliers | `Student()` | identity | scale `σ` (log) + d.o.f. `nu` |
| Strictly positive, continuous | `Gamma()` | log | shape `α = 1/σ²` |
| Positive **with exact zeros** | `Tweedie()` | log | √dispersion `σ` + power `nu` ∈ (1,2) |
| Strictly positive, right-skewed (multiplicative) | `LogNormal()` | identity on `log y` | SD of `log y`, `σ` (log) |
| Counts (variance ≈ mean) | `Poisson()` | log | — |
| Counts, overdispersed | `NegBinomial2()` | log | dispersion `θ` (log) |
| Counts with extra zeros | + `zi ~ …` modifier | logit on `π` | (on `Poisson` / `NegBinomial2`) |
| Proportions in (0,1) | `Beta()` | logit | precision `φ = 1/σ²` |
| Successes out of trials | `BetaBinomial()` | logit | overdispersion `φ = 1/σ²` (`cbind(s,f)`) |
| Proportions on `[0,1]` incl. 0 and 1 | `ZeroOneBeta()` | logit | `φ = 1/σ²` + `zoi` / `coi` |

Each family's `sigma` slot is its natural dispersion handle — the same
`sigma ~ …` formula machinery, with a family-specific link/mapping.

## Example: a Gamma model for positive data

`Gamma()` suits durations, sizes, and concentrations — strictly positive and
right-skewed. The mean uses a log link; the `sigma` slot is the **coefficient of
variation**, mapped to the shape `α = 1/σ²`:

```@example fam
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

```@example fam
exp(-2 * coef(fit, :sigma)[1])   # recovered shape α = 1/σ² (≈ 8)
```

`LogNormal()` is the other positive-continuous option — use it when the data are
*multiplicative* (the log is symmetric). Its `μ` formula is the mean of `log y`,
and `σ` the SD of `log y`:

```@example fam
yln = exp.(0.5 .+ 0.3 .* x .+ 0.4 .* randn(n))    # log y ~ Normal
fitln = drm(bf(@formula(y ~ x), @formula(sigma ~ 1)), LogNormal(); data = (; y = yln, x))
(intercept = coef(fitln, :mu)[1], sd_logy = exp(coef(fitln, :sigma)[1]))   # ≈ (0.5, 0.4)
```

For positive data with **exact zeros** (biomass, rainfall, total loss),
`Tweedie()` adds a point mass at 0. The power `nu` ∈ (1,2) is estimated; `sigma`
is the √dispersion (`φ = σ²`):

```@example fam
function rtw(μi, φ, p)                              # compound Poisson–Gamma draw
    λ = μi^(2 - p) / (φ * (2 - p)); γ = φ * (p - 1) * μi^(p - 1)
    N = rand(Distributions.Poisson(λ))
    N == 0 ? 0.0 : rand(Distributions.Gamma(N * (2 - p) / (p - 1), γ))
end
ytw = [rtw(exp(0.5 + 0.3 * xi), 2.0, 1.5) for xi in x]
fittw = drm(bf(@formula(y ~ x), @formula(sigma ~ 1), @formula(nu ~ 1)), Tweedie(); data = (; y = ytw, x))
(zeros = count(==(0.0), ytw), p = 1 + 1 / (1 + exp(-coef(fittw, :nu)[1])))   # power ≈ 1.5
```

## See also

- [When variance carries signal](../tutorials/location-scale.md) — Gaussian.
- [Robust continuous responses](../tutorials/robust-student.md) — Student-t.
- [Count abundance and extra zeros](../tutorials/count-nbinom2.md) — Poisson / NB2.
- [Proportions and success rates](../tutorials/proportion-beta-binomial.md) — beta.
- [What can I fit today?](model-map.md) — the live capability matrix.
