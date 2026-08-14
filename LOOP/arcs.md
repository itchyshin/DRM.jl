# Arcs — DRM.jl Claude handover while tip is idle

Status: `pending` | `in_progress` | `done` | `blocked`
Gates: `[GATE]` = pause for human.

| id | status | slice | what | gate? |
|---|---|---|---|---|
| S0 | done | recon | `git fetch`; tip `d0fac9d7`; #405 MERGED; issue 136 OPEN; #406 OPEN/BLOCKED; branch from `origin/main` | no |
| S1 | done | handover | `docs/dev-log/handover/2026-08-14-claude-handover-drm-idle.md`; banner 2026-08-13 Cursor idle historical | no |
| S2 | done | LOOP + coord | overwrite LOOP (Claude pickup, not wait-#405); refresh Active-Lane-Split; drmTMB row kept | no |
| S3 | done | DoD docs | check-log.d + after-task (`closeout.py` PASS) + Melissa plan-actual | no |
| S4 | done | PR | this docs PR; issue 136 still OPEN; no closer keywords; `--auto --merge` | no |
| NEXT | blocked | first Julia G0 after idle | owner names it; then ultra-plan | **[GATE]** owner names G0 |
| #406 | sibling-docs | auto-merge policy | OPEN / BLOCKED on CI `test (1.10)` | not a G0 |
| drmTMB | sibling | `engine="julia"` Workflow G | **other repo** — possibly in progress; unknown here | do not start from DRM.jl |
| later-136 | parked | two-part / ZI×RE | epic stays OPEN; 136e public Gamma report already on main | owner-named only |
| #49 | parked | FIML / missing data | issue stays open | owner-named only |

STOP on DRM.jl after S4. Claude rehydrates and asks for G0.
Do not autoload later-136 / #49 / drmTMB / #406-as-ship.
