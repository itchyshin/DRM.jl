# DRM.jl

*Fast **distributional regression** in Julia — a twin of the R package
[drmTMB](https://itchyshin.github.io/drmTMB/).*

DRM.jl fits regression models for one or two responses in which predictors act
on **every** parameter of the response distribution, not just the mean. Each
distributional parameter — the mean **μ**, the residual scale **σ**, and (for two
responses) the residual correlation **ρ12** — gets its own formula. Use it when
variability or coupling is part of the science, not a nuisance.

## Fit your first model

```julia
using DRM

# y varies in BOTH its mean and its spread with x:
fit = drm(bf(@formula(y ~ x), @formula(sigma ~ x)), Gaussian(); data = dat)

coef(fit, :mu)      # mean coefficients
coef(fit, :sigma)   # coefficients on log σ — how the spread changes with x
loglik(fit)
```

The formula bundle `bf(...)` (alias `drm_formula(...)`) reads exactly like
drmTMB and brms: one formula per distributional parameter. See
[Get started](get-started.md) for a worked, runnable example.

## What you can fit today

| Surface | Status |
|---|---|
| Univariate Gaussian **location–scale** (`μ`, `σ`), fixed effects | **Stable** — ML fit, Wald covariance |
| Bivariate Gaussian **q=4 phylogenetic** location–scale (the engine headline) | **Verified** — 2.18× faster than drmTMB, O(p) to p=10,000 |
| `bf()` for bivariate `ρ12`, ordinary & structured random effects, more families | **Landing slice by slice** — see [What can I fit today?](model-guides/model-map.md) |

The full capability map mirrors drmTMB's, with every page carrying an honest
status tag (*Stable / First slice / Opt-in control / Planned*). We don't oversell:
if a surface isn't fitted yet, the page says so.

## Why a Julia twin?

drmTMB's selling-point model — the q=4 phylogenetic bivariate location–scale
model, where a shared phylogenetic effect drives `(μ1, μ2, log σ1, log σ2)` — has
no closed-form marginal and needs a Laplace approximation. brms/Stan: ~122 h.
drmTMB (R/TMB): ~2.5 s at p=100. **DRM.jl: 1.14 s (2.18× faster), near-linear
O(p) to p=10,000, with valid confidence intervals where drmTMB's Hessian is
singular.** A fast engine makes the bootstrap / coverage / power studies that
were bottlenecked by R/TMB cheap.

## For R users

DRM.jl is a true twin: the same `bf()` grammar, the same families, the same
articles. A planned [R↔Julia bridge](r-julia-bridge.md) will let you call it from
R via `drmTMB(formula, ..., engine = "julia")`, and the [Rosetta page](rosetta.md)
shows the same model side by side in both languages.

## Start here

- New to distributional regression? **[Get started](get-started.md)**.
- Want the full status map? **[What can I fit today?](model-guides/model-map.md)**
- Modelling the mean *and* the variance? **[When variance carries signal](tutorials/location-scale.md)**.
- Building the package? The [team & roadmap](https://github.com/itchyshin/DRM.jl/blob/main/AGENTS.md).

!!! note "Pre-release (v0.1.0-DEV)"
    The public API is stabilising as the Gaussian surface is completed; see the
    [roadmap](https://github.com/itchyshin/DRM.jl/blob/main/ROADMAP.md).

---

*MIT licensed. A sister package to [drmTMB](https://itchyshin.github.io/drmTMB/)
(GPL) and [GLLVM.jl](https://github.com/itchyshin/GLLVM.jl). DRM.jl is fresh
code — never a port of drmTMB's GPL source.*
