# Design: variational (VA/ELBO) marginal — #136

**Status:** design / implementation map. **Beyond drmTMB** (drmTMB is
Laplace-only) — an *opt-in* alternative marginal that is steadier on
dispersion/shape/zero-inflation parameters, where Laplace is known to bias.
Implements the ELBO behind an **existing scaffold**. Implementation +
verification are local Julia. Aligns with the "go beyond parity" goal.

## Why (the motivation, from GLLVM.jl)

Laplace (TMB's default, and DRM.jl's) approximates the marginal by a Gaussian at
the posterior mode — fast, but it biases exactly the parameters DRM models with
predictors (σ, shape, zero-inflation). GLLVM.jl hit and documented this: a
two-part Gamma shape recovered ~7× too low under Laplace; ZINB multimodality with
OS/BLAS-dependent sign flips. Any DRM model that integrates a random effect out of
a non-Gaussian response is exposed to the same bias. VA maximizes a provable
lower bound (the ELBO) on the marginal and is typically steadier on those axes.

## What already exists (the scaffold — don't rebuild)

`src/variational.jl` (40 lines) already provides:
- `abstract type MarginalMethod`; `struct Laplace`, `struct Variational`;
- `_marginal_method(:LA|:VA)` resolver (case-insensitive);
- `_fit_va(...)` **stub that errors** pointing to this issue;
- the public surface is `method = :LA` (default) / `:VA`, kept internal-by-design
  (`src/DRM.jl:73`).

Also available to reuse:
- **`_gauss_hermite(K)`** — already used for 1-D GHQ random-effect integration in
  `beta.jl:95` / `betabinomial.jl:58`; the VA 1-D-GHQ terms reuse it.
- the **Laplace RE paths** (`sparse_laplace_glmm.jl`) — VA parallels these per
  family; same per-family `Val{}` conditional-density kernels (value/d1/d2/…).

So #136 = **fill in `_fit_va`** with the per-family ELBO, routed from the family
dispatchers when `method=:VA` and the model has a latent integral.

## The ELBO (per the issue + GLLVM port)

Posterior approximation per group/site `q(z) = N(m, diag(v))`. Maximize
`ELBO = Σ_i E_q[log p(y_i | η_i(z))] − KL(q ‖ prior)` over `(m, v)` and the
fixed/dispersion parameters. Two evaluation regimes for `E_q[log p]`:

- **Closed-form** where the log-density is linear in `η` and `e^{±η}`:
  **Poisson, Gamma, Delta-Gamma** — `E_q[e^{η}] = e^{m + v/2}` etc., **no
  quadrature**. Cheapest and most stable; do these first.
- **1-D Gauss–Hermite** for the rest — **Binomial, NB, Beta** (and BetaBinomial,
  ZOI) — reuse `_gauss_hermite`; `E_q[log p] ≈ Σ_k w_k log p(y; m + √(2v)·z_k)`.

Per-site posterior `(m_i, v_i)` is profiled by an inner optimize of the site ELBO
(closed-form or a few Newton steps); the outer optimizes the model parameters —
the same two-level structure as the Laplace paths, with the mode replaced by the
variational `(m, v)`.

## Scope

- VA helps **only where there is a latent integral** — the random-effect /
  structured models. For **fixed-effects-only** distributional regression VA adds
  nothing (ELBO = the exact log-lik), so `method=:VA` there is a no-op/passthrough
  to the exact fit (or a clear "not needed" note), **not** an error.
- First slices target the **non-Gaussian random-intercept** models (the
  bias-sensitive cells), reusing the existing routing in `poisson.jl`, `gamma.jl`,
  `beta.jl`, `negbinomial.jl`, `betabinomial.jl`.
- Not a default — Laplace stays default; VA is the opt-in for bias-sensitive fits.

## Deterministic anchors (what makes this verifiable without full data)

From the GLLVM.jl experience — these are the cheap correctness levers and become
the tests:
1. **Variance→0 limit:** as the RE loadings/variance → 0, the ELBO reduces
   **exactly** to the independent (no-RE) log-likelihood.
2. **Lower-bound property:** ELBO ≤ a dense high-order quadrature of the true
   marginal at low latent dim (a provable inequality — a one-sided check).
3. **Family limits:** NB `r→∞` → the Poisson-VA; Beta `φ→∞` → near-degenerate;
   etc.

## API & packaging

- `drm(...; method = :VA)` → resolve via `_marginal_method`, route to `_fit_va`.
- **`DrmFit` packaging:** store the **ELBO** as the objective, but **flag it as a
  bound, not the marginal log-lik** — so `loglik`/`aic`/`lrtest` must **warn or
  refuse across methods** (an ELBO and a Laplace logLik are not comparable; same
  discipline as the REML guard #11). Comparing two VA fits is fine.
- Document the **trade-off honestly:** VA is slower (inner per-site solve;
  quadrature for non-conjugate families) and is a *bound* — recommend it for the
  bias-sensitive parameters, not as a blanket replacement.

## Acceptance / test plan (local Julia)

1. **Anchor 1 (variance→0):** ELBO ≡ independent log-lik within tol — the
   foundational unit test.
2. **Anchor 2 (bound):** ELBO ≤ dense-GHQ marginal on a small fixture.
3. **Anchor 3 (family limit):** NB-VA → Poisson-VA as `r→∞`.
4. **Bias reduction (the point):** on a simulated bias-sensitive cell (e.g. a
   Gamma-shape / dispersion model with a random intercept), VA recovers the
   dispersion/shape **closer to truth than Laplace** — reproduce the GLLVM
   finding qualitatively.
5. **Gradient:** analytic vs FD on the ELBO ≤ 1e-6 (or AD through the inner solve).
6. **Guards:** cross-method AIC/lrtest warns; fixed-effects-only `:VA` is a no-op.

## Sequencing

1. **Closed-form families** (Poisson, Gamma) — no quadrature, anchors 1–3 first.
2. **GHQ families** (Binomial, NB, Beta, BetaBinomial) — reuse `_gauss_hermite`.
3. **ZOI / delta** mixtures and the multimodal ZINB case (the original motivation) — last.

## Implementation checklist

- [ ] Replace the `_fit_va` stub with the ELBO driver (outer params + per-site `(m,v)`), behind the existing `method=:VA` scaffold.
- [ ] Closed-form `E_q[log p]` for Poisson/Gamma; 1-D GHQ (reuse `_gauss_hermite`) for Binomial/NB/Beta/BetaBinomial.
- [ ] Route `method=:VA` from the family dispatchers (RE present → `_fit_va`; fixed-only → passthrough).
- [ ] `DrmFit`: store ELBO + a marginal-method marker; cross-method AIC/lrtest guard; `loglik` docstring caveat (bound).
- [ ] Tests: anchors 1–3, bias-reduction vs Laplace, gradient ≤ 1e-6, guards.
- [ ] Docstrings + a worked "VA vs Laplace on a dispersion model" example; update `report/comparison-grid.md` with the VA cell.
