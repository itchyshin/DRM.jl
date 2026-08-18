# Checkpoint — OVERWRITTEN every arc (a pointer to truth, not a log)

GOAL: see GOAL.md.   STATE: S5 docs landed; S3/S4 DONE (27/27 verified twice).
ARCS DONE (verified):
- S1 — `gh pr list` shows #449 OPEN (`feat(#448): 1-D Liu–Pierce AGHQ on Poisson (1|g)`). Did not STOP.
- S2 — issue https://github.com/itchyshin/DRM.jl/issues/450 ; worktree `~/local-scratch/lanes/DRM.jl-phylo-laplace-cox-reid` on `claude/lane-phylo-laplace-cox-reid` off `origin/main`. LOOP kit filled. Did not touch AGHQ files / handover leftover / `docs/a3c-design` / catchup.
- S3 — TDD red: standalone `test/test_cox_reid_poisson_phylo.jl` (not in `runtests.jl`).
- S4 — Wire: lift structured `_reject_reml_route`; thread `reml` into `_fit_poisson_general_laplace`; reuse #444 helpers. Tip before this S5 = `8084532e`.
- S5 — Docs: public `Poisson()` docstring already carries ML-default / Cell D not-recovery / over-correction / phylo-relmat opt-in (no `src/` punch this slice). check-log.d + after-task landed. No capability chip.
- S6 — standalone 27/27 verified twice on S3/S4 (this S5 slice did not re-run).
ARC IN PROGRESS: none.
NEXT: S7 PR (`closes #450`). Sibling opens; this worker does not. Do not `gh pr merge`.
OPEN GATES (need human): human merge of B's PR.
TRUTH LIVES IN: `claude/lane-phylo-laplace-cox-reid` @ this worktree; issue #450; AGHQ PR #449 is foreign.
RESUME: read LOOP/GOAL.md → LOOP/checkpoint.md → LOOP/ultra-plan.md. CONTINUE FROM S7. Do not recreate the worktree. Do not open a second AGHQ issue. Do not edit `test/runtests.jl`. Do not flip capability chips.
