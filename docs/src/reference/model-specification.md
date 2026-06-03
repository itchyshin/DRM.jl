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

## Two-column response

```@docs
cbind
```
