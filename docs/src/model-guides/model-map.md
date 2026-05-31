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
| **Wald** inference (`stderror`, `confint`) | **Stable** | on every fitted model above |
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
| Parametric **bootstrap** intervals (`bootstrap_ci`) | **Stable** | simulate + refit percentiles |
| `predict` (new data, population level) | **Stable** | `Xβ̂` on new rows |
| Profile intervals (#38); `σ` random effects (#40, Laplace) | **Planned** | — |
| Non-Gaussian families (Student, Gamma, beta, Poisson, NB2, …) | **Planned** | Phase 2 |

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
```

## Where to go next

- [Get started](../get-started.md) · [Which scale?](which-scale.md)
- [When variance carries signal](../tutorials/location-scale.md) ·
  [Changing residual coupling with rho12](../tutorials/bivariate-coscale.md)
- [Checking and using fitted models](model-workflow.md) — Wald intervals.
- The [roadmap](https://github.com/itchyshin/DRM.jl/blob/main/ROADMAP.md) for what's next.
