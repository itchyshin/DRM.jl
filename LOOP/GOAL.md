# GOAL — decide, on measured DRM.jl evidence, whether Cox–Reid for non-Gaussian variance components is a small patch or a real build

**IMMUTABLE for this run.** Re-read this file at the top of EVERY arc, before anything else.

**Issue:** https://github.com/itchyshin/DRM.jl/issues/441
**Lane:** `cursor/lane-cox-reid-probe` @ `~/local-scratch/lanes/DRM.jl-cox-reid-probe`, from `origin/main` (post-#440).
**This is a SCOPING PROBE (≤1 day, Mac).** It is *not* the estimator ship.

---

## Why this G0 exists

Vault evidence — MEASURED on drmTMB `cumulative_logit` (mc-0227), 40 seeds, validated
against glmmTMB / glmer / lme4 oracles, 2026-07-18 — says a small-cluster random-effect SD
under ML-Laplace is biased low by **two stacked, orthogonal** effects:

1. **Laplace integral error** — the 1-point-at-the-mode Gaussian approximation. Fixed by
   **AGHQ**. *Shrinks with per-group n.*
2. **ML finite-cluster variance-component bias** — present even under *exact* integration.
   Fixed by a restricted likelihood: exact REML (Gaussian) or the **Cox–Reid adjusted
   profile likelihood** (non-Gaussian) = integrate the fixed effects out under a flat prior,
   subtract `½·log|I_ββ|`. *Shrinks with number of clusters M.*

Worked numbers (`cumulative_logit`, M=40, n_each=15, true slope-SD 0.5):
Laplace **−7.3%** → +AGHQ **−5.0%** → +Cox–Reid **−0.9%**.
**Cox–Reid is the bigger lever (~1.7×).** The AGHQ node sweep converges by `nq≈5` then
plateaus dead flat — nodes cannot cross the variance-bias floor. Hence Cox–Reid FIRST.

Source: `memory/Two-lever fix for small-cluster non-Gaussian variance-component bias
(AGHQ + Cox-Reid REML) — cross-repo map` (shinichi-brain).

---

## Definition of done

- [x] Issue #441 opened; scratch lane scaffolded from `origin/main`
- [x] `src/sparse_laplace_glmm.jl` mapped; the hook point named
- [x] Answered: can the Gaussian REML machinery (`_glsp_reml_penalty` /
      `_glsp_reml_refit_clean` / `_withreml`) punch through to non-Gaussian routes?
- [x] **Measured on THIS engine** (no imported drmTMB numbers): the current ML
      variance-component bias, and whether a generic Cox–Reid penalty removes it
- [x] **Gaussian reduction anchor:** the generic penalty reproduces the independently
      validated exact Gaussian REML (#440 Woodbury `(1|g)`) to tight tolerance
- [x] Design note committed: hook points, cost model, fences, risks, and an explicit
      **go / no-go** for the implement-G0
- [x] Standalone characterization test that documents current behaviour and fails when
      the estimator lands (NOT registered in `test/runtests.jl`)
- [ ] PR against `main`; after-task naming the next G0s in order

**Done means the NEXT session can decide the implement-G0 without re-deriving anything.**

---

## Invariants (never violate, even to finish faster)

- **ML stays the default.** Cox–Reid is opt-in, later. Nothing in this lane changes a default.
- **Scalar-per-cluster random effects only.**
- Verification means reading the LOG and inspecting the ARTEFACT, never the exit code.
- Every number in the design note is reproduced by a run in this lane. **No extrapolated or
  imported figure is promoted to a measured result** — cite drmTMB's numbers as drmTMB's.
- A narrow or negative search is not proof. "No X exists" usually means the query missed X.
- Twin is **drmTMB**, not GLLVM. No GPL vendoring; parity uses generated outputs only.
- Destructive or irreversible ⇒ STOP and surface.
- Owner granted **full pre-approval for this lane** (arm + execute, including the PR).
  Everything outside the fence below still stops.

---

## Out of scope (the fence — do NOT drift here)

**Files owned by other lanes — never touch:**

- `test/runtests.jl` — owned by #423 / #428 / #429 (sibling ops lane, not this `/goal`)
- `src/reml_q4.jl`, the bivariate q4 path, `test/parity/**`, any parity TSV
- `src/gaussian_ranef.jl` and the #440 Woodbury REML (read as an ORACLE only, never edit)
- `docs/dev-log/coordination-board.md` (#406)
- Leftover Dropbox `docs/a3c-design`; do not build in the Dropbox checkout at all

**Work that is a LATER G0, not this one:**

- Implementing the production Cox–Reid estimator and wiring it to `drm(...; method = …)`
- **AGHQ** — vault evidence says it plateaus and is the smaller lever. Do not start it.
- Any coverage / recovery certification campaign; any Totoro or DRAC run
- Porting the HSquared.jl `fit_laplace_reml` kernel
- Reopening `#136` (VA/ELBO), `#49` (PARKED), `#11`, `#439` — do not close any of them
- D-111 (Julia General registration) stays **OFF**

**Claim fence (Rose):** this lane may say *"a scoping probe measured the ML
variance-component bias on DRM.jl's scalar-RE routes and showed a generic Cox–Reid penalty
reduces to validated Gaussian REML."* It may **not** say the estimator ships, that coverage
is nominal, that DRM.jl has non-Gaussian REML, or that drmTMB's measured figures were
reproduced here (different package, different cell).
