# DRM.jl — Project Handover & Roadmap

> **Reader:** whoever continues `DRM.jl` (human, Codex, or Claude). **Purpose:**
> hand over a *verified* proof-of-concept engine plus the full journey, the
> architecture, the traps, and the exact ordered path to v0.1.0 — so you start
> from knowledge, not from scratch. Every number here was reproduced by an
> independent run; don't lower that bar.

---

## 0. TL;DR

- **What:** `DRM.jl` is the Julia twin of the R package **drmTMB**
  (univariate & bivariate *distributional* regression — a formula per parameter
  μ/σ/ρ). It mirrors the **gllvmTMB → GLLVM.jl** move. Sister to GLLVM.jl.
- **Why it exists:** drmTMB's selling-point model — the **q=4 phylogenetic
  bivariate location–scale model (PLSM)** — is wall-clock-bound by R/TMB in
  simulation studies. A fast Julia engine makes bootstrap / coverage / power
  studies feasible.
- **Verified:** **2.18× faster than drmTMB** on the q=4 single fit (same data,
  same marginal), **near-perfect O(p) to 10,000 species**, and **valid confidence
  intervals where drmTMB's Hessian fails entirely**.
- **State:** published at **https://github.com/itchyshin/DRM.jl** (MIT, public);
  **v0.1.0 and v0.1.1 tagged**. The `drm()` / `bf()` front end is wired, all
  **13 families** (12 univariate + bivariate Gaussian) are implemented, exported,
  and recovery-tested, and **inference is wired** in `src/inference.jl` (Wald +
  profile + bootstrap; `infer_q4` graduated). `src/experimental/` (REML,
  location-only, EM variants) remains migrated but **not yet wired**.
