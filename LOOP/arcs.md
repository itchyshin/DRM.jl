# Arcs — drm-136-va-rung1

Status: `pending` | `in_progress` | `done` | `blocked`
Gates: `[GATE]` = pause for human.

| id | status | slice | what | gate? |
|---|---|---|---|---|
| R1.0 | done | RECON | Inventory kernels + family `drm()`; all four `(1\|g)` reachable | no |
| R1.1 | done | TDD | Failing `test/test_va_frontend_families.jl` (unknown `marginal` keyword) | no |
| R1.2 | done | dispatch | Wire Binomial / NB2 / Gamma / Beta `drm(; marginal=:VA)` | no |
| R1.3 | done | docs | capabilities + guide + NEWS honesty | no |
| R1.4 | done | VERIFY | Local subset green (log read): 89/89 + Poisson 43 + kernels + LA smoke | no |
| R1.5 | in_progress | DoD + PR | check-log.d + after-task; PR **not** `closes #136`; issue comment; **[GATE]** merge | **[GATE]** merge |

Sequential: R1.0 → R1.1 → R1.2 → R1.4 → R1.5. R1.3 ∥ after R1.1.
STOP after R1.5 OPEN GATE — do not start 136e / phylo / ZI public VA.
