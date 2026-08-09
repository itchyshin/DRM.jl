# Arcs — #136e honest public-path VA bias report

Status: `pending` | `in_progress` | `done` | `blocked` | `skipped`
Gates: `[GATE]` = pause for human.

| id | status | slice | what | gate? |
|---|---|---|---|---|
| S0 | done | recon | git + design + frontend fixture (planning chat) | no |
| S1 | in_progress | ADEMP + harness | `bench/va_vs_laplace_bias.jl` + ADEMP in report stub | no |
| S2 | pending | smoke | 1–3 local reps; read log (finite α_LA, α_VA, times) | no |
| S3 | pending | report | `report/va-vs-laplace-bias.md` with numbers + not-7×-unless-measured | no |
| S4 | pending | docs honesty | cite report in guide + capabilities; Experimental held | no |
| S5 | pending | optional n-ladder | only if S2 shows material α gap | **[GATE]** Totoro if n_sim would exceed ~15 min laptop |
| S6 | pending | Rose + LOOP + PR | check-log, after-task, PR **without** `closes #136` | **[GATE]** owner merge |
| S7 | pending | mechanical verify | file exists; numbers match log; Experimental strings held | no |
| S8 | pending | Melissa | `docs/dev-log/plan-actual/2026-08-09-136e-va-bias.md` | no |
| #49 | parked | FIML | not this lane | owner-named only |
| drmTMB | sibling | `engine="julia"` | other repo; do not start from DRM.jl | do not claim finished |

Do not close #136. Do not hunt 7× by inventing an unwired two-part DGP.
