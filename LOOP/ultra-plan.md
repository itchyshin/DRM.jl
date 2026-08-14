# LOOP/ultra-plan.md — frozen at G0 approval (2026-08-13)
Binding copy of the approved tip-idle START HERE after #404 plan.
Do not re-plan mid-loop.

🎯 GOAL
Solo platform: Cursor
Deliverable: One docs PR from origin/main @ 733ae972 (Merge #404) that lands tip-idle START HERE after #404
HEADLINE: Tip pointer says IDLE pending owner G0 — not “merge #404 / 136e in flight”
IN PARALLEL: none (linear kit: handover → LOOP → coord board → check-log/after-task → PR)
DEFER: #136 later (two-part/ZI×RE); #49 FIML; drmTMB engine="julia"; inventing a ship G0; src/; Experimental→Implemented; closing issue 136
DISCIPLINE: verify=origin/main is Merge #404, gh issue 136 OPEN, PR body has no closer for issue 136, no src/ · compute=n/a · closure=PR open, owner merge, next chat asks for G0

---

## ARC CARD — tip idle START HERE after #404

**Mode:** EXECUTE DIRECTLY (no fan-out; no nested subagents unless blocked)
**Requested outcome:** docs-only idle kit so the next Cursor chat does not treat 136e as still in flight
**Mechanism authority:** new branch `docs/tip-idle-after-404` from `origin/main` @ `733ae972`; handover + LOOP overwrite + coordination-board + DoD docs; no `src/`; no merge; issue 136 stays OPEN
**Recommended arc:** 45–60 min
**Time contract:** ceiling ~60 min
**Estimate confidence:** high (analogue idle kits already on main: after-401, Julia-lane after-402)
**Arc 0 outcome:** START HERE file exists; LOOP says IDLE; PR open; owner merge = GATE
**State transition:** LOOP “wait for merge #404” → IDLE pending owner G0
**Executable rung and evidence:** `git fetch` + `gh issue view 136` + `git diff origin/main --stat` has no `src/` + `closeout.py check` PASS + PR body has no closer keywords

Capacity: single linear kit (S0–S4). No parallel lanes. No compute.

**In scope:** handover, LOOP, coordination-board Active-Lane-Split, check-log.d, after-task, optional Melissa plan-actual, docs PR
**Not in this arc:** later #136 two-part/ZI×RE; #49; drmTMB from this tree; inventing ship G0; `src/`; flipping Experimental → Implemented; merging the PR; closing issue 136
**Evidence used:** analogue idle kits `docs/dev-log/handover/2026-08-09-cursor-handover-drm-julia-lane.md`, `docs/dev-log/handover/2026-08-05-cursor-handover-drm-idle-after-393.md`, `docs/dev-log/after-task/2026-08-09-tip-idle-after-401.md`; public smoke already on main via #404 (`report/va-vs-laplace-bias.md`)
**Risk branch:** If `origin/main` moved past `733ae972`, STOP and report. If issue 136 is not OPEN, STOP and reopen. If GitHub auto-closes issue 136 from this PR body, reopen immediately.

**Done when:** PR open, mergeable, no `src/`, issue 136 OPEN, handover resume prompt present, closeout PASS, owner merge is the remaining GATE.
**First action after G0:** `git checkout -B docs/tip-idle-after-404 origin/main` then write the handover.

Status: START HERE written. OPEN GATE = owner merge of docs PR, then owner G0.
