---
layout: home

hero:
  name: "DRM.jl"
  text: "Distributional regression in Julia"
  tagline: "The Julian twin of drmTMB — put predictors on every parameter of the response: the mean μ, the scale σ, the shape, and the residual correlation ρ12, each with its own formula."
  actions:
    - theme: brand
      text: Get started
      link: /get-started
    - theme: alt
      text: What can I fit today?
      link: /model-guides/model-map
    - theme: alt
      text: View on GitHub
      link: https://github.com/itchyshin/DRM.jl

features:
  - title: "A formula per parameter"
    details: "Model the mean μ, the residual scale σ, the shape, and — for two responses — the residual correlation ρ12, each with its own formula. The same bf() grammar as drmTMB and brms: variability and coupling become signal, not nuisance."
  - title: "Thirteen families, GLMMs, structured effects"
    details: "Gaussian, Student-t, Poisson, negative-binomial, Beta, beta-binomial, Binomial, Gamma, LogNormal, Tweedie, zero-one-beta and cumulative-logit — with zero-inflation and hurdle modifiers. Random effects (intercept, slope, correlated, crossed) and phylogenetic, spatial, animal and relmat structure."
  - title: "A fast engine"
    details: "drmTMB's headline q=4 phylogenetic bivariate location–scale model fits in 1.14 s — 2.18× faster than drmTMB, near-linear O(p) to 10,000 species, with valid intervals where drmTMB's Hessian is singular."
  - title: "Built for R users"
    details: "A true twin: the same families and articles, plus a planned R↔Julia bridge to call DRM.jl from R. MIT-licensed — fresh code, never a port of drmTMB's GPL source."
---

## Fit your first model

```julia
using DRM

# y varies in BOTH its mean and its spread with x:
fit = drm(bf(@formula(y ~ x), @formula(sigma ~ x)), Gaussian(); data = dat)

coef(fit, :mu)      # mean coefficients
coef(fit, :sigma)   # coefficients on log σ — how the spread changes with x
summary(fit)        # readable coefficient table
```

The formula bundle `bf(...)` (alias `drm_formula(...)`) reads exactly like drmTMB
and brms: one formula per distributional parameter. See
[Get started](/get-started) for a worked, runnable example, or
[What can I fit today?](/model-guides/model-map) for the live capability matrix —
every page carries an honest status tag; we don't oversell.

## Why a Julian twin?

drmTMB's selling-point model — the q=4 phylogenetic bivariate location–scale
model, where a shared phylogenetic effect drives `(μ1, μ2, log σ1, log σ2)` — has
no closed-form marginal and needs a Laplace approximation. brms/Stan: ~122 h;
drmTMB (R/TMB): ~2.5 s at p=100. **DRM.jl: 1.14 s (2.18× faster), near-linear
O(p) to p=10,000, with valid confidence intervals where drmTMB's Hessian is
singular.** A fast engine makes the bootstrap / coverage / power studies that
were bottlenecked by R/TMB cheap.

## For R users

DRM.jl is a true twin: the same `bf()` grammar, the same families, the same
articles. A planned [R↔Julia bridge](/r-julia-bridge) will let you call it from R
via `drmTMB(formula, ..., engine = "julia")`, and the [Rosetta page](/rosetta)
shows the same model side by side in both languages.

---

*MIT licensed. A sister package to [drmTMB](https://itchyshin.github.io/drmTMB/)
(GPL) and [GLLVM.jl](https://itchyshin.github.io/GLLVM.jl). DRM.jl is fresh code —
never a port of drmTMB's GPL source.*
