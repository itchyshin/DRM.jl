# ROADMAP.md — DRM.jl

> The phase plan. Each phase is a **GitHub Milestone**; each slice is an
> **Issue**. This file is the human-readable overview; the live work ledger is
> the [Issues page](https://github.com/itchyshin/DRM.jl/issues) and the
> current capability matrix is
> [`docs/src/model-guides/model-map.md`](docs/src/model-guides/model-map.md).
> Owner: **Ada**. Source of truth for the q=4 engine:
> [`HANDOVER.md`](HANDOVER.md).

## Where we are

**Current state (2026-06-03): v0.1.1 + active #80/#136 engine expansion.**

Phase 0 (team/workflows/ledger/docs shell) is done; the `bf()` / `drm()` front
end ships with drmTMB-exact grammar (Phase 1.1, Workflow B); inference graduated
from `experimental/` into `src/inference.jl` (`infer_q4` wired — Wald + profile +
bootstrap); and **all 13 families** (12 univariate + bivariate Gaussian) are
implemented, exported, and recovery-tested. **v0.1.0 and v0.1.1 are tagged.**
Many Phase 3 articles are filled (formula-grammar, adding-families,
testing-likelihoods, source-map, large-data, convergence, structural-dependence,
Rosetta). The variational-approximation track is newly opened (issue #136), and
#80 now has measured crossed-family and NB2/Gamma/beta phylo speedup slices.
**Still open:** the numerical RCall.jl drmTMB-parity gate (#17, Workflow G), the
remaining `experimental/` wiring (`reml_q4` / `location_only` / `fit_em_natgrad`),
the remaining #80 structured/correlated guardrails, and the Phase 1.5 R-side
bridge. **The verified q=4 PLSM engine (2.18x over drmTMB, O(p) to p=10,000)
stays exactly as handed over.**

## Target

A faithful **twin** of [drmTMB](https://itchyshin.github.io/drmTMB/) — the same
`bf()` formula surface, the same families, the same articles — running on a
Julia engine that wins on speed, with an R↔Julia bridge so biologists can call
DRM.jl from R via `engine = "julia"`. Parity anchor: **drmTMB v0.1.3**.

---

## Completed Milestones

### Phase 0 — Team & workflows  ·  *milestone: `Phase 0 — Team & workflows`*  ·  ✅ complete

Complete. The 12-persona `AGENTS.md`, `CLAUDE.md`, this roadmap, workflow
scripts, dev-log, Documenter shell, CI, issue labels/milestones, and release
scaffold are in place.

### Phase 1.0 — Hygiene + wire `experimental/`  ·  *milestone: `Phase 1.0`*  ·  partial

- Workflow A: wire `infer_q4`, `reml_q4`, `location_only`, `fit_em_natgrad` into
  the public API; fix the orphan tests. — ✅ `infer_q4` graduated into
  `src/inference.jl` (Wald + profile + bootstrap, #106); `reml_q4` /
  `location_only` / `fit_em_natgrad` **still in `experimental/`, not wired**.
- Workflow D ×N: fill the "Get Started" + easy stubs (first-fit,
  what-can-I-fit-today, working-with-large-data — the verified engine supports
  them today). — ✅ large-data / convergence guides filled.
- Workflow Q: complete FD + Allocs gates, the multi-shape sweep.
- `docs/Manifest.toml` + `bench/Manifest.toml` pinned (root Manifest stays
  uncommitted — DRM.jl is a library).
- Workflow R: first real estimator-optimisation run on the verified bench.

### Phase 1.1 — `bf()` front end + inference + R-parity live  ·  *milestone: `Phase 1.1`*  ·  mostly complete

- Workflow B: `bf(mu, sigma, rho12)` + structured markers — drmTMB-exact,
  including the reserved-syntax rejections. Resolves the **public-verb** and
  **tree-I/O** design issues. — ✅ `bf()` shipped, including bivariate
  keyword-form grammar (#115) and reserved-syntax rejections (#109).
- Workflow G: RCall.jl parity gate (`DRM_PARITY_TESTS=1`) against vendored
  drmTMB v0.1.3 outputs in `test/parity/fixtures/`. — open (numerical gate #17).
- Fisher: thread the bootstrap and *measure* the speedup (currently unrun).
  — ✅ bootstrap entry points + threaded timing fixture (#131/#132).
- Pat / Florence: first application articles (location–scale, bivariate
  `rho12`) + the R↔Julia Rosetta page. — ✅ Rosetta phrasebook filled (#112).

### Phase 2 — Family expansion  ·  *milestone: `Phase 2`*  ·  ✅ effectively complete

Complete as of v0.1.1. All drmTMB response families are implemented and
recovery-tested:

- Workflow H ×8: Student / lognormal / Gamma / Tweedie / beta / Poisson /
  nbinom2 / cumulative_logit, with `zi` / `hu` modifiers where applicable.
  — ✅ all 13 families implemented + exported + recovery-tested (full set:
  Gaussian, Student-t, LogNormal, Gamma, Tweedie, Beta, zero-one-inflated beta,
  beta-binomial, Binomial, Poisson, NegBinomial2, truncated-NB2,
  cumulative-logit, + bivariate Gaussian); see `NEWS.md` v0.1.0 / v0.1.1. The
  numerical drmTMB-parity gate (#17) is still open.

### Phase 3 — Articles to mirror drmTMB  ·  *milestone: `Phase 3`*  ·  nearly complete

- Workflow D: fill the remaining Tutorials, Diagnostics & Validation, and
  Developer Notes articles. Target = drmTMB's 26 articles. — many filled
  (formula-grammar, adding-families, testing-likelihoods, source-map,
  large-data, convergence, structural-dependence, Rosetta); remainder in flight.

### #80 — Non-Gaussian Random-Effect Expansion  ·  partial

- single-factor random intercepts and correlated random slopes on the mean for
  Poisson, NB2, Beta, Gamma, Student-t, LogNormal, and Beta-binomial;
- Binomial fixed effects plus random-intercept logistic GLMM;
- crossed/nested scalar random intercepts via sparse Laplace for Poisson,
  Binomial, NB2, Gamma, and Beta;
- exact/fused crossed-Laplace derivative paths and profile CIs for crossed
  random-effect SD rows;
- public non-Gaussian `phylo(1 | species)` formula routing for NB2, Gamma, beta,
  and Julia-only Binomial when `tree = ...` is supplied.

Measured paired drmTMB benchmarks now support public speed claims for successful
crossed-family and NB2/Gamma/beta phylo cells. Current local reports:

- crossed successful paired cells: median 43.24x; medium Gamma 30.71x; medium
  beta 71.48x;
- phylo successful paired cells: median 71.49x; medium NB2 82.51x; medium
  Gamma 18.46x; medium beta 65.58x.

---

## Active Work

### #80 — Crossed / Structured Non-Gaussian RE Laplace

Current engine frontier. Completed slices include Poisson crossed intercepts,
family nuisance fits, exact nuisance gradients, fused derivatives, and profile
CIs for crossed RE SDs.

Remaining / explicitly not claimed:

- beta-binomial phylo in Julia; this needs a beta-binomial derivative kernel;
- nonconstant `sigma` with non-Gaussian phylo;
- non-Gaussian `relmat`, `spatial`, and `animal` public routes;
- crossed correlated slopes and more general random-effect design blocks;
- wider K-component public routing where the generic path is not yet enough;
- additional paired drmTMB/glmmTMB parity fixtures where the R side supports the
  same model.

### #136 — Variational / ELBO Marginal Route

Early scaffold and design work are in flight. This lane is planned as an
alternative marginal method where Laplace approximation error matters, with
deterministic anchors required before any capability is promoted.

### #17 — R-Parity Gate

Wire `DRM_PARITY_TESTS=1` against generated drmTMB v0.1.3 outputs. Generated
outputs only; never vendor drmTMB GPL source.

### #14-#16 — Engine Quality Gates

Promote the PoC checks into standing gates:

- finite-difference vs exact gradient <= 1e-6;
- Allocs.jl / allocation discipline for inner mode-finder loops;
- balanced + caterpillar scaling sweep over p in {100, 1k, 10k}.

### #11-#13 — Experimental Estimators

Promote selected `src/experimental/` engines into clean public or internal APIs:

- `reml_q4.jl` (ML remains default);
- `location_only.jl` (conjugate EM);
- `fit_em_natgrad.jl` and related EM variants.

### #5 / #19 — R Bridge + Object Marshalling

The R-side bridge lives in the drmTMB repo. DRM.jl still needs the bridge design
and object marshalling decisions for trees, pedigrees, known matrices, and
result-shape parity.

### #49 — Missing Data

Future drmTMB-parity missing-data work should start from likelihood-based FIML
or EM handling, not row dropping.

### #7 — Article Completion

Several articles are filled, but remaining Phase-0 stubs should continue to be
replaced with source-backed pages. Open docs PRs are part of this cleanup.

---

## Release Targets

### Next Patch Release

- Merge or rebase the remaining docs PRs.
- Close stale roadmap trackers whose scope is already complete.
- Keep README, ROADMAP, model-map, and check-log aligned.

### v0.2

- R-parity fixture gate (#17) active for a representative cross-section of the
  implemented families.
- #80 narrowed to genuinely missing structured/correlated non-Gaussian RE
  support.
- q=4 public front-end/tree I/O design settled or explicitly deferred.

### v1.0

Full twin: every drmTMB capability matched, R bridge usable, and the speed edge
documented per family with measured parity where both engines support the same
model.

---

## Open Research Items

- REML scale-axis + exact REML gradient (ML stays default).
- χ̄² boundary inference (Self–Liang 1987; Stram–Lee 1994).
- drmTMB head-to-head at nrep=4 / p>100 to replace the *extrapolated* scaling
  comparison with a measured one.
- Creative combinations from Pólya's scout (Workflow S).
