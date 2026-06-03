# ROADMAP.md — DRM.jl

> The phase plan. Each phase is a **GitHub Milestone**; each slice is an
> **Issue**. This file is the human-readable overview; the live work ledger is
> the [Issues page](https://github.com/itchyshin/DRM.jl/issues) and the
> current capability matrix is
> [`docs/src/model-guides/model-map.md`](docs/src/model-guides/model-map.md).
> Owner: **Ada**. Source of truth for the q=4 engine:
> [`HANDOVER.md`](HANDOVER.md).

## Where we are

**Current state (2026-06-02): v0.1.1 + active #80/#136 engine expansion.**

DRM.jl now has a public `bf()` / `drm()` front end, all drmTMB response families
implemented and recovery-tested, non-Gaussian random effects on the main mean
paths, and a sparse-Laplace crossed-intercept engine for non-Gaussian GLMMs.
Recent work also landed formula-grammar rejection parity, Rosetta docs, faster
profile paths, crossed-Laplace profile CIs for random-effect SDs, and fit-based
bootstrap entry points.

The stale Phase-0/Phase-1 wording is intentionally retired here. Remaining work
is no longer "add non-Gaussian families"; it is **finish the parity and engine
hardening around the implemented surface**.

## Target

A faithful **twin** of [drmTMB](https://itchyshin.github.io/drmTMB/) — the same
`bf()` formula surface, the same families, the same articles — running on a
Julia engine that wins on speed, with an R↔Julia bridge so biologists can call
DRM.jl from R via `engine = "julia"`. Parity anchor: **drmTMB v0.1.3**.

---

## Completed Milestones

### Phase 0 — Team & Workflows

Complete. The 12-persona `AGENTS.md`, `CLAUDE.md`, this roadmap, workflow
scripts, dev-log, Documenter shell, CI, issue labels/milestones, and release
scaffold are in place.

### Public Front End + Gaussian Surface

Complete for the documented stable surface. Implemented:

- univariate Gaussian location-scale models;
- bivariate Gaussian location-scale models with residual `rho12`;
- Gaussian mean random effects: intercepts, independent slopes, correlated
  `(1 + x | g)`, and crossed/nested intercepts;
- Gaussian scale random effects;
- Gaussian structured effects: `relmat`, `animal`, `phylo`, `spatial`;
- `meta_V`;
- Wald/profile/bootstrap inference, `predict`, `simulate`, `summary`,
  `coeftable`, information criteria, plotting-data helpers, and auditable
  bootstrap result metadata.

The q=4 phylogenetic bivariate location-scale engine remains a **verified
engine** path: 2.18x over drmTMB on the p=100 single fit, near-linear O(p) to
p=10,000, and usable boundary-aware inference. Its friendly public tree front
end is still a separate follow-up.

### Phase 2 — Family Expansion

Complete as of v0.1.1. All drmTMB response families are implemented and
recovery-tested:

- Gaussian, Student-t, LogNormal, Gamma, Tweedie;
- Poisson, NegBinomial2, TruncatedNegBinomial2;
- Beta, BetaBinomial, ZeroOneBeta;
- Binomial;
- CumulativeLogit;
- `zi` and `hu` count modifiers.

The numerical R-parity fixture gate remains open as #17; family implementation
and recovery testing are complete.

### Non-Gaussian Random-Effect Expansion

Implemented:

- single-factor random intercepts and correlated random slopes on the mean for
  Poisson, NB2, Beta, Gamma, Student-t, LogNormal, and Beta-binomial;
- Binomial fixed effects plus random-intercept logistic GLMM;
- crossed/nested scalar random intercepts via sparse Laplace for Poisson,
  Binomial, NB2, Gamma, and Beta;
- exact/fused crossed-Laplace derivative paths and profile CIs for crossed
  random-effect SD rows.

Measured paired drmTMB benchmarks currently support the public speed claim for
successful Poisson/NB2 crossed cells; Binomial/Gamma/Beta crossed rows are
reported as Julia engine proofs because the local drmTMB target rejects those
fixtures.

---

## Active Work

### #80 — Crossed / Structured Non-Gaussian RE Laplace

Current engine frontier. Completed slices include Poisson crossed intercepts,
family nuisance fits, exact nuisance gradients, fused derivatives, and profile
CIs for crossed RE SDs.

Remaining:

- structured non-Gaussian mean effects: `relmat`, `phylo`, `spatial`, `animal`;
- crossed correlated slopes and more general random-effect design blocks;
- wider K-component public routing where the generic path is not yet enough;
- faster profile CI path for larger crossed sparse-Laplace fits;
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
