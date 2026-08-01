# After-task — tip honesty: Rose nit + #17/#5 wording (2026-08-01)

**Personas:** Shannon + Rose (+ Hopper twin). No spawned subagents.

## Goal

Economical tip honesty after Phase 1.5 idle: (2) Rose nit alignment;
(3) closed-issue wording for #17 (and stale #5 “open” claims).

## Done

- **drmTMB (paired):** `base_gaussian_location_scale` and
  `gaussian_response_mask` → `r_bridge_status = "experimental"`; regenerated
  `julia-capabilities.tsv` (dashboard + `inst/extdata`).
- **DRM.jl:** ROADMAP / HANDOVER / README / LOOP checkpoint / handover note;
  Rose verdict + bridge matrix one-liners; this after-task + check-log.d.

## Rose

**PASS** — claim honesty only; no capability promotion; D-111 / no Registrator;
no `src/` touch. `#17` and `#5` documented as closed; opt-in
`DRM_PARITY_TESTS=1` unchanged.

## Verify

- drmTMB: `pkgload` load + status assert on the two capability_ids; artifact
  regen via `tools/write-julia-capability-comparison.R`.
- DRM.jl: docs-only PR (no `Pkg.test` required beyond CI).

## Melissa

RECONCILE: N/A — tiny honesty slice (not a multi-hour ultra-plan close).
