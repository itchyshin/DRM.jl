# Arcs — #136e honest public-path VA bias report

Status: `pending` | `in_progress` | `done` | `blocked` | `skipped`
Gates: `[GATE]` = pause for human.

| id | status | slice | what | gate? |
|---|---|---|---|---|
| S0 | done | recon | git + design + frontend fixture | no |
| S1 | done | ADEMP + harness | `bench/va_vs_laplace_bias.jl` + ADEMP | no |
| S2 | done | smoke | 3 local reps; log `SMOKE_OK`; LA≈VA | no |
| S3 | done | report | `report/va-vs-laplace-bias.md` with numbers | no |
| S4 | done | docs honesty | guide + capabilities; Experimental held | no |
| S5 | skipped | optional n-ladder | no material α gap | Totoro not needed |
| S6 | done | Rose + LOOP + PR | [#404](https://github.com/itchyshin/DRM.jl/pull/404) **without** `closes #136` | **[GATE]** owner merge
| S7 | done | mechanical verify | file exists; numbers match log (`3.7102` / `3.5764` / `4.5822`) | no |
| S8 | done | Melissa | `docs/dev-log/plan-actual/2026-08-09-136e-va-bias.md` | no |
| #49 | parked | FIML | not this lane | owner-named only |
| drmTMB | sibling | `engine="julia"` | other repo; do not start from DRM.jl | do not claim finished |

Owner prior recorded: LA often similar/faster/more accurate (R/TMB). Smoke agreed.
