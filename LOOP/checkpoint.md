# Checkpoint — OVERWRITTEN every arc (a pointer to truth, not a log)

GOAL: see GOAL.md.   STATE: rebased onto origin/main @ 93c3db6b (#449 AGHQ merged). S3/S4 27/27 after rebase. PR #451 awaiting human merge.
ARCS DONE (verified):
- S1 — AGHQ #448 / PR #449 **merged** to origin/main (`93c3db6b`). Kept: `src/aghq_1d.jl`, `marginal=:AGHQ` / `nAGQ` on Poisson `(1|g)`.
- S2 — issue https://github.com/itchyshin/DRM.jl/issues/450 ; worktree `~/local-scratch/lanes/DRM.jl-phylo-laplace-cox-reid` on `claude/lane-phylo-laplace-cox-reid`.
- S3 — TDD red: standalone `test/test_cox_reid_poisson_phylo.jl` (not in `runtests.jl`).
- S4 — Wire: lift structured `_reject_reml_route`; thread `reml` into `_fit_poisson_general_laplace`; reuse #444 helpers. Unioned with #449 AGHQ dispatch in `src/poisson.jl` (rebase 2026-08-18).
- S5 — Docs: ML-default / Cell D not-recovery / phylo-relmat opt-in. check-log.d + after-task landed. No capability chip.
- S6 — standalone 27/27 after rebase onto #449 (read the log). AGHQ smoke: kernel 9/9 + surface 37/37 still load.
- S7 — PR https://github.com/itchyshin/DRM.jl/pull/451 (`closes #450`). Did not `gh pr merge`.
ARC IN PROGRESS: none.
NEXT: human merge of https://github.com/itchyshin/DRM.jl/pull/451
OPEN GATES (need human): human merge of #451; `src/` + public `method = :REML` needs Noether + maintainer.
TRUTH LIVES IN: `claude/lane-phylo-laplace-cox-reid` @ rebase HEAD (see `git rev-parse HEAD`); issue #450; PR #451; AGHQ is on origin/main (#449), not a foreign open PR.
RESUME: read LOOP/GOAL.md → LOOP/checkpoint.md. CONTINUE FROM human merge. Do not recreate the worktree. Do not re-merge #449. Do not reopen #448. Do not edit `test/runtests.jl`. Do not flip capability chips. Do not `gh pr merge`.
