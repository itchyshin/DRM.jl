# GOAL — drm-136-va-poisson (IMMUTABLE — re-read at the top of EVERY arc)
Read this first, every cycle. Auto-compact eats messages, not this file. Unsure after a compaction?
Re-read THIS, then checkpoint.md, then continue.

## Mission
One PR from tip `origin/main` @ `94a47e8b`: Poisson random-intercept
`drm(...; marginal=:VA)` is a real public path (routes to existing
`_fit_poisson_ranef_va`; `DrmFit` tagged; mixed LA/VA AIC/LRT errors;
unsupported VA rejects; capabilities/guide honesty). Issue **#136 stays OPEN**.
Do **not** start rungs 1–4 / 136e.

## Headline
Reuse existing `_fit_poisson_ranef_va`; wire the public `marginal=:VA` gap on
Poisson `(1|g)` only — do not rebuild kernels; do not cherry-pick the stale
5-family `method=:VA` commit wholesale.

## Invariants
- One lane; branch `feat/136-va-poisson-frontend` from `origin/main` @ `94a47e8b`.
- Keyword is **`marginal=:LA/:VA`** (default `:LA`). Reject `method=:VA` on
  Poisson with a pointer to `marginal`. Gaussian `method=:ML/:REML` untouched.
- Fence: no q=4 core rewrite; ML default; no close #136; #49 parked; no R-bridge;
  never stage `.worktrees/`; no GPL vendoring; no Gamma/Binomial/NB2/Beta public
  VA; no 136e bias report; no kernel rewrite; do **not** merge
  `shannon/overnight-audit-verify-20260619`.
- Opening PR = OK. **Do not merge.** OPEN GATE = Noether + maintainer sign-off.
- ELBO ≠ logLik; no silent LA fallback; verify by LOG not exit code.

## Authoritative WHAT
`LOOP/ultra-plan.md` ↔
`docs/dev-log/plans/2026-08-08-136-va-poisson-frontend-ultra-plan.md`

## Definition of done
- Poisson `(1|g)` `drm(...; marginal=:VA)` ≡ `_fit_poisson_ranef_va` (routing identity)
- Default `:LA` unchanged; `DrmFit.marginal` tagged; mixed AIC/LRT errors
- Unsupported VA (phylo/crossed/corr/zi/hu/FE-only) errors citing #136
- `test/test_va_frontend_poisson.jl` in `runtests.jl`; local subset green
- capabilities.md + marginal-la-vs-va.md honesty (Experimental Poisson RI, not everywhere)
- check-log.d + after-task; Rose PASS; PR does **not** `closes #136`
