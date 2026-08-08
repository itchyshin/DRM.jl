# GOAL — drm-136-va-rung1 (IMMUTABLE — re-read at the top of EVERY arc)
Read this first, every cycle. Auto-compact eats messages, not this file. Unsure after a compaction?
Re-read THIS, then checkpoint.md, then continue.

## Mission
One PR from tip `origin/main` @ `ed35e13c` (PR #399 merged): public
`drm(...; marginal=:VA)` for Binomial / NB2 / Gamma / Beta `(1 | g)` routes to
existing kernels. Same keyword / `_va_reject` / `DrmFit.marginal` / mixed
LA/VA guard as Poisson Arc 0. Issue **#136 stays OPEN**. Do **not** start 136e.

## Headline
Reuse existing `_fit_{binomial,nb2,gamma,beta}_ranef_va`; wire public dispatch
only — do not rebuild kernels; do not rewrite Gamma MGF.

## Invariants
- One lane; branch `feat/136-va-rung1-families` from `origin/main` @ `ed35e13c`.
- Keyword is **`marginal=:LA/:VA`** (default `:LA`). Reject `method=:VA` with a
  pointer to `marginal`.
- Fence: no q=4 core rewrite; ML default; no close #136; #49 parked; no R-bridge;
  never stage `.worktrees/`; no GPL vendoring; no 136e bias report; no kernel
  rewrite; no ZI/phylo/crossed/corr public VA.
- Opening PR = OK. **Do not merge.** OPEN GATE = Noether + maintainer sign-off.
- ELBO ≠ logLik; no silent LA fallback; verify by LOG not exit code.

## Authoritative WHAT
Owner “go Rung 1” brief + Poisson Arc 0 pattern
(`test/test_va_frontend_poisson.jl`, `src/poisson.jl`).

## Definition of done
- Four families `(1|g)` `drm(...; marginal=:VA)` ≡ internal `_fit_*_ranef_va`
- Default `:LA` unchanged; `DrmFit.marginal` tagged
- Unsupported VA errors citing #136; `method=:VA` points at `marginal`
- `test/test_va_frontend_families.jl` in `runtests.jl`; local subset green
- capabilities.md + marginal-la-vs-va.md honesty (Experimental five-family RI)
- check-log.d + after-task; Rose PASS; PR does **not** `closes #136`
