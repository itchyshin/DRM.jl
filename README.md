# DRM.jl

[![Build Status](https://github.com/itchyshin/DRM.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/itchyshin/DRM.jl/actions/workflows/CI.yml)

Fast **distributional regression models** in Julia — the Julia twin of
the R package [drmTMB](https://github.com/itchyshin/drmTMB).

> **Scaffold / pilot (v0.1.0-DEV).** This repo migrates a *verified proof-of-
> concept* engine; the public API and module layout will change before v0.1.0.
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
src/                core engine (verified): sparse_phy, takahashi_selinv,
                    sparse_aug_plsm (robust mode-finder), sparse_em_fit,
                    fit_ml_q4, fit_q4_sparse_tmb; DRM.jl module
src/experimental/   migrated but NOT yet wired: REML (reml_q4), inference
                    (infer_q4), location-only (location_only), EM variants,
                    mode-finder candidates, dense oracle
bench/              runnable benchmarks + the q4_p100 fixtures + R fixture gen
test/               runtests.jl + migrated correctness checks (need path fixes)
report/             13 design/provenance reports (the full poc record)
docs/               Documenter site (mirrors drmTMB navbar) + dev-log; CONTRACT.md
AGENTS.md ROADMAP.md   the 12-persona team + the phase plan
.claude/workflows/  10 scripted workflows (W0/Q/A/B/D/F/G/H/S/R)
```

## Status — honest

- **Solid (verified):** the q=4 ML location-scale single fit (2.18× over drmTMB),
  O(p) scaling to p=10,000, the conjugate location-only cell (EM 3.1× over LBFGS),
  Wald + bootstrap inference.
- **Experimental / needs review:** REML (mean-axis bias-correction verified;
  scale-axis + exact gradient open), threaded-bootstrap timing, χ̄² boundary
  inference, and **wiring `src/experimental/` into a clean public API** — the
  v0.1 work. See [HANDOVER.md](HANDOVER.md).

## License

MIT © 2026 Shinichi Nakagawa. A sister package to drmTMB and GLLVM.jl.
