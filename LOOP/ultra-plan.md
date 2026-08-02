# Ultra-plan freeze — DRM.jl #189 (G0 approved 2026-08-02)

Platform: Cursor `/goal` execution.
Deliverable: close #189 — q=4 coevolution from spatial / relmat / animal.
Headline: reuse `fit_q4_sparse_tmb(prob, Q_cond)`; front-end `Q_cond` only.
Fence: D-111; no `:natgrad`; no #291 accel; no drmTMB R edits; no GPL vendor;
no `.worktrees/`; no non-tree bootstrap CI; no engine-core rewrite.

## Locked decisions
- All three providers in one #189 PR.
- Add level-indexed `make_problem_from_Q` (no `AugmentedPhy` required for fit).
- Spatial: fixed-ρ fixture (`spatial_range` or mean pairwise distance) for this slice.
- Bootstrap for non-tree: clear ArgumentError.
- Hygiene: #366 merge when green + sync `docs/src/capabilities.md`.

## Acceptance
See `LOOP/GOAL.md` Definition of done.
