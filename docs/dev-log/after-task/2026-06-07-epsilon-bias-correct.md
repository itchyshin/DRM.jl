# After-task: TMB-style epsilon-method bias correction for derived quantities

Scout backlog #227, item B11. New public surface `bias_correct`.

## What changed

- New `src/bias_correct.jl` implementing a generalized-delta / epsilon-method
  bias correction for a smooth scalar derived quantity `g(θ)` of a fitted model,
  in the spirit of TMB `sdreport(..., bias.correct = TRUE)` (Thorson &
  Kristensen 2016).
- Public function `bias_correct(fit, g::Function; level = 0.95)` returning a
  `NamedTuple` `(estimate, corrected, bias, se, ci, level)`:
  - `estimate`  = raw plug-in `g(θ̂)`;
  - `corrected` = `g(θ̂) + ½·tr(H_g·V)` (the epsilon-method correction);
  - `bias`      = `½·tr(H_g·V)`;
  - `se`        = delta-method SE `√(∇gᵀ V ∇g)` using the EXACT gradient and the
                  stored `vcov(fit)`;
  - `ci`        = Wald interval `corrected ± z·se`.
  The gradient `∇g` and Hessian `H_g` are obtained by ForwardDiff of the user's
  `g`, so they are exact for any smooth `g`.
- A lower-level method `bias_correct(θ̂, V, g; level)` operates directly on a
  point estimate and covariance (used by the closed-form tests, and usable for
  derived quantities not tied to a `DrmFit`).
- Wired `include("bias_correct.jl")` into `src/DRM.jl` and exported
  `bias_correct`.

## Why / method

θ̂ ≈ N(θ, V). The plug-in `g(θ̂)` is biased for `E[g(θ̂)]` whenever `g` is curved.
A second-order Taylor expansion gives `E[g(θ̂)] ≈ g(θ̂) + ½·tr(H_g·V)`; the
first-order delta method gives `Var ≈ ∇gᵀ V ∇g`. This helps most on the curved
transforms DRM already reports on a working scale — variance `σ² = exp(2 logσ)`,
correlation `ρ12 = tanh(atanh ρ12)`, back-transformed means `exp(η)` — exactly
the dispersion/variance/correlation directions the Laplace approximation biases.

## Scope / non-changes

- Kept DELIBERATELY distinct from the raw plug-in accessors (`coef`, `sigma`,
  `rho12`, …), which still report `g(θ̂)` with no correction. No existing
  accessor or test was modified.
- It is a *second-order* correction under the asymptotic Wald premise; it does
  not fix non-normality of θ̂ or a non-PD `V` at a variance boundary (there the
  SE/CI inherit `vcov`/`stderror` behaviour — bootstrap/profile are preferable,
  per `confint`). Documented honestly in the docstring.

## Verification (CI-only this session — no local Julia runtime)

New testset `test/test_bias_correct.jl`, registered in `runtests.jl`. The
acceptance anchors:

- **Identity anchor (linear g):** `g(θ)=θ_k` and a general affine `g=a·θ+b` give
  `bias ≈ 0` (to 1e-12), `corrected == estimate`, and `se`/`ci` equal the
  plug-in Wald values exactly — both on a hand-built `(θ̂, V)` and on a real
  `DrmFit` (`se == stderror(fit)[k]`).
- **Curvature anchor (g = exp), closed form:** `corrected = exp(m)(1 + v/2)`,
  the second-order expansion of the analytic `E[exp] = exp(m + v/2)`; checked to
  match `exp(m+v/2)` within the `O(v²)` remainder at v ∈ {0.01, 0.02, 0.05},
  with the correct (positive, convex) sign and `se = exp(m)·√v`.
- **Exactness anchors:** quadratic `g=θ²` gives `corrected = m²+v` EXACTLY
  (= `E[θ²]`); bilinear `g=θ₁θ₂` gives `corrected = m₁m₂ + V₁₂` EXACTLY
  (cross-covariance term), proving the off-diagonal `tr(H·V)` handling.
- **DrmFit ↔ manual agreement:** the `DrmFit` method equals the explicit
  `(θ̂, V)` form on a real Gaussian location–scale fit.

## Caveats

- No closed-form CI-checkable anchor exists for the *correlation* `tanh` or
  *phylo-variance* corrections beyond the generic exp/quadratic forms, so those
  are exercised only through the generic mechanism, not pinned to an analytic
  value. The exp/quadratic/bilinear closed forms are what prove correctness.
- Correction quality degrades when θ̂ is far from Gaussian or V is large; this is
  the standard second-order limitation, stated in the docstring.
