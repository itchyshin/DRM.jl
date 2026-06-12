# After-task: generalise coevolution from q=4 to general q (q=6/q=8) — #188

Date: 2026-06-10

## Summary

Added a self-contained **general-q multivariate-Brownian coevolution** block
(`src/coevolution_q.jl`) that generalises the among-trait covariance Λ (= Σ_a)
from the verified q=4 PLSM to arbitrary q (q=6, q=8), carried on the **same**
sparse augmented-state precision `P = kron(Q_tree, Λ⁻¹)` with a q×q Λ. The q=4
location-scale engine is **untouched** — this is purely additive.

## Why a new block rather than retrofitting the q=4 engine

The verified engine (`sparse_aug_plsm.jl` / `fit_q4_sparse_tmb.jl`) hard-codes
q=4 at three different levels:

1. **The leaf likelihood `leaf_nll` is intrinsically BIVARIATE** — 2 means + 2
   log-σ + ONE residual correlation ρ12, a 2×2 Gaussian with a `1-ρ²` quadratic
   form and a `RHO_GUARD*tanh(ηr)` residual-ρ β-block. This is not "q=4 with a
   dimension constant"; the residual-correlation structure and the log-σ axes are
   specific to the bivariate location-scale model. A "q=6 of the *same* family"
   would be a *trivariate* location-scale model (3 means + 3 log-σ, 3 residual
   ρ's) — a different, hand-derived leaf likelihood and gradient, not a loop bound.
2. **The exact O(p) gradient** (`marginal_and_exact_grad`) hard-wires `4(t-1)`,
   `for a in 1:4`, the 16×5 η-jacobians, the 4×4×4 third-derivative tensor, the
   5-element β layout `(mu1,mu2,s1,s2,rho)`, and `Gst=zeros(4,4)`.
3. **The M-step / log-Cholesky** (`mstep_Lambda`, `lc_to_Λ`) hard-code 4×4 / the
   10-vector.

Levels 2–3 are mechanical to parameterise; **level 1 is the real blocker** and
retrofitting it risks the headline 2.18× engine. Per the task's own guidance
("do not force a broken partial"), the q=4 location-scale leaf was left as-is.

What *does* generalise cleanly is the **among-trait covariance block itself** —
the canonical comparative-biology coevolution object. The new module implements
multivariate Brownian motion of q traits with a shared q×q Λ on the tree and a
**diagonal** residual (all among-trait dependence lives in Λ, the standard
identification). Because the leaf likelihood is then **Gaussian in u**, the
problem is *conjugate*: `H_uu = P + blockdiag(per-leaf D⁻¹)` is constant in u,
the inner mode is a single sparse solve, and the **Laplace marginal is EXACT**.
That is the well-posed object on which "recover the among-trait correlation +
variances at q=6/q=8" is a meaningful test.

Reuses the genuinely q-agnostic primitives verbatim: `augmented_tree_precision`,
`prior_precision = kron(Q, Λ⁻¹)`, `random_balanced_tree`, the sparse N(0,P⁻¹)
sampler. New, q-generic: `lc_to_cov`/`cov_to_lc` (q×q log-Cholesky; coincides
with the engine's q=4 `lc_to_Λ`/`Λ_to_lc`), `coevo_marginal`, `fit_coevolution`
(LBFGS + central-FD gradient — ForwardDiff can't cross the CHOLMOD factor),
`simulate_coevolution`.

## Evidence (verified, standalone runs on this Mac)

`coevo_marginal` matches the dense closed-form `MvNormal` marginal to **rtol
1e-8** (the conjugate marginal is exact) — `test/test_coevo_q6.jl` testset 2.

q=6 recovery (p=120, nrep=5, n=600, seed 2024), `fit_coevolution`:

```text
converged=true  iters≈128  wall≈16 s
among-trait SD rel err (max)   0.08      (tol 0.2)
residual SD err (max)          0.015     (tol 0.06)
ρ12  0.61 (truth 0.6)   ρ34 0.47 (0.5)   ρ56 0.46 (0.4)   ρ13 0.45 (0.4)   ρ16 -0.32 (-0.3)
Λ Frobenius rel err            0.158     (tol 0.45)
```

5-seed stability (seeds 11/188/2024/7/99) at the same fixture: SD rel err
≤ 0.139, max corr err ≤ 0.247, σ_res err ≤ 0.021, all strong correlations
correct sign + within ~0.15 of truth — tolerances set with margin over this
spread (correlations have SE ∝ 1/√p, so weak/zero entries recover only loosely
at p=120, the same honest pattern the q=4 recovery gate settled on).

q=8 smoke (p=50, nrep=4, capped 120 iters, ~15 s): Λ is 8×8 and PD, θ length =
2q + q(q+1)/2 + q, the short fit improves the marginal, SD rel err ≤ 0.19,
residual err ≤ 0.03.

Regression: the existing q=4 phylo coevolution front-end test and the #14
FD-vs-exact gradient Q-gate are **bit-for-bit unchanged** (`max_abs_grad =
0.0752466442880162`, identical to baseline). Full `Pkg.test()` green.

Run:

```sh
julia --project=. -e 'include("test/test_coevo_q6.jl")'        # 47 tests pass
julia --project=. -e 'include("test/test_gaussian_bivariate_phylo.jl")'  # q4 unchanged
```

## Interpretation

The "coevolution model" in DRM.jl is the q=4 bivariate location-scale PLSM; its
*location-scale leaf* does not generalise to q traits without re-deriving a new
multivariate leaf likelihood. The *among-trait covariance block* — the part the
issue (#188) is really about — does generalise, and now works at q=6/q=8 on the
same sparse precision, with an exact conjugate marginal and verified recovery.

A natural follow-up: a trivariate (q=6) *location-scale* leaf with a 3×3 residual
correlation, if the location-scale generalisation (not just the coevolution
covariance) is wanted — that is the level-1 work above and is out of scope here.