- **Next:** Phase 1.1 R-parity gate + Phase 3 articles, and the
  variational-approximation track (issue #136).

---

## 1. The mission

Build **the fastest mixed-model fitting engine** for the drmTMB model class, in
Julia, so the simulation studies that are bottlenecked by the R/TMB engine
(ADEMP coverage grids, parametric bootstrap, power) become cheap. The precedent:
the team's GLLVM.jl pilot hit ~340× over R/gllvmTMB on the closed-form Gaussian
case. The open question this PoC answered: **can Julia also win on the *hard*
model** — the q=4 PLSM (Nakagawa et al. 2025 MEE, Model 5), where a shared
phylogenetic random effect drives `(μ1, μ2, log σ1, log σ2)` and the nonlinear
scale dependence means **no closed-form marginal** (it needs a Laplace
approximation)? brms/Stan: ~122 h. drmTMB (R/TMB): ~2.5 s at p=100. **Answer:
yes — 2.18× at p=100, and it scales where the alternatives can't.**

---

## 2. Bottom line — verified results

Same model, same real `q4_p100` data, same Laplace ML marginal as drmTMB.
Reproduced independently (`bench/run_sparse_tmb_nd.jl`, `bench/run_scaling.jl`;
inference now in `src/inference.jl`). Full grid + caveats: `report/comparison-grid.md`.

| Claim | Number | Status |
|---|---|---|
| **Single fit p=100 vs drmTMB** | **1.14 s vs 2.48 s = 2.18×**; logLik −256.51 ≈ −256.52; converged (drmTMB: "false convergence 8") | ✅ head-to-head |
| **O(p) scaling** (per-dim-variance, nrep=4) | p=100/1k/5k/**10k** = 0.77 / 4.5 / 49.5 / **112.9 s**; **k≈1.08** | ✅ verified |
| **Location-only (conjugate)** | **EM 3.1× faster than LBFGS** (p=200/1k), same MLE | ✅ conjugacy thesis |
| **Inference at the variance boundary** | Wald valid **16/17** params (drmTMB sdreport = all-NaN); bootstrap **60/60** | ✅ a genuine inferential edge |
| **REML mean-axis bias correction** | Λ[1,1] 0.70 → 0.83 (×1.18) | ⚠ mean-axis only |

**Defensible story:** DRM.jl matches drmTMB's fit, runs 2.18× faster, scales
near-perfect O(p) (where gllvmTMB's multi-trait gradient is O(p²) — *their* code,
`sparse_phy_grad.jl`, "slope≈2"), EM wins on conjugate sub-models, and it returns
usable uncertainty where drmTMB's Hessian is singular.

**Do NOT oversell:** the "~12× vs drmTMB at p=10,000" is **extrapolated** from
drmTMB's measured slope, not measured at scale on the same nrep=4 data. The
scaling curve uses the synthetic per-dimension-variance model with replicates.
The threaded-bootstrap speedup is **unmeasured** (the verified run was serial,
39 s); warm-start is **not** a lever (tested: 0.8×).

---

## 3. The model

q=4 PLSM, the bivariate location–scale instance: responses `(y1, y2)`, with a
shared phylogenetic random effect on four axes `(μ1, μ2, log σ1, log σ2)` via a
4×4 between-species covariance Λ (a **separate phylo variance per axis** + cross-
covariances — biologically richer than one global variance), and a residual
correlation ρ. The public drmTMB-shaped front end is
`bf(mu1=…, mu2=…, sigma1=…, sigma2=…, rho12=…)`, with matching
`phylo(1 | species)` markers required on the four location/scale axes for the
q=4 route. **Keep `sigma` (not `tau`), `rho12` for residual correlation. ML is
the default** (REML likelihoods aren't comparable across fixed-effect structures
— needed for model selection); REML is an option.

---

## 4. Architecture (how the engine works)

Latent: **augmented state**, node-major over the `2p−1` tree nodes × 4 axes;
data attach only at the p leaf nodes.

- **Prior precision** `P = kron(Q_topology, Λ⁻¹)` — sparse, O(p) nnz, well-
  conditioned (Hadfield–Nakagawa). *Never forms a dense Σ_phy.* → `sparse_phy.jl`,
  `prior_precision`.
- **Laplace marginal** `L(θ) = −jn(û,θ) − ½logdet H_uu + ½logdet P`. The inner
  mode û (the **E-step**) is `estep_mode` in `sparse_aug_plsm.jl`: a **fast-path
  (cheap damped Newton, accept once ‖∇u‖<1e-3) with robust trust-region LM
  fallback** (hybrid Fisher/observed Hessian, anti-collapse trust region). The
  single biggest robustness+speed lever; merged from a 4-strategy search.
- **Exact O(p) gradient** `marginal_and_exact_grad` (`fit_q4_sparse_tmb.jl`):
  cheap term + implicit-function correction; all CHOLMOD-blocked log-det
  derivatives via **Takahashi selected inversion** (`takahashi_selinv.jl`) at the
  sparse pattern. Validated to 1e-6 vs finite-diff. **This is the edge over
  gllvmTMB's O(p²) multi-trait gradient.**
- **Optimiser:** LBFGS + MoreThuente, **mean-objective** normalisation (scale-
  invariant across p), Inf barrier on PD/ρ-guard violations, **relative-objective
  stopping** (the singular variance boundary makes ‖g‖ plateau; gradient-norm
  stopping never fires — same spot where drmTMB reports "false convergence 8").
- **O(p) data sampler** (`bench/run_scaling.jl` `gen`): `u ~ N(0,P⁻¹)` via sparse
  `cholesky(P)` + triangular solve (`F.UP \ z`); verified `Cov(û)≈P⁻¹` at p=8.
  Replaces the dense-Σ_phy O(p³) generator (capped ~p=3000).

**Core files** (`src/`, wired): `sparse_phy` · `takahashi_selinv` ·
`sparse_aug_plsm` · `sparse_em_fit` (`make_problem(...; species=)`, `mstep_*`) ·
`fit_ml_q4` · `fit_q4_sparse_tmb` · the family modules (`gaussian_*`, `student`,
`poisson`, `negbinomial`, `beta`, `betabinomial`, `binomial`, `gamma`,
`lognormal`, `zeroonebeta`, `tweedie`, `cumulative`) · `inference` (Wald +
profile + bootstrap; `infer_q4` graduated here) · `summary` · `visualization` ·
`DRM.jl`.
**Experimental** (`src/experimental/`, migrated, still NOT wired): `reml_q4`
(Laplace-REML) · `location_only` (conjugate EM vs LBFGS) · `fit_em_natgrad`
(natural-gradient EM) · `estep_{lm,trustregion,armijoguard,initprior}`
(mode-finder candidates) · dense oracle (`q4_em_dense`, `fit_q4_tmbgrad`).

---

## 5. The journey — what was built, and the dead-ends (so you don't re-walk them)

1. **Dense Laplace failed** (229 s / NaN): forgot the sparse Hadfield–Nakagawa
   precision and nested AD. → the **sparse augmented-state** route. *Lesson: never
   form dense Σ_phy; use the sparse precision + Takahashi.*
2. **The "12.5 s/eval O(p²) bug" was a myth** — a prior session *assumed* it and
   never profiled. Measured: the exact gradient is **16.5 ms**, fully O(p). The
   real blocker was **2 of 17 gradient components** (the within-response μ↔logσ
   Cholesky entries) — a **removable singularity at the ρ=0 + diagonal-Λ init**.
   Fixed by starting Λ0 off-diagonal. *Lesson: verify, don't trust prior claims.*
3. **Line search**, not start point, caused a 120-iter crawl: `BackTracking` is
   Armijo-only. **MoreThuente** (Wolfe) → the 1.86×→2.18× win.
4. **SQUAREM: tested, rejected** — it accelerates EM iteration *count*, but the
   finite-diff per-iter cost dominated (15.6 s, *slower*). The exact gradient was
   the real lever, not convergence tricks.
5. **The EM stalls on location-scale** (−259.79, suboptimal): block-coordinate
   ascent can't navigate the β↔σ coupling in the non-conjugate model. *Verified
   negative.* Joint quasi-Newton (TMB-like) is the right engine here. **But EM
   wins on the conjugate location-only model (3.1×)** — the **conjugacy thesis**,
   now measured both ways.
6. **The scale-RE degeneracy** (a 4-agent search *proved* it): with **1 obs per
   species** the inner objective is unbounded below at scale (the scale latents
   slide to σ→0). The Watanabe-singular boundary the info-geometry scout flagged.
   **Fix: nrep ≥ 2 replicates** (a modeling decision). This is statistics, not a
   solver bug — no mode-finder can find a mode that doesn't exist.
7. **Warm-start across a bootstrap grid: negative result** (0.8×) — the flat-
   region crawl dominates per-fit cost, not the approach distance.
8. **Robust mode-finder merge** then **fast-path-fallback** recovered speed
   (4.83 → 1.14 s) while keeping robustness; **multi-obs refactor** + **O(p)
   sampler** unlocked p=10,000; the **comparison suite** (location-only / REML /
   inference / grid) closed it out.

**Cross-cutting disciplines that made this work** (keep them):
- **Verify before claiming** — every headline was reproduced by an independent
  run; this caught the "12.5 s myth", the lc3/lc7 bug, and a stale auto-grid.
- **Autonomous workflows with verify-and-revert** — each optimization backed up
  the file, ran its gate, and reverted on failure, so the baseline never broke.
- **Information geometry** (scout): natural gradient ≡ Fisher scoring ≡ AI-REML;
  the variance-boundary plateau is degenerate Fisher info (Watanabe), not a bug.

---

## 6. Gotchas (read before touching the engine)

1. **lc3/lc7 removable singularity** — at ρ=0 + diagonal Λ the within-response
   μ↔logσ Cholesky gradient blows up (0/0 funnel). Start Λ0 **off-diagonal**.
   Auto-detecting this for arbitrary user data is open.
2. **Scale-RE identifiability** — use **nrep ≥ 2** obs/species, or the inner
   objective is unbounded below at scale.
3. **Singular variance boundary (Watanabe)** — near sd_phy→0, ‖g‖ plateaus and
   drmTMB's `sdreport` returns NaN. Use relative-objective stopping; for inference
   prefer bootstrap / χ̄² over Wald there.
4. **Dense-Σ_phy generator caps ~p=3000** — always use the O(p) precision sampler
   at large p.

---

## 7. Current repo state

Published, MIT, public; **v0.1.0 and v0.1.1 tagged**. `src/` core loads cleanly
(`using DRM` resolves the include chain + exports). The `drm()` / `bf()` front
end, all 13 families (12 univariate + bivariate Gaussian), and the inference
surface (Wald + profile + bootstrap) are wired and exported; families are
validated by simulation parameter recovery (the numerical drmTMB-parity gate is
#17). `src/experimental/` (REML, location-only, EM variants) is migrated but
**not wired**. `bench/` has runnable benchmarks + the `q4_p100` fixtures + the R
fixture-gen. `report/` has all 13 design/provenance docs. CI is Linux-only, PR +
`workflow_dispatch` (cost-disciplined). **Honest:** the engine still carries some
of the PoC's script-style includes (one stray load-time print still fires from
`sparse_aug_plsm.jl:267`; cleanup tracked under Workflow A).

---

## 8. Roadmap to v0.1.0 (ordered)

> **Update (Phase 0, 2026-05-30):** the team ([`AGENTS.md`](AGENTS.md)), the 10
> scripted workflows (`.claude/workflows/`), the Documenter shell (`docs/`),
> `bench/Project.toml`, `TagBot.yml` / `Documenter.yml`, and the GitHub Issues
> ledger now exist. See [`ROADMAP.md`](ROADMAP.md) for the live phase plan; the
> engine steps below (A–D) remain the substantive roadmap.

**A. Package hygiene (first).** Wire a clean module (single base include, remove
load-time prints, deliberate public API); make `Pkg.instantiate(); using DRM;
Pkg.test()` green (the migrated `test/*.jl` need path/`using DRM` fixes); add
`Manifest.toml`, `docs/` Documenter site, `TagBot.yml`/`Documenter.yml`,
`bench/Project.toml`.
**B. Wire `experimental/` into the API.** The q=4 bivariate `bf()` front end and
`infer_q4` inference path are now public; remaining migrated pieces include
`reml_q4`, `location_only`, and EM variants. **Thread the bootstrap** and
*measure* the speedup (currently unrun end-to-end).
**C. Open research items.** REML scale-axis + exact REML gradient (keep ML
default); χ̄² boundary inference (Self–Liang 1987; Stram–Lee 1994); drmTMB
head-to-head at nrep=4/p>100 to replace the extrapolated scaling comparison.
**D. v0.1.0 pilot scope.** Gaussian-only, fixed-effects pilot (univariate +
bivariate distributional regression, closed-form marginal) shipped with the
bench/ADEMP harness vs drmTMB; then grow toward the phylogenetic Laplace path
that already works here.

---

## 9. Decisions

**Made:** package name `DRM` (drops the TMB suffix, matches GLLVM.jl pattern);
**MIT license** (Julia-ecosystem norm + matches GLLVM.jl; DRM.jl is fresh code,
not a port of drmTMB's GPL source, so it's legally free to be MIT); **public**
repo at `itchyshin/DRM.jl`; cost-disciplined CI.
**Open:** the v0.1 pilot scope cut; whether to vendor any drmTMB GPL source later
(would force GPL — avoid, or isolate); registration in the Julia General registry
(after v0.1 + tests green).

---

## 10. Provenance (`report/`, 13 docs — the full record)

`comparison-grid.md` (verified grid) · `plan-and-timings.md` (the running log:
every measurement, dead-end, fix) · `info-geometry-scout.md` (Amari/Watanabe:
natural-gradient = AI-REML; the singular boundary) · `why-q4-plsm-matters.md` ·
`q4-laplace-findings.md` · `q4-sparse-status.md` · `laplace-design.md` ·
`DRM-architecture.md` · `em-acceleration-recipe.md` ·
`drmTMB-q4-numerical-recipes.md` · `three-way-comparison.md` ·
`GLLVM-porting-playbook.md` · `summary.md`. Original scratch lives in the
`drm-julia-poc/` folder (not migrated).

---

## 11. How to verify right now

```bash
cd DRM.jl
julia --project=. -e 'using Pkg; Pkg.instantiate(); using DRM; println("DRM loaded")'
julia --project=. bench/run_sparse_tmb_nd.jl   # ~1.1 s, logLik −256.51, 2.18× vs drmTMB
julia --project=. bench/run_scaling.jl         # k≈1.08 to p=10,000
```

*Until step A.1 (clean module wiring), `bench/` runners may need the poc env or
small path fixes — they were validated in `drm-julia-poc/`, the migration source.*
