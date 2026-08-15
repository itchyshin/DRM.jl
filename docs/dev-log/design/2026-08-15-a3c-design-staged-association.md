# A3c design pass — staged association (`biv_associate` / `associate_pairs`)

Date: 2026-08-15 · lane: DRM.jl (Claude) · anchor: drmTMB **0.7.0 @ `origin/main`**
· the design pass the A3 re-scope required **before** A3c may start

## What the route actually is

Not a joint model. A **two-stage estimator**:

```r
associate_pairs(fit_1, fit_2, kernel = latent_normal(), association = ~ 1)
```

`fit_1` and `fit_2` are **already-fitted univariate drmTMB models**. The route
validates them, **freezes** them, and estimates a single latent-normal copula
association from the frozen margins. There is no joint refit.

Five reviewed **pair classes**, decided from the two model types:

| class | margins |
|---|---|
| `gaussian_bernoulli` | gaussian × binomial |
| `gaussian_nbinom2` | gaussian × nbinom2 |
| `bernoulli_nbinom2` | binomial × nbinom2 |
| `bernoulli_bernoulli` | binomial × binomial |
| `nbinom2_nbinom2` | nbinom2 × nbinom2 |

Anything else is refused: *"Other pair classes require their own Arc 6 review."*

## The estimator

- `alpha` = association design × coefficients; `eta = 0.999999 * tanh(alpha)`.
- Objective: `-loglik(alpha, frozen components)`, `+Inf` guarded to `double.xmax`.
- **`nlminb`, box-bounded `alpha ∈ [-8, 8]`, MULTISTART** from three starts
  (`-1, 0, 1` for the intercept-only case). The objective is not assumed unimodal.
- Uncertainty is **NOT** a Hessian: finite-difference **score** and **curvature**
  at the optimum (`h = 1e-4`), refusing to report when a coordinate sits on the
  box boundary.
- Explicit diagnostics: `near_boundary` when `|eta| >= 0.995`, and a
  **multistart-disagreement** flag comparing the three optima.

## The likelihoods — one is free, four need quadrature

**`gaussian_bernoulli` is fully closed form.** The Gaussian margin's latent is
*observed exactly* (`z = (y − mu)/sigma`), so the Bernoulli's contribution is a
conditional univariate normal CDF:

```
threshold      = qnorm(p, lower = FALSE)
conditional_z  = (threshold − eta*z) / sqrt(1 − eta^2)
loglik        += dnorm(y, mu, sigma, log) + pnorm(conditional_z, log, tail by y)
```

Needs only `phi`/`Phi`/`Phi^-1` — DRM.jl has `Distributions` already.

**The other four need a rectangle probability**, because both latents are
censored to intervals. drmTMB reduces the 2-D rectangle to a **1-D adaptive
integral**:

```
P = ∫ phi(z1) * Phi(conditional z2) dz1     over z1's interval
    stats::integrate(rel.tol = 1e-10, subdivisions = 200)
```

and it **keeps `abs.error`**, feeding per-row integration-error diagnostics.

## The one real dependency question

Julia has no `stats::integrate` equivalent in `Base` or in DRM.jl's current
deps. Matching drmTMB's numerics — adaptive, with a returned error estimate —
means **adding `QuadGK.jl`**. Options:

1. **Add QuadGK** (recommended). Small, pure-Julia, standard, gives the
   `(value, abs_error)` pair the diagnostics need. A new dependency is a public
   packaging change (Aqua checks deps), so it needs owner sign-off.
2. **Fixed Gauss–Hermite.** No new dep, but no error estimate — drmTMB's
   integration-error diagnostics could not be reproduced, so the parity claim
   would be narrower.
3. **Hand-rolled adaptive Gauss–Kronrod.** Avoids the dep at the cost of owning
   a numerical routine that QuadGK already does better. Not recommended.

## The limitation that must be documented, not discovered

**Frozen margins mean the reported uncertainty ignores margin estimation
error.** The two-stage estimator conditions on `fit_1`/`fit_2` as if exact, so
alpha-scale standard errors are conditional, not joint. drmTMB is explicit about
this — alpha-scale Wald only, an experimental-interval warning, `eta` uncertainty
inheriting that tier, and **no simultaneous `eta` bands or profiles**. DRM.jl
must carry the same warning and must not offer intervals the R twin refuses.

This is exactly why the re-scope demanded a design pass: the hard part is not
the likelihood, it is not over-claiming the uncertainty.

## Revised estimate (D-139)

The original re-scope said 2–3 days for A3c as a whole. With the quadrature
dependency, five pair classes, and the diagnostic surface, split it:

| slice | scope | estimate |
|---|---|---|
| **A3c-1** | `gaussian_bernoulli` only — closed form, **no new dependency**, full estimator (multistart, bounds, FD score/curvature, boundary flag) | **0.5–1 day** |
| **A3c-2** | the four quadrature classes + `QuadGK` + per-row integration-error diagnostics | 1.5–2 days |
| **A3c-3** | diagnostic/warning parity: multistart disagreement, experimental-interval warning, refusal surface | 0.5–1 day |

Total **2.5–4 days**, modestly above the original 2–3 because the dependency and
the diagnostics were not visible before this pass.

**Recommended first slice: A3c-1.** It exercises the entire staged architecture
— freeze, associate, optimise, diagnose — on the one pair class that needs no
new dependency, so the dependency decision can be made on evidence afterwards
rather than up front.

## Decision needed before A3c-2

**May DRM.jl take `QuadGK.jl` as a dependency?** A3c-1 does not need it. A3c-2
cannot match drmTMB's numerics without it (or without giving up the
integration-error diagnostics).

## Fences for this arc

Margins are **frozen** — this route must never refit them. No random effects, no
offsets, no missing predictors, no aliased columns, no dot expansion (drmTMB's
staged formula rejects all of these). `eta` is constant except for drmTMB's one
exception: an intercept-bearing fixed-effect association formula for
literal-Bernoulli × ordinary-NB2. Other pair classes stay intercept-only.
