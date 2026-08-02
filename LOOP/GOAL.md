# GOAL — issue #189 q=4 structured coevolution providers (IMMUTABLE — re-read at the top of EVERY arc)

## Mission
Close DRM.jl #189: bivariate q=4 coevolution from `spatial` / `relmat` / `animal`
(not only a phylo tree), with tests + docs + Rose claim fence; PR `closes #189`.

## Headline
Reuse verified `fit_q4_sparse_tmb(prob, Q_cond)`; generalize front-end `Q_cond`
assembly only — never rewrite the Laplace / exact-grad core.

## Invariants
- One DRM.jl lane; leave `.worktrees/` unstaged.
- No Registrator / Julia General (D-111).
- No `:natgrad` / AI-REML; no #291 acceleration follow-on.
- No drmTMB R-bridge edits; never vendor GPL source.
- Do not edit `src/fit_q4_sparse_tmb.jl` / `src/sparse_aug_plsm.jl` / Takahashi core.
- Non-tree bootstrap CIs out of scope — clear `ArgumentError` only.
- Twin doctrine: API/capability parity; bridge R→Julia only.

## Authoritative WHAT
`LOOP/ultra-plan.md` (frozen copy of the approved #189 ultra-plan).

## Definition of done
1. `drm(bf(... + spatial|relmat|animal on all four axes), Gaussian(); …)` routes to
   the q=4 engine and returns `fit.ranef.Sigma_a`.
2. Parameter-recovery or strong smoke + FD for each provider; phylo path regression-safe.
3. `coevolution_cor` works; non-tree bootstrap CI errors clearly.
4. Docs + DoD artifacts (tests, docstring, worked example, check-log.d, after-task, Rose).
5. PR closes #189.
