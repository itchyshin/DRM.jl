# 2026-08-18 — Cox–Reid scoping probe (#441)

**Lane:** `cursor/lane-cox-reid-probe`. **Persona:** Noether (map + measure).
Hopper fence landed: `docs/dev-log/evidence/2026-08-18-hopper-cox-reid-gllvm-fence.md`.
No nested subagents. **Does not close** #136 / #11 / #49 / #439.

## What landed

- Issue: https://github.com/itchyshin/DRM.jl/issues/441 (S0 already open; not re-opened).
- Hook: after `_withnll` on `src/sparse_laplace_glmm.jl` (canonical `:555`).
- `_withreml`: tag only. Estimator punch-through is `_glsp_reml_*`. Public Poisson `method = :REML` does **not** punch through.
- Probe note: `docs/dev-log/evidence/2026-08-18-cox-reid-scoping-probe.md`
- Standalone test: `test/test_cox_reid_characterization.jl` (not in `runtests.jl`)
- Capture: `bench/out/cox_reid_probe.txt` (~66 s Mac)

## This-engine numbers (not drmTMB −7.3/−5.0/−0.9)

- Cell B: max |θ_CR − θ_REML| = 2.871e-06
- Cell A GHQ-32 Poisson `(1|g)`, σ=0.6: G=10 ML −12.37% / CR −1.77%; G=40 CR **+4.38%** (over-correct)
- Cell C: `_glsp_reml_penalty` unmodified on Poisson phylo; rel-diff 8.29e-04; refit 5 steps
- Cell D cheap Laplace (ntip=16, 12 seeds, σ=0.7): ML **+8.18%**, CR **+17.41%** — underpowered for a Laplace-bias sign claim

## Go

Wiring job. First implement cell = Poisson `(1|g)` GHQ. ML default. No AGHQ. No TSV / "has non-Gaussian REML".

## Fence held

No `src/` engine edit. No `test/runtests.jl`. No `src/reml_q4.jl`. No `src/gaussian_ranef.jl`. No q4. No GPL. No GLLVM Λ numbers.
