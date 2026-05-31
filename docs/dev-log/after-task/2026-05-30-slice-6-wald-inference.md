# After-task — Slice 6 (first part): Wald inference

**Date:** 2026-05-30 · **Branch:** `gaussian-inference-wald`

## Landed
- `src/inference.jl` — `stderror(fit)` (√diag of the covariance) and
  `confint(fit; level)` (Wald `estimate ± z·se`, one row per coefficient with
  its param / name / bounds). Extends the StatsAPI generics; works on every
  model type built so far (univariate, bivariate, random-intercept).
- `model-guides/model-workflow.md` filled with an executed `@example`.

## Verified
- `Pkg.test()` → all green (engine + univariate + bivariate + RE + inference).
- Inference test asserts the **deterministic** Wald property (CI = est ± z·se,
  se = √diag vcov) + loose recovery — not a single-seed coverage event (that
  first draft was a flawed ~95%-probabilistic assertion; corrected).
- docs build clean; `model-workflow` `@example` runs.

## Per-persona
- **Fisher:** Wald SE/CI from the observed information; intervals on each
  parameter's working scale (σ on log σ, ρ12 on atanh, RE SD on log σ_b) —
  documented so users exponentiate σ bounds for SD ratios.
- **Rose:** scope honest — profile/bootstrap intervals and `predict`/`simulate`/
  residuals explicitly deferred (need design storage on the fit).

## Next
Remaining post-fit (predict / fitted / residuals / simulate) needs design
storage on `DrmFit`; then Slice 4 — the `phylo()` structured-effect front end
wiring the verified q=4 engine.
