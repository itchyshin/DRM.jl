# Recovery checkpoint — 2026-05-31 (pause for usage limit; resume ~2h)

Evidence-first rehydration: trust `git status` / recent commits / GitHub Issues /
this file over chat memory.

## ✅ Headline: docs site is LIVE
- **Working link: https://itchyshin.github.io/DRM.jl/dev/** (verified 200 + real
  VitePress HTML; `/dev/get-started`, `/dev/model-guides/model-map` all 200).
- Root cause of the earlier 404 was `docs/make.jl` using plain `deploydocs`
  (deployed the VitePress *intermediate* `build/1/*` verbatim → no HTML). Fixed in
  **#75** by switching to `DocumenterVitepress.deploydocs(...)` (flattens build/1 +
  rewrites base) + a `push: branches:[main]` deploy trigger. Mirrors GLLVM.jl.
- Repo About: homepage set to the docs URL; description fixed to **"Julian twin"**
  (NOT "digital twin" — maintainer rule).

## main state
- HEAD `d1019dc` (board #77). Recent: `ff30484` docs-deploy fix (#75),
  `e532ddc` RE on Student-t/LogNormal/Beta-binomial (#71).
- RE (intercept + correlated slope) complete on all 7 non-Gaussian families.

## Open / in-flight
- **PR #74** (Binomial family + `summary`/`coeftable`) — CI-green, **awaiting merge**
  (maintainer's call). Branch `feat-binomial-summary`.
- **Codex on #70** (engine lane): uncommitted WIP in the working tree —
  `src/sparse_laplace_glmm.jl`, `test/test_poisson_crossed_laplace.jl`,
  `src/DRM.jl` include. **DO NOT touch / commit** these (Codex's lane).
- **Pinned #76** = Codex brief (fast estimators + #70). Board: `coordination-board.md`.
- Forward issues: **#72** non-Gaussian bootstrap_ci, **#73** ranef(), **#70** Laplace
  crossed-RE, **#10–16** engine/experimental wiring + Q-gates.
- 3 read-only recon agents were running (drmtmb-look / gllvm-docs / vitepress-deploy);
  drmTMB-look spec feeds the docs look-polish — check for their results on resume.

## Resume actions (priority order)
1. Confirm `/dev/` still live; check PR #74 + merge if maintainer approves.
2. (Optional) cut `v0.1.2` tag → rebuilds `/stable/` with the fixed deploy so the
   **bare root** lands correctly (currently bounces to stale `/stable/`).
3. drmTMB-look polish: apply the `drmtmb-look-recon` VitePress nav/hero spec
   (the "add as you go" item; site works without it).
4. Coordinate with Codex on #70 as it lands; stay out of engine files.

## Lane discipline
Claude = families / post-fit / docs. Codex = engine core + estimators
(`sparse_aug_plsm.jl`, `fit_q4_sparse_tmb.jl`, `takahashi_selinv.jl`,
`experimental/*`, `sparse_laplace_glmm.jl`). Shared: `src/DRM.jl` (coordinate).
