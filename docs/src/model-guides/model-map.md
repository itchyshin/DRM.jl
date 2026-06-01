# What can I fit today?

!!! note "Status — the live capability map"
    Mirrors drmTMB's [What can I fit today?](https://itchyshin.github.io/drmTMB/articles/model-map.html).
    This page is the honest status map for **DRM.jl**: what is fitted today,
    what is the verified engine, and what is planned. It is updated as each
    slice merges.

DRM.jl is building toward drmTMB's full surface, Gaussian first. The design rule
is the same: **one formula per distributional parameter**.

## Status words

- **Stable** — a routine fitted path with a recovery test and a runnable example.
- **Verified engine** — a benchmarked, tested engine exists; its public `bf()`
  front end is still being wired.
- **Planned** — public grammar may exist on this site, but `drm()` does not fit
  it yet.

## Gaussian capability matrix

| Surface | Status | Fitted today |
|---|---|---|
| Univariate location–scale (`μ`, `σ`), fixed effects | **Stable** | `drm(bf(y ~ x, sigma ~ x), Gaussian())` — ML, recovery-tested |
| Bivariate location–scale + residual `rho12`, fixed effects | **Stable** | `bf(mu1=…, mu2=…, sigma1=…, sigma2=…, rho12=…)` — 2D normal, tanh link on ρ12 |
| Ordinary **random intercept** `(1 \| g)` on the mean | **Stable** | closed-form Gaussian marginal; `re_sd(fit)` for the group SD |
| **Wald** + **profile-likelihood** inference (`confint(fit; method = :wald \| :profile)`) | **Stable** | `stderror`; profile inverts the LR statistic; on every fitted model above |
| q=4 **phylogenetic** bivariate location–scale | **Verified engine** | 2.18× over drmTMB, O(p) to p=10,000 (`HANDOVER.md`); public `phylo()` front end planned |
| Independent random **slope** `(0 + x \| g)` on the mean | **Stable** | closed-form marginal; `re_sd` |
| Correlated random slope `(1 + x \| g)` | **Stable** | 2×2 block marginal; `vc(fit)` |
| Multiple RE terms `(1 \| g) + (1 \| h)` (crossed / nested) on the mean | **Stable** | whitened-Woodbury dense capacitance; `re_sd(fit)` per grouping |
| `relmat(1 \| id)` structured effect (supplied `K`) on the mean | **Stable** | closed-form GLS; `re_sd` |
| `animal(1 \| id)` (pedigree `A`) / `phylo(1 \| species)` (tree) on the mean | **Stable** | closed-form GLS via the `relmat` engine |
| `spatial(1 \| site)` structured effect (coords + estimated range) | **Stable** | exponential kernel `exp(-d/ρ)`, closed-form GLS |
| Known sampling covariance `meta_V(v)` (meta-analysis) | **Stable** | diagonal known variances + estimated heterogeneity τ |
| `fitted` / `residuals` post-fit accessors | **Stable** | on every fitted model |
| `simulate` (parametric replicate) | **Stable** | residual-level draw; bootstrap building block |
| Parametric **bootstrap** intervals (`bootstrap_ci`) | **Stable** | simulate + refit percentiles; Gaussian + **Poisson · NB2 · Beta · Gamma** (constant dispersion); Wald & profile cover all families |
| `predict` (new data; `type = :response` / `:link`) | **Stable** | response-scale mean (family inverse link) or linear predictor `Xβ̂`; in-sample `≈ fitted` |
| `summary(fit)` / `coeftable(fit)` — readable fit + Wald coefficient table | **Stable** | REPL summary (family · nobs · logLik) then a per-block Estimate / Std.Error / z / p table (+ CI from `coeftable`) |
| `aic(fit)` / `bic(fit)` / `dof(fit)` — information criteria | **Stable** | `−2·loglik + 2k` and `+ k·log n` (`k = dof = #params`); ML-based model selection |
| `σ` random effects `sigma ~ … + (1 \| g)` (RE on the scale) | **Stable** | per-group Gauss–Hermite marginal (32 nodes); `re_sd(fit)` for the scale-RE SD |
| Random intercept `(1 \| g)` on a **non-Gaussian** mean — Poisson · NB2 · Beta · Gamma · Student-t · LogNormal · Beta-binomial GLMMs | **Stable** | per-group Gauss–Hermite marginal; `re_sd(fit)` for the group SD |
| Correlated random slope `(1 + x \| g)` on a **non-Gaussian** mean — Poisson · NB2 · Beta · Gamma · Student-t · LogNormal · Beta-binomial | **Stable** | per-group 2-D Gauss–Hermite tensor grid; `vc(fit)` for the 2×2 RE cov |
| **Student-t** family `Student()` — robust location–scale–shape (`μ`, `σ`, `ν`) | **Stable** | `bf(y ~ x, sigma ~ 1, nu ~ 1)`; fixed effects |
| **Poisson** family `Poisson()` — counts, log-link mean | **Stable** | `bf(y ~ x)`; fixed effects |
| **Negative-binomial** `NegBinomial2()` — overdispersed counts (NB2) | **Stable** | `bf(y ~ x, sigma ~ 1)`; `sigma` slot = dispersion θ |
| **Beta** `Beta()` — proportions in (0,1), logit-link mean | **Stable** | `sigma` slot = precision via `φ = 1/σ²` |
| **Beta-binomial** `BetaBinomial()` — successes / trials, `cbind(s, f) ~ …` | **Stable** | logit mean + overdispersion `φ = 1/σ²` |
| **Binomial** `Binomial()` — successes / trials (logistic regression), `cbind(s, f) ~ …` or 0/1 | **Stable** | logit mean, no dispersion; fixed effects + `(1 \| g)` logistic GLMM |
| **Gamma** `Gamma()` — positive continuous, log-link mean | **Stable** | `sigma` slot = CV via shape `α = 1/σ²` |
| **LogNormal** `LogNormal()` — positive, multiplicative (log y Gaussian) | **Stable** | `μ` = mean of `log y`; `σ` = SD of `log y` |
| **`zi`** zero-inflation modifier on counts (ZIP / ZINB) | **Stable** | `bf(y ~ x, zi ~ 1)` with `Poisson()` / `NegBinomial2()` |
| **`hu`** hurdle modifier on counts (hurdle-Poisson / -NB) | **Stable** | `bf(y ~ x, hu ~ 1)`; zero-truncated positive part |
| **Truncated NB2** `TruncatedNegBinomial2()` — positive counts (≥ 1) | **Stable** | `bf(y ~ x, sigma ~ 1)`; `P(k)=NB(k)/(1−NB(0))` |
| **Zero-one-inflated beta** `ZeroOneBeta()` — proportions on `[0,1]` | **Stable** | `mu`/`sigma` + `zoi` (boundary) / `coi` (one) |
| **Tweedie** `Tweedie()` — semicontinuous (positive + exact zeros, `1<p<2`) | **Stable** | `mu`(log) / `sigma`(√dispersion) / `nu`(power); Dunn–Smyth series |
| **Cumulative-logit** `CumulativeLogit()` — ordinal (ordered categories) | **Stable** | `Pr(y≤k)=logistic(θ_k−η)`; K−1 cutpoints |

