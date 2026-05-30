# DRM.jl — Handover & Roadmap

**Reader:** the developer (human, Codex, or Claude) who will turn this scaffold
into a released `DRM.jl` package. **Purpose:** hand over a *verified* proof-of-
concept engine with an honest map of what is solid, what is experimental, and the
exact ordered work to reach v0.1.0 — so you can start without re-deriving context.

**One-line scope:** `DRM.jl` is the Julia "digital twin" of the R package
**drmTMB** (univariate & bivariate *distributional* regression — a formula per
distributional parameter μ/σ/ρ, plus families, random effects, phylogenetic and
spatial structure, meta-analysis). It mirrors the **gllvmTMB → GLLVM.jl** move.
This scaffold delivers the hardest piece first: a fast, robust engine for the
**q=4 phylogenetic bivariate location–scale model (PLSM)** — drmTMB's selling
point (Nakagawa et al. 2025 MEE, Model 5).

---

## 1. What is verified (the reason this package exists)

Same model, same real `q4_p100` data, same Laplace ML marginal as drmTMB.
Reproduced independently in this repo (`bench/run_sparse_tmb_nd.jl`,
`bench/run_scaling.jl`, `src/experimental/infer_q4.jl`). Full table +
honest caveats: `report/comparison-grid.md`.

| Claim | Number | Status |
|---|---|---|
| Single fit p=100 vs drmTMB | **1.14 s vs 2.48 s = 2.18×**, logLik −256.51≈−256.52, converged | ✅ verified, head-to-head |
| O(p) scaling (per-dim-variance, nrep=4) | p=10,000 in **113 s, k≈1.08** | ✅ verified |
| Location-only (conjugate) cell | **EM 3.1× faster than LBFGS**, same MLE | ✅ verified — conjugacy thesis |
| Inference at the variance boundary | Wald valid **16/17** params (drmTMB sdreport = all-NaN); bootstrap 60/60 | ✅ verified — a genuine inferential edge |
| REML mean-axis bias correction | Λ[1,1] 0.70 → 0.83 (×1.18) | ⚠ partial (mean-axis only) |

**The defensible scientific story:** DRM.jl matches drmTMB's fit, runs 2.18×
faster, scales near-perfect O(p) where gllvmTMB's multi-trait gradient is O(p²)
(their own code: `sparse_phy_grad.jl` "slope≈2"), EM wins on conjugate sub-models,
and it returns *usable uncertainty where drmTMB's Hessian fails entirely*.

**Do NOT oversell:** the "~12× at p=10,000 vs drmTMB" is **extrapolated** from
drmTMB's measured slope, not measured at scale on the same nrep=4 data. The
scaling curve uses the synthetic per-dimension-variance model with replicates.

---

## 2. Architecture (how the engine works)

Latent: **augmented state**, node-major over the `2p−1` tree nodes × 4 axes
`(μ1, μ2, logσ1, logσ2)`; data attach only at the p leaf nodes.

- **Prior precision** `P = kron(Q_topology, Λ⁻¹)` — sparse, O(p) nnz, well-
  conditioned (Hadfield–Nakagawa). *Never forms a dense Σ_phy* (that was the
  original 229 s / NaN failure). `sparse_phy.jl`, `prior_precision`.
- **Laplace marginal** `L(θ) = −jn(û,θ) − ½logdet H_uu + ½logdet P`. The inner
  mode û is the **E-step**: `estep_mode` in `sparse_aug_plsm.jl` — a **fast-path
  (cheap damped Newton, accept once ‖∇u‖<1e-3) with a robust trust-region LM
  fallback** (hybrid Fisher/observed Hessian, anti-collapse trust region). This
  is the merged result of a 4-strategy search; it is the single biggest
  robustness + speed lever.
- **Exact O(p) gradient** `marginal_and_exact_grad` (`fit_q4_sparse_tmb.jl`):
  cheap term + implicit-function correction, all CHOLMOD-blocked log-det
  derivatives via **Takahashi selected inversion** (`takahashi_selinv.jl`) at the
  sparse pattern. Validated to 1e-6 vs finite-diff. **This O(p) gradient is the
  edge over gllvmTMB's O(p²) multi-trait gradient.**
- **Optimiser**: LBFGS + MoreThuente, **mean-objective** normalisation (scale-
  invariant across p), Inf barrier on PD/ρ-guard violations, **relative-objective
  stopping** (the Watanabe-singular variance boundary makes ‖g‖ plateau — gradient-
  norm stopping never fires; drmTMB reports "false convergence (8)" at the same
  spot).
- **O(p) data sampler** (`bench/run_scaling.jl` `gen`): draws `u ~ N(0,P⁻¹)` via
  sparse `cholesky(P)` + a triangular solve (CHOLMOD `F.UP \ z`), verified
  `Cov(û)≈P⁻¹` at p=8. Replaces the dense-Σ_phy O(p³) generator (capped ~p=3000).

### Core files (`src/`, wired into the module)
`sparse_phy.jl` · `takahashi_selinv.jl` · `sparse_aug_plsm.jl` (E-step + Hessians
+ leaf NLL) · `sparse_em_fit.jl` (`make_problem(...; species=)`, `mstep_*`) ·
`fit_ml_q4.jl` (EM infra) · `fit_q4_sparse_tmb.jl` (exact gradient + the fit) ·
`DRM.jl` (module).

