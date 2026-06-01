# DRM.jl architecture

A self-contained design document for the Julia engine that mirrors
`drmTMB`. Audience: the human author and the Codex/Claude agents who
will implement it. Sources of truth:
`~/.claude/plans/this-we-are-working-wobbly-crescent.md`,
`drm-julia-poc/CONTRACT.md`, `drm-julia-poc/report/summary.md`,
`drm-julia-poc/julia/bf_sketch.jl`, and `gllvmTMB.jl/src/`.

## TL;DR

- **Mission.** Julia engine for the model class `drmTMB` serves: one
  or two responses, one formula per dpar (`mu`, `sigma`, `rho12`,
  `nu`, `zi`).
- **v0.1.x.** Closed-form Gaussian (univariate + bivariate), fixed
  effects plus Gaussian-marginal phylo / SharedRE paths.
  ForwardDiff + Optim LBFGS.
- **v0.3+.** TMB-like Laplace wrapper unlocks non-Gaussian families
  and RE on non-linear dpars (e.g. `sigma`). The only large new piece
  of infrastructure beyond v0.1.x.
- **Reuse.** Packing, profile-out, CIs (Wald / profile / bootstrap),
  EM/SQUAREM, sparse-phylogenetic precision: all ported from
  `gllvmTMB.jl`. New code: `bf()` parser, per-dpar design matrices,
  the two Gaussian likelihoods.
- **Syntax.** `bf()`, `phylo(1 | p | g)`, `meta_V(V = V)` (the older
  `meta_known_V()` is deprecated — kept only as a parity stub),
  `sigma`/`rho12`/`nu`/`zi` — verbatim from `drmTMB`. RE forms:
  lme4-style `(1 | g)`, brms-style `(1 | p | g)`, `phylo(... | tree = ...)`.
- **POC evidence.** Median speedup R/Julia 22.6× (max 83.8×) on the
  5-cell headline grid; `|ΔlogLik| < 4e-5` everywhere
  (`drm-julia-poc/report/summary.md`). Large-`p` phylo regresses
  because the POC uses a dense marginal Cholesky; production hooks
  GLLVM.jl's sparse-Q augmented-state representation.

## 1. Mission

DRM.jl is a Julia engine for the distributional-regression model class
that `drmTMB` serves. v0.1.x covers Gaussian univariate and bivariate
models with fixed effects plus the Gaussian-marginal RE structures
(IID, AR1, phylogenetic). v0.3+ adds a TMB-like Laplace wrapper that
unlocks the rest of the family list (Student-t with RE, Tweedie, Beta,
NB, ordinal, zero-inflated) and random effects on non-linear dpars
such as `sigma`. The scope stops at one or two responses; anything
higher-dimensional belongs to `gllvmTMB.jl`.

## 2. Module layout

```
DRM.jl/
├── Project.toml
├── LICENSE                       # MIT
├── COPYRIGHTS.md                 # provenance for code ported from gllvmTMB.jl
├── README.md
├── src/
│   ├── DRM.jl                    # top-level module: using, include()s, exports
│   ├── formula.jl                # bf() parser; ports bf_sketch.jl with full impls
│   ├── families.jl               # Gaussian, BivGaussian, StudentT, ZI, …; link objects
│   ├── design.jl                 # per-dpar X matrices from a DataFrame
│   ├── packing.jl                # flat θ pack/unpack; port of gllvmTMB packing.jl
│   ├── profile.jl                # profile-out sigma when no `sigma ~ x`; port
│   ├── likelihood_univ_gaussian.jl   # closed-form univariate Gaussian loglik
│   ├── likelihood_biv_gaussian.jl    # closed-form 2×2 bivariate Gaussian loglik
│   ├── likelihood_phylo.jl       # marginal phylo Gaussian (sparse Q path)
│   ├── sparse_phy.jl             # augmented-state sparse precision; verbatim port
│   ├── sparse_phy_grad.jl        # analytic gradient for sparse phylo block; port
│   ├── fit.jl                    # fit_drm(): Optim + ForwardDiff wrapper
│   ├── simulate.jl               # parametric simulation from a fitted model
│   ├── predict.jl                # response/link/component-scale predictions
│   ├── confint.jl                # Wald CIs; port
│   ├── confint_profile.jl        # profile-likelihood CIs; port
│   ├── confint_bootstrap.jl      # parametric bootstrap CIs; port
│   ├── confint_derived_wald.jl   # delta-method CIs for derived quantities; port
│   ├── laplace.jl                # v0.3+ Laplace wrapper (STUB in v0.1.x)
│   ├── em.jl                     # EM solver; port of em_fa.jl
│   └── em_squarem.jl             # SQUAREM acceleration; port
├── test/
│   ├── runtests.jl
│   ├── test_formula.jl
│   ├── test_likelihood_gaussian.jl
│   ├── test_likelihood_biv.jl
│   ├── test_phylo.jl
│   ├── test_ci.jl
│   └── test_vs_drmTMB.jl         # equivalence vs POC fixtures
└── bench/
    └── Project.toml
```

