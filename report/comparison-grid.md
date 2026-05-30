# Engine × model × objective comparison grid

*Generated 2026-05-30 (corrected). Engines: drmTMB (R/TMB/CppAD/nlminb);
Julia-TMB-like (fit_q4_sparse_tmb.jl + sparse_aug_plsm.jl, MoreThuente LBFGS,
fast-path + robust-LM fallback); Julia-EM (natural-gradient / closed-form).*

> Correction note: an earlier auto-generated version of this file marked the
> location-only, REML, and inference cells "not run" — that was a consolidation
> bug (the grid step received empty inputs). Those cells DID run and are filled
> in below; numbers re-verified where noted.

---

## 1. Engine × objective × model grid (p = 100, q = 4 PLSM)

| Objective | Model | Engine | result | wall | notes |
|---|---|---|---|---|---|
| **ML** | location-scale | drmTMB | LL −256.52, conv=false(8) | 2.48 s | mature; nlminb plateau |
| ML | location-scale | Julia-EM | LL −259.79 (suboptimal) | 2.9 s | block-coord stalls on β↔σ coupling — *verified negative* |
| **ML** | location-scale | **Julia-TMB-like** | **LL −256.51, conv=true** | **1.14 s** | **2.18× faster than drmTMB** ✓verified |
| **ML** | location-only | **Julia-EM** | recovers MLE, EM=LBFGS | EM 0.18 s | **EM 3.1× faster than LBFGS** (conjugate home turf) ✓ |
| ML | location-only | Julia-TMB-like(LBFGS) | recovers MLE | 0.57 s | reference for the EM win |
| ML | location-only | drmTMB | — | — | not run (R side) |
| **REML** | location-scale | **Julia-TMB-like** | built (reml_q4.jl) | ~6 s/p=100 | Λ[1,1] REML 0.83 > ML 0.70 (mean-axis inflation) ✓ partial |
| REML | location-scale | drmTMB | — | — | not run (R side) |
| REML / location-only | — | — | — | — | not run |

---

## 2. Head-to-head single fit — drmTMB vs Julia-TMB-like  ✓ VERIFIED
*Same model, same real q4_p100 data, same Laplace ML marginal.*

| | drmTMB | Julia-TMB-like |
|---|---|---|
| logLik | −256.52 | **−256.51** (Δ=0.01, Julia higher) |
| wall | 2.48 s | **1.14 s** → **2.18× faster** |
| converged | false (code 8) | **true** |

Both sit at the Watanabe-singular variance boundary (sd_phy[3,4]≈0.1–0.2); the
logLik gap is 0.01 and both flag the plateau (drmTMB "false convergence 8";
Julia g_resid=1.7e-3). Model-geometry artefact, not an engine bug.

---

## 3. O(p) scaling — biological per-dimension-variance model  ✓ VERIFIED
*4×4 Λ (separate phylo variance per axis + cross-cov); nrep=4 replicates; O(p)
sparse-precision sampler (CHOLMOD, Cov(û)≈P⁻¹ at p=8, rel-err 0.023). Julia-TMB-like.*

| p (×4 obs) | wall | iters | per-obs logLik |
|---|---|---|---|
| 100 | 0.77 s | 37 | −2.09 |
| 1000 | 4.49 s | 15 | −2.36 |
| 5000 | 49.5 s | 22 | −2.35 |
| **10000** | **112.9 s** | 23 | −2.61 |

**k = 1.08 (near-perfect O(p))**, flat iters, consistent per-obs logLik.
- vs gllvmTMB multi-trait: their gradient is O(p²) (own code, "slope≈2"), caps ~p=500. Ours is O(p) (Takahashi, never forms dense Σ_phy).
- vs drmTMB at scale: NOT measured at nrep=4/p>100 — the "~12× at p=10000" is **extrapolation of drmTMB's k≈1.36, not a measured result. Do not cite as measured.**

---

## 4. Location-only (conjugate) cell — EM's home turf  ✓ VERIFIED
*Gaussian phylo mixed model, phylo RE on the MEAN only → closed-form marginal.
location_only.jl: EM (closed-form, exact O(p) Takahashi traces) vs LBFGS, same data.*

