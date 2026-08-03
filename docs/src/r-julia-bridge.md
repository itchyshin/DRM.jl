# R ↔ Julia bridge

!!! note "Status — Experimental bridge + fixture-backed coefficient-scale gate (#370) + measured six-cell timing (#372)"
    DRM.jl exposes `drm_bridge()`, a marshalling-friendly entry point for the R-side `drmTMB(formula, ..., engine = "julia")` glue. The companion R glue lives in the **drmTMB R repository** via [JuliaCall](https://github.com/JuliaInterop/JuliaCall).

    **Admitted fixture-backed coefficient-scale parity** (opt-in `DRM_PARITY_TESTS=1`, via `drm_bridge` + committed drmTMB v0.1.3 generated numbers only):

    - `gaussian-locscale`
    - `gaussian-bivariate-rho12`
    - `robust-student`
    - `count-nbinom2`
    - `proportion-beta`
    - `meta-analysis-V`

    **Measured warm wall-clock** for the same six fixtures (local machine;
    Julia `drm_bridge` vs installed drmTMB **0.6.0**; BLAS/OMP threads = 1;
    1 warmup + 5 timed reps; median R/Julia ratios ≈ **4.8×–46×** depending on
    cell — full method, versions, and per-cell medians retained in
    `docs/dev-log/evidence/2026-08-03-372-six-cell-timing.md`).
    This is **not** a general “Nx faster for all drmTMB models” claim, and it is
    **not** the verified q=4 PLSM 2.18× cell (`report/comparison-grid.md`).
    For translating R syntax to Julia by hand, see the [Rosetta page](rosetta.md).

## The idea

Two ways to use DRM.jl from R, in increasing integration:

1. **Translate by hand** — rewrite the model in Julia using `drm` / `bf`. The
   [Rosetta](rosetta.md) phrasebook is the lookup table. Available today.
2. **`engine = "julia"`** — keep writing ordinary `drmTMB(...)` R code; drmTMB
   marshals the formula and data across JuliaCall, calls DRM.jl to fit, and
   returns a result object shaped like a native drmTMB fit. Experimental for
   Gaussian one-response and two-response models, the first Gaussian
   `phylo(1 | species)` mean bridge with constant `sigma`, narrow
   complete-response q=2 structured Gaussian fixtures, and the six
   fixture-backed coefficient-scale cells listed above (Julia-side
   `drm_bridge` gate; R-side Lovelace glue remains in the drmTMB repo).

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

## Coefficient-scale parity gate (#370)

Behind `DRM_PARITY_TESTS=1`, `test/parity/runparity_bridge.jl` fits the six
cohort fixtures through `drm_bridge` and compares against committed
`expected.toml` numbers via `compare_bridge` (same coef bar as Workflow G /
`compare_fit`: default `atol_coef=1e-6`, `rtol_coef=1e-4`, with per-case
`[tol]` overrides). Native `drm()` parity (`runparity.jl`, #17) still runs in
the same env gate. `xfam-external-gllvm` remains OUT (cross-package estimand).

MIT/GPL: fixtures are **generated numeric outputs only** — never vendored
drmTMB source.

## Open design questions

Tracked in the issue ledger:

- **Broader phylo / pedigree / relatedness marshalling** — the first Newick
  tree slice works for one Gaussian `phylo(1 | species)` mean term, and the q=2
  direct-export branch adds fixture-level `K` / `A` evidence. Broad pedigree or
  relatedness marshalling, `Ainv`, multiple structured terms, slopes, and
  non-Gaussian phylogenetic models still need separate parity tests (issue #19).
- **Result-shape parity** — exact field-by-field equivalence between a native
  drmTMB fit and the Julia-engine fit (issue #5), guarded by the R-parity suite
  (Workflow G, issue #17) plus the `drm_bridge` fixture path (#370).
- **Round-trip `bf()` formulas** — an R formula and its Julia translation must
  describe the same model; the parity tests enforce this once R is available in CI.
- **Broader measured speed campaigns** — the six-cell fixture timing in #372 is
  retained and scoped; ROADMAP p>100 head-to-head and other large-n campaigns
  remain separate issues (Rose: do not promote extrapolated p-scaling).

Use the bridge for Gaussian one-response / two-response, the admitted Gaussian
phylogenetic smoke runs, the narrow q=2 structured exact-Gaussian fixture
cells, and the six coefficient-scale fixture families above. Use hand-translation
via the Rosetta phrasebook or native `drmTMB` for remaining families and
unsupported formula features.
