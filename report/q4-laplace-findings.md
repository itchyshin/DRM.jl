# q=4 PLSM in Julia: Laplace implementation findings

**Date**: 2026-05-29
**Model**: bivariate phylogenetic location-scale (Model 5, Nakagawa et al.
2025 MEE) — phylo random effects on mu1, mu2, log sigma1, log sigma2
sharing one 4×4 covariance block Σ_a, plus residual rho12.
**Goal**: hand-rolled Laplace in Julia, compared to drmTMB/TMB.

## Headline verdict

**A naive Julia Laplace with a dense ForwardDiff Hessian is SLOWER than
drmTMB, not faster.** drmTMB fits the p=100 q=4 cell in **2.6 s**. The
Julia POC at **p=30** had not converged after **19m39s** (5 LBFGS
iterations). The 30–340× wins seen on closed-form Gaussian models do NOT
transfer to the Laplace-approximated q=4 case without serious
Hessian-structure engineering.

This is an honest, expected result: TMB's sparse reverse-mode AD plus
built-in Laplace is genuinely good at this model class.

## What was built

`julia/fit_q4_julia.jl` (~500 LOC):
- Joint NLL with 2×2 closed-form bivariate Gaussian data term + Kronecker
  prior `vec(U) ~ MVN(0, Σ_phy ⊗ Λ_phy)`
- Λ_phy via log-Cholesky (4 log-SD + 6 unconstrained correlation params)
- Inner mode-finding: fixed-iteration Newton (now ridge-regularized)
- Laplace marginal: `nll(û) + 0.5·logdet(H_uu)` (now Cholesky-based,
  Inf on non-PD so the outer optimizer rejects bad steps)
- Outer optimization: Optim LBFGS

## Correctness: CONFIRMED

`julia/test_q4_laplace.jl` — all 6 unit tests pass:
- Λ_phy reconstruction is PD for arbitrary inputs; SDs round-trip
- Kronecker prior NLL matches brute-force `MvNormal(0, kron(Σ,Λ))` to 1e-8
- `∇_u nll_joint` matches 5-point finite differences to < 1e-4
- Inner Newton reaches ‖g‖ < 1e-6 in 30 iters
- **Laplace marginal matches a 100k-sample Monte-Carlo marginal at p=4**
  (|diff| = 0.051, within Laplace bias)
- Σ_phy_inv / logdet pre-compute correct

The p=30 fit also showed clean monotone descent (function value
83.76 → 79.68, gradient norm 7.99 → 4.20), so the optimizer is working —
just slowly.

## Two bugs found and fixed

### 1. Non-PD Hessian crash (DomainError in logdet)

At the starting θ, `H_uu` was not positive-definite, so `logdet` threw
`DomainError(-1.0)` and killed the whole fit on the first evaluation.

**Fix**: Cholesky-based logdet with a 1e-4 ridge fallback; return `Inf`
if still non-PD so the outer optimizer rejects that step. Inner Newton
also got progressive ridge regularization (1e-6 → 1e2 → scaled-gradient
fallback).

### 2. Nested ForwardDiff is pathologically slow (the real killer)

The outer optimizer used `autodiff = AutoForwardDiff()`, which made it
differentiate through the inner Newton loop — and the inner loop itself
calls `ForwardDiff.hessian` 10–12 times per evaluation. This Dual-of-Dual
nesting blew up combinatorially.

**Measured**: a single outer gradient at **p=20** ran for **8m44s at 98%
CPU / 4 GB RAM and never finished.**

**Fix**: outer optimizer switched to **finite-difference gradients**
(treats `nll_marginal` as a black-box scalar; single-level ForwardDiff
still used inside the inner Newton). After the fix the fit progresses —
each outer gradient is ~18–34 cheap `nll_marginal` evals instead of one
unbounded nested-AD computation.

## Why it is still slow after the fix

Per `nll_marginal` evaluation at p=30:
- 12 inner Newton iterations, each computing a dense 120×120
  `ForwardDiff.hessian` (~120 forward passes) and a dense solve
- 1 final 120×120 Hessian for the Laplace logdet

Per outer LBFGS iteration: ~34 such evaluations (finite-diff gradient) +
line search. Observed 40–230 s per outer iteration at p=30.

The dense `H_uu` recomputed every evaluation is the bottleneck. At p=100
(4p = 400) the Hessian is 400×400 — roughly 11× more expensive again.

## What DRM.jl would need to actually beat TMB on q=4

| Lever | Speedup est. | Effort |
|---|---|---|
| **Block-diagonal data Hessian** — data part of H_uu is independent 4×4 blocks per species; solve in O(p·4³) not O((4p)³) | 10–50× | medium |
| **Kronecker prior Hessian** — prior part is Σ_phy⁻¹ ⊗ Λ_phy⁻¹; never densify | stacks with above | medium |
| **Analytic inner gradient + Hessian** — hand-coded, not ForwardDiff | 5–20× | high |
| **Sparse reverse-mode AD** (what TMB does) | the real competition | high |
| **Hadfield-Nakagawa sparse Σ_phy** (already in GLLVM.jl) | matters at large p | port |

Stacked, these could plausibly bring Julia to parity-or-better with TMB,
but it is genuinely hard engineering — not a free win. This is the v0.3
"Laplace machinery" work in the DRM.jl plan, and it is the real cost
center.

## Bottom line for the DRM.jl decision

- **Closed-form Gaussian / bivariate distributional regression**: Julia
  wins 20–50× cheaply (already demonstrated in `report/summary.md`).
- **q=4 phylogenetic location-scale (the PLSM selling point)**: Julia
  does NOT win for free. TMB is strong here. Beating it requires
  structured-Hessian engineering (the levers above).
- **Honest framing**: the brms→drmTMB jump (122 h → 2.6 s, ~170,000×) is
  the big one and is already done in R. A Julia rewrite's marginal gain on
  q=4 is uncertain until the structured Hessian is built and measured.

## Files

- `julia/fit_q4_julia.jl` — implementation (patched)
- `julia/test_q4_laplace.jl` — 6 passing correctness tests
- `julia/smoke_q4_p30.jl` — p=30 end-to-end smoke (slow; demonstrates the
  speed finding)
- `julia/probe_q4.jl` — timing probe that isolated the nested-AD bug
- `report/drmTMB-q4-numerical-recipes.md` — drmTMB's recipes for parity
