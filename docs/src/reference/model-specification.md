# Model specification

!!! note "Status — Reference"
    Mirrors drmTMB's [Model specification](https://itchyshin.github.io/drmTMB/reference/index.html) (13 items in drmTMB). A model is one [`bf`](@ref) formula bundle (one linear predictor per distributional parameter) plus a response family. All 13 drmTMB families are available.

## Formula bundle

```@docs
bf
DrmFormula
BivariateDrmFormula
```

## Response families

```@docs
Gaussian
Student
Poisson
NegBinomial2
TruncatedNegBinomial2
Beta
BetaBinomial
Binomial
Gamma
LogNormal
ZeroOneBeta
Tweedie
CumulativeLogit
```

## Advanced family type

`SkewNormal` is a Julia family type with its own docstring. Its presence here
does not widen the supported-model matrix; consult the capability matrix before
selecting a family and structure.

The source docstring below uses a shorthand formula sketch. For a call with
prepared data `dat`, use explicit Julia formula objects:

```julia
fit = drm(bf(@formula(y ~ x), @formula(sigma ~ 1), @formula(nu ~ 1)),
          SkewNormal(); data = dat)
```

```@docs
SkewNormal
```

## Two-column response

```@docs
cbind
```
