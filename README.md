# DRM.jl

[![Build Status](https://github.com/itchyshin/DRM.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/itchyshin/DRM.jl/actions/workflows/CI.yml)

Fast **distributional regression models** in Julia — the Julia twin of
the R package [drmTMB](https://github.com/itchyshin/drmTMB).

> **Current status (v0.1.1).** DRM.jl has a public `bf()` / `drm()` front end,
> all drmTMB response families, the Gaussian structured/random-effect surface,
> and expanding non-Gaussian GLMM support. See [ROADMAP.md](ROADMAP.md) for the
> active gaps and [HANDOVER.md](HANDOVER.md) for the verified q=4 engine.
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

## Quick look

```julia
using DRM
# Sparse phylogenetic precision foundation:
phy = random_balanced_tree(8; branch_length = 0.2)
Σ   = sigma_phy_dense(phy)                       # dense leaf covariance (small p)
# The q=4 PLSM engine (fit on a prepared AugProblem) is fit_q4_sparse_tmb;
# see bench/run_sparse_tmb_nd.jl for an end-to-end fit on the q4_p100 fixture.
```

Run the head-to-head and the O(p) scaling curve:

```bash
julia --project=. bench/run_sparse_tmb_nd.jl     # 2.18× vs drmTMB, p=100
julia --project=. bench/run_scaling.jl           # O(p) curve to p=10,000
```

## Repository layout (mirrors GLLVM.jl)

```
src/                verified q=4 engine; public bf()/drm() front end; Gaussian
                    and non-Gaussian families; inference, summary, visualization
src/experimental/   migrated but NOT yet wired: REML (reml_q4), location-only,
                    EM variants, mode-finder candidates, dense oracle
bench/              runnable benchmarks + q4/crossed-family fixtures + R compare scripts
test/               runtests.jl + recovery, grammar, inference, and engine tests
report/             13 design/provenance reports (the full poc record)
docs/               Documenter site (mirrors drmTMB navbar) + dev-log; CONTRACT.md
AGENTS.md ROADMAP.md   the 12-persona team + the phase plan
.claude/workflows/  10 scripted workflows (W0/Q/A/B/D/F/G/H/S/R)
```

## Status — honest (v0.1.1)

**Public `drm()` / `bf()` front end** — recovery-tested, drmTMB-mirroring syntax:

- **Gaussian** — location–scale, bivariate `rho12`, random effects on the mean
  (intercept / slope / correlated / crossed-nested) **and the scale**
  (`sigma ~ (1|g)`, Gauss–Hermite), structured effects (`relmat` / `animal` /
  `phylo` / `spatial`), `meta_V`; Wald + profile + bootstrap intervals;
  `predict` / `simulate`.
- **All drmTMB response families** — Gaussian, Student-t, LogNormal, Gamma,
  Tweedie, Poisson, NegBinomial2, TruncatedNegBinomial2, Beta, BetaBinomial,
  Binomial, ZeroOneBeta, and CumulativeLogit — plus the `zi` / `hu` count
  modifiers.
- **Non-Gaussian GLMMs** — single-factor mean random intercepts/slopes on the
  main families, plus crossed/nested scalar random-intercept sparse-Laplace
  paths for Poisson, Binomial, NB2, Gamma, and Beta.
- **Docs** — a DocumenterVitepress site (the docs.makie.org look) with CairoMakie
  figures (incl. the Confidence Eye), executed examples, honest per-page tags.

Families are validated by **simulation parameter recovery**; the numerical
drmTMB-parity gate (RCall vs. drmTMB v0.1.3 outputs) is tracked in
[#17](https://github.com/itchyshin/DRM.jl/issues/17).

**Verified engine (foundation):** the q=4 ML location-scale single fit — 2.18×
over drmTMB, O(p) to p=10,000, valid CIs where drmTMB's Hessian is singular.

**Still open:** R numerical parity fixtures (#17), structured/correlated
non-Gaussian RE expansion (#80), selected `src/experimental/` estimators
(`#11`-`#13`), the bivariate-phylo q=4 public front end, and the R↔Julia bridge
(`#5` / `#19`). See [ROADMAP.md](ROADMAP.md).

## License

MIT © 2026 Shinichi Nakagawa. A sister package to drmTMB and GLLVM.jl.
