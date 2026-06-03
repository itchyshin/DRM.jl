# Which scale are you modelling?

!!! note "Status — Stable"
    Mirrors drmTMB's [Which scale are you modelling?](https://itchyshin.github.io/drmTMB/articles/which-scale.html).
    **In DRM.jl today:** all of them — the residual scale `σ` (including a
    random effect *on* `σ`), a group-level random-intercept SD, and known
    sampling variances via `meta_V`.

"Variance" can mean different things, and DRM.jl keeps them separate:

| Quantity | What it is | How you model it |
|---|---|---|
| **Residual `σ`** | within-unit spread of `y` around its mean | the `sigma ~ …` formula |
| **Group-level SD** | between-group spread of random intercepts | a `(1 \| g)` term on the mean |
| **Known sampling V** | measurement uncertainty you supply | `meta_V(v)` in the mean formula |
| **Scale-level RE** | between-group spread of the *dispersion* | a `(1 \| g)` term on `sigma ~ …` |

## Residual σ vs group SD, side by side

```@example ws
using DRM, Random
Random.seed!(3)

G = 60; m = 25; n = G * m
g = repeat(1:G, inner = m)
x = randn(n)
b = 0.8 .* randn(G)                      # between-group: SD 0.8
y = 1.0 .+ 0.3 .* x .+ b[g] .+ 0.5 .* randn(n)   # within-group residual: SD 0.5
dat = (; y, x, g)

fit = drm(bf(@formula(y ~ x + (1 | g)), @formula(sigma ~ 1)), Gaussian(); data = dat)

exp(coef(fit, :sigma)[1])     # residual (within-group) SD ≈ 0.5
```

```@example ws
re_sd(fit)[:g]                # group-level (between-group) SD ≈ 0.8
```

The two are genuinely different parameters: `σ` is how much observations vary
*within* a group; `re_sd` is how much group means vary *around* the overall
mean. A mean random effect leaves the marginal model Gaussian, so this is fit in
closed form (no approximation).

!!! tip
    Modelling how the *residual* spread changes with a predictor? That's
    `sigma ~ x` — see [When variance carries signal](../tutorials/location-scale.md).

## Inference at the variance boundary (where drmTMB can't)

A variance component — a group-level SD, or a phylo-axis variance — can have its
maximum-likelihood estimate sitting *on* the boundary at zero. This is the
Watanabe-singular case: the data's MLE is degenerate, the observed information
loses positive-definiteness in that one direction, and there is nothing wrong
with the fit. drmTMB hits this honestly too (it reports `false convergence 8`),
but its `sdreport` then returns **all-`NaN`** standard errors — one unidentified
direction poisons the entire SE vector, so you lose the uncertainty on *every*
parameter, including the well-identified ones.

DRM.jl keeps the inference you are entitled to:

- **Boundary-aware Wald.** [`stderror`](@ref) reports a finite SE wherever the
  estimated variance is finite and positive, and `Inf` — an undefined,
  infinitely wide SE — only for the genuinely unidentified direction. That `Inf`
  propagates to an honest **unbounded `(-Inf, Inf)`** Wald interval rather than a
  silent `NaN`. The well-identified directions stay usable.
- **Profile likelihood.** [`confint`](@ref)`(fit; method = :profile)` inverts the
  likelihood-ratio statistic and returns an unbounded endpoint when the profile
  never crosses the threshold — the correct answer at the boundary, not a number
  the quadratic Wald approximation invented.
- **Parametric bootstrap.** [`bootstrap_ci`](@ref) sidesteps the Hessian
  entirely and is the recommended tool right at a true boundary.
- **Diagnostics.** [`check_drm`](@ref) flags the situation explicitly via its
  `vcov_posdef` / `min_eigval` fields, so a non-PD covariance is reported, not
  hidden.

This is a **measured** advantage, not a hope. On the verified q=4 PLSM fit, the
17×17 observed information had a single negative eigenvalue (the singular
variance direction); DRM.jl returned valid Wald SEs for the **16 of 17**
identified parameters where drmTMB's `sdreport` was all-`NaN`, and a parametric
bootstrap gave finite intervals for **60/60** replicates. See
`report/comparison-grid.md`.

!!! note "An undefined CI is information, not a failure"
    `(-Inf, Inf)` and `Inf` are deliberate: they say "this direction is not
    identified by these data" — which is the truth at the boundary. A `NaN` that
    swallows every other SE is not. When a variance pins at zero, prefer the
    profile or bootstrap interval over Wald for the affected component.

## See also

- [Get started](../get-started.md) · [What can I fit today?](model-map.md)
