# Proportions and success rates

!!! note "Status — First slice (beta)"
    Mirrors drmTMB's [Proportions and success rates](https://itchyshin.github.io/drmTMB/articles/proportion-beta-binomial.html).
    **In DRM.jl today:** the **beta** family `Beta()` for continuous proportions
    in `(0,1)`. The beta-binomial family for count-of-successes data is a later
    Phase-2 slice.

Proportions, rates, and probabilities live on `(0,1)` — bounded at both ends, so
a Gaussian model can predict impossible values. The **beta** family models the
mean on the logit scale and a precision separately.

## A beta regression

The mean uses a logit link; the `sigma` slot carries the dispersion, mapped to
the beta **precision** `φ = 1/σ²` (drmTMB's convention) — larger `φ` means tighter
spread around the mean:

```@example beta
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

The slope is a **log odds ratio** on the mean proportion; recover the precision
from the `sigma` coefficient:

```@example beta
exp(-2 * coef(fit, :sigma)[1])     # precision φ = 1/σ² (≈ 15)
```

Fitted values come back as proportions on `(0,1)`:

```@example beta
extrema(fitted(fit))
```

!!! tip "Precision, not SD"
    The `sigma` slot is a dispersion handle: `φ = 1/σ²`. A large `φ` (small `σ`)
    means observations hug the mean; a small `φ` means they spread toward 0 and 1.

## See also

- [Choosing response families](../model-guides/distribution-families.md).
- [What can I fit today?](../model-guides/model-map.md) — the family/feature matrix.
