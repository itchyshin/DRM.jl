# Checkpoint — OVERWRITTEN every arc (a pointer to truth, not a log)

GOAL: see GOAL.md.   STATE: S1 cleared (AGHQ PR #449 OPEN); S2 landed (#450 + worktree).
ARCS DONE (verified):
- S1 — `gh pr list` shows #449 OPEN (`feat(#448): 1-D Liu–Pierce AGHQ on Poisson (1|g)`). Did not STOP.
- S2 — issue https://github.com/itchyshin/DRM.jl/issues/450 ; worktree `~/local-scratch/lanes/DRM.jl-phylo-laplace-cox-reid` on `claude/lane-phylo-laplace-cox-reid` off `origin/main` `@53742f4d`. LOOP kit filled. Did not touch AGHQ files / handover leftover / `docs/a3c-design` / catchup.
ARC IN PROGRESS: S3 TDD red — standalone `test/test_cox_reid_poisson_phylo.jl`
NEXT: S3 write failing test; then S4 wire.
OPEN GATES (need human): none yet. Later: human merge of B's PR (do not `gh pr merge`).
TRUTH LIVES IN: `claude/lane-phylo-laplace-cox-reid` @ this worktree; issue #450; AGHQ PR #449 is foreign.
RESUME: read LOOP/GOAL.md → LOOP/checkpoint.md → LOOP/ultra-plan.md. CONTINUE FROM S3. Do not recreate the worktree. Do not open a second AGHQ issue. Do not edit `test/runtests.jl`.
