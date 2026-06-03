# R ↔ Julia bridge

!!! note "Status — Planned (Phase 1.5)"
    This page describes the **intended** bridge that lets an R user run drmTMB's front end on the DRM.jl engine: `drmTMB(formula, …, engine = "julia")`. The R-side glue lives in the **drmTMB R repository** (via [JuliaCall](https://github.com/JuliaInterop/JuliaCall)), not in this package, so the steps below are the design + the DRM.jl-side contract, not a shipped feature. For translating R syntax to Julia by hand today, see the [Rosetta page](rosetta.md).

## The idea

Two ways to use DRM.jl from R, in increasing integration:

1. **Translate by hand** — rewrite the model in Julia using `drm` / `bf`. The
   [Rosetta](rosetta.md) phrasebook is the lookup table. Available today.
2. **`engine = "julia"`** — keep writing ordinary `drmTMB(...)` R code; drmTMB
   marshals the formula and data across JuliaCall, calls DRM.jl to fit, and
   returns a result object shaped like a native drmTMB fit. Planned (Phase 1.5).

## The DRM.jl-side contract

For the bridge to work, DRM.jl exposes a stable, marshalling-friendly surface:

- **Formula** — the R `bf(mu = y ~ x, sigma = ~ x, …)` is mapped to DRM.jl's
  `bf(...)` (see the [Formula grammar](developer-notes/formula-grammar.md) and Rosetta pages for the exact
  spelling map);
- **Data** — an R `data.frame` crosses as a column table (`NamedTuple` /
  `DataFrame`) keyed by the same column names;
- **Result** — the fitted `DrmFit` exposes the accessors R expects
  (`coef`, `vcov`, `loglik`, `aic`/`bic`, `confint`, `fitted`, `residuals`,
  `predict`, `simulate`, `ranef`/`vc`), so the R wrapper can reconstruct a
  drmTMB-shaped object.

## Open design questions

Tracked in the issue ledger:

- **Phylo / pedigree / relatedness marshalling** — how a Newick tree, an `Ainv`,
  or a `K` matrix crosses the R ↔ Julia boundary (issue #19).
- **Result-shape parity** — exact field-by-field equivalence between a native
  drmTMB fit and the Julia-engine fit (issue #5), guarded by the R-parity suite
  (Workflow G, issue #17).
- **Round-trip `bf()` formulas** — an R formula and its Julia translation must
  describe the same model; the parity tests enforce this once R is available in CI.

Until the bridge ships, the supported path is hand-translation via the Rosetta
phrasebook.
