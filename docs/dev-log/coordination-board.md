# coordination-board.md — branch / PR overlap

Check this before editing shared files (`src/DRM.jl`, `AGENTS.md`, `CLAUDE.md`,
`ROADMAP.md`, `test/runtests.jl`, `docs/`). Record active branches + which files
they touch so two agents don't collide.

## Lane split — Claude ↔ Codex

Full Codex brief: **#76** (pinned).

- **Claude (Shannon)** — family front-ends, post-fit, docs.
  Files: family `src/*.jl`
  (`poisson` / `negbinomial` / `beta` / `gamma` / `student` / `lognormal` /
  `betabinomial` / `binomial`), `summary.jl`, `inference.jl`, `docs/`,
  `test/runtests.jl`, `model-map.md`, `check-log.md`.
- **Codex** — engine core + estimators.
  Files: `src/sparse_aug_plsm.jl`, `src/fit_q4_sparse_tmb.jl`,
  `src/takahashi_selinv.jl`, `src/experimental/*`, `bench/*`, `report/*`.
  Queue: **#70** (new algorithm — crossed/structured non-Gaussian RE via Laplace),
  **#10–13** (wire `experimental/`), **#14–16** (Q-gates), **#49** (FIML/EM).
- **Shared — coordinate on the PR:** `src/DRM.jl` (include/export list).
  Append engine/experimental symbols in their own spot; flag on the PR.

## Active branches

| Branch | Owner | Touching | Status |
|---|---|---|---|
| `main` | — | docs deploy fixed (`DocumenterVitepress.deploydocs` + deploy-on-main, `ff30484`) | deploying `/dev/` |
| `feat-binomial-summary` | Shannon (Claude) | `src/binomial.jl`, `src/summary.jl`, `src/DRM.jl`, `test/test_binomial*`, `test/test_summary.jl` | PR #74 open |
| `laplace-crossed-re` (planned) | Codex | engine: `sparse_aug_plsm.jl`, `fit_q4_sparse_tmb.jl` + new crossed-RE Laplace path | #70 — not yet started |
