# After-task: #136 Rung 1 — Binomial / NB2 / Gamma / Beta public `marginal=:VA`

Date: 2026-08-08 · related #136 (**stays OPEN**)

Perspectives: Shannon · Ada · Noether · Fisher · Rose · Pat · Grace.
No nested subagents (thin conductor).

## Summary

Wired the public gap for four families whose VA kernels were already on tip:
Binomial, NegBinomial2, Gamma, and Beta random-intercept `(1 | g)` now reach
those kernels via `drm(...; marginal = :VA)`. Same keyword, `_va_reject`,
`DrmFit.marginal` tag, and mixed LA/VA AIC/LRT guard as Poisson Arc 0 (#399).
Default Laplace unchanged. Issue **#136 stays open**.

## What landed

- Branch `feat/136-va-rung1-families` from tip `ed35e13c` (PR #399 merged)
- `src/binomial.jl`, `src/negbinomial.jl`, `src/gamma.jl`, `src/beta.jl` —
  `marginal` kwarg; `(1|g)` → existing `_fit_*_ranef_va`; forward through
  missing-response recursion; locscale / phylo / crossed / corr / `sigma ~ x` /
  zi/hu reject via `_va_reject`
- `src/variational.jl` — `_va_reject` copy updated; shared
  `_reject_method_as_marginal` (Poisson drm() now calls it). **Kernels untouched.**
- `test/test_va_frontend_families.jl` wired in `test/runtests.jl`
- Docs honesty: `capabilities.md` + `marginal-la-vs-va.md` + `NEWS.md`
- check-log.d + this after-task

## Families shipped vs skipped

| Family | Public VA `(1\|g)` | Notes |
|---|---|---|
| Poisson | already on main (#399) | regression-tested 43/43 |
| Binomial | **shipped** | cbind + Bernoulli designs both reach kernel |
| NegBinomial2 | **shipped** | `sigma ~ 1` only |
| Gamma | **shipped** | `sigma ~ 1` only; no MGF rewrite |
| Beta | **shipped** | `sigma ~ 1` only |
| ZINB / hurdle / phylo / crossed / corr | **skipped** (honest reject) | no first-class public kernel |

## Verify (log — not exit code)

Julia 1.10.0, `julia --project=. -e 'include(...)'` (log inspected):

```
Rung 1 public VA frontend (#136) | Pass 89  Total 89
Poisson public VA frontend (#136 Arc 0) | Pass 43  Total 43
Binomial random-intercept VA (ELBO) marginal (#136) | Pass 9  Total 9
NB2 random-intercept VA (ELBO) marginal (#136) | Pass 17  Total 17
Gamma random-intercept VA (ELBO) marginal (#136) | Pass 17  Total 17
Beta random-intercept VA (ELBO) marginal (#136) | Pass 17  Total 17
Poisson LA smoke: … marginal=LA
Binomial LA smoke: … marginal=LA
NB2 LA smoke: … marginal=LA
Gamma LA smoke: … marginal=LA
Beta LA smoke: … marginal=LA
ALL_SUBSET_DONE
```

Routing identity: public `marginal=:VA` coef/loglik match the internal kernels.

## Not covered / deferred

- Closing #136
- 136e bias report
- Public VA for phylo / crossed / corr / ZI / hu / locscale / `sigma ~ x`
- q=4 core; #49 FIML; R-bridge; GPL; `.worktrees/`
- Merge (OPEN GATE — Noether + maintainer)

## Rose audit (claim-vs-evidence)

| Check | Verdict |
|---|---|
| Claim = four families `(1\|g)` public `marginal=:VA` route to existing kernels | **PASS** — 89/89 frontend; identity vs `_fit_*_ranef_va` |
| Claim = default LA unchanged | **PASS** — `marginal=:LA` ≡ omit; LA smoke all five families |
| Claim = Experimental, not “implemented everywhere” | **PASS** — capabilities + guide still Planned for the epic; ZI/phylo/crossed absent |
| Claim = #136 stays open / PR does not close | **PASS** — PR body must not say `closes #136` |
| No kernel rewrite / no Gamma MGF rewrite / no 136e | **PASS** |
| ELBO ≠ logLik (mixed AIC/LRT) | **PASS** — already guarded; not re-duplicated |
| License / `.worktrees/` | **PASS** |

**Rose verdict: PASS** — no overclaim; #136 remains the epic.

## Melissa

`RECONCILE:` see `docs/dev-log/plan-actual/2026-08-08-136-va-rung1-families.md`.
Keyword stayed `marginal=:VA`. All four tip kernels were reachable without math
changes. Shared `_reject_method_as_marginal` is a small DRY of Arc 0, not a
new selector.

*Shannon · Ada · Noether · Fisher · Rose · Pat · Grace.*
