# coordination-board.md — branch / PR overlap

Check this before editing shared files (`src/DRM.jl`, `AGENTS.md`, `CLAUDE.md`,
`ROADMAP.md`, `test/runtests.jl`, `docs/`). Record active branches + which files
they touch so two agents don't collide.

_Light tip refresh 2026-08-07 (`docs/7-phase3-closeout`): tip base `f3d8ce7d`
(Merge #396 / #388). Phase 3 / #7 → complete-with-carveouts (26/26 slugs;
phylo×spatial Theory+roadmap + VA Experimental #136). Prior refresh 2026-06-02
still holds for families/inference wiring — see "Verified state" below._

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
- **Phase 3 / #7 complete-with-carveouts (2026-08-07).** All 26 drmTMB-target
  Documenter slugs exist; carve-outs named (phylo×spatial Theory+roadmap;
  VA Experimental #136). Public VA is Experimental `(1 | g)` on Poisson /
  Binomial / NB2 / Gamma / Beta (`marginal = :VA`); Laplace remains default;
  `_fit_va` still errors for unwired families; #136 stays OPEN. Inventory:
  `docs/dev-log/evidence/2026-08-07-7-phase3-inventory.md`.

## Active branches

| Branch | Owner | Touching | Status |
|---|---|---|---|
| `main` | — | tip @ `fbbb8a56` (Merge #400); docs deploy | tip after VA Rung 1 |
| `feat/136-va-rung2-3` | Shannon (Cursor) | `test/test_variational.jl`, `test/test_va_frontend_families.jl`, `src/comparison.jl`, VA docs, LOOP/, check-log/after-task | **active** — Rung 2+3; #136 stays OPEN; no merge |
| #136e / drmTMB `engine="julia"` | — | fenced | **next fresh task after owner merge** — not this PR |

> Note: Phase 3 article-fill work is exhausted (26/26). Do not invent tip-idle
> SHA padding. Never stage `.worktrees/`. Coordinate on `src/DRM.jl` if an
> engine lane reopens.
