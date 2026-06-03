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
  Queue: **#80** (remaining crossed/structured non-Gaussian RE via Laplace),
  **#11–13** (wire selected `experimental` estimators), **#14–16** (Q-gates),
  **#49** (FIML/EM), **#136** (VA/ELBO marginal method lane).
- **Shared — coordinate on the PR:** `src/DRM.jl` (include/export list).
  Append engine/experimental symbols in their own spot; flag on the PR.

## Active branches

| Branch | Owner | Touching | Status |
|---|---|---|---|
| `main` | — | current through #132 (`1c5094e`): fit-based bootstrap entry points; no merged VA work | live `/dev/` source |
| `codex/status-ledger-cleanup` | Codex | `README.md`, `ROADMAP.md`, this board, source docstrings/comments, `check-log.d/`, after-task | local status cleanup branch from `origin/main`; avoids `docs/src/r-julia-bridge.md` because PR #135 owns it |
| `codex/profile-ci-bootstrap-speed` | Codex | `src/inference.jl`, `src/DRM.jl`, profile/bootstrap tests/docs, reports, `check-log.d/`, after-task | PR #137 open: auditable `profile_result` + endpoint threading |
| `docs-reference-bridge-stubs` | Shannon (Claude) | `docs/src/reference/deprecated-marker-internals.md`, `docs/src/r-julia-bridge.md`, `check-log.d/` | PR #135 open; owns R-bridge stub fill |
| `docs-implementation-map` | Shannon (Claude) | implementation-map docs, `check-log.d/` | PR #129 open |
| `docs-simulation-plot-grammar` | Shannon (Claude) | simulation/plot grammar docs, `check-log.d/` | PR #134 open |
| `va-scaffold` | Shannon (Claude) | `src/variational.jl`, `src/DRM.jl`, `test/runtests.jl`, `test/test_variational.jl` | PR #138 open; shared `src/DRM.jl` include |
| `va-docs` / `va-design` | Shannon (Claude) | VA/ELBO docs + model-guide nav | PR #139 open; `origin/va-design` also exists |

## Stale coordination notes

- PR #74 is merged; Binomial and `summary`/`coeftable` are on `main`.
- #70 is closed; #80 is the active crossed/structured non-Gaussian RE umbrella.
- #10 is effectively complete through the production inference module and
  boundary-aware Wald SE slice. Remaining `experimental/` wiring is #11-#13.
- New check-log entries should use `docs/dev-log/check-log.d/`, not append to
  `docs/dev-log/check-log.md`.
