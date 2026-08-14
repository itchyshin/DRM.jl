# LOOP/ultra-plan.md — frozen at G0 approval (2026-08-14)
Binding copy of the approved Claude handover while tip is idle.
Do not re-plan mid-loop.

🎯 GOAL
Solo platform: Cursor (author) → Claude (pickup)
Deliverable: One docs PR from origin/main @ d0fac9d7 (Merge #405) that lands Claude START HERE while tip is idle
HEADLINE: Tip pointer says IDLE pending owner G0 — Claude pickup — not “wait for merge #405”
IN PARALLEL: none (linear kit: handover → LOOP → coord board → check-log/after-task → PR)
DEFER: #136 later (two-part/ZI×RE); #49 FIML; drmTMB engine="julia"; inventing a ship G0; src/; Experimental→Implemented; closing issue 136; treating #406 as ship work
DISCIPLINE: verify=origin/main is Merge #405, gh issue 136 OPEN, PR body has no closer for issue 136, no src/ · compute=n/a · closure=PR + --auto --merge, next Claude chat asks for G0

---

## ARC CARD — Claude handover while tip is idle

**Mode:** EXECUTE DIRECTLY (no fan-out; no nested subagents unless blocked)
**Requested outcome:** docs-only idle kit so the next Claude chat does not invent a G0 and does not treat #405 as still the open gate
**Mechanism authority:** new branch `docs/claude-handover-idle` from `origin/main` @ `d0fac9d7`; handover + LOOP overwrite + coordination-board + DoD docs; no `src/`; issue 136 stays OPEN
**Recommended arc:** 45–60 min
**Time contract:** ceiling ~60 min
**Estimate confidence:** high (analogue idle kits already on main: after-404, after-401, Julia-lane after-402)
**Arc 0 outcome:** START HERE file exists; LOOP says Claude pickup / IDLE; PR open; next chat asks for G0
**State transition:** LOOP “wait for merge #405” → IDLE pending owner G0, Claude pickup
**Executable rung and evidence:** `git fetch` + `gh issue view 136` + `git diff origin/main --stat` has no `src/` + `closeout.py check` PASS + PR body has no closer keywords

Capacity: single linear kit (S0–S4). No parallel lanes. No compute.

**In scope:** handover, LOOP, coordination-board Active-Lane-Split, check-log.d, after-task, optional Melissa plan-actual, docs PR
**Not in this arc:** later #136 two-part/ZI×RE; #49; drmTMB from this tree; inventing ship G0; `src/`; flipping Experimental → Implemented; closing issue 136; merging #406
**Evidence used:** analogue idle kit `docs/dev-log/handover/2026-08-13-cursor-handover-drm-idle-after-404.md`; public smoke already on main via #404 (`report/va-vs-laplace-bias.md`)
**Risk branch:** If `origin/main` moved past `d0fac9d7` with a named ship G0, STOP and report. If issue 136 is not OPEN, STOP and reopen. If GitHub auto-closes issue 136 from this PR body, reopen immediately.

**Done when:** PR open, no `src/`, issue 136 OPEN, handover resume prompt present, closeout PASS, next Claude step is rehydrate → STOP and ask for G0.
**First action after G0:** Claude rehydrates from `docs/dev-log/handover/2026-08-14-claude-handover-drm-idle.md`, then asks the owner for the next G0.

Status: START HERE written. OPEN GATE = owner-named G0.
