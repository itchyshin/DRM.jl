# DRM.jl — NEWS

All notable changes are recorded here. The live work ledger is
[GitHub Issues](https://github.com/itchyshin/DRM.jl/issues); this file is the
human-readable changelog and mirrors `docs/src/changelog.md`.

## Unreleased

- **Non-Gaussian phylogenetic location–scale (#202)** — public `drm()` path for
  `NegBinomial2()` / `Gamma()` with a shared structured RE on **μ and log σ**
  via grammar B `(1 | p | phylo(species))` on both axes (`tree=` forwarded into
  the locscale frontend). `vc(fit)[:species]` reports the 2×2 group-level
  covariance (never residual `rho12`). Dual issue-text `phylo(1|sp)` on both
  axes stays rejected. Evidence: `test/test_public_phylo_locscale.jl` (NB2
  recovery + Gamma smoke). R `nbinom2-locscale` fixture deferred until drmTMB
  supports coupled `(1|p|species)` (D-94; R q=1 structured-σ covers scale-axis
  existence).

## v0.1.2 (2026-08-01)

**Version catch-up on the post–v0.1.1 `main` tip (registry candidate — not yet
in Julia General).** `Project.toml` / `CITATION.cff` advance `0.1.0` → `0.1.2`
so a first General registration does not collide with the existing git tags
`v0.1.0` / `v0.1.1` (May 2026; tip is hundreds of commits past those tags).
Prep + gates: [`docs/dev-log/plans/registrator-prep-2026-08-01.md`](docs/dev-log/plans/registrator-prep-2026-08-01.md).
**Registrator submit and tagging wait explicit Shinichi OK** (ultra-plan S4).
This note does **not** claim General membership, Phase 1.5 / #5 bridge closeout,
or a full public wire of remaining `src/experimental/`.

Post–v0.1.1 tip highlights already on `main` (Rose-honest; measured claims stay
in `HANDOVER.md` / `report/`):

- **Registry hygiene (S2/S3)** — ayumi↔main integrate (#340), load-banner silence
  (#341), docs honesty on Next / bridge / version drift (#342), post-merge
  checkpoint (#343).
- **σ-phylo REML correctness** — REML restricts both β_μ and β_ψ (#337).
- **Opt-in Gaussian REML**, conjugate-EM phylo-mean solver, heritability /
  repeatability / ICC accessors, DHARMa-style randomised quantile residuals, and
  the coevolution q=4 phylo front end (see HANDOVER TL;DR).
- **Julia-side bridge surface** (`drm_bridge` / `drm_bridge_inference`) remains
  in-tree; R-side `engine = "julia"` finish is still open (#5).
- **Bivariate q=4 coevolution bootstrap uncertainty** — `bootstrap_sigma_a` gives
  parametric-bootstrap intervals for the q=4 phylogenetic among-axis SDs
  (`sqrt(diag(Σ_a))`) and the six among-axis coevolution correlations, reachable
  from R via JuliaCall; `bootstrap_result(fit)` and the R bridge route a bivariate
  q4 fit here. Boundary-honest: a collapsing scale axis returns a small interval
  near the floor and its correlations come back unidentified (`~[−1, 1]`). A
  coverage study (`report/finish-audit/bootstrap-coverage-findings.md`) confirms
  the mean-axis SD CIs are well-calibrated and the detection/correlation reads are
  robust; the scale-axis *precise* CIs are anti-conservative (a known
  boundary-bootstrap effect) — read them as detection/indication, with a calibrated
  interval (BCa / bias-correction) tracked as a follow-up.
- **Per-parameter prediction** — `predict_parameters` (fitted distributional
  parameters on new data), `marginal_parameters` (population-averaged), and
  `prediction_grid` (build a swept `newdata` grid from a reference table).
- **Auditable profile-likelihood CIs** — `profile_result` exposes the full
  profile object behind `confint(fit; method = :profile)`.
- **Post-fit accessors** — `summary`, `family`, `is_converged`, `deviance`,
  `dof_residual`, and `rho12` (bivariate residual correlation).
- **Non-Gaussian phylogenetic random effects** — `phylo(1 | species, tree)` on
  the mean for Poisson, NegBinomial2, Gamma, Beta, and Binomial families
  (constant `σ`), via a sparse Laplace approximation, plus crossed intercepts
  `(1 | g) + (1 | h)` for those families.

## v0.1.1 (2026-05-31)

**drmTMB family parity complete** — the four remaining families, each
recovery-tested and shipped one-PR-per-family with green CI. DRM.jl now fits
every distribution family drmTMB offers.

- **Beta-binomial** `BetaBinomial()` — successes out of known trials with
  extra-binomial overdispersion. Two-column `cbind(successes, failures) ~ …`
  response (drmTMB-exact, via a `cbind` formula marker + a second-response field
  on `DrmFormula`), logit mean + `φ = 1/σ²`. (drmTMB has no standalone
  `binomial`; ordinary binomial is the `φ → ∞` limit of beta-binomial.)
- **Zero-one-inflated beta** `ZeroOneBeta()` — proportions on the closed `[0,1]`;
  mixture `P(0)=zoi(1-coi)`, `P(1)=zoi·coi`, `(1-zoi)·Beta(μ,φ)`. Params
  `mu`/`sigma`/`zoi`/`coi`.
- **Tweedie** `Tweedie()` — semicontinuous (compound Poisson–Gamma, `1<p<2`):
  exact-zero mass + positive continuous part. Mean `μ` (log), `sigma` =
  √dispersion, `nu` = the estimated power `p` (logit-`(1,2)`). Density via the
  Dunn–Smyth series (adds the `SpecialFunctions` dependency).
- **Cumulative-logit** `CumulativeLogit()` — ordinal: `Pr(y≤k)=logistic(θ_k−η)`
  with `K-1` ordered cutpoints; intercept dropped.

Full set (12 univariate + bivariate Gaussian): Gaussian, Student-t, LogNormal,
Gamma, Tweedie, Beta, zero-one-inflated beta, beta-binomial, Poisson,
NegBinomial2, truncated-NB2, cumulative-logit. Families are validated by
simulation parameter recovery; the numerical drmTMB-parity gate is #17.

## v0.1.0 (2026-05-31)

First tagged release: the `drm()` / `bf()` distributional-regression front end
with **8 response families**, the count `zi` / `hu` modifiers, the complete
Gaussian random-effect / structured / inference surface, and a published
DocumenterVitepress site. Formula syntax mirrors drmTMB exactly; families are
validated by simulation parameter recovery (numerical drmTMB-parity gate: #17).

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

### Gaussian surface — completed (2026-05-31)

Completing the Gaussian distributional-regression surface, all recovery-tested,
each shipped as one PR with green CI:

- **Random effects on the mean** — independent slopes `(0 + x | g)`, correlated
  intercept+slope `(1 + x | g)` (`vc`), and multiple crossed / nested terms
  `(1 | g) + (1 | h)` (whitened-Woodbury capacitance).
- **Random effects on the scale** — `sigma ~ … + (1 | g)`, integrated out by
  per-group Gauss–Hermite quadrature (#40).
- **Structured effects on the mean** — `relmat(1|id, K)`, `animal(1|id, A)`,
  `phylo(1|species, tree)`, `spatial(1|site, coords)` — closed-form GLS.
- **Parametric bootstrap** (`bootstrap_ci`) and **profile-likelihood** intervals
  (`confint(fit; method = :profile)`, #38), alongside Wald.
- **Post-fit** — `predict` (new data) and `simulate`.

### Phase 2 — response families (2026-05-31)

Eight families behind the same `bf()` grammar, each with its own per-parameter
formulas and a simulation recovery test:

- **Student-t** `Student()` — robust location–scale–shape (μ, σ, ν).
- **Poisson** `Poisson()` — counts (log-link mean).
- **NegBinomial2** `NegBinomial2()` — overdispersed counts (dispersion θ).
- **TruncatedNegBinomial2** `TruncatedNegBinomial2()` — positive counts (≥ 1).
- **Beta** `Beta()` — proportions in (0,1) (logit mean; precision φ = 1/σ²).
- **Gamma** `Gamma()` — positive continuous (shape α = 1/σ²).
- **LogNormal** `LogNormal()` — positive, multiplicative.
- **Count modifiers** — `zi` (zero-inflation: ZIP / ZINB) and `hu` (hurdle).

### Documentation — the makie-style site (2026-05-31)

- Adopted the **DocumenterVitepress** backend (the docs.makie.org look); Node is
  supplied by `NodeJS_jll`, so there is no system install and no extra CI step.
- **CairoMakie** figure gallery rendered from live fits, including the
  **Confidence Eye** (pale compatibility lens + outline + hollow estimate).
- Landing page, capability matrix, family guide, and tutorials filled with
  executed examples and honest status tags.

Planned next: the R↔Julia bridge (`engine = "julia"`), beta-binomial (needs a
trials column — drmTMB has no standalone binomial), the bespoke families
(Tweedie / cumulative_logit / zero-one-inflated beta), wiring `src/experimental/`,
and the RCall numerical drmTMB-parity gate (#17).

[parity anchor: drmTMB v0.1.3 (2026-05-20)]
