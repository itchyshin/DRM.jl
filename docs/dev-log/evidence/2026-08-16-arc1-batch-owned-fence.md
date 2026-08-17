# S4 — owned + fence (rows 10–11)

**Persona:** Shannon / Hopper (conductor recon on Cursor Grok; no Task child).
**Date:** 2026-08-16. **Read-only.** Do not steal `#428`. Leave row 11 `unsupported`.
**PR census:** `gh pr list --repo itchyshin/DRM.jl --state open` this pass.
**Collisions:** `docs/dev-log/evidence/2026-08-16-arc1-lane-collisions.md`.

## 10. `cross_family_latent` — OWNED SKIP

| Field | Value |
|---|---|
| claim_status | `experimental` |
| class | **owned** |
| claim_boundary | "Latent-rho development route; public docs must not present rho12 formulas or release-ready cross-family inference." |
| next_action | Resolve the mixed-family API mismatch before any public promotion. |
| existing fixture | **NONE** on `origin/main` / this inventory branch. Live work is `#428` (`feat/a11-cross-family-formula`): `test/test_cross_family_formula.jl` (added on that PR), `src/mixed_family*.jl`, `docs/src/cross-family.md`. Do not copy or complete those files here. |
| twin map | **UNKNOWN** — may twin staged `associate_pairs()` / `association()` / `latent_normal()` or a future joint `c(gaussian(), poisson())` fit. NEWS: Julia xfam fitting deferred. Do not invent equivalence. |
| collision | **`#428` A11 owns this.** BEHIND · **unarmed**. Files: `LOOP/checkpoint.md`, `docs/src/cross-family.md`, `src/mixed_family.jl`, `src/mixed_family_postfit.jl`, `test/runtests.jl`, `test/test_cross_family_formula.jl`. Also do not touch `report/xfam-external-validation.md` / `test/parity/fixtures/xfam-external-gllvm/` as a substitute twin. |
| later implement? | **No. OWNED SKIP.** Do not propose a competing slice. Do not unarm/re-arm. |

## 11. `engine_control_surface` — fence

| Field | Value |
|---|---|
| claim_status | `unsupported` |
| class | **fence** |
| claim_boundary | "Do not document user-selectable Julia optimizer controls until a real R API is designed." |
| next_action | Design `engine_control` explicitly before relaxing the gate. |
| existing fixture | **NONE** |
| twin map | **NO** — no exported `engine_control()`; `drm_control()` is TMB/`nlminb` only. Reserved/gated in R (`julia-bridge.R` + TSV: "no R surface by design"). Needs an R API first — not a Julia port. |
| collision | none. Design lives on drmTMB if anywhere. STOP GATE: do not invent the R API from this tree. |
| later implement? | **No.** Leave `unsupported`. Not a port. |

## Batch verdict

Row 10 = owned by `#428` — inventory writes one line and stops.
Row 11 = design fence — leave `unsupported`.
Neither is the recommended later implement slice.
