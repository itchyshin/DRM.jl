GOAL: see GOAL.md.   STATE: docs Claude-handover kit; tip IDLE pending owner G0; next pickup Claude.
ARCS DONE (verified): S0 recon (tip d0fac9d7 / #405 MERGED / issue 136 OPEN / #406 OPEN BLOCKED); S1 Claude handover; S2 LOOP+coord (Cursor idle/handing off); S3 DoD docs (`closeout.py` PASS); S4 this PR (no closer keywords; issue 136 still OPEN).
ARC IN PROGRESS: none. **[GATE] owner-named G0**.
NEXT: STOP. Claude rehydrates, confirms idle-or-named-work, asks owner for G0. Do not invent next G0. Do not start drmTMB from this tree.
OPEN GATES (need human): **owner names the next Julia G0**. #406 remains OPEN/BLOCKED (policy note; not a G0).
TRUTH LIVES IN: `docs/claude-handover-idle`; origin/main `d0fac9d7` until this PR merges; handover `docs/dev-log/handover/2026-08-14-claude-handover-drm-idle.md`.
RESUME: You are drm-claude-handover-idle. READ FIRST: LOOP/GOAL.md → LOOP/checkpoint.md → LOOP/ultra-plan.md → AGENTS.md → the Claude handover. WORKSPACE: `/Users/z3437171/Dropbox/Github Local/DRM.jl` on `docs/claude-handover-idle` (or `main` after merge). CONTINUE FROM: rehydrate, then STOP and ask for G0. Pause at: inventing G0 / drmTMB from this tree.
