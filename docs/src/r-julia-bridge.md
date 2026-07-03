# R ↔ Julia bridge

!!! note "Status — Experimental first slice (Phase 1.5)"
    DRM.jl now exposes `drm_bridge()`, a marshalling-friendly entry point for the R-side `drmTMB(formula, ..., engine = "julia")` glue. The companion R glue lives in the **drmTMB R repository** via [JuliaCall](https://github.com/JuliaInterop/JuliaCall). The first tested bridge slice covers Gaussian one-response and two-response fits, plus narrow complete-response q=2 structured Gaussian fixture cells; broader families wait for coefficient-scale parity tests. For translating R syntax to Julia by hand, see the [Rosetta page](rosetta.md).

## The idea

Two ways to use DRM.jl from R, in increasing integration:

1. **Translate by hand** — rewrite the model in Julia using `drm` / `bf`. The
   [Rosetta](rosetta.md) phrasebook is the lookup table. Available today.
2. **`engine = "julia"`** — keep writing ordinary `drmTMB(...)` R code; drmTMB
   marshals the formula and data across JuliaCall, calls DRM.jl to fit, and
   returns a result object shaped like a native drmTMB fit. Experimental for
   Gaussian one-response and two-response models, the first Gaussian
   `phylo(1 | species)` mean bridge with constant `sigma`, and narrow
   complete-response q=2 structured Gaussian fixtures.

## The DRM.jl-side contract

For the bridge to work, DRM.jl exposes a stable, marshalling-friendly surface:

- **Formula** — the R `bf(mu = y ~ x, sigma = ~ x, ...)` is mapped to DRM.jl's
  `bf(...)` (see the [Formula grammar](developer-notes/formula-grammar.md) and Rosetta pages for the exact
  spelling map);
- **Data** — an R `data.frame` crosses as a column table (`NamedTuple` /
  `DataFrame`) keyed by the same column names;
- **Result** — `drm_bridge()` returns a flat dictionary with coefficient names
  and values, covariance matrix, likelihood summaries, convergence state,
  fitted values, residuals, fitted scale, residual-correlation payloads when
  present, and direct q=2/q=4 point-export payloads when the exact fitted cell
  supplies them. The direct exports carry their own claim-boundary strings and
  remain point/export evidence, not interval or coverage evidence.

For the Gaussian phylogenetic mean cell, the current `algorithm = :auto` route
uses the all-node sparse L-BFGS fitter in `src/location_only.jl`. That route
profiles the mean coefficients by sparse GLS, uses exact Takahashi trace
gradients for the residual and phylogenetic standard deviations, and returns a
finite mean-coefficient covariance block. Scale and variance-component
covariance are still left unset for the R bridge, so profile/bootstrap work
remains the next inference slice.

## Open design questions

Tracked in the issue ledger:

- **Broader phylo / pedigree / relatedness marshalling** — the first Newick
  tree slice works for one Gaussian `phylo(1 | species)` mean term, and the q=2
  direct-export branch adds fixture-level `K` / `A` evidence. Broad pedigree or
  relatedness marshalling, `Ainv`, multiple structured terms, slopes, and
  non-Gaussian phylogenetic models still need separate parity tests (issue #19).
- **Result-shape parity** — exact field-by-field equivalence between a native
  drmTMB fit and the Julia-engine fit (issue #5), guarded by the R-parity suite
  (Workflow G, issue #17).
- **Round-trip `bf()` formulas** — an R formula and its Julia translation must
  describe the same model; the parity tests enforce this once R is available in CI.

Until broader parity ships, use the bridge for Gaussian one-response,
two-response, the admitted Gaussian phylogenetic smoke runs, and the narrow q=2
structured exact-Gaussian fixture cells. Use hand-translation via the Rosetta
phrasebook or native `drmTMB` for the remaining families and unsupported formula
features.