Layout mirrors `gllvmTMB.jl/src/` so ports stay line-recognisable.

## 3. Public API

| Category | Symbol | One-liner |
|---|---|---|
| Fitting | `fit_drm(f, data; family, control)` | Main entry. `f` is a `FormulaTerm` (univariate) or `DistributionalFormula` (from `bf()`). |
| Formula | `bf(args...; kwargs...)` | brms-style constructor; positional `:mu`, keyword dpars. |
| Family | `Gaussian()` | dpars `(:mu, :sigma)`, links `(identity, log)`. |
| Family | `BivGaussian()` | dpars `(:mu1, :mu2, :sigma1, :sigma2, :rho12)`, links `(identity, identity, log, log, atanh_guarded)`. |
| Family | `StudentT()` | v0.2+. Adds `:nu`, log link. |
| Family | `ZIPoisson()`, `Beta()`, `NB2()`, `Tweedie()` | v0.3+ Laplace path. |
| Structural | `phylo(rhs | label | group; tree)` | Phylogenetic RE block; marginal-Gaussian-friendly in v0.1.x. |
| Structural | `spatial(formula; mesh)` | v0.5+ SPDE block. |
| Structural | `animal(group; A)`, `relmat(group; A)` | Pedigree / arbitrary positive-definite block. |
| Structural | `meta_V(V = V)` | v0.2+ meta-analysis marker (`meta_known_V` deprecated). |
| Methods | `coef(fit[, :sigma])` | Coefficient vector or per-dpar dict. |
| Methods | `vcov(fit)`, `logLik(fit)`, `nobs(fit)`, `dof(fit)`, `AIC(fit)`, `BIC(fit)` | Standard fit summaries. |
| Methods | `confint(fit; method = :wald)` | `:wald`, `:profile`, `:bootstrap`. |
| Methods | `predict(fit, newdata; type)` | `:response`, `:link`, `:component`. |
| Methods | `simulate(fit; n, rng)` | Parametric draws — used by bootstrap and tests. |
| Diagnostics | `converged(fit)`, `identifiability(fit)` | Convergence + rank/condition reports. |
| Helpers | `block_specs(df)` | Returns `Vector{CovBlockSpec}` for `bf()` output. |

## 4. Parameter packing

The flat parameter vector for v0.1.x has three contiguous segments:

```
θ = [ β per dpar in order ;
      log_sd per covariance block in order ;
      chol_offdiag per covariance block in order ]
```

Per-dpar `β` ordering follows `df.dpars`: `:mu, :sigma` for univariate
and `:mu1, :mu2, :sigma1, :sigma2, :rho12` for bivariate. For each
`CovBlockSpec` (`bf_sketch.jl:284-291`), the block contributes `k`
log-SDs and `k(k-1)/2` strict-lower entries of a row-normalised
Cholesky factor `L_corr`; the marginal covariance is
`Σ = diag(exp(log_sd)) · (L_corr L_corr') · diag(exp(log_sd))`. Same
parameterisation as `gllvmTMB.jl/src/packing.jl:1-30` and TMB's
`density::UNSTRUCTURED_CORR_t`.

### Worked examples

| Model | Segment | Layout | Length |
|---|---|---|---|
| Univariate Gaussian, `y ~ x1 + x2`, `sigma ~ x1` | β | `β_mu (3)`, `β_sigma (2)` | 5 |
| | log_sd | — | 0 |
| | chol_offdiag | — | 0 |
| | **total** | | **5** |
| Bivariate q=4 phylo block (label `:core`, dpars `mu1,mu2,sigma1,sigma2`), all intercept-only, `rho12 ~ 1` | β | `β_mu1 (1), β_mu2 (1), β_sigma1 (1), β_sigma2 (1), β_rho12 (1)` | 5 |
| | log_sd | `log_sd_mu1, log_sd_mu2, log_sd_sigma1, log_sd_sigma2` | 4 |
| | chol_offdiag | 6 strict-lower entries of the 4×4 `L_corr` | 6 |
| | **total** | | **15** |
| `(1 | p | id)` shared block at q=2, `mu ~ x` and `sigma ~ x` | β | `β_mu (2), β_sigma (2)` | 4 |
| | log_sd | `log_sd_mu_id, log_sd_sigma_id` | 2 |
| | chol_offdiag | 1 strict-lower entry → atanh-correlation `mu↔sigma` | 1 |
| | **total** | | **7** |

