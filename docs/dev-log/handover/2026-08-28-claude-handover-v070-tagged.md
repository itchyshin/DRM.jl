# Handover addendum — v0.7.0 tagged (2026-08-28)

**Author:** Claude (Shannon speaking; no subagents running). **Addressed to:** the next session, any platform.
Supplements `2026-08-28-claude-handover-v020-tagged.md` — read that one for the full arc; this
addendum records only the release event and what the next session owes.

## State

- **`v0.7.0` is tagged and pushed** on merge commit `051bdc11` (PR #542): `Project.toml` 0.7.0,
  NEWS section with the twin pin **drmTMB `a6de6bb71`** (0.7.0). The tag annotation carries the
  release summary and the governance holds.
- All waves of the completion roadmap (`docs/dev-log/plans/2026-08-28-v1.0-roadmap.md`, renamed
  v0.7.0 by D-181) are DONE: M (mi() fenced at the bridge, drmTMB #1098), Q (quality debt zero),
  I (interval fences permanent), A (API freeze gate: `test/test_api_stability.jl` +
  `docs/src/api-stability.md`), R (this tag).
- Evidence riding the tag: engine speed grid (Julia 14/15 cells, 2.3×–42×,
  `report/engine-speed-grid.md`), user-journey sweep from R `engine = "julia"` (25/29 OK_MATCH,
  `docs/dev-log/evidence/2026-08-28-user-journey-sweep.md`), threaded bootstrap 10× at R=199.
  The predict(newdata) cross-engine naming bug found by the sweep is fixed in drmTMB (#1099, merged).
- Both repos clean: DRM.jl main = `051bdc11` = v0.7.0; drmTMB main includes #1087/#1089/#1091/#1093/#1098/#1099.

## OWED — next release event

1. **Registration in Julia General at v0.7.1** (owner decision, D-181). D-111's hold applied
   *through* v0.7.0 only. Mechanics when the time comes: JuliaRegistries/Registrator on the
   v0.7.1 release commit; no compat surprises expected (Project.toml compat is already bounded).
2. Post-0.7 headline: **mi() match** — unpark the drmTMB #49 axis; the fence text in
   `R/julia-bridge.R` (drmTMB) and the pin rule name the contract to meet.

## Deferred ledger (recorded, not owed now)

DRM.jl #495 · #527-residuals · #467 · #471 (Student structured markers — OUT per D-180 #3) ·
exact REML gradient via `lc_metric` (the q4 REML 0.94× residual). drmTMB CRAN: D-164, untouched.

## Resume prompt

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-28-claude-handover-v070-tagged.md. Run the handover rehydration steps, reconcile with current git state, then continue only the OWED items (registration at v0.7.1 is owner-gated — confirm with Shinichi first).
```
