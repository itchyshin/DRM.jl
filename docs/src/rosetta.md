# Rosetta — R ↔ Julia

DRM.jl is the Julia twin of [drmTMB](https://itchyshin.github.io/drmTMB/), so the
modelling grammar is intentionally parallel: the same `bf()` formula bundle, the
same distributional-parameter names, the same structured-effect markers. This
page is a side-by-side phrasebook for translating a drmTMB (R) call into DRM.jl
(Julia).

Three differences cover almost everything:

| | drmTMB (R) | DRM.jl (Julia) |
|---|---|---|
| **Fit verb** | `drmTMB(bf(...), family = ...)` | `drm(bf(...), Family(); data = ...)` |
| **Family** | lower-case function — `gaussian()` | capitalised struct — `Gaussian()` |
| **Scale parameter** | `sigma` | `sigma` (never `tau`) |

!!! note "On the R column"
    The R snippets show drmTMB's grammar (which itself mirrors **brms**). The
    family-constructor and S3 method spellings here were reconciled (2026-06-03)
    against the verified drmTMB `NAMESPACE` (see
    `docs/dev-log/decisions/2026-06-03-drmtmb-api-snapshot.md`); the
    parameterisations (e.g. Beta `φ = 1/σ²`) match. drmTMB reuses the base-R
    `stats` families (`gaussian()`, `poisson()`, `Gamma()`, `binomial()`) rather
    than redefining them. This page is maintained from the Julia side.

## The fit call

```r
# R — drmTMB
fit <- drmTMB(bf(y ~ x, sigma ~ x), family = gaussian(), data = dat)
```

```julia
# Julia — DRM.jl
fit = drm(bf(@formula(y ~ x), @formula(sigma ~ x)), Gaussian(); data = dat)
```

`bf()` keeps the same shape in both: the first formula's left-hand side is the
response and its `μ` predictor; each later `param ~ …` formula sets that
distributional parameter (`sigma` defaults to `~ 1`).

## Families

| drmTMB (R) | DRM.jl (Julia) | extra parameters |
|---|---|---|
| `gaussian()` | `Gaussian()` | `sigma` |
| `student()` | `Student()` | `sigma`, `nu` |
| `poisson()` | `Poisson()` | — (mean only; `zi`, `hu`) |
| `nbinom2()` | `NegBinomial2()` | `sigma` (dispersion θ); `zi`, `hu` |
| `truncated_nbinom2()` | `TruncatedNegBinomial2()` | `sigma` |
| `beta()` | `Beta()` | `sigma` (precision `φ = 1/σ²`) |
| `beta_binomial()` | `BetaBinomial()` | `sigma` (`φ = 1/σ²`) |
| `binomial()` | `Binomial()` | — (mean only) |
| `Gamma()` | `Gamma()` | `sigma` (CV; shape `α = 1/σ²`) |
| `lognormal()` | `LogNormal()` | `sigma` |
| `zero_one_beta()` | `ZeroOneBeta()` | `sigma`, `zoi`, `coi` |
| `tweedie()` | `Tweedie()` | `sigma` (`φ`), `nu` (power `p`) |
| `cumulative_logit()` | `CumulativeLogit()` | — (ordered cutpoints) |
| `biv_gaussian()` | `Gaussian()` + `bf(mu1=…, mu2=…, rho12=…)` | `sigma1`, `sigma2`, `rho12` |

## Formula grammar

| Intent | drmTMB (R) | DRM.jl (Julia) |
|---|---|---|
| Mean + scale | `bf(y ~ x, sigma ~ x)` | `bf(@formula(y ~ x), @formula(sigma ~ x))` |
| Extra parameter | `bf(y ~ x, sigma ~ 1, nu ~ 1)` | `bf(@formula(y ~ x), @formula(sigma ~ 1), @formula(nu ~ 1))` |
| Random intercept | `y ~ x + (1 \| g)` | `@formula(y ~ x + (1 \| g))` |
| Random slope | `y ~ x + (1 + x \| g)` | `@formula(y ~ x + (1 + x \| g))` |
| Crossed REs | `y ~ x + (1 \| g) + (1 \| h)` | `@formula(y ~ x + (1 \| g) + (1 \| h))` |
| Two-column response | `cbind(s, f) ~ x` | `@formula(cbind(s, f) ~ x)` |
| Zero-inflation | `bf(y ~ x, zi ~ 1)` | `bf(@formula(y ~ x), @formula(zi ~ 1))` |
| Hurdle | `bf(y ~ x, hu ~ 1)` | `bf(@formula(y ~ x), @formula(hu ~ 1))` |

### Bivariate (two responses + residual correlation)

```r
# R — drmTMB
drmTMB(bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~ x, sigma2 = ~ 1, rho12 = ~ 1),
       family = biv_gaussian(), data = dat)
```

```julia
# Julia — DRM.jl  (keyword form; ρ12 is the residual correlation, on atanh ρ12)
bf(mu1 = @formula(y1 ~ x), mu2 = @formula(y2 ~ x),
   sigma1 = @formula(sigma1 ~ x), sigma2 = @formula(sigma2 ~ 1),
   rho12 = @formula(rho12 ~ 1))
```

### Structured effects & meta-analysis

| Intent | drmTMB (R) | DRM.jl (Julia) |
|---|---|---|
| Relatedness matrix | `y ~ x + relmat(1 \| id)`, `K = K` | `@formula(y ~ x + relmat(1 \| id))`, `K = K` |
| Animal model | `y ~ x + animal(1 \| id)`, `A = A` | `@formula(y ~ x + animal(1 \| id))`, `A = A` |
| Phylogenetic | `y ~ x + phylo(1 \| species)`, `tree = tree` | `@formula(y ~ x + phylo(1 \| species))`, `tree = tree` |
| Spatial | `y ~ x + spatial(1 \| site)`, `coords = xy` | `@formula(y ~ x + spatial(1 \| site))`, `coords = xy` |
| Meta-analysis | `gaussian()` + `meta_V(v)` | `Gaussian()` + `meta_V(v)` |

## Post-fit accessors

| drmTMB (R) | DRM.jl (Julia) |
|---|---|
| `coef(fit)` / `fixef(fit)` | `coef(fit)` / `fixef(fit)` |
| `vcov(fit)` | `vcov(fit)` |
| `confint(fit, method = "wald")` | `confint(fit; method = :wald)` |
| `confint(fit, method = "profile")` / `profile(fit)` | `confint(fit; method = :profile)` |
| parametric bootstrap CIs | `bootstrap_ci(bf(...), Family(); data, B = 300)` |
| `logLik(fit)` | `loglik(fit)` |
| `AIC(fit)` / `BIC(fit)` | `aic(fit)` / `bic(fit)` |
| `nobs(fit)` | `nobs(fit)` |
| `deviance(fit)` | planned (parity gap) |
| `df.residual(fit)` | planned (parity gap) |
| `ranef(fit)` | `ranef(fit)` |
| random-effect SDs | `re_sd(fit)` / `vc(fit)` |
| `sigma(fit)` | `sigma(fit)` |
| `rho12(fit)` | planned (parity gap) |
| `corpair(fit)` / `corpairs(fit)` | `corpairs(fit)` / `corpairs_data(fit)` |
| `fitted(fit)` / `residuals(fit)` | `fitted(fit)` / `residuals(fit)` |
| `predict(fit, newdata)` | `predict(fit, newdata)` |
| `predict_parameters(fit, newdata)` | planned (parity gap) |
| `marginal_parameters(fit)` | planned (parity gap) |
| `prediction_grid(...)` | planned (parity gap) |
| `simulate(fit)` | `simulate(fit)` |
| `summary(fit)` | `show(fit)` / `coeftable(fit)` (no `summary` method; parity gap) |
| `weights(fit)` | planned (parity gap) |
| `family(fit)` | planned (parity gap) |
| `is_converged(fit)` / `check_drm(fit)` | `check_drm(fit)` (`is_converged`: parity gap) |

## Naming rules to remember

- **Scale is `sigma`, never `tau`.** `bf(y ~ x, tau ~ x)` is rejected — use
  `sigma`. (Group-level phylo/spatial/study variances are reported as named
  covariance summaries, not as a residual scale.)
- **`rho12` is the bivariate *residual* correlation** between the two responses
  (on the `atanh` scale). It is only valid in the keyword `bf(mu1 = …, mu2 = …,
  rho12 = …)` form — not as a univariate parameter.
- **ML is the default.** REML is an option (the likelihoods are not comparable
  across different fixed-effect structures, so ML is used for model selection).

See also the [R ↔ Julia bridge](r-julia-bridge.md) for the planned
`drmTMB(..., engine = "julia")` round-trip via JuliaCall.
