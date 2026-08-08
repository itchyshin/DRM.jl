# After-task: #136 Arc 0 — Poisson public `marginal=:VA`

Date: 2026-08-08 · related #136 (**stays OPEN**)

Perspectives: Shannon · Ada · Noether · Fisher · Rose · Pat · Grace.
No nested subagents (thin conductor).

## Summary

Wired the public gap only: Poisson `(1 | g)` `drm(...; marginal = :VA)` routes to
the existing `_fit_poisson_ranef_va` kernel. Default Laplace unchanged. `DrmFit`
is tagged; mixed LA/VA AIC/LRT errors; unsupported VA rejects citing #136.
`method = :VA` on Poisson points at `marginal`. Issue **#136 stays open**.

## What landed

- Branch `feat/136-va-poisson-frontend` from tip `94a47e8b`
- Plan: `docs/dev-log/plans/2026-08-08-136-va-poisson-frontend-ultra-plan.md` (+ `LOOP/`)
- `src/poisson.jl` — `marginal` kwarg; `(1|g)` → `_fit_poisson_ranef_va`; forward through missing-response recursion
- `src/variational.jl` — `_va_reject` only (kernels untouched)
- `DrmFit.marginal` + `_withmarginal`; comparison / `aic`/`bic`/`aicc` mixed-marginal guards
- `test/test_va_frontend_poisson.jl` wired in `test/runtests.jl`
- Docs honesty: `capabilities.md` + `marginal-la-vs-va.md`
- check-log.d + this after-task

## Verify (log — not exit code)

Julia 1.10.0, `julia --project=. -e 'include(...)'` (log inspected):

```
Poisson public VA frontend (#136 Arc 0) | Pass 43  Total 43
Poisson random-intercept VA (ELBO) marginal (#136) | Pass 9  Total 9
VA marginal scaffold (#136) | Pass 6  Broken 3  Total 9
AIC / BIC / dof | Pass 7  Total 7
comparison: lrtest / anova / aicc / weights / update | Pass 12  Total 12
LA smoke OK: loglik=-293.606… aic=591.213… marginal=LA
ALL_SUBSET_DONE
```

Routing identity: `drm(...; marginal=:VA)` coef/loglik match `_fit_poisson_ranef_va`.

## Not covered / deferred

- Rungs 1–4 / 136e bias report
- Public VA for Binomial / NB2 / Gamma / Beta
- Closing #136
- q=4 core; #49 FIML; R-bridge; GPL; `.worktrees/`
- Merge (OPEN GATE — Noether + maintainer)

## Rose audit (claim-vs-evidence)

| Check | Verdict |
|---|---|
| Claim = Poisson `(1\|g)` public `marginal=:VA` routes to existing kernel | **PASS** — 43/43 frontend; identity vs `_fit_poisson_ranef_va` |
| Claim = default LA unchanged | **PASS** — `marginal=:LA` ≡ omit; LA smoke `marginal===:LA` |
| Claim = Experimental, not “implemented everywhere” | **PASS** — capabilities row + guide banner still Planned for the epic |
| Claim = #136 stays open / PR does not close | **PASS** — PR body must not say `closes #136` |
| No kernel rewrite / no overnight-audit merge / no 5-family `method=:VA` | **PASS** |
| No bias-recovery / 136e claim | **PASS** — not started |
| ELBO ≠ logLik (mixed AIC/LRT error) | **PASS** — 6 mixed-guard tests |
| License / `.worktrees/` | **PASS** |

**Rose verdict: PASS** — no overclaim; #136 remains the epic.

## Melissa

`RECONCILE:` see `docs/dev-log/plan-actual/2026-08-08-136-va-poisson-frontend.md`.
Keyword locked as `marginal=:VA` (Q1 IF YOU DO NOT MIND). Struct field added
(S2 risk branch not taken). AIC on a lone VA fit errors (stronger than warn;
prevents mixed IC by construction).

*Shannon · Ada · Noether · Fisher · Rose · Pat · Grace.*