### Experimental files (`src/experimental/`, migrated, NOT wired)
`infer_q4.jl` (Wald + bootstrap) · `reml_q4.jl` (Laplace-REML, Schur complement) ·
`location_only.jl` (conjugate Gaussian phylo: EM vs LBFGS) · `fit_em_natgrad.jl`
(natural-gradient EM) · `estep_{lm,trustregion,armijoguard,initprior}.jl` (the
mode-finder candidates — `estep_lm`'s hybrid Fisher idea is what was merged) ·
dense oracle (`q4_em_dense.jl`, `fit_q4_tmbgrad.jl`).

---

## 3. Gotchas (read before touching the engine)

1. **lc3/lc7 removable singularity.** At `ρ=0` + diagonal Λ the gradient w.r.t.
   the within-response μ↔logσ Cholesky entries blows up (a 0/0 funnel). Fix in
   place: start Λ0 **off-diagonal** (ε-nudge). Auto-detecting this for arbitrary
   user data is an open item.
2. **Scale-RE identifiability.** With **one observation per species** the per-leaf
   scale latents are unanchored → the inner objective is unbounded below at scale
   (a real model degeneracy, proven by a 4-agent search). Use **nrep ≥ 2**
   replicates (the modeling fix the user chose). This is statistics, not a bug.
3. **Singular variance boundary (Watanabe).** Near sd_phy→0 the Fisher info is
   degenerate; ‖g‖ plateaus and drmTMB's `sdreport` returns NaN. Use relative-
   objective stopping; for inference prefer bootstrap / χ̄² over Wald there.
4. **Dense-Σ_phy generator caps ~p=3000** — always use the O(p) precision sampler
   for large p.

---

## 4. Roadmap to v0.1.0 (ordered)

**A. Package hygiene (do first).**
1. Wire a clean module: the migrated files use script-style `include` chains and
   a couple of top-level `println("… loaded")`. Resolve to a single base include,
   remove the load-time prints, and define a deliberate public API. Make
   `Pkg.instantiate(); using DRM; Pkg.test()` green (see `test/runtests.jl`; the
   migrated `test/*.jl` need path/`using DRM` fixes).
2. Add `Manifest.toml`, `docs/` Documenter site, `TagBot.yml`/`Documenter.yml`
   (mirror GLLVM.jl), and a `bench/Project.toml` (CSV, DataFrames, BenchmarkTools).

**B. Wire the experimental engines into the API.**
3. `fit` dispatch + a `bf()`-style multi-formula front end (mirror drmTMB's
   `bf(mu1=…, mu2=…, sigma1=…, sigma2=…, rho12=…)`; StatsModels.jl). Keep `sigma`
   (not `tau`), `rho12` for residual correlation, meta-analysis as `gaussian()` +
   `meta_known_V`.
4. Inference module from `infer_q4.jl`: Wald + parametric bootstrap (port the
   GLLVM.jl `confint*` patterns; `report/GLLVM-porting-playbook.md`). **Thread the
   bootstrap** — the threading lever was *not yet measured end-to-end* (verified
   run was serial 39 s; warm-start is NOT a lever, tested 0.8×).

**C. Open research items (verify before claiming).**
5. **REML scale-axis**: the bias-correction is verified only for the mean-axis
   variances; the scale-axis behaviour and an exact REML gradient are open. Keep
   **ML as the default** (REML likelihoods aren't comparable across fixed-effect
   structures — needed for model selection).
6. **χ̄² boundary inference** (Self–Liang 1987; Stram–Lee 1994) for variance
   components at the boundary — motivated, not implemented.
7. **drmTMB head-to-head at scale**: run drmTMB on the same nrep=4 data at
   p=500/1000 to replace the extrapolated scaling comparison with a measured one.

**D. The v0.1.0 pilot scope** (from the original plan): a Gaussian-only,
fixed-effects pilot — univariate + bivariate distributional regression with the
closed-form Gaussian marginal — shipped with the bench/ADEMP harness against
drmTMB, *then* grow toward the phylogenetic Laplace path that already works here.

---

## 5. GitHub remote — OPEN DECISION (do not push without confirming)

The scaffold is `git init`'d locally only. Before pushing, confirm:
- **Owner/name**: `github.com/itchyshin/DRM.jl` (matches the GLLVM.jl convention)?
- **Visibility**: public or private at this pilot stage?
- **CI**: `.github/workflows/CI.yml` is Linux-only, PR + `workflow_dispatch`
  (cost-disciplined). Add macOS/Windows + a `main` push trigger only at release.

---

## 6. Provenance (`report/`, 13 docs — the full record)

`comparison-grid.md` (the verified grid) · `plan-and-timings.md` (the running
log: every measurement, dead-end, and fix) · `info-geometry-scout.md` (Amari/
Watanabe insights: natural-gradient = AI-REML, the singular boundary) ·
`why-q4-plsm-matters.md` · `q4-laplace-findings.md` · `q4-sparse-status.md` ·
`laplace-design.md` · `DRM-architecture.md` · `em-acceleration-recipe.md` ·
`drmTMB-q4-numerical-recipes.md` · `three-way-comparison.md` ·
`GLLVM-porting-playbook.md` · `summary.md`.

---

## 7. How to verify this scaffold right now

```bash
cd DRM.jl
# module loads (deps must be instantiated first for a clean env):
julia --project=. -e 'using Pkg; Pkg.instantiate(); using DRM; println("DRM loaded")'
# reproduce the head-to-head + scaling (uses bench fixtures):
julia --project=. bench/run_sparse_tmb_nd.jl     # expect ~1.1 s, logLik −256.51, 2.18×
julia --project=. bench/run_scaling.jl           # expect k≈1.08 to p=10,000
```

*Honest note: until step A.1 (clean module wiring), `bench/` runners may need the
poc env or small path fixes — they were validated in `drm-julia-poc/`, the source
of this migration.*
