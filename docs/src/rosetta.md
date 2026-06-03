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
    The R snippets show drmTMB's grammar (which itself mirrors **brms**). Exact
    family-constructor spellings should be confirmed against your installed
    drmTMB — the parameterisations (e.g. Beta `φ = 1/σ²`) match, but this page is
    maintained from the Julia side.

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
| `Beta()` | `Beta()` | `sigma` (precision `φ = 1/σ²`) |
| `beta_binomial()` | `BetaBinomial()` | `sigma` (`φ = 1/σ²`) |
| `binomial()` | `Binomial()` | — (mean only) |
| `Gamma()` | `Gamma()` | `sigma` (CV; shape `α = 1/σ²`) |
| `lognormal()` | `LogNormal()` | `sigma` |
| `zero_one_inflated_beta()` | `ZeroOneBeta()` | `sigma`, `zoi`, `coi` |
| `tweedie()` | `Tweedie()` | `sigma` (`φ`), `nu` (power `p`) |
| `cumulative()` | `CumulativeLogit()` | — (ordered cutpoints) |

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
bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~ x, sigma2 = ~ 1, rho12 = ~ 1)
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
| `confint(fit, method = "profile")` | `confint(fit; method = :profile)` |
| parametric bootstrap CIs | `bootstrap_ci(bf(...), Family(); data, B = 300)` |
| `logLik(fit)` | `loglik(fit)` |
| `AIC(fit)` / `BIC(fit)` | `aic(fit)` / `bic(fit)` |
| `nobs(fit)` | `nobs(fit)` |
| `ranef(fit)` | `ranef(fit)` |
| random-effect SDs | `re_sd(fit)` / `vc(fit)` |
| fitted scale `σ` | `sigma(fit)` |
| `fitted(fit)` / `residuals(fit)` | `fitted(fit)` / `residuals(fit)` |
| `predict(fit, newdata)` | `predict(fit, newdata)` |
| `simulate(fit)` | `simulate(fit)` |
| `summary(fit)` | `show(fit)` / `coeftable(fit)` (no `summary` method) |
| `family(fit)` | `family(fit)` |
| convergence diagnostics | `check_drm(fit)` |

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