## Worked, fitted paths

```julia
using DRM

# univariate location–scale
drm(bf(@formula(y ~ x), @formula(sigma ~ x)), Gaussian(); data = dat)

# bivariate with predictor-dependent residual correlation
drm(bf(mu1 = @formula(y1 ~ x), mu2 = @formula(y2 ~ x),
       sigma1 = @formula(sigma1 ~ 1), sigma2 = @formula(sigma2 ~ 1),
       rho12 = @formula(rho12 ~ x)), Gaussian(); data = dat)

# random intercept on the mean
drm(bf(@formula(y ~ x + (1 | g)), @formula(sigma ~ 1)), Gaussian(); data = dat)

# multiple crossed random intercepts — re_sd(fit) returns one SD per grouping
drm(bf(@formula(y ~ x + (1 | g) + (1 | h)), @formula(sigma ~ 1)), Gaussian(); data = dat)

# random effect on the SCALE — group-level dispersion (Gauss–Hermite marginal)
drm(bf(@formula(y ~ x), @formula(sigma ~ 1 + (1 | g))), Gaussian(); data = dat)
```

## Where to go next

- [Get started](../get-started.md) · [Which scale?](which-scale.md)
- [When variance carries signal](../tutorials/location-scale.md) ·
  [Changing residual coupling with rho12](../tutorials/bivariate-coscale.md)
- [Checking and using fitted models](model-workflow.md) — Wald + profile intervals.
- The [roadmap](https://github.com/itchyshin/DRM.jl/blob/main/ROADMAP.md) for what's next.
