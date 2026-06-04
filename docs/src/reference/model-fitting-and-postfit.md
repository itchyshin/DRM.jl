# Model fitting and post-fit tools

!!! note "Status — Reference"
    Mirrors drmTMB's [Model fitting and post-fit tools](https://itchyshin.github.io/drmTMB/reference/index.html) (23 in drmTMB). The fitting verb is [`drm`](@ref); the post-fit accessors below cover coefficients, fitted scale / correlation, random-effect estimates, predictions, simulation, inference, and convergence diagnostics.

## Fitting

```@docs
drm
DrmFit
```

## Coefficients and (co)variance

```@docs
fixef
re_sd
vc
coeftable
coef
vcov
nobs
```

## Fitted scale and correlation

```@docs
sigma
corpairs
rho12
```

## Random-effect estimates

```@docs
ranef
```

## Prediction and simulation

```@docs
predict
predict_parameters
marginal_parameters
simulate
fitted
residuals
```

### Predicting distributional parameters

[`predict`](@ref) returns the response (mean) prediction, but a distributional
regression also models the scale and—bivariately—the correlation. Use
[`predict_parameters`](@ref) to obtain the population-level value of **every**
distributional parameter the model carries (`:mu`, `:sigma`, plus any family
extras) at new covariate values, with random / structured effects integrated
out. [`marginal_parameters`](@ref) is the cheap in-sample accessor that reads the
fitted per-observation parameters straight off the fit.

```julia
using DRM, Random
Random.seed!(20260603)

x = randn(500)
y = 0.5 .- 0.8 .* x .+ exp.(-0.3 .+ 0.4 .* x) .* randn(500)
data = (; y, x)

# Gaussian location–scale fit: both μ and σ depend on x.
fit = drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1 + x)), Gaussian(); data = data)

# Per-distributional-parameter prediction over a covariate sweep.
grid = (; x = collect(range(-2, 2; length = 11)))
p = predict_parameters(fit, grid)   # Dict(:mu => …, :sigma => …) on the response scale
p[:mu]                              # predicted mean across the sweep
p[:sigma]                          # predicted scale across the sweep

# Working (link) scale instead: returns Xβ̂ per parameter.
predict_parameters(fit, grid; type = :link)[:mu]

# In-sample fitted parameters, straight off the fit (no recomputation).
marginal_parameters(fit)            # == predict_parameters(fit, data) in-sample
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

## Diagnostics and accessors

```@docs
check_drm
family
is_converged
deviance
dof_residual
```
