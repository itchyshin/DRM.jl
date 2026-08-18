# Checkpoint — OVERWRITTEN every arc (a pointer to truth, not a log)

- **DONE:** Arc 0 (pre-flight, issue #441, lane scaffolded off `origin/main` `5e392c6e`,
  branch renamed to the `cursor/` prefix). Arc 1 (LOOP kit overwritten — the inherited
  #434 kit was a different subject). Arcs 2–3 (engine mapped; hook named; the
  `(obj, grad_fn, pμ)` contract confirmed by reading every non-Gaussian `_fg` route).
  **Arcs 4–6 (cells B, A and C all measured and committed).** Hopper's GLLVM fence
  ingested into `LOOP/ultra-plan.md`.
- **IN PROGRESS:** nothing owned by Shannon. **Handed off** — see ownership below.
- **NEXT (Noether `aa167761`):** the probe design note and, if wanted, a standalone
  characterization test. Then Rose after-task + check-log, then the PR.
- **OPEN GATE:** none. Owner gave full pre-approval for this lane including the PR.
- **WHERE TRUTH LIVES:** `cursor/lane-cox-reid-probe`. Measured output is
  `bench/out/cox_reid_probe.txt` @ `4b3e53ec`; the probe is `bench/cox_reid_probe.jl`;
  the fence is `docs/dev-log/evidence/2026-08-18-hopper-cox-reid-gllvm-fence.md`.
- **RESUME:** read `LOOP/GOAL.md` → this file → `LOOP/ultra-plan.md`, then continue from NEXT.

## OWNERSHIP (2026-08-18) — do not fork

| Artefact | Owner |
|---|---|
| `LOOP/**`, lane coordination, fence ingestion, the PR | **Shannon** (this session) |
| Probe source, the design note, any characterization test | **Grok Noether `aa167761`** |
| The GLLVM fence note | Hopper (landed; read-only) |

Shannon landed the probe script and its recorded output before handing off, because Hopper's
fence §6 made the recorded artifact a proof gate. **Noether builds on `4b3e53ec`.** Shannon
writes no further probe source and no design note from here.

## Hopper fence — the parts that bind the numbers below

- Cite drmTMB's −7.3% / −5.0% / −0.9% (`cumulative_logit`, M=40, 40 seeds) **as drmTMB's**.
- GLLVM numbers do **not** transfer (variance lives in Λ, not a scalar cluster SD); there
  Cox–Reid moved the estimate ~1% the *wrong* way. Our Cell B anchor is what distinguishes
  our case: the penalty acts on the same β block that carries the bias.
- **Do not start AGHQ.** Cox–Reid first; a GLLVM.jl kernel port is lever 2 and waits.
- ML stays default — over-correction at large M is measured on both sides.
- drmTMB design 224: O2 (joint-Laplace β fold) ≡ glmmTMB REML and is *not* the target;
  O3 is **nested** (AGHQ over `u`, then `½log|I|` on the AGHQ-marginal). The implement-G0
  must choose its object deliberately, not fold β into a TMB-style `random=`.

## Measured on THIS engine (`julia --project=. bench/cox_reid_probe.jl`, ~65 s)

**Cell B — Gaussian reduction anchor.** Gaussian `(1|g)`, G=12, n_each=5. Generic Cox–Reid
penalty `½logdet(I_ββ)` on the ML objective vs #440's exact Woodbury REML:
**max |θ̂_CR − θ̂_REML| = 2.87e-06**. The penalty is anchored, not ad hoc.

**Cell A — ML variance-component bias.** Poisson `(1|g)`, GHQ-32 (integral error already
negligible, so this isolates the ML finite-cluster effect), true σ_b = 0.6, 60 seeds.

| G | n_each | nrep | σ̂_ML | bias_ML | σ̂_CR | bias_CR |
|---|---|---|---|---|---|---|
| 10 | 6 | 58 | 0.5258 | **−12.37%** | 0.5894 | **−1.77%** |
| 20 | 6 | 60 | 0.5561 | **−7.32%** | 0.5903 | **−1.62%** |
| 40 | 6 | 60 | 0.6085 | +1.41% | 0.6263 | **+4.38%** |

The vault's *mechanism* reproduces on our engine: ML bias shrinks with M, Cox–Reid removes
most of it where it is large, and it over-corrects once M is big enough that ML is already
fine. That over-correction is the evidence for keeping ML the default.

**Cell C — hook viability on the sparse-Laplace route** (Poisson phylo, ntip=24, per=4,
true σ_phylo = 0.7, single seed). The wired Gaussian helpers were called **unmodified**:

- `fit.nllgrad` present — the analytic gradient contract holds
- `_glsp_reml_penalty` = 3.17639042, vs an independent value-surface FD 3.17375941
  (**rel diff 8.29e-04**)
- `_glsp_reml_refit_clean` converged in **5 LBFGS steps**; σ̂_phylo 0.95488 → 0.99187

## Carried-forward risks (for the implement-G0, not resolved here)

1. **Cell C is one seed.** It shows the hook *runs*; it says nothing about phylo bias. The
   direction (Cox–Reid raises σ̂) is mechanical, not evidence.
2. **The 8.29e-04 cross-check gap is the real finding.** On the Gaussian/boundary cases the
   two routes to the same penalty agreed to ~1e-6; on the Laplace route they differ by ~1e-3
   relative. The likely cause is the inner Newton mode-finder's warm start (`last_b` mutates
   across calls), which makes both the value and the gradient mildly path-dependent. **An
   implement must pin the inner solve — fixed `b0` or a tightened inner tolerance — before
   trusting an FD-formed `I_ββ`.**
3. **Boundary failures are real:** 2 of 60 seeds at G=10 failed the refit (non-PD
   β-information). The 1e18 sentinel path is exercised, so it needs a tested fallback rather
   than an assumed one.
4. **Over-correction at large M** is measured here (+4.38% at G=40), earlier than drmTMB saw
   it (+2.1% at M=160). Opt-in only.
