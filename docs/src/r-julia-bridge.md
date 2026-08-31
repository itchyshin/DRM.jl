# R ↔ Julia bridge

!!! note "Status — Experimental bridge + fixture-backed coefficient-scale gate (#370/#383/#385) + measured timing (#372/#389)"
    DRM.jl exposes `drm_bridge()`, a marshalling-friendly entry point used by
    the optional `drmTMB(formula, ..., engine = "julia")` backend for supported
    models. The companion R glue lives in the **drmTMB R repository** via
    [JuliaCall](https://github.com/JuliaInterop/JuliaCall); the default
    `engine = "tmb"` does not require Julia.

    **Admitted fixture-backed coefficient-scale parity** (opt-in
    `DRM_PARITY_TESTS=1`, via `drm_bridge` + committed drmTMB generated
    numbers only). The eleven cells below all record **drmTMB 0.7.0** in their
    `expected.meta.toml` files:

    Original six (#370 / refresh #392):

    - `gaussian-locscale`
    - `gaussian-bivariate-rho12`
    - `robust-student`
    - `count-nbinom2`
    - `proportion-beta`
    - `meta-analysis-V`

    +4 FE cohort (#383):

    - `count-poisson`
    - `positive-gamma`
    - `binomial-trials`
    - `positive-lognormal`

    NB2 location–scale FE (#385):

    - `nbinom2-dispersion` (`y ~ x; sigma ~ x`)

    A separate seven-cell `bridge-*` formula-construct cohort also records
    0.7.0, but it tests formula translation rather than expanding this
    coefficient-scale cohort. Across all 18 `test/parity/fixtures/*/expected.meta.toml`
    files that name drmTMB, the version is 0.7.0. Those files do **not** record
    a comparator build string or source hash, so 0.7.0 is a package-version
    anchor, not a unique drmTMB source-build pin.

    **Historical measured warm wall-clock** (local machine; Julia `drm_bridge`
    vs installed drmTMB **0.6.0** at the time; BLAS/OMP threads = 1; 1 warmup +
    5 timed reps):

    - Original six (#372) — median R/Julia ratios ≈ **4.8×–46×**; retained in
      `docs/dev-log/evidence/2026-08-03-372-six-cell-timing.md`.
    - +4 FE + `nbinom2-dispersion` (#389) — median R/Julia ratios ≈ **11.4×–59.6×**;
      retained in `docs/dev-log/evidence/2026-08-05-389-plus5-bridge-timing.md`.

    The timing artifacts were not re-measured on the 0.7.0 fixture anchor. They
    are neither a general “Nx faster for all drmTMB models” claim nor the
    verified q=4 PLSM 2.18× cell (`report/comparison-grid.md`).
    For translating R syntax to Julia by hand, see the [Rosetta page](rosetta.md).

## The idea

Two ways to use DRM.jl from R, in increasing integration:

1. **Translate by hand** — rewrite the model in Julia using `drm` / `bf`. The
   [Rosetta](rosetta.md) phrasebook is the lookup table. Available today.
2. **`engine = "julia"`** — keep writing ordinary `drmTMB(...)` R code; drmTMB
   marshals the formula and data across JuliaCall, calls DRM.jl to fit, and
   returns a result object shaped like a native drmTMB fit. Supported for
   Gaussian one-response and two-response models, the first Gaussian
   `phylo(1 | species)` mean bridge with constant `sigma`, location–scale–scale
   `sd(group)` / `sd(species, level = "phylogenetic")` models (ML, REML, sparse
   scaling, and missing response inclusion), narrow complete-response q=2
   structured Gaussian fixtures, and the eleven fixture-backed coefficient-scale
   cells listed above (Julia-side `drm_bridge` gate; R-side Lovelace glue remains
   in the drmTMB repo).

### Trees with polytomies

A polytomy is an internal node with more than two immediate children. The development
bridge accepts these nodes without resolving them into invented binary branches.
The tree must still have positive branch lengths, nonempty unique tip labels, and
at least two children at every internal node. The R bridge currently requires an
ultrametric tree for its correlation-scale convention. Zero-length branches
and unary nodes remain separate parity work.

The development bridge preserves tip labels containing spaces, punctuation,
Unicode and apostrophes. Keep the same labels in your data; do not replace spaces
with underscores. The serializer quotes labels where needed, and Julia decodes
them without changing their spelling. In direct Newick input, use single quotes
around such labels and double an apostrophe inside a quoted label:

```@example quoted_tree_labels
using DRM
named_tree = augmented_phy("('Mola mola':1,'O''Brien':1,A_B:1);")
@assert named_tree.leaf_names == ["Mola mola", "O'Brien", "A_B"]
named_tree.leaf_names
```

Quoted labels preserve whitespace literally, including leading/trailing spaces.
This concerns tip identity; internal-node labels are parsed but not retained.

Direct Julia keeps the supplied Brownian branch-length scale and can represent
unequal tip depths:

```@example polytomy_tree
using DRM
phy = augmented_phy("((A:1,B:2,C:3):4,D:5,E:6);")
@assert phy.n_leaves == 5 && phy.n_total == 7
@assert phylo_tree_height(phy) == 7
# Small diagnostic only: a dense tip covariance is unsuitable for large trees.
sigma_phy_dense(phy)
```

For an ultrametric tree of height `h`, Julia's raw phylogenetic SD multiplied by
`sqrt(h)` is on the correlation scale used by the R bridge. One height cannot
standardize a tree whose tip depths differ. Accepting a topology does not itself
verify every response family, profile interval or bootstrap workflow.

### One modelled missing predictor — development admission

The R bridge also has a deliberately narrow development route for one modelled
missing predictor. It accepts a Gaussian identity-link response, exactly one
bare additive `mi(x)` term in `mu`, complete fixed-effect exogenous designs,
and a Gaussian, Bernoulli, ordinal or categorical fixed-effect predictor model. The direct
Julia frontend and `drmTMB(..., engine = "julia")` use the same prepared joint
likelihood; observed `x` values remain observed and missing `x` values are
integrated rather than filled before fitting.

Use `impute = list(x = x ~ z)` for a Gaussian predictor, or
`impute = list(x = impute_model(x ~ z, family = binomial()))` for a binary
predictor, with either `missing = miss_control(response = "drop", predictor =
"model")` or `miss_control(response = "include", predictor = "model")`. The
bridge response-drop path removes missing-response rows before preparation.
That is a documented preprocessing choice, not native response-policy parity.

This admission is not a general missing-data bridge. It rejects other response
families, interactions or nesting involving `mi()`,
random or structured effects, offsets, non-default controls, likelihood weights,
and REML. `summary()` and Wald `confint()` are available only when the returned
covariance is usable; profile and bootstrap intervals explicitly error. The
Gaussian predictor-SD interval is a natural-scale delta-Wald interval, may cross
zero, and is not claimed to match native intervals or to have established
coverage.

Two public bridge-adapter cases pass. Training prediction and binary
`newdata` handling have been repaired and checked independently. Full numerical
parity remains open: small differences in native optimizer stopping affect
coefficients and predictions beyond the declared tolerance. This route makes
no full native-parity, speed, or interval-coverage claim. A separate development
route also admits two independent Gaussian predictors; this does not admit
arbitrary combinations of missing-predictor families.

For an ordered predictor, use an ordered R factor and
`impute_model(x ~ z, family = cumulative_logit())`; for a nominal predictor,
use a factor and `impute_model(x ~ z, family = categorical())`. Both finite-state
routes require at least three observed levels. The ordered predictor model
removes its intercept because its cutpoints already supply location parameters.
The response mean still follows its own formula's intercept convention.

Finite-state predictions average the fitted mean over posterior states.
`imputed()` returns expected category scores and conditional score SDs for an
ordered predictor, or the first modal category code for a nominal predictor.
Nominal metric standard errors are unavailable. These are conditional summaries,
not multiple-imputation draws. Ordered-predictor cutpoints are retained in
`fit$missing_data$predictors$x$cutpoints`; ordinary R `coef()` and `vcov()` exclude
them. The bridge retains all raw covariance coordinates internally.

The two retained finite-state bridge cases pass transport and public-operation
checks, including new-data predictions. Native numerical parity remains open
at the unchanged `4e-6` tolerance; these checks establish neither faster warm
workflows nor the full native missing-data interface.

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

## R formula constructs through `engine = "julia"`

R's formula mini-language is not Julia's. `@formula` cannot evaluate `poly(x, 3)` or
`factor(g)` the way an R user means them, so the bridge **rewrites** each construct into
materialised columns or an expanded term list *before* handing the formula to
`@formula`. Every construct below is either implemented with an R-parity fixture on
byte-identical data (`test/parity/fixtures/bridge-*`), or rejected for a measured reason.

| construct | status |
|---|---|
| `I(expr)` | supported, over a safe `+ - * / ^` grammar only — never arbitrary code |
| `scale(x)` | supported; centres and scales by the sample mean/SD (R's default, `n-1` denominator) |
| `factor(g)` | supported; levels ordered by `sort(unique(...))` on the original values, matching R's `contr.treatment` baseline |
| `(...)^k` | supported for a literal positive integer `k` over a `+`-only expression |
| `- term` | supported, including general term removal |
| `poly(x, k)` | supported — R's **orthogonal** basis (`raw = FALSE`, the default), expanding to `k` columns |
| `poly(x, k, raw = TRUE)` | rejected — write the powers explicitly with `I(x^k)` |
| `poly()` inside `(...)^k` | **rejected on measured evidence**, see below |
| `poly()` inside a scalar function | rejected, e.g. `log1p(poly(x, 2))` |
| `poly(x, y, degree)`, explicit `coefs =` | rejected — precompute in R and pass the columns |

### Two rejections worth explaining

`poly()` is the only construct that rewrites to a **group** of terms, and a group does not
compose everywhere a single column does.

**Inside `(...)^k`.** R treats `poly(x, 2)` as **one term**, so `(x + poly(x, 2))^2` crosses
two terms and never forms `poly1:poly2`. Measured against `model.matrix()` on both sides:
R produces **6** model-matrix columns, the flattened rewrite produces **7** — the extra one
being exactly that interaction. Rejected rather than special-cased, because keeping the group
intact through the power algebra needs a term-grouping concept this rewrite does not have.

**Inside a scalar function.** R maps the function elementwise over poly's `k`-column matrix,
giving `k` columns; the rewrite would map it over their **sum**, giving one. Silent, and of
exactly the shape a bridge exists to prevent.

Where poly *does* compose, it was checked rather than assumed — `x * poly(x, 2)`,
`z : poly(x, 2)`, `poly(x, 2) + z` and `x + z - poly(x, 2)` all match R's model-matrix width
exactly.

### Materialised columns and `newdata`

`I()`, `scale()`, `factor()` and `poly()` become synthetic columns (`__bridge_<kind>_<n>`),
which is why bridge coefficient names differ from R's term text — the model is the same, only
the label differs. Those columns are **not** reconstructed for `newdata`: a formula using them
together with `newdata` **fails loudly** with a missing column rather than silently
re-deriving a different basis. For `poly()` that matters more than for the others, since
recomputing the QR on fresh rows would produce a genuinely different basis.

## Coefficient-scale parity gate (#370 / #383 / #385)

Behind `DRM_PARITY_TESTS=1`, `test/parity/runparity_bridge.jl` fits the
admitted cohort fixtures (original six + four FE families +
`nbinom2-dispersion`) through `drm_bridge` and compares against committed
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
  retained and scoped; #376 measured the ROADMAP nrep=4 / p>100 q4 scaling
  head-to-head on Totoro (extrapolated “~12×” **retired** — see
  `docs/dev-log/evidence/2026-08-03-376-q4-scaling-h2h.md`). Other large-n
  campaigns remain separate (Rose: do not invent unmeasured ratios).

Use the bridge for Gaussian one-response / two-response, the admitted Gaussian
phylogenetic smoke runs, the narrow q=2 structured exact-Gaussian fixture
cells, and the eleven coefficient-scale fixture families above. Use
hand-translation via the Rosetta phrasebook or native `drmTMB` for remaining
families and unsupported formula features.
