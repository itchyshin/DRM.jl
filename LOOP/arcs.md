# Arcs — DRM.jl tip idle after #401

Status: `pending` | `in_progress` | `done` | `blocked`
Gates: `[GATE]` = pause for human.

| id | status | slice | what | gate? |
|---|---|---|---|---|
| R2.0–R2.4 | done | VA Rung 2+3 | anchors a/b/c + aicc guard + Experimental docs | no |
| R2.5 | done | merge #401 | CI green; `gh pr merge 401 --merge`; #136 stays OPEN | no |
| T1 | in_progress | tip-idle START HERE | handover + LOOP + coordination-board | **[GATE]** owner merge docs PR |
| NEXT | blocked | drmTMB julia engine | live Workflow G — **other repo**, fresh chat | **[GATE]** owner opens drmTMB chat |
| 136e | parked | bias report | `report/va-vs-laplace-bias.md` | owner-named only |
| #49 | parked | FIML / missing data | issue stays open | owner-named only |

STOP on DRM.jl after T1. Do not start 136e from this LOOP kit.
