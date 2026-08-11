# Laplace vs variational marginals

!!! note "Status — Experimental (#136 open)"
    A variational (VA / ELBO) marginal is an **opt-in Experimental** alternative
    for random-intercept `(1 | g)` models. **Laplace remains the default** — the
    same family of method drmTMB and TMB use.

    **Public path today (does not close #136):** Poisson, Binomial, NegBinomial2,
    Gamma, and Beta `(1 | g)` via `drm(...; marginal = :VA)` (scale families need
    `sigma ~ 1`). That `loglik` is an ELBO, not a Laplace log-likelihood. Mixed
    LA/VA AIC / LRT errors. Phylo / crossed / correlated slopes / ZI / hurdle /
    `sigma ~ x` stay unwired — not “implemented everywhere.” Public Gamma RI
    LA-vs-VA smoke: `report/va-vs-laplace-bias.md` (#136e scoped; #136 stays open).

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
| Ordinary Gamma `(1\|g)` shape | LA ≈ VA in the #136e smoke; **prefer LA** (15–20× faster warm). |
| Two-part / hurdle / ZINB geometry | VA may help (GLLVM evidence) — **not a public DRM path yet**. |
| Speed-critical fits | LA — default; one inner solve per step. |

In short: **LA is faster and is the default.** On the public Gamma random-intercept
cell, Julia matches the R/TMB pattern: the two marginals agree on `α` and LA
wins on time (`report/va-vs-laplace-bias.md`). VA stays an opt-in for the
bias-sensitive *two-part / ZI* cells — those are still unwired here.

## The public API (Experimental)

The marginal is selected with `marginal` (not Gaussian `method = :ML/:REML`).
LA remains the default:

```julia
# default — Laplace, as today
drm(...; marginal = :LA)

# opt-in variational marginal (Experimental: `(1 | g)` on Poisson / Binomial /
# NegBinomial2 / Gamma / Beta; scale families need sigma ~ 1)
drm(...; marginal = :VA)
```

Everything else about the call — the `bf(...)` formulas, the family, the data —
stays the same; only how the random effects are integrated out changes.
`method = :VA` on non-Gaussian families is rejected with a pointer to `marginal`.

## How we trust it (anchors on tip)

The Experimental `(1 | g)` path is gated by deterministic anchors in
`test/test_variational.jl` (and per-family ELBO tests) — checks with a known
answer, not just "the numbers look plausible":

1. **Variance → 0 collapses to independence.** As the random-effect variance is
   driven to zero there is nothing left to integrate, so the ELBO equals the
   ordinary independent log-likelihood. This pins the no-RE limit exactly.
2. **ELBO ≤ dense quadrature.** At low latent dimension the true marginal is
   computed by dense *adaptive* Gauss–Hermite. The ELBO, being a lower bound,
   must sit at or below it — never above. (Non-adaptive engine GHQ centred at 0
   can sit below the ELBO; that is not a counterexample.)
3. **Family limits.** The negative binomial as its size `r → ∞` becomes Poisson,
   so NB2-VA converges to Poisson-VA on a shared fixture.

The scoped **#136e** public-path report is `report/va-vs-laplace-bias.md`:
on Gamma `(1 | g)`, LA ≈ VA on shape `α` and LA is much faster. Closing #136 still
needs public VA beyond random intercept (phylo / crossed / ZI / hurdle) and any
two-part bias cell — those are not claimed here.

## A place DRM.jl can exceed drmTMB

drmTMB is built on TMB, which is **Laplace-only**. Offering a variational
marginal alongside LA is therefore not parity work — it is a capability drmTMB
does not have. That option is useful **only** where Laplace is known to fail
(two-part shape, ZINB multimodality). On ordinary Gamma `(1 | g)`, the #136e
smoke does **not** show a VA accuracy edge; prefer the default Laplace, as in R.

## See also

- [Which scale are you modelling?](which-scale.md) · [Improving convergence](convergence.md)
