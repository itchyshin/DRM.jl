# Hopper fence — Cox–Reid probe vs GLLVM numbers

**Role:** Hopper (R↔Julia translator). **Read-only of twins.** No `src/` edits. No GPL paste.
**Date:** 2026-08-18. **Lane:** `cursor/lane-cox-reid-probe` @
`~/local-scratch/lanes/DRM.jl-cox-reid-probe` (issue #441). **Not** leftover
`docs/a3c-design`.

**One line.** DRM.jl random effects are **scalar-per-cluster**, so the *drmTMB*
two-lever diagnosis transfers and the **GLLVM numbers do not**. Implement
Cox–Reid first. Do not import GLLVM recovery tables, AGHQ-first ordering, or
loading-matrix medians.

---

## 1. Twin path found (or not)

| Twin | Checkout used | Cox–Reid NG REML | AGHQ over latent | What transfers |
|---|---|---|---|---|
| **drmTMB** | Dropbox `drmTMB` (docs only) | public NG REML still gated; O3 is a nested AGHQ + observed-info *profile*, not a TMB `random=` fold | no shipped AGHQ engine; 2026-07-18 rolled GHQ was the scoping oracle | **mechanism + lever order** for scalar-per-cluster RE |
| **gllvmTMB / GLLVM.jl** | vault notes + GLLVM.jl board (no checkout) | Cox–Reid **dead there** (moved 1% the *wrong* way) | GLLVM.jl has Liu–Pierce AGHQ (#251/#252); ledger rows stay `missing`; gllvmTMB AGHQ is a different product | **method lessons only** |

Primary locators (generated / design / vault — not GPL source):

- Vault: `memory/Two-lever fix for small-cluster non-Gaussian variance-component bias (AGHQ + Cox-Reid REML) — cross-repo map` (MEASURED, 2026-07-18).
- Vault: `memory/AGHQ exposes a flat likelihood direction in GLLVMs — the runaway is bimodal, not biased` (2026-07-28; D-43 correction: reference fitter ≠ engine).
- Vault: `memory/AGENT_LOG.md` 2026-08-18 DRM.jl next-arc paragraph; `memory/WHAT-WORKS.md` (median / k=1 / reference-fitter rules).
- Vault: [[DECISIONS#D-94]] — DRM.jl is sequenced behind **drmTMB**, not GLLVM.jl.
- drmTMB: `docs/dev-log/2026-07-18-cumlogit-laplace-diagnosis-and-aghq-next-arc.md`; `docs/design/224-aghq-coxreid-nongaussian-reml-alignment.md`.
- This lane already: `LOOP/GOAL.md`, `LOOP/ultra-plan.md`, `LOOP/checkpoint.md` (Cells A/B measured on *this* engine).

---

## 2. drmTMB numbers (cite as drmTMB's)

**Cell:** `cumulative_logit`, M=40, n_each=15, true slope-SD 0.5, 40 seeds, 2026-07-18.
Scalar **per-cluster** slope RE. Validated vs glmmTMB / glmer / lme4 oracles.

| Object | rel-bias | what it removes |
|---|---|---|
| Laplace ML (O1) | **−7.3%** | baseline |
| rolled exact-ML AGHQ | **−5.0%** | +2.3 pt — Laplace integral error |
| rolled Cox–Reid on that marginal | **−0.9%** | +4.0 pt — ML finite-cluster VC bias |

**Cox–Reid is the bigger lever (~1.7×).** AGHQ node sweep converges by `nq≈5` then
**plateaus dead flat at −5.0%** — more nodes cannot cross the variance-bias floor.
Binomial oracle (high information): glmmTMB `REML=TRUE` removes ~42% of ML bias;
glmer `nAGQ=25` removes ~0.1 pt. Caveat: Cox–Reid **over-corrects** at large M
(+2.1% at M=160).

Design 224: O2 (joint-Laplace fold of β) ≡ glmmTMB REML and is **not** the ordinal
nominal object. O3 is a **nested** construction (AGHQ over `u`, then
`½ log|I_{(β,θ)}|` on the AGHQ-marginal). Do not fold AGHQ-u into TMB `random=`.

**These figures are drmTMB's.** Different package, family, cell. The probe lane
must not promote them as DRM.jl measurements.

---

## 3. GLLVM numbers (do not transfer)

GLLVM variance lives in the **loading matrix Λ** (LVs fixed N(0,I)), not a
scalar cluster RE-SD. That is a different estimand.

Measured (vault, 2026-07-28; first table is the *reference fitter*, not the
shipped engine — D-43):

| Claim that looks portable | Why it is not |
|---|---|
| Laplace ~21% low, flat in *n* (sites); AGHQ 1.0021 at n=3200 | That is **per-site trait count T**, a loadings problem. DRM.jl `(1\|g)` already pays GHQ-32 on the simple route. |
| AGHQ small-n “bias” ~97% | **Bimodal**, not shifted: ~50% of fits unbiased, ~50% runaway. Median sits between modes and describes neither. |
| Cox–Reid as the 1.7× lever | **Dead here:** moved the estimate **1%, in the wrong direction**. Integrates 4 trait intercepts; **never touches Λ**. |
| AGHQ-first / more nodes | Integral already exact to 1.2e-09; leftover is a **flat direction** needing a **ridge**, not more quadrature. |
| Unpenalised AGHQ better than Laplace at small n | **Reversed on the shipped engine** (Laplace 1.011 vs AGHQ+ridge 1.262 at n=100). Never cite a separate reference fitter as engine evidence. |

GLLVM.jl has an AGHQ *kernel* (Liu–Pierce, #251/#252) and **no Cox–Reid**. Both
AGHQ ledger rows stay `missing`. Porting that kernel later is a lever-2
plumbing job after `GLLVM.jl-a43-honesty` — **not** a licence to copy GLLVM
recovery numbers or to start AGHQ on this G0.

---

## 4. Why DRM.jl follows drmTMB, not GLLVM

DRM.jl non-Gaussian REs (`(1|g)`, phylo, crossed) are **scalar-per-cluster**.
The two-lever map says the cheap scalar-RE probe “works directly where the RE
is a scalar per cluster (drmTMB families)” and “needs a multi-dim extension
for GLLVM latents.”

This lane already reproduced the *mechanism* on the Julia engine (checkpoint;
not imported):

- **Cell B:** generic `½ logdet(I_ββ)` vs #440 Woodbury REML,
  max |θ̂_CR − θ̂_REML| = **2.87e-06**. Penalty is anchored.
- **Cell A:** Poisson `(1|g)` GHQ-32, true σ_b = 0.6, 60 seeds — ML bias
  shrinks with M; Cox–Reid removes most of it at small M; **over-corrects at
  G=40** (+4.38%). That is why ML stays default.

On `(1|g)` the integral lever is **already paid** at 32 nodes. Starting AGHQ
here is worse ordering than it was in drmTMB.

---

## 5. Implementer fence (do not violate)

1. **Scalar-per-cluster only.** drmTMB lever *order* transfers. GLLVM
   loading-matrix numbers (Cox–Reid −1% the wrong way; AGHQ bimodal + ridge;
   Laplace −21% flat in *n*) **do not**.
2. **Cite −7.3% / −5.0% / −0.9% as drmTMB `cumulative_logit`.** Measure DRM.jl
   on this engine. Do not headline vault figures as a DRM.jl recovery.
3. **Cox–Reid first. Do not start AGHQ.** Nodes plateau at the VC-bias floor.
   Do not port GLLVM.jl quadrature *claims*; a later kernel port is lever 2
   and waits on GLLVM honesty. D-94: behind drmTMB, not GLLVM.
4. **ML stays the default.** Cox–Reid is opt-in. It over-corrects at large M
   (drmTMB +2.1% at M=160; this probe +4.38% at G=40). No default flip, no
   capability-chip / TSV / “has non-Gaussian REML” sentence.
5. **Carry GLLVM *method* lessons only.** Never summarise a mixture with a
   median. k=1 agreement proves plumbing, not quadrature. Never cite a
   separate reference fitter as engine evidence. No GPL vendoring. No q4.
   No edits to `src/gaussian_ranef.jl` or `test/runtests.jl`. Any later
   `src/` implement-G0 needs Noether + maintainer.

---

## 6. What this note is not

Not a ship. Not Workflow G. Not coverage. Not an AGHQ design. Not a GLLVM.jl
port brief. Cell C (sparse-Laplace hook) was in-flight on this lane when this
note was written — do not treat the hook as proven until
`bench/out/cox_reid_probe.txt` records it.

**Co-opt vs n/a:** co-opt drmTMB's *statistical target* (opt-in restricted
profile; ML default; `½ log|I_ββ|` on a scalar RE). n/a for GLLVM numbers,
GLLVM AGHQ-first product, and TMB `random=` construction.
