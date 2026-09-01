```@raw html
---
layout: home

hero:
  name: "DRM.jl"
  text: "Distributional regression in Julia"
  tagline: "Model more than the mean: use separate formulas for location, scale, shape, boundary probabilities, and correlation in Julia."
  actions:
    - theme: brand
      text: Get started
      link: /getting-started
    - theme: alt
      text: What can I fit today?
      link: /model-guides/model-map
    - theme: alt
      text: View on GitHub
      link: https://github.com/itchyshin/DRM.jl

features:
  - title: "A formula per parameter"
    details: "Use bf() to bundle the formulas your selected family accepts, so mean, scale, and other distributional effects can be modelled separately."
  - title: "Families and structured effects"
    details: "Fit continuous, count, binary, and proportion responses, with random effects and phylogenetic, spatial, pedigree, or supplied-matrix structure. Check the capability matrix for supported combinations."
  - title: "Sparse phylogenetic models"
    details: "Work with tree-structured models through sparse Julia solvers. Profile likelihood and parametric bootstrap support inference on the documented routes; performance depends on the model and data."
  - title: "Built for R users"
    details: "The optional R bridge is available for its admitted model cells through drmTMB(..., engine = \"julia\"); the default R engine remains TMB. MIT-licensed fresh code, never a port of drmTMB's GPL source."
---
```

## Fit your first model

Given a table `dat` with numeric columns `y` and `x`, fit a location–scale
model as below. [Get started](getting-started.md) includes the complete data
setup and a runnable example.

```julia
using DRM

# y varies in BOTH its mean and its spread with x:
fit = drm(bf(@formula(y ~ x), @formula(sigma ~ x)), Gaussian(); data = dat)

coef(fit, :mu)      # mean coefficients
coef(fit, :sigma)   # coefficients on log σ — how the spread changes with x
summary(fit)        # readable coefficient table
```

The formula bundle `bf(...)` (alias `drm_formula(...)`) collects one formula per
available distributional parameter. See [Get started](getting-started.md) for a
worked, runnable example, or [What can I fit today?](model-guides/model-map.md)
for the model-space guide and its route-specific boundaries.

## Why use the Julia workflow?

DRM.jl gives you a direct Julia route for models whose mean and distributional
parameters need separate predictors. Use the [capability matrix](capabilities.md)
to choose a supported family and structure, and the
[diagnostics and validation guides](diagnostics-and-validation/testing-likelihoods.md)
to see how that route is checked. Performance and inference evidence are specific
to the fitted model and its data; they are not a general promise for every model.

## For R users

The optional [R ↔ Julia bridge](r-julia-bridge.md) already lets supported
`drmTMB(...)` calls use `engine = "julia"`; its page lists the admitted fixtures,
formula translations, and explicit refusals. The default R route remains
`engine = "tmb"` and does not require Julia. For direct Julia use, the
[Rosetta page](rosetta.md) compares the two syntaxes side by side.

---

*MIT licensed. A sister package to [drmTMB](https://itchyshin.github.io/drmTMB/)
(GPL) and [GLLVM.jl](https://itchyshin.github.io/GLLVM.jl). DRM.jl is fresh code —
never a port of drmTMB's GPL source.*
