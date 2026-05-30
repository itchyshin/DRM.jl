# DRM.jl

*Fast **distributional regression** in Julia — the twin of the R package
[drmTMB](https://itchyshin.github.io/drmTMB/).*

DRM.jl fits distributional regression models for one or two responses: each
distributional parameter — the mean **μ**, the residual scale **σ**, and the
bivariate residual correlation **ρ12** — gets its own formula. Use it when
predictors may affect not only the expected response but also its variability
and the coupling between two responses. The first examples are motivated by
ecology and evolution, but the engine is general-purpose.

!!! note "Scaffold / pilot (v0.1.0-DEV)"
    This site grows alongside the package. Every page carries a **status tag**
    mirroring drmTMB's vocabulary — *Stable*, *First slice*, *Opt-in control*,
    *Planned or reserved*, *Unsupported or blocked* — so you always know what is
    fitted today versus on the roadmap. See [`HANDOVER.md`](https://github.com/itchyshin/DRM.jl/blob/main/HANDOVER.md)
    for the verified engine and [`ROADMAP.md`](https://github.com/itchyshin/DRM.jl/blob/main/ROADMAP.md) for the phases.

## Why a Julia twin?

drmTMB's selling-point model — the **q=4 phylogenetic bivariate location–scale
model (PLSM)**, where a shared phylogenetic random effect drives
`(μ1, μ2, log σ1, log σ2)` — has no closed-form marginal and needs a Laplace
approximation. brms/Stan needs ~122 h; drmTMB (R/TMB) fits it in ~2.5 s at
p=100 species. DRM.jl fits the same model in **1.14 s (2.18× faster)**, scales
**near-linear O(p) to p=10,000**, and returns **valid confidence intervals where
drmTMB's Hessian is singular**. A fast engine makes the bootstrap / coverage /
power studies that were bottlenecked by R/TMB cheap.

## The planned surface (mirrors drmTMB)

!!! warning "Planned or reserved — front end lands in Phase 1.1"
    The `bf()` formula front end is being wired ([roadmap](https://github.com/itchyshin/DRM.jl/blob/main/ROADMAP.md)).
    The target reads exactly like drmTMB, so an R user can move across with no
    relearning:

    ```julia
    using DRM
    fit = drm(
        bf(y ~ x1, sigma ~ x1),   # a formula per distributional parameter
        family = gaussian(),
        data = dat,
    )
    ```

What works **today** is the verified q=4 PLSM engine — see
[Working with large data](model-guides/large-data.md) and the head-to-head in
`bench/run_sparse_tmb_nd.jl`.

## For R users

DRM.jl is a true twin: the same `bf()` grammar, the same families, the
same articles. A planned [R↔Julia bridge](r-julia-bridge.md) will let you call
DRM.jl from R via `drmTMB(formula, ..., engine = "julia")`, and the
[Rosetta page](rosetta.md) shows the same model side by side in both languages.

## Start here

- New to distributional regression? **[Get started](get-started.md)**.
- Not sure what's implemented? **[What can I fit today?](model-guides/model-map.md)**
- Modelling two responses? **[Changing residual coupling with rho12](tutorials/bivariate-coscale.md)**.
- Building the package? **[Developer notes](developer-notes/formula-grammar.md)** and the [team](https://github.com/itchyshin/DRM.jl/blob/main/AGENTS.md).

---

*MIT licensed. A sister package to [drmTMB](https://itchyshin.github.io/drmTMB/)
(GPL) and [GLLVM.jl](https://github.com/itchyshin/GLLVM.jl). DRM.jl is fresh
code — never a port of drmTMB's GPL source.*
