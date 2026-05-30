# Three-way algorithm comparison: R-TMB vs Julia-EM vs Julia-TMB-like

Design (user): isolate the OPTIMIZATION ALGORITHM on the identical q=4 PLSM
model/data, to see meaningful differences.

| Arm | Engine | Algorithm | Marginal | Variance components (Λ) |
|---|---|---|---|---|
| **R** | drmTMB | TMB: Laplace + nlminb on full ML marginal, CppAD exact gradient | ML Laplace | in the outer optimizer (correct) |
| **Julia-1** | DRM.jl | sparse Laplace-**EM** (+ guard, SQUAREM) | ML Laplace | EM M-step / marginal ascent |
| **Julia-2** | DRM.jl | **TMB-like**: exact gradient (implicit-fn-thm) on the sparse marginal + (L)BFGS | ML Laplace | in the outer optimizer (correct) |

All three optimize the SAME ML Laplace marginal (logLik comparable; verified
Julia ≈ R ≈ −256 on q4_p100).

## Results so far (q4_p100, p=100)

| Arm | logLik | wall-clock | converged | Λ estimated | notes |
|---|---|---|---|---|---|
| R (drmTMB) | −256.52 | 2.48 s | "false conv (8)" | yes | mature; flags non-convergence on this model |
| Julia-1 (EM) | −259.88 (climbing) | 26.8 s | not yet | yes | correct; slow ONLY due to finite-diff Λ gradient |
| Julia-2 (TMB-like) | — | — | — | — | **needs sparse exact-gradient build** (dense ver. is 229 s / NaN at p=100) |

## Meaningful differences already visible (algorithm-level)

- **EM (Julia-1)**: robust/monotone (guard guarantees ascent — *cannot*
  diverge), but **linear convergence** → many iterations (300+ unaccelerated;
  ~6 with SQUAREM). Its closed-form Λ step OVERSHOOTS far from the optimum
  (the diagnosed bug). Strength: robustness. Weakness: convergence rate.
- **TMB-like (Julia-2 / R)**: **superlinear** convergence (~30–50 nlminb
  iters for R), but needs the EXACT gradient (the implicit dû/dθ term — the
  cheap gradient is WRONG on the scale axes, verified). Strength: speed/iters.
  Weakness: gradient must be exact; can be fragile (R flags false convergence;
  dense Julia-2 NaN's on ill-conditioned trees).
- **R-TMB vs Julia**: R's edge is mature CppAD sparse-AD + nlminb. Julia's
  potential edge is (a) EM robustness, (b) sparse O(p) + warm-start for the
  bootstrap/CI pipeline, (c) threading. The single-fit contest is close;
  the *pipeline* (bootstrap/profile CIs, simulation grids) is where Julia's
  threading + warm-start should win.

## To complete the three-way (+ species scaling 100/1000/5000)

1. **Build sparse Julia-2** (exact gradient on the sparse marginal) — the
   keystone. Then all three arms run at p=100/354/1000/5000.
2. Run the **species-scaling** study: wall-clock(p) for R, Julia-1, Julia-2
   at p ∈ {100, 1000, 5000}. Expectation: R and Julia-2 both O(p) sparse;
   Julia-1 EM O(p)/iter but more iters; the gap should reveal where each
   algorithm's per-iteration cost vs iteration-count trade-off lands.
3. Then profile-likelihood (threaded) + Louis SE on the winning fit.

## Honest status
R and Julia-1 are runnable now; **Julia-2 (sparse TMB-like) is the one build
that completes the three-way** and is the same keystone that makes the single
fit fast. logLik equivalence (Julia ≈ R) is already confirmed.
