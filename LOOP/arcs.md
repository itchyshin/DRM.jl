# Arcs — drm-136-va-poisson Arc 0

Status: `pending` | `in_progress` | `done` | `blocked`
Gates: `[GATE]` = pause for human.

| id | status | slice | what | gate? |
|---|---|---|---|---|
| A0 | done | S0 RECON | Inventory `b32488d5` Poisson + `_va_reject` hunks vs tip `poisson.jl`. Co-opt pattern only. | no |
| A1 | done | S1 TDD + dispatch | Failing `test/test_va_frontend_poisson.jl`; `marginal` kwarg; `(1\|g)` → `_fit_poisson_ranef_va`; `_va_reject`; forward through missing-response recursion; reject `method=:VA`. | no |
| A2 | done | S2 DrmFit tag | `marginal::Symbol=:LA` + `_withmarginal`; thread `_withformula/_withnll/_withranef/_withreml`; default LA for 11-arg ctor. | no |
| A3 | done | S3 comparison | `lrtest`/`aic`/`aicc`/`bic`: error if mixed `:LA`/`:VA` (unary AIC errors on VA ELBO). | no |
| A4 | done | S4 docs honesty | capabilities.md VA row; marginal-la-vs-va.md Experimental Poisson RI (banner stays Planned for epic). | no |
| A5 | done | S5 VERIFY | Local subset green (log read): frontend 43/43; elbo 9/9; variational 6+3skip; aic 7/7; comparison 12/12; LA smoke. | no |
| A6 | in_progress | S6 DoD + PR | check-log.d + after-task; PR **not** `closes #136`; issue comment; **[GATE]** merge. | **[GATE]** merge |
| A7 | done | RECONCILE | `docs/dev-log/plan-actual/2026-08-08-136-va-poisson-frontend.md` (Melissa). | no |

Sequential: A0 → A1 → A2 → A3 → A5 → A6 → A7. A4 ∥ after A1.
STOP after A6 OPEN GATE — do not start rungs 1–4 / 136e.
