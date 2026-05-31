# After-task — Slice 3: ordinary Gaussian random intercept (1 | g)

**Date:** 2026-05-30 · **Branch:** `gaussian-random-intercept`

## Landed
- `src/gaussian_ranef.jl` — `(1 | g)` random intercept on the mean. For a mean
  random effect the marginal is exactly Gaussian (`V = D + σ_b² ZZᵀ`); fit in
  **closed form** via the matrix-determinant lemma + Woodbury, O(n) with a
  diagonal G×G capacitance (no Laplace). ForwardDiff-friendly accumulations.
- Refactored `drm(::DrmFormula, ::Gaussian)` to split `(1 | g)` terms from the
  fixed RHS and dispatch (`_fit_fixed_gaussian` / `_fit_ranef_gaussian`) —
  fixed-effect path unchanged (regression-safe).
- `re_sd(fit)` accessor (group-level SDs, keyed by grouping factor); exported.
- `model-guides/which-scale.md` filled with an executed `@example` showing the
  residual σ vs group-level SD distinction.

## Verified
- `Pkg.test()` → **27/27** (13 engine + 4 univariate + 6 bivariate + 4 RE).
- RE recovery at G=80, m=20: β within 0.1, residual σ within 0.1, σ_b within 0.15.
- docs build clean; `which-scale` `@example` recovers residual SD ≈ 0.5, group SD ≈ 0.8.

## Per-persona
- **Noether:** closed-form marginal via det-lemma + Woodbury; diagonal capacitance ⇒ O(n).
- **Boole:** `(1 | g)` detected as a `FunctionTerm{|}`; one random-intercept term this slice (multiple terms / random slopes are follow-ups).
- **Fisher:** Wald covariance from the marginal Hessian includes the RE SD param.
- **Rose:** honest — single random-intercept scope stated in the error path; group SD ≠ residual σ documented.

## Next
Slice 4 — structured-effect API: wire the verified q=4 phylo engine behind a public `phylo(1 | species, tree = …)`, then spatial/animal/relmat.
