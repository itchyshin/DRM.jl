
# Proportions and success rates {#Proportions-and-success-rates}

::: tip Status — Stable (beta + beta-binomial + zero-one-inflated beta)

Mirrors drmTMB's [Proportions and success rates](https://itchyshin.github.io/drmTMB/articles/proportion-beta-binomial.html). **In DRM.jl today:** the **beta** family `Beta()` for continuous proportions in `(0,1)`, the **beta-binomial** family `BetaBinomial()` for counts of successes out of known trials (`cbind(successes, failures) ~ …`), and the **zero-one-inflated beta** `ZeroOneBeta()` for proportions on `[0,1]`.

:::

Proportions, rates, and probabilities live on `(0,1)` — bounded at both ends, so a Gaussian model can predict impossible values. The **beta** family models the mean on the logit scale and a precision separately.

## A beta regression {#A-beta-regression}

The mean uses a logit link; the `sigma` slot carries the dispersion, mapped to the beta **precision** `φ = 1/σ²` (drmTMB's convention) — larger `φ` means tighter spread around the mean:

```julia
using DRM, Random
import Distributions          # `Beta` below is DRM's family; qualify the distribution
Random.seed!(20260617)

n = 3000
x = randn(n)
φ = 15.0
μ = 1 ./ (1 .+ exp.(-(0.3 .+ 0.8 .* x)))         # logit-linear mean
y = Float64.([rand(Distributions.Beta(μi * φ, (1 - μi) * φ)) for μi in μ])
dat = (; y, x)

fit = drm(bf(@formula(y ~ x), @formula(sigma ~ 1)), Beta(); data = dat)
coef(fit, :mu)              # coefficients on the logit-mean
```


```ansi
2-element Vector{Float64}:
 0.29931081535419335
 0.8067298348727054
```


The slope is a **log odds ratio** on the mean proportion; recover the precision from the `sigma` coefficient:

```julia
exp(-2 * coef(fit, :sigma)[1])     # precision φ = 1/σ² (≈ 15)
```


```ansi
14.48158982798246
```


Fitted values come back as proportions on `(0,1)`:

```julia
extrema(fitted(fit))
```


```ansi
(0.07207144265711433, 0.9529190622023357)
```


::: tip Precision, not SD

The `sigma` slot is a dispersion handle: `φ = 1/σ²`. A large `φ` (small `σ`) means observations hug the mean; a small `φ` means they spread toward 0 and 1.

:::

## Successes out of trials: the beta-binomial family {#Successes-out-of-trials:-the-beta-binomial-family}

When the data are **counts of successes out of a known number of trials** (not a continuous proportion), keep the denominator: give a two-column response `cbind(successes, failures)` — exactly as drmTMB — and use `BetaBinomial()`. It adds extra-binomial overdispersion through the same `sigma` precision (`φ = 1/σ²`):

```julia
Random.seed!(20260623)
N = 3000; ntr = fill(25, N)
φbb = 12.0
μbb = 1 ./ (1 .+ exp.(-(0.2 .+ 0.7 .* x)))
succ = [rand(Distributions.BetaBinomial(ntr[i], μbb[i] * φbb, (1 - μbb[i]) * φbb)) for i in 1:N]
datbb = (; s = Float64.(succ), fail = Float64.(ntr .- succ), x)

fitbb = drm(bf(@formula(cbind(s, fail) ~ x), @formula(sigma ~ 1)), BetaBinomial(); data = datbb)
exp(-2 * coef(fitbb, :sigma)[1])     # recovered precision φ (≈ 12)
```


```ansi
11.908086999428692
```


`coef(fitbb, :mu)` is the success probability on the logit scale; ordinary binomial is the no-overdispersion limit (`φ → ∞`).

## Proportions that hit 0 or 1: zero-one-inflated beta {#Proportions-that-hit-0-or-1:-zero-one-inflated-beta}

A plain beta lives on the _open_ `(0,1)` — it cannot represent an exact 0 or 1. When the data pile up at the boundaries (none-detected, all-detected), `ZeroOneBeta()` adds two logit parameters: `zoi` = P(the value is a boundary) and `coi` = P(it is 1, given a boundary). The interior is the usual `Beta(μ, φ)`:

```julia
Random.seed!(20260624)
zoi = 0.25; coi = 0.4; φz = 12.0
μz = 1 ./ (1 .+ exp.(-(0.2 .+ 0.6 .* x)))
yz = map(μi -> rand() < zoi ? (rand() < coi ? 1.0 : 0.0) :
                rand(Distributions.Beta(μi * φz, (1 - μi) * φz)), μz)
datz = (; y = yz, x)

fitz = drm(bf(@formula(y ~ x), @formula(sigma ~ 1), @formula(zoi ~ 1), @formula(coi ~ 1)),
    ZeroOneBeta(); data = datz)
(zoi = 1 / (1 + exp(-coef(fitz, :zoi)[1])),     # recovered P(boundary) ≈ 0.25
 coi = 1 / (1 + exp(-coef(fitz, :coi)[1])))     # recovered P(1 | boundary) ≈ 0.40
```


```ansi
(zoi = 0.24300000000000027, coi = 0.41289437585733885)
```


`fitted(fitz)` returns the unconditional mean `(1 - zoi)·μ + zoi·coi`.

## See also {#See-also}
- [Choosing response families](../model-guides/distribution-families.md).
  
- [What can I fit today?](../model-guides/model-map.md) — the family/feature matrix.
  
