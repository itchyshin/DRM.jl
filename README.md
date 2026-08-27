# DRM.jl

[![Build Status](https://github.com/itchyshin/DRM.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/itchyshin/DRM.jl/actions/workflows/CI.yml)

Fast **distributional regression models** in Julia — the Julia twin of
the R package [drmTMB](https://github.com/itchyshin/drmTMB).

> **Early v0.1.0 release.** This repo migrates a *verified proof-of-concept*
> engine; the public API and module layout are still expected to evolve across
> the 0.x series, with breaking changes requiring a minor-version bump.
> See [HANDOVER.md](HANDOVER.md) (verified engine), [ROADMAP.md](ROADMAP.md)
> (phases), and [AGENTS.md](AGENTS.md) (the team) for what is solid vs. planned.
> The [Documenter site](https://itchyshin.github.io/DRM.jl/) mirrors drmTMB's
> navbar, with every page status-tagged.

## Why

drmTMB fits univariate and bivariate **distributional** regressions — each
distributional parameter (mean μ, scale σ, correlation ρ) gets its own formula —
including the **q=4 phylogenetic bivariate location–scale model (PLSM)**, where a
shared phylogenetic random effect acts on `(μ1, μ2, log σ1, log σ2)`. Because the
scale depends nonlinearly on a random effect, there is no closed-form marginal:
it needs a **Laplace approximation**. brms/Stan needs ~122 h on this model;
drmTMB (R/TMB) fits it in ~2.5 s at p=100 species.

`DRM.jl` is a Julia engine for that model class, built on a **sparse
augmented-state precision** (`kron(Q_topology, Λ⁻¹)`, O(p) non-zeros) with an
**exact O(p) marginal gradient** (implicit-function / TMB-style, via Takahashi
selected inversion — it never forms a dense p×p phylogenetic covariance) and a
fast-path-then-robust Laplace mode-finder.

## Verified results (proof-of-concept)

Same model, same real `q4_p100` data, same Laplace ML marginal as drmTMB
(reproduced in this repo's `bench/run_sparse_tmb_nd.jl`):

| | drmTMB | DRM.jl |
|---|---|---|
| single fit (p=100) | 2.48 s, false-conv | **1.14 s, converged → 2.18× faster** |
| logLik | −256.52 | −256.51 (matches) |
| O(p) scaling to p=10,000 | infeasible (dense) | **~113 s, k≈1.08 (near-linear)** |
| Wald SEs at the variance boundary | all-NaN (non-PD Hessian) | **valid for 16/17 params** |

Full grid and honest caveats: [report/comparison-grid.md](report/comparison-grid.md).

## Install (development)

```julia
using Pkg
Pkg.develop(path = "/path/to/DRM.jl")
Pkg.instantiate()              # resolve deps the first time
using DRM
```

## Worked example — a Gaussian location–scale regression

The smallest real **distributional** regression: both the mean **and** the
(log) scale depend on a covariate. This runs as-is (verified).

```julia
using DRM, Random
Random.seed!(1)

n = 400
x = randn(n)
# data-generating process: μ = 0.5 − 0.8·x,  log σ = −0.3 + 0.4·x
y = (0.5 .- 0.8 .* x) .+ exp.(-0.3 .+ 0.4 .* x) .* randn(n)

fit = drm(bf(@formula(y ~ 1 + x),        # mean μ
             @formula(sigma ~ 1 + x)),     # log scale σ
          Gaussian(); data = (; y, x))

coef(fit, :mu)      # ≈ [ 0.50, -0.80]
coef(fit, :sigma)   # ≈ [-0.32,  0.40]
coeftable(fit)      # Wald SEs, z, p, 95% CIs for every coefficient
```

```
─────────────────────────────────────────────────────────────────────────
                    Estimate  Std.Error        z  Pr(>|z|)  Lower 95%  Upper 95%
─────────────────────────────────────────────────────────────────────────
mu: (Intercept)     0.50299  0.0398921   12.609    <1e-35   0.424799   0.581173
mu: x              -0.79985  0.0292344  -27.360    <1e-99  -0.857148  -0.742551
sigma: (Intercept) -0.32217  0.0353752   -9.107    <1e-19  -0.391506  -0.252838
sigma: x            0.39537  0.0335957   11.768    <1e-31   0.329524   0.461217
─────────────────────────────────────────────────────────────────────────
```

The same `bf(...)` grammar carries the full audited surface — 13 families, random
effects on the mean **and** scale, structured (`relmat` / `animal` / `phylo` /
`spatial`) effects, `meta_V` meta-analysis, the bivariate `rho12` model, and the
q=4 phylogenetic location–scale (PLSM) route — see
[Capabilities](docs/src/capabilities.md) for the precise, test-cited matrix.

Run the head-to-head and the O(p) scaling curve:

```bash
julia --project=. bench/run_sparse_tmb_nd.jl     # 2.18× vs drmTMB, p=100
julia --project=. bench/run_scaling.jl           # O(p) curve to p=10,000
```

## Repository layout (mirrors GLLVM.jl)

```
src/                core engine (verified): sparse_phy, takahashi_selinv,
                    sparse_aug_plsm (robust mode-finder), sparse_em_fit,
                    fit_ml_q4, fit_q4_sparse_tmb; DRM.jl module
src/experimental/   leftover prototypes NOT wired into the public API
                    (SQUAREM / natgrad EM [\#13 FAIL — parked], E-step variants,
                    dense oracle, leftover location_only copy). Public surfaces
                    in src/: method=:REML, algorithm=:em, lc_metric (Fisher infra).
bench/              runnable benchmarks + the q4_p100 fixtures + R fixture gen
test/               runtests.jl + migrated correctness checks
report/             13 design/provenance reports (the full poc record)
docs/               Documenter site (mirrors drmTMB navbar) + dev-log; CONTRACT.md
AGENTS.md ROADMAP.md   the 12-persona team + the phase plan
.claude/workflows/  10 scripted workflows (W0/Q/A/B/D/F/G/H/S/R)
```

## Status — honest (v0.1.x)

Tree version and git tag are **`0.1.2` / `v0.1.2`**. Older tags `v0.1.0` /
`v0.1.1` remain historical. **Julia General stays out** until readiness
(catch up with drmTMB + both working well; drmTMB likely R/CRAN first —
brain **D-111**). MIT via GitHub / `Pkg.develop` until then. Do not treat
`v0.1.2` as General registration; do not chase Registrator.

**Next:** Phase 1.5 / [#5](https://github.com/itchyshin/DRM.jl/issues/5) is
**closed** (#349 + drmTMB #878). Tip hygiene / deeper parity remain — **not**
General registration. S2/S3 hygiene already landed (#340–#342).

**Public `drm()` / `bf()` front end** — recovery-tested, drmTMB-mirroring syntax:

- **Gaussian** — location–scale, bivariate `rho12`, random effects on the mean
  (intercept / slope / correlated / crossed-nested) **and the scale**
  (`sigma ~ (1|g)`, Gauss–Hermite), structured effects (`relmat` / `animal` /
  `phylo` / `spatial`), `meta_V`, and the bivariate q=4 phylogenetic
  location-scale route with `Σ_a` stored on the fit; Wald + profile + bootstrap
  intervals; `predict` / `simulate`.
- **13 families** — Gaussian, Student-t, Poisson, NegBinomial2,
  TruncatedNegBinomial2, Beta, BetaBinomial, Binomial, Gamma, LogNormal,
  ZeroOneBeta, Tweedie, and CumulativeLogit — plus `zi` / `hu` count modifiers
  and beta boundary modifiers `zoi` / `coi`.
- **Docs** — a DocumenterVitepress site (the docs.makie.org look) with CairoMakie
  figures (incl. the Confidence Eye), executed examples, honest per-page tags.

Families are validated by **simulation parameter recovery**; the numerical
drmTMB-parity gate (RCall vs. drmTMB v0.1.3 outputs) lives under opt-in
`DRM_PARITY_TESTS=1` ([#17](https://github.com/itchyshin/DRM.jl/issues/17)
closed).

**Verified engine (foundation):** the q=4 ML location-scale single fit — 2.18×
over drmTMB, O(p) to p=10,000, valid CIs where drmTMB's Hessian is singular.
Per-family engine-vs-engine timings, with their caveats stated, are
consolidated in [report/speed-per-family.md](report/speed-per-family.md); the
R↔Julia capability ledger itself lives in drmTMB's generated
`inst/extdata/julia-capabilities.tsv`, where rows are promoted only on
measured evidence.

**Inference:** Wald + profile + parametric bootstrap; opt-in **REML**
(`method = :REML`, with the model-selection guard) across the fixed-effect
Gaussian location–scale fit, a single Gaussian mean intercept `(1|g)` (#439),
the σ-phylo route, the bivariate q=4 all-axes route (`reml_q4.jl`, #11), and
the bivariate q=2 structured route (`reml_q2.jl`, #470); epsilon-method bias
correction; `heritability` /
`repeatability` / `icc` with delta + profile CIs. Julia-side R↔Julia helpers
(`drm_bridge` / `drm_bridge_inference`) are in-tree; **Phase 1.5 /
[#5](https://github.com/itchyshin/DRM.jl/issues/5)** is **closed** at the
experimental Hopper finish-matrix bar (#349 + drmTMB #878) — not a CRAN /
“supported” promotion.

**Not fully wired / still open:** `src/experimental/` holds only classified
material — recorded negative results (#13, #472), superseded predecessors, and
oracles; see [src/experimental/README.md](src/experimental/README.md) for the
per-file verdicts (public `method = :REML`, `algorithm = :em`, and `lc_metric`
Fisher infra are already in `src/`);
**χ̄² boundary inference** where not yet exported; the **variational (VA/ELBO)**
marginal track (#136, deferred). See
[Capabilities](docs/src/capabilities.md),
[capability-status](docs/design/capability-status.md),
[HANDOVER.md](HANDOVER.md), and [ROADMAP.md](ROADMAP.md) for the
test-cited breakdown — prefer those over any shorter summary here.

## License

MIT © 2026 Shinichi Nakagawa. A sister package to drmTMB and GLLVM.jl.
