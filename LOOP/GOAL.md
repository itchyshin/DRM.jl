# GOAL — issue #166 beta-binomial phylo/crossed RE route (IMMUTABLE — re-read at the top of EVERY arc)

## Mission
Close DRM.jl #166: add the beta-binomial derivative kernel to the sparse-Laplace GLMM engine;
route `drm(bf(cbind(s,f) ~ x + phylo(1|species)), BetaBinomial(); tree=...)` and the crossed
`(1|g)+(1|h)` analogue through it. Constant-sigma (overdispersion) first; PR `closes #166`.

## Headline
Generalize the verified Beta-family analytic kernel (`_laplace_v123(::Val{:beta_fixed}, …)`) to
beta-binomial's discrete known-trials data term — shifted digamma/trigamma/polygamma arguments,
not a new derivation. Reuse the Poisson/Binomial/Beta phylo+crossed routing plumbing verbatim.

## Invariants
- One DRM.jl lane; leave `.worktrees/` unstaged.
- No Registrator / Julia General (D-111).
- No `:natgrad` / AI-REML; no #291 acceleration follow-on.
- No drmTMB R-bridge edits; never vendor GPL source.
- Do not edit `src/fit_q4_sparse_tmb.jl` / `src/sparse_aug_plsm.jl` / Takahashi core.
- Nonconstant-sigma beta-binomial out of scope (tracked separately).
- Twin doctrine: R already has this capability (per #166 body) — Julia is following, per D-94.

## Authoritative WHAT
`LOOP/ultra-plan.md` (frozen copy of this approved #166 ultra-plan).

## Definition of done
1. Phylo and crossed beta-binomial routes both reach the sparse-Laplace engine (not GHQ).
2. Parameter-recovery + analytic-vs-FD gradient ≤1e-6 for both routes, constant-sigma only.
3. Docs + DoD artifacts (tests, docstring, worked example, check-log.d, after-task, Rose).
4. PR closes #166.
