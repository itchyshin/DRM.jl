# After-task — Slice 1: univariate Gaussian location–scale + landing page

**Date:** 2026-05-30 · **Branch:** `gaussian-core-univariate` · **Closes:** #18

## Landed
- `src/gaussian_core.jl` — `Gaussian()` family, `bf()` / `drm_formula()`, the
  `drm()` ML fitter for univariate Gaussian location–scale (μ, log σ), `DrmFit`
  with `coef` / `coef(fit,:param)` / `vcov` / `loglik` / `nobs` / `fixef` / `show`.
  Built on StatsModels; added StatsModels + StatsAPI + Tables to deps (+ compat).
- Public-verb decision recorded (`drm` + `bf`), resolving #18.
- **Landing page rewritten** as a real stats-package page leading with a working
  example; `get-started.md` + `tutorials/location-scale.md` filled with
  **executed** `@example` blocks.

## Verified (evidence)
- `Pkg.test()` → **17/17** (13 engine + 4 Gaussian recovery).
- Recovery: μ ≈ [0.5, −0.8], σ(logσ) ≈ [−0.3, 0.4] within atol 0.08 at n=4000.
- `docs/make.jl` builds; rendered `get-started.html` / `location-scale.html`
  carry no error markers and show computed output → `@example` blocks ran.

## Per-persona
- **Boole:** `bf` / `drm_formula` mirror drmTMB; each formula LHS names its dpar; `@formula` re-exported.
- **Noether:** location–scale NLL + ForwardDiff Hessian → Wald covariance; verified `src/` engine untouched.
- **Pat / Florence:** landing page leads with capability + a runnable example, not a scaffold warning.
- **Rose:** status tags honest — Stable only where it fits today (univariate loc-scale); the rest Planned. License boundary intact.

## Next
Slice 2 — bivariate Gaussian (`rho12`): `bf(mu1, mu2, sigma1, sigma2, rho12)` + the 2D-normal likelihood.
