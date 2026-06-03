# Laplace vs variational marginals

!!! note "Status — Planned (#136)"
    A variational (VA / ELBO) marginal is an opt-in alternative under design.
    **In DRM.jl today** the marginal likelihood is computed by the Laplace
    approximation (LA) — the same family of method drmTMB and TMB use — and LA
    remains the default. This page documents the planned VA path so the design,
    its motivation, and the gates it must pass are recorded before any code lands.

## What "the marginal" is, and why it matters

When a model has random effects `z`, `drm` does not maximise the joint
likelihood of data and random effects directly. It integrates the random
effects out, leaving a *marginal* likelihood that depends only on the fixed
parameters and the variance components:

```
L(θ) = ∫ p(y | z, θ) p(z | θ) dz.
```

That integral has no closed form for non-Gaussian families, so it must be
approximated. The quality of the approximation is not a side detail: it is what
the dispersion, shape, and zero-inflation parameters are estimated *against*. A
biased marginal biases exactly those parameters.

### The Laplace approximation (today's default)

LA replaces the integrand with a Gaussian centred at the posterior mode of `z`,
matched in curvature (the Hessian) at that mode. It is fast — one inner mode
solve per outer step — and for a Gaussian random effect on the mean it is
*exact*, because the integrand really is Gaussian (this is why a mean random
intercept in a Gaussian model needs no approximation at all).

The trouble starts when the integrand is **not** close to Gaussian:

- **Skewed or heavy-tailed posteriors** — a single mode-plus-curvature match
  understates the mass in the tail, so the integral, and the variance/shape
  parameters tied to it, are off.
- **Multimodal posteriors** — LA sees one mode and is blind to the others; which
  mode it lands on can depend on the optimiser, the OS, or the BLAS.
- **Dispersion / shape / zero-inflation parameters** — these read the *shape* of
  the integrand, not just its peak, so they absorb the approximation error
  first. Mean (location) parameters are comparatively robust.

## Concrete evidence (from the sister project GLLVM.jl)

DRM.jl is a sister of GLLVM.jl, which fits the same kind of latent-variable
integrals and has measured where LA bites:

- **Two-part Gamma shape.** In a two-part (hurdle) Gamma model, the Gamma shape
  parameter `α` was recovered roughly **7× too low** under Laplace. The mean was
  fine; the shape — which is read off the curvature of a skewed positive density
  — was badly biased.
- **ZINB multimodality.** In a zero-inflated negative binomial model the
  zero-inflation probability `π` and the low-count-mean intercept `βc` trade off:
  a zero can be "structural" (`π`) or "a Poisson/NB zero from a small mean"
  (`βc`). That gives the marginal **two modes**, and the sign of the count
  intercept was observed to **flip across OS / BLAS** — a hallmark of LA picking
  different modes on different platforms.

Neither failure is a bug in the optimiser; both are the geometry the Laplace
approximation cannot see.

## The variational (VA / ELBO) proposal

The variational path replaces "find one mode and match curvature" with "fit a
whole approximating distribution." We choose a factorised Gaussian

```
q(z) = N(m, diag(v)),
```

and pick `m` and `v` to maximise the **evidence lower bound** (ELBO):

```
ELBO(θ, m, v) = E_q[ log p(y, z | θ) ] − E_q[ log q(z) ]  ≤  log L(θ).
```

The ELBO is a *provable lower bound* on the true log marginal, which is the
property that makes it well-behaved as an objective: optimising it cannot
silently chase a spurious peak the way a mode-match can.

The expectations under a Gaussian `q` are tractable in the two regimes DRM.jl
needs:

- **Closed form** when the log-density is linear in the linear predictor `η` and
  in `e^{±η}` — this covers **Poisson** and **Gamma**, because the Gaussian
  expectations of `η` and of `e^{η}` (a log-normal moment) are both analytic.
- **One-dimensional Gauss–Hermite quadrature** for everything else —
  **Binomial**, **negative binomial**, and **Beta** — where the expectation
  reduces to a single integral over the scalar `η`, cheaply and accurately
  evaluated with a handful of GH nodes.

Because `q` carries a *variance* `v`, not just a location, it represents tail and
spread directly, so the shape and dispersion parameters are no longer estimated
against a curvature match at a single point.

## When to use which

| Situation | Recommendation |
|---|---|
| Fixed-effects-only model | VA adds nothing — there is no latent integral to approximate. |
| Gaussian random effect on the mean | VA adds nothing — LA is already exact here. |
| Non-Gaussian RE with dispersion / shape / zero-inflation of interest | VA is steadier — these are the parameters LA biases. |
| Skewed or multimodal latent posteriors | VA is more robust — the ELBO does not lock onto a single mode. |
| Speed-critical, bias-tolerant fits | LA — one inner solve per step is faster. |

In short: **LA is faster and is the default; VA is an opt-in for the
bias-sensitive cells** — the two-part / hurdle, zero-inflated, and shape-driven
models where the GLLVM evidence above shows LA struggling.

## The intended API (planned)

The marginal will be selected with a single keyword, LA remaining the default:

```julia
# default — Laplace, as today
drm(...; method = :LA)

# opt-in variational marginal
drm(...; method = :VA)
```

Everything else about the call — the `bf(...)` formulas, the family, the data —
stays the same; only how the random effects are integrated out changes.

## How we'll trust it

A new marginal earns its place only by passing deterministic anchors — checks
with a known answer, not just "the numbers look plausible":

1. **Variance → 0 collapses to independence.** As the random-effect variance is
   driven to zero there is nothing left to integrate, so the ELBO must equal the
   ordinary independent log-likelihood. This pins the no-RE limit exactly.
2. **ELBO ≤ dense quadrature.** At low latent dimension we can compute the true
   marginal by dense quadrature. The ELBO, being a lower bound, must sit at or
   below it — never above. A VA value exceeding quadrature is a bug, by
   construction.
3. **Family limits.** Family parameters have known degenerate limits — e.g. the
   negative binomial as its size `r → ∞` becomes Poisson, so NB-VA must converge
   to Poisson-VA. Each family is anchored to its limit.

## A place DRM.jl can exceed drmTMB

drmTMB is built on TMB, which is **Laplace-only**. Offering a variational
marginal alongside LA is therefore not parity work — it is a capability drmTMB
does not have. For the exact cells where Laplace is known to bias the shape and
zero-inflation parameters, a VA option lets DRM.jl give a steadier answer than
the R package it mirrors.

## See also

- [Which scale are you modelling?](which-scale.md) · [Improving convergence](convergence.md)
