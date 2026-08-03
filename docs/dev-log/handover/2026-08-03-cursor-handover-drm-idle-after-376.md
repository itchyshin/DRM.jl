# Session Handoff: DRM.jl #376+#377 landed → tip idle

Meta: 2026-08-03 · from **Cursor** (Shannon) · TARGET **Cursor** · AUTHOR **cursor**

You are **Cursor**, picking up the DRM.jl repository after #376 ship work
landed. You inherit no chat context. Rehydrate from the current repository and
classify every item below **`OWED` · `DONE` · `RETRACTED` · `PROTECTED`**;
execute only `OWED`.

**Supersedes:** [`2026-08-03-cursor-handover-drm-idle-after-372.md`](2026-08-03-cursor-handover-drm-idle-after-372.md)
(#370+#372 tip-idle) as the DRM.jl **START HERE** pointer. That record remains
historical. This is the tip-idle record after #376 (PR #377).

## Critical Context

1. **#376 is CLOSED and merged.** Measured drmTMB q4 scaling head-to-head
   (retire extrapolated ~12×) closed via [PR #377](https://github.com/itchyshin/DRM.jl/pull/377)
   (squash `ae4e67d`).
2. **Tip is IDLE.** `origin/main` tip for this hygiene is `ae4e67d`.
3. **Default next action is DRM.jl tip IDLE — wait for an owner-opened G0.**
   Do **not** invent ship work. Leave `.worktrees/` alone. **D-111 OFF**
   (no Registrator / Julia General).

## OWED

| Item | State |
|---|---|
| Pick / invent next DRM ship slice without owner G0 | **RETRACTED** |
| Refresh `LOOP/*` + tip-idle handover after #376/#377 | **DONE** (this docs PR) |
| Stage or clean `.worktrees/` | **PROTECTED** — leave alone |
| Registrator / Julia General | **PROTECTED** — D-111 OFF |
| Rewrite measured #376 ratios / claim surfaces | **PROTECTED** — already on tip via #377; do not invent new headlines |

## Current Working State

- **Working:** `origin/main` @ `ae4e67d`; #376/#377 complete.
- **In progress:** none (docs tip-idle hygiene only).
- **Evidence:** `docs/dev-log/evidence/2026-08-03-376-q4-scaling-h2h.md`
  (paired Julia/R medians on Totoro; nrep=4; p∈{100,1000,5000,10000} —
  not the real-data q4_p100 2.18× cell; not #372 bridge ratios).

## How to Resume

```bash
cd "/Users/z3437171/Dropbox/Github Local/DRM.jl"
git fetch origin && git status -sb && git log --oneline -5 origin/main
```

Read `AGENTS.md` → `HANDOVER.md` → `LOOP/checkpoint.md` → this handover.
Start new DRM work only after owner G0.

*Shannon · perspectives: Ada (coordination), Rose (scope). No nested subagents.*
