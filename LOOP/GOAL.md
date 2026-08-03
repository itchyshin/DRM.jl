# GOAL — #376 measured drmTMB head-to-head nrep=4 / p>100
# (IMMUTABLE once G0 APPROVED — re-read at the top of EVERY arc)

## Mission
Close DRM.jl #376: retain a **paired** Julia vs drmTMB wall-clock artifact on the
q=4 PLSM biological per-dimension-variance model at **nrep=4**,
**p ∈ {100, 1000, 5000, 10000}**, rewrite claim surfaces only from that artifact,
PR `closes #376`.

## Headline
Kill the extrapolated “~12× vs drmTMB at p=10,000” claim with measured (or honest
R-blocked) cells.

## Invariants
- One lane: branch `feat/376-q4-scaling-h2h` from `e3b3b8a`. Leave `.worktrees/` alone.
- D-111 OFF (no Registrator / Julia General).
- Never vendor GPL drmTMB source; public API + generated fixtures only.
- Do not regress verified q=4 engine (logLik −256.51 / 2.18×); do not edit
  `src/fit_q4_sparse_tmb.jl` / `src/sparse_aug_plsm.jl` / Takahashi core unless
  Noether + maintainer (prefer bench-only).
- Do not cite #372 six-cell bridge ratios as this evidence.
- Heavy grid on Totoro (D-50); no GHA heavy drmTMB sweeps.
- Smoke-first: non-empty paired p=100 before scaling up.
- Rose: every public speed sentence cites the retained evidence file.

## Authoritative WHAT
`LOOP/ultra-plan.md` (approved G0 ultra-plan).

## Definition of done
- Retained evidence md + JSON/TOML (both arms or honest R-blocked cells)
- comparison-grid / HANDOVER / large-data / ROADMAP match the artifact
- check-log.d + after-task + Rose claim-vs-evidence
- PR closes #376
