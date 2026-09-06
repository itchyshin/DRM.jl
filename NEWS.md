# DRM.jl — NEWS

All notable changes are recorded here. The live work ledger is
[GitHub Issues](https://github.com/itchyshin/DRM.jl/issues); this file is the
human-readable changelog and mirrors `docs/src/changelog.md`.

## Unreleased

- **`drm_bridge` admits `skew_normal`** — `_bridge_family` now maps drmTMB's
  `skew_normal()` (tags `skew_normal` / `skewnormal`) to the native `SkewNormal()`
  family. The family was already implemented (`src/skewnormal.jl`) but the R
  bridge had no case for it, so drmTMB's `engine = "julia"` could not admit it.
  Both packages use the same public moment parameterisation (`mu` = mean,
  `sigma` = SD, `nu` = Azzalini slant), so the bridged coefficients are the
  native ones. Fixed effects only, ML only — exactly what `SkewNormal()` fits.
- **REML on the residual-only bivariate Gaussian route (#624; drmTMB #1142).** `drm(bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~1), Gaussian(); method = :REML)` fits instead of refusing. The old message ("`method = :REML` needs random effects to restrict") mistook "no random effects" for "nothing to restrict": REML here integrates the MEAN fixed effects `beta_mu1`/`beta_mu2` out of the Gaussian likelihood under the row-wise 2x2 residual covariance — the classical Patterson–Thompson/SUR case, and the same set native drmTMB hands to TMB's Laplace approximation for this cell (whose Laplace step is EXACT, the integrand being quadratic). Closed form: profile `beta` by GLS, add `-0.5*logdet(sum_i Z_i' S_i^-1 Z_i)` and the `+(p_beta/2)*log(2*pi)` normalising constant, and optimise over `(beta_sigma1, beta_sigma2, beta_rho)` alone. Same-target against drmTMB `engine = "tmb"` with `REML = TRUE` on the committed fixture: logLik `-97.021205818372` on both engines (difference 0.0 at 12 decimal places), coefficients to 4.33e-7, standard errors to 6.54e-7 relative. `vcov` reports the joint mean block `H^-1 + G Var(phi) G'` that TMB's `sdreport()` reports. The ML route is unchanged (same fixture, `-90.202703298791` on both engines, difference 4.8e-13). `meta_V` plus `:REML` keeps its permanent refusal — that route marginalises nothing. `test/test_reml_reml_biv_residual.jl`.
- **Inference on a missing-response ("response mask") Gaussian fit: `is_converged` read false on a
  converged fit, and every bootstrap replicate failed (#646).** Both defects sat downstream of the
  fit itself -- the point estimates were already right, matching drmTMB's `engine = "tmb"` to ~7e-06
  on the qualification fixture -- which is why nothing caught them until bridge-side inference was
  measured. (1) `_nondegenerate_fit` (`src/summary.jl`) took its scale-free degeneracy bar as
  `std(fit.obs[:mu])`, but the missing-response routes keep the full-design response there with NaN
  in the masked positions, so `yscale` was NaN and `smax > 1e-6 * max(NaN, eps)` was false for every
  `smax` under IEEE-754. `is_converged` therefore returned false on EVERY masked Gaussian fit,
  independent of the optimiser: measured on the fixture, `Optim.converged` true, `|grad|inf`
  6.41e-12 against `g_tol` 1e-8, and `theta` bit-identical to the complete-case fit (max abs diff
  0.0), yet `is_converged` false. The bar is now taken over the observed (finite) responses only;
  a genuinely degenerate sigma is still rejected. (2) `_simulate_once` (`src/gaussian_core.jl`)
  drew `randn(rng, fit.nobs)` -- the count that entered the likelihood, 54 on the fixture -- and
  broadcast it against the length-60 `means`/`scales` that `_with_full_fixed_gaussian_rows` rebuilds
  over the full design, throwing `DimensionMismatch` deterministically on every replicate, so
  `bootstrap_result` raised `"all B bootstrap replicates failed"`. Draws are now taken per row of
  the design, which is also the length `_bootstrap_data` needs to merge back into the caller's
  table. (3) Found while fixing those: `_with_full_fixed_gaussian_rows` and `_with_full_response_rows`
  used the 19-argument compatibility constructor, silently resetting `iterations` to -1
  ("not recorded") -- the identical complete-case fit reported 7 -- and dropping the MAP penalty
  slots; both now pass all 22 fields. Guarded by `test/test_bridge_response_mask_inference.jl`
  (21 assertions: converged status, a 5-replicate bootstrap on a masked response, the iteration
  count, and a degenerate-sigma control proving the widened bar still rejects).

- **Gaussian two-SD phylogenetic random slope `phylo(1 + x | species)` on the mean (#620).** The
  #621 refusal is replaced by the fit on the Gaussian mean route: two INDEPENDENT phylogenetic
  fields, `a ~ N(0, σₐ² C)` for the intercept and `b ~ N(0, σ_b² C)` for the slope on the same
  tree correlation `C`, no intercept–slope correlation. That is drmTMB's Gaussian model
  term for term (`src/drmTMB.cpp`, `model_type == 1`, `has_phylo_mu` with `q_phylo == 2`: both
  fields sit on `mu`, so `has_cross_dpar_phylo` is false and the else-branch adds one
  `exp(-2·log_sd_phylo(k))·uₖᵀQuₖ` term per field with no cross term). Fitted here as the
  closed-form dense marginal `V = D + σₐ² Z C Zᵀ + σ_b² Zₓ C Zₓᵀ`, which is that Laplace
  objective evaluated exactly. Reported as a two-row `:resd` block (`species`, `species:x`;
  `re_sd`/`vc`/`ranef` all carry both fields), five free parameters — the same five drmTMB
  optimizes. Measured same-target against drmTMB 67703f541 on the committed fixture: logLik,
  both SDs, β and log σ all agree to ≤ 6.7e-13 (`test/test_phylo_slope_two_sd.jl`).
  BOUNDARY (corrected 2026-09-05 after measurement): drmTMB fits `phylo(1 + x | g)` on Poisson
  and NegBinomial2 as well, and it fits the SAME independent two-SD model there — measured on
  drmTMB main, `corpars` is empty for the untagged `phylo(1 + x | g)` on Poisson (two SD rows,
  `phylo(1 | site)` and `phylo(0 + x | site)`), while the estimated intercept–slope correlation
  (`has_phylo_mu_q2_covariance`, reported in `corpars` as `cor(mu:(Intercept),mu:x | p | site)`)
  appears only for the DIFFERENT tagged formula `phylo(1 + x | p | g)`. drmTMB refuses the
  formula on Gamma ("intercept-only in this q=1 route"). DRM.jl still refuses every non-Gaussian
  family here, for the accurate reason: this route is the EXACT closed-form Gaussian marginal
  and does not extend to a non-Gaussian likelihood, so the count families need a two-field
  Laplace route that does not exist yet. The earlier claim that drmTMB fits "a DIFFERENT model"
  for Poisson/NegBinomial2 on this formula was wrong; the refusal it justified is unchanged. `phylo(0 + x | g)`, multi-slope
  forms, a second structured component, ordinary and `sigma`-side random effects, a structured
  (`phylo`) `sigma`, the `sd(...)`/`sd_phylo(...)` location-scale-scale submodels, REML, missing
  responses, the sparse algorithms and the parametric-bootstrap simulator all stay refused with
  a named error. Those refusals are raised next to `_split_ranef`, ABOVE every route that can
  return, so no engine written for the intercept-only cell can receive this formula and quietly
  fit `phylo(1 | g)` instead.

## v0.7.0 — 2026-08-28

**The twin-parity release.** Versioning now twin-tracks drmTMB (D-181, like GLLVM.jl↔gllvmTMB):
v0.7.0 means "at parity with drmTMB 0.7.0", pinned at drmTMB commit `a6de6bb71`; drmTMB's
fast-moving mi() missing-data axis is a named, fenced delta (D-180 #1) and the designated
post-0.7 headline. Registration in Julia General is planned at v0.7.1, mirroring the twin.

- **The API freeze** — every one of the 159 exports classified into Stable / Experimental /
  Engine tiers, machine-checked by `test/test_api_stability.jl` (total classification: a new
  export cannot appear untiered, a stable name cannot vanish silently). The promise and its
  honest Julia-0.x framing: `docs/src/api-stability.md`.
- **The comprehensive engine speed grid** (`report/engine-speed-grid.md`) — Julia wins 14 of 15
  comparable warm-fit cells (2.3×–42×); the one loss (q4 phylo REML, 0.46×) was diagnosed (the
  inner alternation burned 15 iterations per objective evaluation against a never-firing exit)
  and fixed to ~parity (0.94×, 2.1× faster).
- **The user-journey sweep** (`tools/user_journey_sweep.R`) — 29 models typed the way users type
  them, both engines: 25 matches at 1e-6..1e-11, refusal quality graded, and one real bug found
  and fixed (drmTMB#1099: `predict(newdata)` on factors/interactions failed on
  Julia-vs-R coefficient-name conventions).
- **The threaded bootstrap, demonstrated** — `confint(fit, parm, method = "bootstrap",
  threads = TRUE)` from R: 10× native TMB at R=199 on the same model and data
  (`docs/dev-log/evidence/2026-08-28-engine-julia-usability-demo.md`).
- Wave Q quality debt to zero: drmTMB#1090 (univariate `nu` tripping the bivariate bridge
  branch) fixed; #526 (q4 REML flag folds in the inner alternation, measured criterion);
  #527 hardening both repos; #482 and #8 closed.

## v0.2.0 — 2026-08-28

### The completion arc (2026-08-24 → 2026-08-27, D-179)

- **The R↔Julia capability ledger is COMPLETE** (drmTMB PRs #1085, #1087, and
  the Phase 2 promotions): every one of the 11 rows in drmTMB's generated
  `julia-capabilities.tsv` is now `covered` (9), an owner-signed permanent
  boundary (`cross_family_latent`, drmTMB #1089 — with a retraction: the route
  IS reachable from R), or unsupported by design (`engine_control_surface`).
  Every promotion is backed by SE-grade parity on a stamped comparator build.
  `covered` remains a capability claim, never interval coverage — the
  `coverage_claimed` fences are permanent documented boundaries by owner
  decision (D-179 #4).
- **`converged` answers a fixed question (#491, #517)** — the sparse-Laplace
  flag now tests the mean per-observation gradient against 1e-6 and no longer
  short-circuits on `Optim.converged`; a deliberately sloppy `g_tol` can no
  longer buy a green flag ("converged is not for sale" gate).
- **The large-p SE gap is fixed at source (#517)** — the outer vcov
  finite-difference step now grows with n (`clamp(2.5e-7·n, 1e-4, 1e-2)`);
  measured SE parity vs native TMB at p=1000 went 1.2e-03 → 4.0e-06 and at
  p=3000 9.0e-04 → 4.5e-06. Below n=400 nothing changes.
- **`response = "include"` fits the Gaussian phylo-mean cell (#517)** —
  measured byte-identical to `drop` on drmTMB's own route, so it is
  implemented as observed-rows + full tree (the σ-phylo convention); the
  wrapper deliberately does not extend to positional-matching routes.
- **q4 `converged` is gated on Λ admissibility (#509, #518)** — success is no
  longer claimed at a numerically singular Λ (the saturated-fixture regime);
  the smoke fixture is de-saturated and the saturated one kept as the
  negative control.
- **`mstep_Lambda`'s descent is a wired characterisation (#472, #519)** — the
  measured negative result now runs in the default suite as a tripwire, and
  `src/experimental/` carries per-file verdicts (#520).
- **Per-family speed table (#9, #521)** — `report/speed-per-family.md`
  consolidates every engine-vs-engine timing with its caveats; README swept to
  match the promoted ledger (its REML sentence was three routes stale).
- Earlier in the same arc: bivariate q=2 structured REML (#470,
  `reml_q2.jl`), per-coefficient `parm` for `confint` (#495, #514), comparator
  provenance stamping in all four parity harnesses (#473, #512), and the inner
  `newton_tol` tightening whose SE effect was measured, not assumed (#513).


- **VA Rung 2+3 (#136)** — scaffold anchors a/b/c in `test/test_variational.jl`
  are live (RE→0 ELBO = GLM loglik; ELBO ≤ adaptive GHQ; NB2 `r→∞` ≈ Poisson-VA).
  `aicc` on a VA fit errors even when `n − k − 1 ≤ 0` (no `Inf` short-circuit).
  Docs status is **Experimental** for Poisson + Binomial + NB2 + Gamma + Beta
  `(1 | g)`, not Planned-only. **Does not close #136.**

- **Public variational marginal Rung 1 (#136)** — Experimental
  `drm(...; marginal = :VA)` now covers Poisson **and** Binomial / NegBinomial2 /
  Gamma / Beta random intercept `(1 | g)` (scale families need `sigma ~ 1`),
  routing to the existing ELBO kernels. Default remains Laplace. `loglik` on a
  VA fit is an ELBO; mixed LA/VA AIC/LRT errors. Unsupported VA
  (phylo/crossed/corr/zi/hu/FE/`sigma ~ x`) rejects. `method = :VA` points at
  `marginal`. **Does not close #136.**

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
