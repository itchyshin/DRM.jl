# Checkpoint — G0 **DONE** (2026-08-18)

**The probe answered its question: Cox–Reid is a WIRING job, not a derivation job.**
Nothing here ships an estimator. ML remains the default on every route.

- **DONE:** Arcs 0–10. Issue #441. LOOP kit. Engine map. Cells A–D captured in
  `bench/out/cox_reid_probe.txt` (~66 s Mac). Hopper fence landed. Probe note
  + standalone characterization test + after-task + check-log.
- **IN PROGRESS:** none (Noether G0 deliverables). PR is Shannon/Arc 10.
- **NEXT:** **PR #442 is open** (https://github.com/itchyshin/DRM.jl/pull/442) — claimed
  early so the note landed into an existing PR instead of racing a second one for #441.
  Shannon marks it ready and merges if CI is green. Implement-G0 is a **later** slice
  (Poisson `(1|g)` GHQ first). Do not start AGHQ.
- **VERIFIED BY ARTEFACT (not by tick):** `test/test_cox_reid_characterization.jl` runs
  **12/12 pass in 15 s** on this Mac. It is standalone and deliberately NOT registered in
  `test/runtests.jl` (#423/#428/#429 own that file).
- **OPEN GATE:** none. Owner pre-approved this lane.
- **WHERE TRUTH LIVES:** this worktree; `docs/dev-log/evidence/2026-08-18-cox-reid-scoping-probe.md`;
  `bench/out/cox_reid_probe.txt`.
- **RESUME:** read `LOOP/GOAL.md` → this file → the probe note.

## Measured (reproduce with `julia --project=. bench/cox_reid_probe.jl`)

**Cell B.** max |θ̂_CR − θ̂_REML| = **2.871e-06**.

**Cell A.** Poisson `(1|g)` GHQ-32, true σ_b = 0.6, 60 seeds (this engine, not drmTMB):

| G | n_each | nrep | σ̂_ML | bias_ML | σ̂_CR | bias_CR |
|---|---|---|---|---|---|---|
| 10 | 6 | 58 | 0.5258 | **−12.37%** | 0.5894 | **−1.77%** |
| 20 | 6 | 60 | 0.5561 | **−7.32%** | 0.5903 | **−1.62%** |
| 40 | 6 | 60 | 0.6085 | +1.41% | 0.6263 | **+4.38%** |

**Cell C.** `_glsp_reml_penalty` unmodified on Poisson phylo; rel-diff **8.29e-04**; refit 5 steps.

**Cell D.** Cheap Laplace phylo (ntip=16, 12 seeds, true σ=0.7): ML **+8.18%**, CR **+17.41%**.
Underpowered for a Laplace-bias *sign* claim — not a recovery headline.

**Punch-through.** `_withreml` = tag only. `_glsp_reml_*` = estimator (yes). Public Poisson `method = :REML` = no.

**Hook.** Attach after `_withnll`, `src/sparse_laplace_glmm.jl:555`.

## Carried-forward risks — the implement-G0 must handle these, not rediscover them

1. **The 8.29e-04 cross-check gap is the most useful thing the probe found.** Two routes to
   the *same* penalty agree to ~1e-6 on the Gaussian cases but differ by ~1e-3 relative on
   the Laplace route. `AGENT-INFERRED` (hypothesis, not measured): the inner Newton
   mode-finder is warm-started from a `last_b` that mutates across calls, so both the value
   and the gradient are mildly path-dependent, and an FD-formed `I_ββ` inherits that noise.
   **Pin the inner solve — fixed `b0` or a tightened inner tolerance — and re-measure the gap
   before trusting the penalty on Laplace routes.** Do not treat this hypothesis as
   load-bearing until it is tested.
2. **Boundary failures are real, not theoretical.** 2 of 60 seeds at G=10 hit the non-PD
   `I_ββ` sentinel. Keep the finite `1e18` sentinel (never `Inf` — it breaks the line search)
   and give the fallback a test rather than an assumption.
3. **Cox–Reid over-corrects once M is large enough** (+4.38% at G=40 here; drmTMB saw +2.1%
   at M=160). This is the measured reason the estimator must be opt-in.
4. **Cell C is one seed and Cell D is 12 seeds on a 16-tip tree.** They establish that the
   hook *runs* on the Laplace spine. Neither supports a claim about Laplace bias direction.
5. **drmTMB design 224 splits O2 from O3.** O2 (joint-Laplace fold of β) ≡ glmmTMB REML and
   is *not* the target; O3 is nested — AGHQ over `u`, then the penalty on that marginal. The
   implement must choose its object deliberately rather than folding β into `random=`.

## Next G0s (do not start either in this lane)

1. **Cox–Reid implement — a wiring job.** First cell: Poisson `(1|g)` GHQ. Narrow
   `_reject_method_as_marginal` (`src/variational.jl:72–86`) to admit `:REML` on
   scalar-per-cluster non-Gaussian routes, reuse `_glsp_reml_penalty` +
   `_glsp_reml_refit_clean`, tag with `_withreml`. Needs Noether + maintainer sign-off
   because it touches `src/`.
2. **AGHQ port** (lever 2) — after Cox–Reid, never instead of it.
