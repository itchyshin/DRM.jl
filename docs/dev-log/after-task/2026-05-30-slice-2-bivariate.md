# After-task — Slice 2: bivariate Gaussian location–scale + rho12

**Date:** 2026-05-30 · **Branch:** `gaussian-bivariate-rho12` · advances roadmap #4

## Landed
- `src/gaussian_bivariate.jl` — keyword `bf(mu1=…, mu2=…, sigma1=…, sigma2=…, rho12=…)`
  (mirrors drmTMB) + the 2D-normal location–scale likelihood with a **tanh** link
  on ρ12 (coefficients on `atanh ρ12`). Reuses `DrmFit` + accessors.
- **Bug fix (Noether):** `_design` now adds R's **implicit intercept** via a
  `StatisticalModel` apply-schema context, so `y ~ x` means `y ~ 1 + x` (matching
  drmTMB). Previously `y ~ x` silently dropped the intercept — caught by the
  bivariate recovery test and confirmed to have affected the doc examples too.
- `tutorials/bivariate-coscale.md` filled with an executed `@example`.

## Verified
- `Pkg.test()` → **23/23** (13 engine + 4 univariate + 6 bivariate recovery).
- Bivariate recovery: μ1/μ2/σ1/σ2 within atol 0.06, atanh(ρ12) within atol 0.10 at n=6000.
- docs build clean; `bivariate-coscale` `@example` runs; `get-started` now shows the
  intercept (≈1.0) + slope (≈0.5), confirming the implicit-intercept fix.

## Per-persona
- **Boole:** keyword `bf` matches drmTMB's `mu1/mu2/sigma1/sigma2/rho12`; one-sided predictors take a placeholder LHS.
- **Noether:** 2D-normal NLL (log|Σ| + quadratic form), ForwardDiff Hessian; implicit-intercept parity fix.
- **Rose:** honest status — bivariate fixed-effect ρ12 is Stable; group-level correlation ≠ residual ρ12 noted.

## Next
Slice 3 — ordinary random effects (Gaussian) via the Laplace marginal.
