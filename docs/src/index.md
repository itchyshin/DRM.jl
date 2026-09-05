```@raw html
---
layout: home

hero:
  name: "DRM.jl"
  text: "Distributional regression, with each parameter in view"
  tagline: "A Julia workflow for models in which covariates can affect the mean, spread, shape, boundary probabilities, or residual correlation."
  image:
    src: /logo.svg
    alt: "DRM.jl convergence mark: three distributional parameter paths join at a fitted distribution"
  actions:
    - theme: brand
      text: Fit your first model
      link: /getting-started
    - theme: alt
      text: See the model map
      link: /model-guides/model-map
    - theme: alt
      text: Evidence & limits
      link: /capabilities
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

```@raw html
<div class="drm-reader-journey" aria-label="Choose your DRM.jl starting point">
  <a class="drm-route-card drm-route-card--fit" href="/getting-started">
    <span class="drm-route-card__eyebrow">01 · First model</span>
    <strong>Mean and spread can both vary.</strong>
    <span>Start with a Gaussian location–scale model and read each coefficient block on its own scale.</span>
  </a>
  <a class="drm-route-card drm-route-card--map" href="/model-guides/model-map">
    <span class="drm-route-card__eyebrow">02 · Choose honestly</span>
    <strong>Find the model cell you can fit today.</strong>
    <span>The model map distinguishes tested routes, partial routes, experimental work, and absences.</span>
  </a>
  <a class="drm-route-card drm-route-card--evidence" href="/capabilities">
    <span class="drm-route-card__eyebrow">03 · Check the evidence</span>
    <strong>Match the claim to the route.</strong>
    <span>Every capability statement points to an implementation and a test; performance and interval evidence stay model-specific.</span>
  </a>
</div>
```

## Start with the scientific question

The first question is not “which optimiser?” It is: **which feature of the
response might change?** A mean-only model asks whether the expected response
changes. A distributional model can also ask whether its residual spread, shape,
or association changes. DRM.jl keeps those questions visible by giving each
admitted distributional parameter its own formula.

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

## What the fit estimates

In the model above, DRM.jl estimates one coefficient vector for **μ** (the mean)
and one for **log σ** (the residual standard deviation). A positive σ coefficient
means a multiplicative increase in residual spread, not an additive change in
the mean. Other families expose other admitted parameters, but the same rule
holds: interpret a coefficient on the scale named by that parameter's link.

## Evidence and limitations

DRM.jl is a pre-release package. Use the [capability matrix](capabilities.md) to
choose a tested family–structure combination, and the
[diagnostics and validation guides](diagnostics-and-validation/testing-likelihoods.md)
to see how it was checked. The verified sparse phylogenetic engine, profile
likelihood, and bootstrap routes are useful evidence—not blanket promises for
every family, data set, or interval. In particular, an interval method being
implemented does not claim universal calibrated coverage.

## Relation to drmTMB

DRM.jl is the Julia twin of [drmTMB](https://itchyshin.github.io/drmTMB/): it
adopts a closely related `bf()` grammar and vocabulary so R users do not have to
relearn the model class. It is independent, MIT-licensed Julia code—not a port
of drmTMB's GPL source. The optional [R ↔ Julia bridge](r-julia-bridge.md) lists
the admitted `engine = "julia"` cells; `engine = "tmb"` remains the default R
route and does not require Julia. The [Rosetta page](rosetta.md) compares the
two syntaxes directly.

---

*MIT licensed. A sister package to [drmTMB](https://itchyshin.github.io/drmTMB/)
(GPL) and [GLLVM.jl](https://itchyshin.github.io/GLLVM.jl). DRM.jl is fresh code —
never a port of drmTMB's GPL source.*
