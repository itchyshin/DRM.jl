# GOAL — #336 DRMMakieExt (IMMUTABLE — re-read every arc)
# Status: ACTIVE 2026-08-07 — G0 APPROVED (owner: ship DRMMakieExt; merge OPEN GATE).

## Mission
Close DRM.jl #336 via one PR that adds `DRMMakieExt` (HSquared-pattern Makie
drawing layer) from tip `origin/main` @ `6c224a6c`. Prepare-data stays in
`src/visualization.jl`; drawing lives in `ext/DRMMakieExt.jl`.

## Headline
Makie + AlgebraOfGraphics as **weakdeps** only; CI gates the method-less stub
(Makie OUT of CI). Public API: `drm_figure` + thin `plot_*` aliases. Kinds:
`:profile` (Confidence Eye), `:parameter_surface`, `:corpairs`.

## Invariants
- One lane; branch `feat/336-makie-ext` from updated main.
- Fence: no `src/` q=4 engine / families; no #136 VA; no #49 FIML; no R-bridge;
  never stage `.worktrees/`; no GPL vendoring.
- Do **not** put Makie in `[deps]` or default CI test deps.
- Opening PR = OK; **do not merge** without owner (OPEN GATE).
- STOP: do not start VA/FIML/R-bridge in the same PR.

## Authoritative WHAT
`LOOP/ultra-plan.md` ↔
`docs/dev-log/plans/2026-08-07-336-makie-ext-ultra-plan.md`
(Cursor plan "336 Makie Ext").

## Definition of done
- `Project.toml` weakdeps/extensions; `src/plotting_ext.jl`; `ext/DRMMakieExt.jl`
- Stub tests green (no Makie in default CI)
- Docs honesty (visualization + simulation-plot-grammar + capabilities)
- check-log.d + after-task with Rose PASS
- PR open with `closes #336`; merge left as OPEN GATE