| p (nrep=6) | EM | LBFGS | EM speedup |
|---|---|---|---|
| 200 | 0.009 s (17 it) | 0.028 s (26 it) | **3.1×** |
| 1000 | 0.182 s (23 it) | 0.566 s (29 it) | **3.1×** |
| 5000 | 0.813 s (24 it) | 1.137 s (27 it) | 1.4× |

EM and LBFGS recover the **same MLE** (|ΔlogLik|=0.0017, param rel-diff <0.007).
**Validates the conjugacy thesis:** EM wins when conjugate (location-only); the
joint LBFGS wins on the non-conjugate location-scale model (§1). Caveat: intercept
poorly identified at large σ²_phy (root confounding) — both engines agree, it's the
dataset MLE, not an optimizer issue.

---

## 5. REML — built and partially verified  ⚠ (reml_q4.jl, 553 lines, additive)
Laplace-REML: L_REML = L_ML(β̂_μ) − ½·logdet(S), S = Schur complement (β_μ info),
β_μ integrated out (bordered state, flat prior). Reuses the ML engine; warm-starts
from the ML optimum.
- **Verified:** mean-axis phylo variance inflates under REML vs ML (Λ[1,1]: 0.70→0.83,
  ratio 1.18 — the defining REML bias-correction), on intercept-only p=6.
- **Honest limits:** the REML>ML property holds reliably only for the *mean*-axis
  variances (dims 1,2); the *scale*-axis variances (dims 3,4) don't consistently
  satisfy it (they compete with the non-profiled β_σ/β_ρ — expected). ~4–5× more
  expensive per eval (alternating joint-mode solve + Schur complement); FD gradient
  (no exact REML gradient yet); S-non-PD barrier far from the optimum. **Needs human
  review before production use.** REML default must remain optional (ML for model comparison).

---

## 6. Inference / CIs  ✓ VERIFIED (infer_q4.jl, 407 lines, additive)
At the q4_p100 ML optimum:
- **Wald (observed information):** I_obs (17×17, central-FD of the exact gradient) has
  **1 negative eigenvalue** (−0.20, the Λ[4,3] singular direction); the other 16 are
  positive (1 → 1496). **16/17 parameters get finite, valid Wald SEs** (floored-inverse),
  in 0.51 s. **drmTMB's sdreport is all-NaN here (non-PD) — Julia is strictly better:
  usable uncertainty where drmTMB gives none.** This is the predicted inferential
  quality win. (At a true singular boundary, χ̄² / Self–Liang is the rigorous tool —
  noted for later.)
- **Parametric bootstrap:** B=60 via the O(p) precision sampler, **60/60 successful**,
  all CIs finite and bracket θ̂ (β_rho: [0.19, 0.62]; sd_phy[1]: [0.06, 1.67]).
  Bootstrap SEs 1.1–2.4× the Wald diagonal (captures variance-param variability).
  **Timing caveat:** verified run was **serial (39 s, 0.66 s/refit)** — threading did
  not engage (`Threads.@threads` needs `JULIA_NUM_THREADS`); the ~10 s "threaded"
  figure is **NOT verified**. Threading is the documented ~8× lever (unrun end-to-end).

---

## 7. Solid vs needs-review

**SOLID (verified this session):**
1. ML × location-scale head-to-head: Julia 1.14 s / −256.51 / converged vs drmTMB 2.48 s — **2.18×**.
2. O(p) scaling to p=10000 (k=1.08), biological per-dim-variance model.
3. Location-only conjugate cell: **EM 3.1× faster than LBFGS**, same MLE — conjugacy thesis confirmed.
4. Inference: Wald **16/17 valid SEs where drmTMB is all-NaN**; bootstrap **60/60** valid CIs.
5. Julia-EM ML×location-scale: verified *negative* (stalls −259.79).
6. Exact gradient O(p); convergence flag correct at the singular plateau.

**NEEDS HUMAN REVIEW:**
1. REML scale-axis behaviour + exact REML gradient + production stability (§5).
2. drmTMB at nrep=4 / p>100 (the scaling head-to-head is one-sided; 12× is extrapolated).
3. Threaded bootstrap end-to-end timing (verified serial; threaded ~8× unrun).
4. χ̄² boundary inference (motivated, not implemented).
5. lc3/lc7 ε-nudge auto-detection for arbitrary user data.

*Do not promote extrapolated numbers (drmTMB-at-p=10000) to measured results.*
