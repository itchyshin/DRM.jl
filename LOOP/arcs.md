# Arcs — drm-136-va-rung2-3

Status: `pending` | `in_progress` | `done` | `blocked`
Gates: `[GATE]` = pause for human.

| id | status | slice | what | gate? |
|---|---|---|---|---|
| R2.0 | done | RECON | Tip `fbbb8a56`; inventory skips + AIC guard + docs banners | no |
| R2.1 | done | TDD | Failing tiny-VA `aicc`; live anchors a/b/c in `test_variational.jl` | no |
| R2.2 | done | guard | `aicc` calls `_va_infocrit_guard` first; NB2 mixed AIC/LRT | no |
| R2.3 | done | docs | Experimental banner; capabilities; NEWS | no |
| R2.4 | done | VERIFY | Local subset green (log read): 15/15 + 95/95 + 43/43 + kernels + LA smoke | no |
| R2.5 | in_progress | DoD + PR | check-log.d + after-task; PR **not** `closes #136`; issue comment; **[GATE]** merge | **[GATE]** merge |

Sequential: R2.0 → R2.1 → R2.2 → R2.4 → R2.5. R2.3 ∥ after R2.1.
STOP after R2.5 OPEN GATE — do not start 136e / drmTMB engine=julia.
