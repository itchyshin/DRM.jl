# check-log.md — DRM.jl gate status

Canonical per-slice gating status. One row per slice; cite the issue, the
verification command, and the result. This is a **shared resource** — check PR
overlap before editing. See `AGENTS.md` → *Definition of Done*.

| Date | Slice / Issue | Gate run | Result | By |
|---|---|---|---|---|
| 2026-05-30 | Phase 0 scaffold (#2) | `using DRM` load | ✅ loads ("DRM loaded OK"); found a stray load-time print in `sparse_aug_plsm.jl` (→ Phase 1.0) | Shannon |
| 2026-05-30 | Phase 0 scaffold (#2) | `Pkg.test()` | ✅ 13/13 pass (engine loads + phylo foundation) | Shannon |
| 2026-05-30 | Phase 0 scaffold (#2) | `julia --project=docs docs/make.jl` | ✅ 36 pages render (warnonly; 14 docstrings not yet in `@docs`) | Shannon |
| 2026-05-30 | Phase 0 scaffold (#2) | Workflow A + W0 smoke-run | ✅ script format valid; scaffold present | Shannon |
| 2026-05-30 | Phase 0 scaffold (#2) | headline bench logLik −256.51 | ⏭️ NOT re-run — `bench/run_*.jl` needs the Phase-1.0 path fix (HANDOVER §11); engine unchanged so verified number stands | Shannon |
| 2026-05-30 | Slice 1: Gaussian loc-scale (#18) | `Pkg.test()` + docs build | ✅ 17/17 (13 engine + 4 Gaussian recovery); docs `@example` blocks execute, no error markers | Shannon |
| 2026-05-30 | Slice 2: bivariate Gaussian ρ12 | `Pkg.test()` + docs build | ✅ 23/23 (+6 bivariate recovery incl. ρ12); fixed implicit-intercept (`y ~ x` now ⇒ `1 + x`); docs `@example` clean | Shannon |
| 2026-05-30 | Slice 3: random intercept (1\|g) | `Pkg.test()` + docs build | ✅ 27/27 (+4 RE recovery: β, residual σ, group SD via closed-form marginal); `which-scale` `@example` clean | Shannon |
| 2026-05-30 | Slice 6: Wald inference | `Pkg.test()` + docs build | ✅ `stderror` + `confint` (est ± z·se) on all model types; `model-workflow` `@example` clean. (Profile/bootstrap + predict/simulate deferred.) | Shannon |
| 2026-05-30 | Slice 7a: capability map | docs build | ✅ `model-map.md` rewritten to the live Gaussian surface (Stable / Verified engine / Planned); build clean | Shannon |
| 2026-05-30 | Slice (post-fit): fitted + residuals | `Pkg.test()` + docs build | ✅ all green; `fitted`/`residuals` on univariate/bivariate/RE (stored means+obs on DrmFit); `model-workflow` `@example` clean | Shannon |
| 2026-05-30 | Slice 5: meta_V (meta-analysis) | `Pkg.test()` + docs build | ✅ all green; `meta_V(v)` known sampling variances + heterogeneity τ recovered; `meta-analysis` `@example` clean | Shannon |
| 2026-05-30 | Slice: simulate | `Pkg.test()` + docs build | ✅ all green; `simulate(fit)` parametric replicate (univariate + bivariate); refit-recovers-coefs sanity; `model-workflow` `@example` clean | Shannon |
| 2026-05-30 | Slice: independent random slope (0+x\|g) | `Pkg.test()` | ✅ 9 testsets; weighted diagonal-capacitance marginal; fixed slope correctly targets β₁ + realized mean RE (finite-G); variance components recovered | Shannon |
| 2026-05-30 | Slice 4a: structured RE `relmat(1\|id, K)` | `Pkg.test()` + docs | ✅ 10 testsets; closed-form structured GLS (det-lemma + Woodbury, known K); recovers structured SD + residual σ. Engine for animal/phylo/spatial. `relmat-known-matrices` `@example` clean | Shannon |
| 2026-05-30 | Slice 4b: `animal(1\|id, A)` + `phylo(1\|species, tree)` | `Pkg.test()` + docs | ✅ both reuse the structured-GLS engine; phylo K from the verified `sigma_phy_dense`; recoveries pass; `phylogenetic-models` + `animal-models` `@example` clean | Shannon |
| 2026-05-30 | Slice: `bootstrap_ci` | `Pkg.test()` + docs | ✅ parametric bootstrap (simulate + refit percentiles); CIs bracket point estimates + cover truth; 300 refits ~1s | Shannon |
| 2026-05-30 | Slice 4c: `spatial(1\|site, coords)` | `Pkg.test()` + docs | ✅ exponential K(ρ)=exp(-d/ρ), range estimated; β + residual σ recovered, spatial variance detected. **All 4 structured markers done** (relmat/animal/phylo/spatial). `spatial-models` `@example` clean | Shannon |
| 2026-05-31 | Slice: `predict(fit, newdata)` | `Pkg.test()` + docs | ✅ population-level Xβ̂ on new data (univariate + bivariate); in-sample == fitted; formula stored on the fit via default ctor + `_withformula` (no fitter churn) | Shannon |
| 2026-05-31 | Slice: correlated RE `(1+x\|g)` | `Pkg.test()` | ✅ 2×2 block-diagonal capacitance (O(G), explicit 2×2 inv/det/solve, log-Cholesky Σ_re); recovers residual σ + RE SDs; `vc(fit)` accessor | Shannon |
| 2026-05-31 | Slice: multiple crossed RE `(1\|g)+(1\|h)` (#39) | `Pkg.test()` + docs | ✅ all green (17 files, +4 recovery: residual σ + per-grouping SDs); whitened-Woodbury dense capacitance `M=I+Z̃ᵀD⁻¹Z̃`, robust `check=false` factorization + finite penalty (rounding loses I at extreme σ; crossed cols rank-deficient), balanced variance-split init; `model-map` Stable + `@example` | Shannon |
| 2026-05-31 | Slice: profile-likelihood CIs (#38) | `Pkg.test()` + docs | ✅ all green (18 files, +12: profile brackets est, ≈ Wald on μ, default stays Wald); `confint(fit; method=:profile)` inverts LR (re-opt nuisance per fixed value, bracket+bisection); objective `nll` now stored on the fit (`_withnll`, all 8 fitters); verified generic on fixed/RE/bivariate; `model-workflow` `@example` executes | Shannon |
| 2026-05-31 | Slice: σ random effect `sigma ~ 1+(1\|g)` (#40) | `Pkg.test()` + docs | ✅ all green (19 files, +5 recovery: μ, σ-intercept, σ_b); GHQ marginal (32-node Gauss–Hermite per group, Golub–Welsch nodes, logsumexp) — no Laplace/engine surgery; numerics pre-validated in scratch before slice; `re_sd(fit)[:g]`=scale-RE SD; `model-map` Stable + `location-scale` `@example`. **All Gaussian modelling surfaces now Stable.** | Shannon |
| 2026-05-31 | Docs: reflect completed Gaussian surface | docs build | ✅ landing page capability table rewritten (full Gaussian surface = Stable, honest); fixed stale "planned" tags (which-scale `meta_V`, structural-dependence spatial/animal/relmat, get-started understatement, location-scale LRT note); structural-dependence overview filled (4-marker table + links); build clean | Shannon |
