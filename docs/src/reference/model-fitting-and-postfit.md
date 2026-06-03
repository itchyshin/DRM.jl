# Model fitting and post-fit tools

!!! note "Status — Reference"
    Mirrors drmTMB's [Model fitting and post-fit tools](https://itchyshin.github.io/drmTMB/reference/index.html) (23 in drmTMB). The fitting verb is [`drm`](@ref); the post-fit accessors below cover coefficients, fitted scale / correlation, random-effect estimates, predictions, simulation, inference, and convergence diagnostics.

## Fitting

```@docs
drm
```

<!-- `DrmFit` is documented once `coef`/`vcov`/`nobs` gain docstrings — its
docstring cross-references them via `@ref`, which are dead links until then. -->

## Coefficients and (co)variance

```@docs
fixef
re_sd
vc
coeftable
```

## Fitted scale and correlation

```@docs
sigma
corpairs
```

## Random-effect estimates

```@docs
ranef
```

## Prediction and simulation

```@docs
predict
simulate
fitted
residuals
```

## Inference

```@docs
confint
stderror
profile_result
bootstrap_ci
bootstrap_summary
bootstrap_result
```

## Information criteria

```@docs
loglik
dof
aic
bic
```

## Diagnostics

```@docs
check_drm
```
