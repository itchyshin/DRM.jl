# DRM.jl — NEWS

All notable changes are recorded here. The live work ledger is
[GitHub Issues](https://github.com/itchyshin/DRM.jl/issues); this file is the
human-readable changelog and mirrors `docs/src/changelog.md`.

## v0.1.0-DEV (unreleased)

### Phase 0 — Team & workflows (2026-05-30)

- Stood up the 12-persona team (`AGENTS.md`), extended the project `CLAUDE.md`,
  and added `ROADMAP.md` (phases → v1.0).
- Added 10 scripted workflows in `.claude/workflows/` (W0/Q/A/B/D/F/G/H/S/R)
  and 12 Codex agent configs in `.codex/agents/`.
- Established the **GitHub work ledger**: labels, milestones (Phase 0 → v1.0),
  and the initial near-term issues; issue + PR templates.
- Added the `docs/dev-log/` discipline (check-log, coordination-board,
  after-task, decisions, recovery-checkpoints, scout) and
  `tools/drm-checkpoint.jl`.
- Scaffolded the **Documenter** site mirroring drmTMB's pkgdown navbar — 36
  status-tagged stub pages, reference index in 6 workflow-ordered categories.
- Project meta: `bench/Project.toml`, `test/Project.toml`, `CITATION.cff`,
  `.JuliaFormatter.toml`, and `Documenter.yml` / `TagBot.yml` CI.
- **Engine unchanged.** The verified q=4 PLSM engine (2.18× over drmTMB on the
  single fit, O(p) to p=10,000, valid CIs where drmTMB's Hessian is singular)
  is exactly as handed over. See `HANDOVER.md`.

### Gaussian surface — first tranche (2026-05-30)

The public `drm()` / `bf()` front end (StatsModels `@formula`, mirroring drmTMB)
and the Gaussian family, built test-first with recovery tests and merged via
PRs #21–#27 (green CI each):

- **Univariate location–scale** — `drm(bf(y ~ x, sigma ~ x), Gaussian())`, ML.
- **Bivariate location–scale + residual correlation** —
  `bf(mu1=…, mu2=…, sigma1=…, sigma2=…, rho12=…)` (tanh link on ρ12).
- **Ordinary random intercept** `(1 | g)` on the mean — closed-form Gaussian
  marginal (matrix-determinant lemma + Woodbury); `re_sd`.
- **Meta-analysis** — `meta_V(v)` known sampling variances + estimated
  heterogeneity τ.
- **Inference & post-fit** — `coef` / `vcov` / `stderror` / `confint` (Wald) /
  `fitted` / `residuals` / `loglik` / `nobs` / `fixef`.
- **Docs** — landing page rewritten as a real stats-package page; Get started,
  location-scale, bivariate-coscale, which-scale, meta-analysis, model-workflow,
  and the "What can I fit today?" capability map filled with **executed**
  examples.
- Fixed R's implicit intercept (`y ~ x` ⇒ `y ~ 1 + x`). Verified `src/` engine
  unchanged.

Planned next: structured effects (`phylo()` wiring the verified q=4 engine,
then `spatial()` / `animal()` / `relmat()`), random slopes, `σ` random effects,
`predict` (new data) / `simulate`, and profile / bootstrap intervals.

[parity anchor: drmTMB v0.1.3 (2026-05-20)]
