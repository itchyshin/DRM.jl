# Checkpoint — OVERWRITTEN every arc (a pointer to truth, not a log)

- **DONE:** Arcs 0–8. Issue #441. LOOP kit. Engine map. Cells A–D captured in
  `bench/out/cox_reid_probe.txt` (~66 s Mac). Hopper fence landed. Probe note
  + standalone characterization test + after-task + check-log.
- **IN PROGRESS:** none (Noether G0 deliverables). PR is Shannon/Arc 10.
- **NEXT:** Shannon opens the PR against `main` if wanted. Implement-G0 is a
  **later** slice (Poisson `(1|g)` GHQ first). Do not start AGHQ.
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
