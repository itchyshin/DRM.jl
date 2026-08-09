# GOAL — new DRM.jl Julia lane IDLE pending owner G0 (IMMUTABLE — re-read every arc)
Read this first, every cycle. Auto-compact eats messages, not this file. Unsure after a compaction?
Re-read THIS, then checkpoint.md, then continue.

## Mission
New **Julia DRM.jl** lane after owner merged [#402](https://github.com/itchyshin/DRM.jl/pull/402)
@ `a913af8d` and started drmTMB elsewhere. Tip is **IDLE**. Issue **#136 stays
OPEN**. Do **not** start 136e / #49 / any ship slice unless the owner names it.
Do **not** start drmTMB from this tree. Do **not** claim the drmTMB sibling
lane is finished (status unknown from this session).

## Headline
Julia lane desk-ready; no invented G0; #136e / #49 PARKED; drmTMB = sibling.

## Invariants
- One *DRM.jl* ship lane at a time. Multi-lane split: DRM.jl Julia + drmTMB sibling.
- Fence: no q=4 core rewrite; ML default; no close #136; #49 parked; no GPL
  vendoring; never stage `.worktrees/`; D-111 OFF; no inventing ship from ROADMAP.
- START HERE: `docs/dev-log/handover/2026-08-09-cursor-handover-drm-julia-lane.md`.
- Morning note `docs/dev-log/handover/2026-08-09-cursor-handover.md` is historical
  (drmTMB handoff). Active-Lane-Split on `docs/dev-log/coordination-board.md`.

## Definition of done (this hygiene slice)
- New Julia-lane handover + LOOP + coordination-board match tip `a913af8d` / #402 MERGED
- #136 confirmed OPEN; drmTMB row not orphaned
- Next Immediate Steps = rehydrate → ask owner for first G0 (not 136e, not drmTMB)
