# coordination-board.md — branch / PR overlap

Check this before editing shared files (`src/DRM.jl`, `AGENTS.md`, `CLAUDE.md`,
`ROADMAP.md`, `test/runtests.jl`, `docs/`). Record active branches + which files
they touch so two agents don't collide.

_Refreshed to HEAD reality 2026-06-02 (`chore-coordination-board`). All 13
drmTMB families are implemented / exported / tested; inference is wired;
v0.1.0 and v0.1.1 are tagged. See the "Verified state" section below._

## Lane split — Claude ↔ Codex

Full Codex brief: **#76** (pinned).

- **Claude (Shannon)** — family front-ends, post-fit, docs.
  Files: family `src/*.jl`
  (`poisson` / `negbinomial` / `beta` / `gamma` / `student` / `lognormal` /
  `betabinomial` / `binomial` / `zeroonebeta` / `tweedie` / `cumulative`),
  `summary.jl`, `inference.jl`, `variational.jl`, `docs/`, `test/runtests.jl`,
  `model-map.md`, `check-log.d/`.
- **Codex** — engine core + estimators.
  Files: `src/sparse_aug_plsm.jl`, `src/fit_q4_sparse_tmb.jl`,
  `src/takahashi_selinv.jl`, `src/experimental/*`, `bench/*`, `report/*`.
- **Shared — coordinate on the PR:** `src/DRM.jl` (include/export list).
  Append engine/experimental symbols in their own spot; flag on the PR.

## Verified state (as of HEAD)

- **All 13 families done / exported / tested.** Each has a `struct … end`
  marker in `src/` (`gaussian_core.jl` `Gaussian`, `student.jl` `Student`,
  `poisson.jl` `Poisson`, `negbinomial.jl` `NegBinomial2` + `TruncatedNegBinomial2`,
  `beta.jl` `Beta`, `betabinomial.jl` `BetaBinomial`, `binomial.jl` `Binomial`,
  `gamma.jl` `Gamma`, `lognormal.jl` `LogNormal`, `zeroonebeta.jl` `ZeroOneBeta`,
  `tweedie.jl` `Tweedie`, `cumulative.jl` `CumulativeLogit`) and all 13 appear in
  the `src/DRM.jl` export list. Family parity completed at **v0.1.1**
  (see `NEWS.md`).
- **Inference is wired** in `src/inference.jl` — Wald (`confint(…, method=:wald)`,
  boundary-aware SEs, #106), profile-likelihood (`method=:profile`, #103), and
  bootstrap (coefficient summaries #101 / auditable results #105 / fit-based
  entry points #132).
- **Tagged releases:** `v0.1.0` and `v0.1.1` (`git tag`).
- **Engine — crossed/structured Laplace merged.** Codex's lane landed crossed
  random effects (`closes #70`) plus a series of crossed/structured Laplace
  speed/correctness merges: #89, #97, #108, #111, #114, #119, #123, #126, #128.
- **Phase-3 docs + VA scaffold (Claude).** Developer/parity articles filled
  (#112/#116/#117/#121/#122, etc.); VA/ELBO marginal method-selection surface
  in progress (#136 — design spec + LA-vs-VA guide + `src/variational.jl`
  scaffold; Laplace stays the default, `_fit_va` is a stub).

## Active branches

| Branch | Owner | Touching | Status |
|---|---|---|---|
| `main` | — | docs deploy (DocumenterVitepress, deploy-on-main) | green / deploying |
| Codex engine lane (`codex/crossed-poisson-speed`, `codex/profile-ci-*`) | Codex | engine: `sparse_aug_plsm.jl`, `fit_q4_sparse_tmb.jl`, crossed/structured Laplace + profile-CI speed | active — **#80 / #113** |
| Claude docs + VA lane (`#136` scaffold) | Shannon (Claude) | `src/variational.jl`, `docs/`, `test/test_variational.jl` | active — Phase-3 docs + VA scaffold (#136) |

> Note: crossed/structured Laplace (#70 and follow-ons) and the 13-family +
> inference surface are **merged**; no stale "PR #74 open", "Phase 0 current", or
> "#70 not started" rows remain. Coordinate on `src/DRM.jl` include/export edits.