In v0.3+ the Laplace path appends a contiguous RE vector `u` of
length `sum_block(k_block · n_levels_block)`. `u` is an inner
optimisation variable, not part of `θ`.

## 5. Dependency graph

```
                    ┌────────────────────┐
                    │  DRM.jl (module)   │
                    └─────────┬──────────┘
                              │ include
        ┌─────────────────────┼──────────────────────┐
        ▼                     ▼                      ▼
  ┌──────────┐         ┌────────────┐         ┌──────────┐
  │formula.jl│         │families.jl │         │packing.jl│
  └────┬─────┘         └─────┬──────┘         └─────┬────┘
       │                     │                      │
       │   ┌─────────────────┘                      │
       ▼   ▼                                        │
  ┌──────────┐                                      │
  │design.jl │                                      │
  └────┬─────┘                                      │
       │                                            │
       │ ┌──────────────────────────────────────────┘
       ▼ ▼
  ┌─────────────────────────────────────────────────────────┐
  │ likelihood_univ_gaussian.jl                              │
  │ likelihood_biv_gaussian.jl                               │
  │ likelihood_phylo.jl ──→ sparse_phy.jl, sparse_phy_grad.jl│
  └────────────────────────────┬─────────────────────────────┘
                               │
                               ▼
                         ┌──────────┐
                         │profile.jl│  (σ profile-out when sigma ~ 1)
                         └─────┬────┘
                               ▼
                         ┌──────────┐
                         │  fit.jl  │  (Optim + ForwardDiff)
                         └─────┬────┘
              ┌────────────────┼─────────────────┐
              ▼                ▼                 ▼
        ┌──────────┐    ┌─────────────┐   ┌───────────────┐
        │confint.jl│    │confint_     │   │confint_       │
        │ (Wald)   │    │ profile.jl  │   │ bootstrap.jl  │
        └──────────┘    └─────────────┘   └──────┬────────┘
                                                 │
                                                 ▼
                                           ┌──────────┐
                                           │simulate.jl│
                                           └──────────┘

  predict.jl uses: design.jl, families.jl, fit (predictions)
  em.jl, em_squarem.jl: alternative solvers, optional path
  laplace.jl: v0.3+; sits between design.jl and likelihood_*.jl,
              providing inner mode-finding for non-Gaussian families
```

## 6. Project.toml (v0.1.x)

```toml
name    = "DRM"
uuid    = "<to-be-generated>"
authors = ["Shinichi Nakagawa <itchyshin@gmail.com>"]
version = "0.1.0"

[deps]
Distributions = "31c24e10-a181-5473-b8eb-7969acd0382f"
ForwardDiff   = "f6369f11-7733-5829-9624-2563aa707210"
LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
Optim         = "429524aa-4258-5aef-a3af-852621145aeb"
Random        = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
SparseArrays  = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
Statistics    = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
StatsModels   = "3eaba693-3990-54bb-aba2-c4ec64f95603"
DataFrames    = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
MixedModels   = "ff71e718-51f3-5ec2-a782-8ffcbfa3c316"  # parsing reuse only

[compat]
Distributions = "0.25"
ForwardDiff   = "0.10"
Optim         = "1.7"
StatsModels   = "0.7"
DataFrames    = "1.6"
MixedModels   = "4"
julia         = "1.10"

[extras]
AppleAccelerate = "13e28ba4-7ad8-5781-acae-3021b1ed3924"  # suggested on Apple Silicon
BenchmarkTools  = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
Test            = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[targets]
test = ["Test"]
```

The first seven entries are verbatim from `gllvmTMB.jl/Project.toml`.
`StatsModels` and `DataFrames` are new because DRM.jl is tabular.
`MixedModels` is included only for its RE-formula parser; the solver
is not called. `AppleAccelerate` is suggested for M-series users; the
core engine does not require it.

## 7. Versioning roadmap

