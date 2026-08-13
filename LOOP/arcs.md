# Arcs — DRM.jl tip idle after #404

Status: `pending` | `in_progress` | `done` | `blocked`
Gates: `[GATE]` = pause for human.

| id | status | slice | what | gate? |
|---|---|---|---|---|
| S0 | done | recon | `git fetch`; tip `733ae972`; issue 136 OPEN; no competing ship PR; branch from `origin/main` | no |
| S1 | done | handover | `docs/dev-log/handover/2026-08-13-cursor-handover-drm-idle-after-404.md`; banner 2026-08-09 Julia-lane historical | no |
| S2 | done | LOOP + coord | overwrite LOOP (idle, not wait-#404); refresh Active-Lane-Split; drmTMB row kept | no |
| S3 | done | DoD docs | check-log.d + after-task (`closeout.py` PASS) + Melissa plan-actual | no |
| S4 | in_progress | PR | commit explicit paths; push; `gh pr create`; confirm issue 136 still OPEN | **[GATE]** owner merge |
| NEXT | blocked | first Julia G0 after idle | owner names it; then ultra-plan | **[GATE]** owner names G0 |
| drmTMB | sibling | `engine="julia"` Workflow G | **other repo** — possibly in progress; unknown here | do not start from DRM.jl |
| later-136 | parked | two-part / ZI×RE | epic stays OPEN; 136e public Gamma report already on main | owner-named only |
| #49 | parked | FIML / missing data | issue stays open | owner-named only |

STOP on DRM.jl after S4 until owner merges, then a fresh chat asks for G0.
Do not autoload later-136 / #49 / drmTMB.
