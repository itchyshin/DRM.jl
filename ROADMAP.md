# ROADMAP.md — DRM.jl

> The phase plan. Each phase is a **GitHub Milestone**; each slice is an
> **Issue**. This file is the human-readable overview — the live status is on
> the [Milestones page](https://github.com/itchyshin/DRM.jl/milestones).
> Owner: **Ada**. Source of truth for the engine: [`HANDOVER.md`](HANDOVER.md).

## Where we are

**Phase 2 (families) effectively complete; Phase 3 (articles) nearly complete.**
Phase 0 (team/workflows/ledger/docs shell) is done; the `bf()` / `drm()` front
end ships with drmTMB-exact grammar (Phase 1.1, Workflow B); inference graduated
from `experimental/` into `src/inference.jl` (`infer_q4` wired — Wald + profile +
bootstrap); and **all 13 families** (12 univariate + bivariate Gaussian) are
implemented, exported, and recovery-tested. **v0.1.0 and v0.1.1 are tagged.**
Many Phase 3 articles are filled (formula-grammar, adding-families,
testing-likelihoods, source-map, large-data, convergence, structural-dependence,
Rosetta). The variational-approximation track is newly opened (issue #136).
**Still open:** the numerical RCall.jl drmTMB-parity gate (#17, Workflow G), the
remaining `experimental/` wiring (`reml_q4` / `location_only` / `fit_em_natgrad`),
and the Phase 1.5 R-side bridge. **The verified q=4 PLSM engine (2.18× over
drmTMB, O(p) to p=10,000) stays exactly as handed over.**

## Target

A faithful **twin** of [drmTMB](https://itchyshin.github.io/drmTMB/) —
the same `bf()` formula surface, the same families, the same articles — running
on a Julia engine that wins on speed, with an R↔Julia bridge so biologists can
call DRM.jl from R via `engine = "julia"`. Parity anchor: **drmTMB v0.1.3**.

---

## Phases

### Phase 0 — Team & workflows  ·  *milestone: `Phase 0 — Team & workflows`*  ·  ✅ complete

- 12-persona `AGENTS.md`, project `CLAUDE.md`, this file.
- 10 scripted workflows in `.claude/workflows/` (W0/Q/A/B/D/F/G/H/S/R).
- 12 `.codex/agents/*.toml`.
- GitHub ledger: labels, 8 milestones, ~18 near-term issues.
- `docs/dev-log/` (check-log, coordination-board, after-task, decisions,
  recovery-checkpoints, scout) + `tools/drm-checkpoint.jl`.
- Documenter shell: navbar = drmTMB's, 36 status-tagged stub pages.
- Project meta: `bench/Project.toml`, `test/Project.toml`, `NEWS.md`,
  `CITATION.cff`, `.JuliaFormatter.toml`, `Documenter.yml`, `TagBot.yml`.
- **Gate:** engine still loads + `bench/run_sparse_tmb_nd.jl` still logLik
  −256.51; docs build locally; ledger live; Rose scope pass.

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

### Phase 1.5 — R-side bridge ships  ·  *milestone: `Phase 1.5`*

- Lovelace: `drmTMB(formula, ..., engine = "julia")` lands in the R package,
  calls DRM.jl via JuliaCall, returns a drmTMB-shaped result. The bridge glue
  lives in the drmTMB (R) repo. Hopper's parity gate guards equivalence.

### Phase 2 — Family expansion  ·  *milestone: `Phase 2`*  ·  ✅ effectively complete

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

### v0.1.0  ·  *milestone: `v0.1.0`*

Gaussian univariate + bivariate (q=4 PLSM headline) + inference + docs published
+ R-bridge functional. Then register in the Julia General registry.

### v1.0  ·  *milestone: `v1.0`*

Full twin — every drmTMB capability matched, with the speed edge
documented per family.

---

## Open research items (tracked as `idea` issues)

- REML scale-axis + exact REML gradient (ML stays default).
- χ̄² boundary inference (Self–Liang 1987; Stram–Lee 1994).
- drmTMB head-to-head at nrep=4 / p>100 to replace the *extrapolated* scaling
  comparison with a measured one.
- Creative combinations from Pólya's scout (Workflow S).
