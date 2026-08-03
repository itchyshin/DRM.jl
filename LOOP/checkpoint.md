GOAL: #166 beta-binomial phylo/crossed RE route — COMPLETE. STATE: `origin/main` @
`5b93b0b` (squash-merge #368). #166 CLOSED.
ARCS DONE (verified): design note (kernel derivation); `:betabinomial_fixed`
kernel (value/d1/d2/d3/mean/obs/d12/v123 + nuisance value/d1/d2/v123) in
`src/sparse_laplace_glmm.jl`, verified vs ForwardDiff to machine precision;
`_fit_betabinomial_phylo_laplace` + `_fit_betabinomial_crossed_laplace` +
`_betabinomial_laplace_setup`; `BetaBinomial()`'s `drm()` routes
`phylo(1 | species)` (+ `tree=`) and crossed `(1 | g) + (1 | h)`,
constant-σ-only; tests (phylo 9 pass, crossed 12 pass, standing grad-gate
6.6e-8/7.7e-8 ≤ 1e-6); docs (capabilities.md, phylogenetic-models.md worked
example); check-log.d + after-task (incl. Rose-style claim-vs-evidence table).
One CI flake fixed mid-run: the crossed-RE recovery fixture's G=14/H=12/n=1008
was marginal cross-platform (ML variance-component small-sample bias +
platform floating-point noise through the Laplace Newton iterations) — CI
(Linux/Julia 1.12) failed `abs(re_sd(fit)[:h]-σh)<0.15` at 0.15577; scaled to
G=28/H=24/n=2400 (matches `test_crossed_laplace_generic.jl`'s size), verified
0.01-0.11 error across 5 reseeds; both CI legs (`test (1)` 55m16s,
`test (1.10)` 40m53s) plus `docs` passed clean on the second push.
ARC IN PROGRESS: none. TIP: IDLE.
NEXT: do not invent follow-on. New DRM.jl work requires an owner-opened G0.
Nonconstant-σ beta-binomial, q>1 non-Gaussian phylo location-scale (#202), and
combining phylo/crossed with an ordinary `(1|g)` on the mean remain out of
scope and rejected with explicit errors.
OPEN GATES: none. Fenced: Registrator (D-111), `:natgrad`/AI-REML, `.worktrees/`,
GPL vendoring, AGENTS fence commits.
TRUTH LIVES IN: `origin/main` @ `5b93b0b`; after-task
`docs/dev-log/after-task/2026-08-02-166-betabinomial-phylo-crossed-laplace.md`.
START HERE: this checkpoint (tip idle after #166).
RESUME: read AGENTS.md → this checkpoint; remain idle unless Shinichi opens a
DRM.jl G0. Leave `.worktrees/` alone; no Registrator.
