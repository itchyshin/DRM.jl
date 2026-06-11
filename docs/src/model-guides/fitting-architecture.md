# How a fit happens: the integral and optimiser layers

Fitting a model with random effects in DRM.jl is **two nested problems**, and
almost all of the vocabulary you meet — Laplace, variational, Gauss–Hermite,
L-BFGS, REML — is really an answer to one of the two. Keeping them apart is the
fastest way to understand what the engine is doing (and which knob to turn).

!!! tip "The one-line version"
    The **integral layer** turns the intractable marginal likelihood into
    something you can evaluate; the **optimiser layer** climbs it. They are
    *orthogonal* — any optimiser pairs with any marginal approximation.

## The two questions

A model has fixed parameters `θ` (coefficients, variance components, dispersion,
shape) and latent variables / random effects `u` (group effects, phylogenetic
deviations, the shared cross-family latent). We do not maximise the joint
likelihood of data *and* `u`; we integrate `u` out, leaving a **marginal**
likelihood that depends only on `θ`:

```
L(θ) = ∫ p(y | u, θ) · p(u | θ) du.
```

Fitting then splits cleanly into:

1. **The integral (marginal) layer** — make `L(θ)` *computable*. The integral
   has no closed form for non-Gaussian families, so it must be approximated.
2. **The optimiser layer** — maximise the resulting `L̂(θ)` over `θ`.

```
┌─ OUTER · optimise θ ─────────────────────────────────────────┐
│   climb L̂(θ):  L-BFGS · trust-region Newton · (ML / REML)     │  ← optimiser layer
└───────────────────────────────────────────────────────────────┘
        ▼ every evaluation of L̂(θ) must first build the marginal …
┌─ MIDDLE · the marginal   L(θ) = ∫ p(y|u,θ) p(u|θ) du ────────┐
│   make it tractable:  Laplace (default) · VA / ELBO · GHQ     │  ← integral layer
└───────────────────────────────────────────────────────────────┘
        ▼ which in turn must handle the latent u …
┌─ INNER · the latent u ───────────────────────────────────────┐
│   Laplace → Newton mode û(θ) · VA → q(u|φ) · GHQ → fixed nodes │
└───────────────────────────────────────────────────────────────┘
```

## Layer 1 — the integral (how DRM.jl handles `u`)

DRM.jl carries three ways to make the marginal tractable; they differ only in
how they treat `u`, and each returns a value **and** a gradient in `θ`.

- **Laplace approximation — the default.** The verified sparse augmented-state
  engine replaces the integrand with a Gaussian centred at the posterior mode
  `û(θ)`, matched in curvature there. It costs one inner Newton mode-solve per
  outer step and is *exact* for a Gaussian random effect on the mean. This is
  the same family of method TMB / drmTMB use. See
  [Laplace vs variational marginals](marginal-la-vs-va.md) for when it is, and
  is not, the right choice.
- **Variational / ELBO — opt-in (`method = :VA`).** Instead of expanding at the
  mode, VA replaces the posterior with the best tractable `q(u | φ)` and works
  with the evidence lower bound (ELBO). It is more faithful for skewed, sparse,
  or binary posteriors, at the cost of carrying variational parameters `φ`.
- **Gauss–Hermite quadrature — cross-family.** The cross-family bivariate models
  correlate two responses through a shared scalar latent `u`; that one-dimensional
  integral is done by Gauss–Hermite quadrature. See
  [Cross-family methods](cross-family-methods.md).

## Layer 2 — the optimiser (how DRM.jl maximises `L̂(θ)`)

DRM.jl hands `(L̂, ∇L̂)` to [Optim.jl](https://github.com/JuliaNLSolvers/Optim.jl):

- **L-BFGS is the workhorse outer optimiser.** It is a *quasi-Newton* method:
  it learns curvature from successive gradients (limited-memory BFGS updates)
  instead of forming a Hessian, so each step needs only `∇L̂` and it scales to
  thousands of parameters. This is the same choice as the sister package
  GLLVM.jl, and as `gllvm` in R (which defaults to `optim`'s `L-BFGS-B`).
- **A trust-region Newton** is used for the curvature-sensitive *inner* solves
  (for example the location–scale mode-find), where shrinking a trust radius is
  more robust than a line search near a variance boundary.
- **The gradient is exact.** What DRM.jl feeds the optimiser is the **exact
  `O(p)` implicit-function gradient** of the Laplace marginal — differentiated
  analytically *through* the inner mode rather than by generic autodiff. That
  analytic gradient (FD-gated to ≤ 1e-6) is the package's performance edge.
- **ML by default; REML optional.** REML changes *which* likelihood you climb —
  it integrates the fixed effects out as well — not the optimiser that climbs it.

## Why "orthogonal" matters

The optimiser never needs to know which integral approximation produced
`L̂(θ)`; it only consumes a value and a gradient. So you can switch
`method = :LA` ↔ `:VA` without touching the optimiser, and change optimiser
tolerances without touching the marginal. Conversely, EM — which some packages
use — is an *alternative to the optimiser layer* (it ascends by alternating an
E-step and an M-step rather than climbing a gradient); DRM.jl keeps a
conjugate-Gaussian EM path for that reason, but the default route is
"Laplace marginal + L-BFGS".

!!! note "Why profile-likelihood CIs are the expensive part"
    The layers nest: every *outer* `θ`-step triggers an *inner* latent solve. A
    profile-likelihood CI adds a **third** level — fix one component of `θ`,
    re-optimise all the rest, and repeat that constrained solve along a root-find
    for the χ²₁ crossing. Optimisation inside optimisation inside a mode-find is
    why profiling is the costliest thing the engine does, and why its inner solve
    is kept Hessian-free.

## Where each piece lives

| Layer | Question it answers | In DRM.jl |
|---|---|---|
| **Integral** | how to handle the latent `u` | Laplace (default) · VA / ELBO (`:VA`) · Gauss–Hermite (cross-family) |
| **Optimiser** | how to maximise `L̂(θ)` | `Optim.LBFGS` · trust-region Newton (inner) · ML / REML |

## See also

- [Laplace vs variational marginals](marginal-la-vs-va.md) — choosing the integral layer.
- [Cross-family methods](cross-family-methods.md) — the shared-latent GHQ route.
- [Profile-likelihood CIs](../diagnostics-and-validation/profile-likelihood.md) — the nested-optimisation cost in practice.
- [R ↔ Julia bridge](../r-julia-bridge.md) — how `drmTMB(..., engine = "julia")` reuses this engine.
