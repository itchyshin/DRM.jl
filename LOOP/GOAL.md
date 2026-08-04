# GOAL — tip idle after #386 (IMMUTABLE — re-read every arc)
# Status: ACTIVE 2026-08-04 — G0 approved via /goal (tip-idle hygiene).

## Mission
Docs-only tip-idle START HERE after #385/#386 MERGED: refresh stale LOOP/*
(still said “merge #386”), write handover
`docs/dev-log/handover/2026-08-04-cursor-handover-drm-idle-after-386.md`
superseding after-381, open docs PR (pattern #378–#382). Tip IDLE; next
session waits for owner-named DRM.jl ship G0 only.

## Headline
LOOP/checkpoint claimed a merge gate for #386 while tip was already
`d543f94` — fix ledger drift before the next lane.

## Invariants
- One lane: branch `docs/tip-idle-after-386` from `d543f94`. Leave `.worktrees/` alone.
- D-111 OFF (no Registrator / Julia General).
- Docs/LOOP/handover/check-log/after-task only — no `src/` engine edits.
- Do not invent ship from ROADMAP; do not rebuild #376/#383/#385.
- No fixture 0.6.0 refresh, timing campaigns, #202/#49, or Lovelace in this arc.
- Rose: docs-only scope; no speed claims; ML default.
- Never stage `.worktrees/`.

## Authoritative WHAT
`docs/dev-log/plans/2026-08-04-tip-idle-after-386-ultra-plan.md` (and
`LOOP/ultra-plan.md` copy). Tip `origin/main` @ `d543f94`.

## Definition of done
- LOOP/{GOAL,arcs,checkpoint,ultra-plan} say tip IDLE; no stale merge-#386 gate
- Handover after-386 is START HERE; supersedes after-381
- check-log.d + after-task + docs PR open (owner merge = L2)
- Optional: vault MC drmTMB.json Julia tip string refreshed (brain local)