| Version | Adds | Major new code | Status |
|---|---|---|---|
| **v0.1.x** | Gaussian univariate + bivariate fixed effects; Gaussian-marginal phylo block; SharedRE Gaussian-only; Wald/profile/bootstrap CIs | `formula.jl`, `design.jl`, `likelihood_univ_gaussian.jl`, `likelihood_biv_gaussian.jl`, `likelihood_phylo.jl` (with sparse Q ports) | POC validated; build target |
| **v0.2.x** | Student-t (univariate, no RE); `meta_V`; richer diagnostics | `families.jl` extensions; `meta.jl` thin wrapper | Plan only |
| **v0.3.x** | **Laplace wrapper** unlocking non-Gaussian + RE on `sigma` etc.; IID + AR1 random effects via Laplace; Tweedie, Beta, NB2, ZI, ordinal families | `laplace.jl` (the major new piece); inner-mode finder + outer AD | Architecture deferred |
| **v0.4.x** | Phylogenetic random effects on non-Gaussian families (via Laplace) | Hook sparse-Q ports into Laplace inner loop | Architecture deferred |
| **v0.5.x** | Spatial SPDE | FEM mesh helpers; sparse precision construction | Sketch only |
| **v1.0** | Full drmTMB parity: `sd(group) ~ x` structured RE-SD, emmeans-style marginal effects, all families | API-layer additions on top of v0.3+ infrastructure | Long-horizon |

The single non-obvious investment is **v0.3.x's Laplace wrapper**.
Everything earlier is closed-form Gaussian; everything later sits on
top of the wrapper.

## 8. Design rules

Mirroring `drmTMB/AGENTS.md`:

1. **Scope is fixed.** Univariate + bivariate distributional
   regression only. Higher-dimensional multivariate goes to
   `gllvmTMB.jl`.
2. **Stable public names.** `sigma`, `rho12`, `nu`, `zi`, `mu`, `mu1`,
   `mu2`, `sigma1`, `sigma2` are canonical and must not drift. `tau`
   is reserved for the second shape parameter or meta-analysis
   contrasts; it is not an alias for `sigma`.
3. **Syntax matches drmTMB verbatim.** `bf(mu1 = y1 ~ x, mu2 = y2 ~ x,
   sigma1 = ~ x, sigma2 = ~ x, rho12 = ~ x)`; `phylo(1 | p | species,
   tree = tree)`; `meta_V(V = V)`. Where a Julia idiom is
   unavoidable (`@formula`, kwargs in `bf()`), keep the rest verbatim.
4. **Reuse from GLLVM.jl is wholesale.** Ported files (packing,
   profile, `confint_*`, EM, sparse phylo) are copied with file-level
   provenance in `COPYRIGHTS.md`. Reverse-port fixes back to
   `gllvmTMB.jl`.
5. **RE grammar.** lme4 `(1 | g)`, brms `(1 | p | g)` for cross-dpar
   shared blocks (label `p` is significant), `phylo(rhs | label | group;
   tree)` for phylogenetic RE. No further grammar without an explicit
   design decision.
6. **Meta-analysis is `Gaussian()` + `meta_V(V = V)`.** (The older
   `meta_known_V()` is deprecated, kept only as a parity stub.) No
   `meta_gaussian()` family, no `tau ~` syntax.
7. **No new family without a simulation test.** A family is "in" only
   when a recovery test on `n ∈ {200, 1000}` matches the truth to the
   pre-registered tolerance.
8. **Likelihood parameterisation is documented before code.** Changes
   to the Gaussian or bivariate Gaussian closed forms require a
   paired update to a parallel `docs/design/03-likelihoods.md`.
9. **CI is cost-aware.** `[pull_request, workflow_dispatch]`,
   `ubuntu-latest` only for routine work, expanded to macOS/Windows
   only before tagged releases. Local `Pkg.test()` is the first gate.
10. **License: MIT.** Matches `gllvmTMB.jl`.

## 9. POC results (anchor)

The 5-cell headline grid plus four phylogenetic cells were measured
against `drmTMB`. Median speedup R/Julia 22.6×, max 83.8×
(`drm-julia-poc/report/summary.md:3`); `|ΔlogLik| < 4.8e-5` and
`max|Δcoef| < 5e-5` on every cell. Large-`p` phylo regresses because
the POC uses a dense `Σ_y = σ²_phy Σ_phy + σ²_eps I` Cholesky; the
production path hooks `sparse_phy.jl` from `gllvmTMB.jl` (sparse Q
over augmented tree state) and recovers `O(p)` scaling. The `q4_p100`
bivariate q=4 phylogenetic cell is out of scope until v0.3+ because
its marginal is non-closed-form.
