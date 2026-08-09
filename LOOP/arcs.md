# Arcs — new DRM.jl Julia lane (IDLE pending owner G0)

Status: `pending` | `in_progress` | `done` | `blocked`
Gates: `[GATE]` = pause for human.

| id | status | slice | what | gate? |
|---|---|---|---|---|
| R2.0–R2.4 | done | VA Rung 2+3 | anchors a/b/c + aicc guard + Experimental docs | no |
| R2.5 | done | merge #401 | CI green; `gh pr merge 401 --merge`; #136 stays OPEN | no |
| T1 | done | morning tip-idle START HERE | handover + LOOP after #401; #402 MERGED @ `a913af8d` | no |
| T2 | in_progress | Julia-lane START HERE | new handover + LOOP + Active-Lane-Split (drmTMB not orphaned) | **[GATE]** owner merge docs PR |
| NEXT | blocked | first Julia G0 | owner names it; then ultra-plan | **[GATE]** owner names G0 |
| drmTMB | sibling | `engine="julia"` Workflow G | **other repo** — possibly in progress; unknown here | do not start from DRM.jl |
| 136e | parked | bias report | `report/va-vs-laplace-bias.md` | owner-named only |
| #49 | parked | FIML / missing data | issue stays open | owner-named only |

STOP on DRM.jl after T2 until owner names G0. Do not autoload 136e / #49.
