# After-task: #166 beta-binomial phylo + crossed sparse Laplace

Date: 2026-08-02 · closes #166

## Summary

Generalized the already-verified Beta family analytic kernel
(`src/beta.jl`'s `:beta_fixed` in `src/sparse_laplace_glmm.jl`) to
beta-binomial's discrete known-trials data term, then routed
`BetaBinomial()`'s `drm()` through the sparse augmented-state Laplace engine
for a phylogenetic random intercept on the logit mean
(`phylo(1 | species)` + `tree = ...`) and its crossed analogue
(`(1 | g) + (1 | h)`), constant-σ (overdispersion) only. This is a mechanical
kernel generalization — shifted digamma/trigamma/polygamma arguments
(`s+a`, `n-s+b`, `n+φ`) replace Beta's `(a, b)` — not a new derivation or a
q=4 engine change; no file under `src/fit_q4_sparse_tmb.jl` /
`src/sparse_aug_plsm.jl` was touched.

## What landed

- Design note: `docs/dev-log/plans/2026-08-02-166-betabinomial-kernel-design.md`
  — the full mean-axis (`A`/`B`/`C`) and nuisance-axis (`dL`/`dA`/`dB`)
  derivation.
- `:betabinomial_fixed` kernel in `src/sparse_laplace_glmm.jl`: value / d1 / d2 /
  d3 / mean / obs / d12 / v123 on the η-axis, plus value / d1 / d2 / v123 on the
  φ (nuisance) axis. Verified against ForwardDiff (nested AD, not naive
  central-FD, which is numerically unstable past first order) to machine
  precision on both axes.
- `_betabinomial_laplace_setup`, `_fit_betabinomial_phylo_laplace`,
  `_fit_betabinomial_crossed_laplace` in `src/sparse_laplace_glmm.jl`; added an
  `extra_scales` kwarg to `_fit_phylo_mean_laplace_nuisance` /
  `_fit_general_mean_laplace_nuisance` / `_fit_crossed_mean_laplace_nuisance` so
  `:trials` reaches the fitted object's `scales` (needed by
  `quantile_residuals.jl`).
- `src/betabinomial.jl`: `drm()` now accepts `tree =` and `se =`, routes
  `phylo(1 | group)` and crossed `(1 | g) + (1 | h)` random intercepts on the
  mean to the new fitters, and rejects (with explicit `error()`s) combining
  phylo/crossed with ordinary random effects, `meta_V`, and any non-constant
  `sigma` formula.
- Tests: `test/test_betabinomial_phylo_laplace.jl` (recovery + public-API FD
  gradient + error checks, 9 pass), `test/test_betabinomial_crossed_laplace.jl`
  (recovery + low-level FD≤1e-6 gate + error check, 12 pass), a new "Beta-binomial
  phylo Laplace gradient gate (#166): FD-vs-exact ≤ 1e-6" testset in the
  standing `test/test_nongaussian_phylo_grad_gate.jl` (achieves 6.6e-8). All
  wired into `test/runtests.jl`.
- Docs: `docs/src/capabilities.md` capability-matrix row updated
  (`intercept + slope + crossed + phylo`); `docs/src/tutorials/phylogenetic-models.md`
  updated (family list + a runnable `BetaBinomial()` phylo `@example`, recovers
  `σ_phylo` ≈ 0.32 vs a true 0.35).

## Rose audit (claim-vs-evidence)

| Claim | Verdict |
|---|---|
| Kernel matches ForwardDiff to machine precision (η-axis and φ-axis) | **PASS** — verified interactively before landing |
| Analytic-vs-FD gradient gate ≤ 1e-6 (phylo + crossed) | **PASS** — 6.6e-8 (phylo), 7.7e-8 (crossed) |
| Parameter recovery (phylo + crossed) | **PASS** — focused test files green |
| No regression in existing BetaBinomial routes (`(1|g)`, `(1+x|g)`, fixed) | **PASS** — `test_betabinomial{,_re,_slope_re}.jl` re-run green |
| No `src/` q=4 engine files touched | **PASS** — diff confined to `src/sparse_laplace_glmm.jl` + `src/betabinomial.jl` |
| Nonconstant-σ beta-binomial | **OUT OF SCOPE** — rejected with explicit `error()`; tracked separately (#166's own acceptance bar) |
| Registrator / General | **OUT** — D-111, untouched |
| GPL vendoring | **OUT** — no drmTMB source touched; kernel is fresh algebra from the design note |

## Not covered

- Nonconstant-σ beta-binomial (structured or predictor-driven overdispersion).
- q>1 non-Gaussian phylo, and the non-Gaussian phylogenetic location–scale
  extension (#202).
- Combining phylo/crossed random effects with an ordinary `(1|g)` on the mean
  in the same fit.

## Verify

```bash
julia --project=test test/test_betabinomial_phylo_laplace.jl     # 9 pass
julia --project=test test/test_betabinomial_crossed_laplace.jl   # 12 pass
julia --project=test test/test_nongaussian_phylo_grad_gate.jl     # incl. beta-binomial gate 6.6e-8
julia --project=test test/runtests.jl                             # full Pkg.test() equivalent
```

## CI follow-up

The first push (local macOS/Julia 1.10 green throughout) hit one flaky
recovery assertion in CI (Linux/Julia 1.12): `test_betabinomial_crossed_laplace.jl`'s
`abs(re_sd(fit)[:h] - σh) < 0.15` evaluated `0.15577 < 0.15` — false by 0.006.
Root cause: the original fixture used only `G=14`/`H=12` groups, where ML
variance-component recovery is both small-sample-biased (known; ML shrinks
variance components downward relative to REML) and sensitive to
platform-level floating-point differences (BLAS/libm) propagating through the
Laplace Newton iterations on 12 groups' worth of curvature. Fix: scaled the
fixture to `G=28`/`H=24`/`n=2400` — the same order as the pre-existing
`test_crossed_laplace_generic.jl` fixture — which gave `σg`/`σh` errors of
0.01–0.11 across five independent reseeds (all comfortably inside the 0.15
bound), vs. the original's single marginal draw.
