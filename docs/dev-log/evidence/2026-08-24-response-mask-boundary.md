# Evidence: `gaussian_response_mask` — does drmTMB admit a cell DRM.jl refuses?

Date: 2026-08-24
Author: Hopper (R↔Julia translator), measurement/diagnosis slice only — no fix implemented.
Repos: `drmTMB` @ installed 0.7.0 (source checkout), `DRM.jl` @ current `docs/handover-parity-merged` checkout.
Environment: R 4.6.0, drmTMB 0.7.0, JuliaCall (installed), Julia 1.10.0, `DRM_JL_PATH=<DRM.jl>`.

## 1. The two gates, read from source

**drmTMB (R bridge admission gate).** `R/julia-bridge.R:457-464`:

```r
drm_julia_missing_supported <- function(missing_control, family_type) {
  identical(missing_control$predictor, "fail") &&
    (identical(missing_control$response, "drop") ||
      (identical(missing_control$response, "include") &&
        family_type %in% c("gaussian", "biv_gaussian")))
}
```

This admits `response = "include"` for **any** formula whose `family_type` is `"gaussian"` or
`"biv_gaussian"` — it does not look at the formula's structure (whether `mu`, `sigma`, both, or
neither carries a `phylo(1|g)` term). `family_type` comes from `drm_julia_bridge_family_type()`
(`R/julia-bridge.R:488-500`), which classifies purely on the `family` object, not the formula.

Two call sites gate on this, both admitting the same way:
- `R/julia-bridge.R:366` inside `drmTMB_julia_bridge()` (the route actually taken by
  `phylo(1|g)` on `mu` — see below).
- `R/julia-bridge.R:4002` inside `drmTMB_julia_structured_bridge()` (the route for
  `relmat()`/`animal()`/`spatial()` — **not** `phylo()`; confirmed at
  `R/julia-bridge.R:3735-3736`, `drm_julia_structured_marker_types()` returns
  `c("relmat","animal","spatial")` only).

A phylo term is detected separately by `drm_julia_has_phylo_term()`
(`R/julia-bridge.R:574-585`), which only affects the family *tag* sent to Julia
(`drm_julia_family_tag(family_type, has_phylo = has_phylo)`, line 380) — it plays **no role**
in the `drm_julia_missing_supported()` admission decision. So a mean-phylo Gaussian formula with
`missing = miss_control(response = "include")` reaches this gate exactly like a non-phylo
Gaussian formula does, and is admitted.

**DRM.jl (engine-side gate).** `src/gaussian_core.jl:547-552`, inside `drm(f::DrmFormula,
fam::Gaussian; ...)`:

```julia
if has_missing_response
    (isempty(re) && isempty(sigma_re) && structured === nothing && metav === nothing &&
     length(all_structured) == 0) ||
        throw(ArgumentError("drm: missing Gaussian responses are currently supported for " *
            "fixed-effect univariate location-scale models. Structured, random-effect, " *
            "and meta-analysis response-missing support need their own likelihood slice."))
end
```

This is reached only when the formula did **not** hit the earlier, separate `structured_sigma
!== nothing` early-return block (`gaussian_core.jl:415-509`, the σ-phylo location-scale route,
which has its own internal missing-response handling — see `gaussian_core.jl:428-461`). For a
**mean**-phylo formula (`structured !== nothing`, `structured_sigma === nothing`), execution
falls through to line 547, where `structured === nothing` is `false`, so the whole admission
conjunction is `false` and the `ArgumentError` fires. DRM.jl's missing-response support is
therefore gated by **route** (only the fixed-effect location-scale cell and the σ-phylo cell have
missing-response handling wired), not by family alone.

This is exactly the asymmetry the promotion-path analysis predicted: drmTMB's gate is a
**family**-level predicate; DRM.jl's real support is a **route**-level predicate, and mean-phylo
Gaussian is a route the R gate does not distinguish from the supported non-phylo route.

## 2. Measured: the prediction, run live

Script: `/private/tmp/.../scratchpad/test_mean_phylo_missing.R`, run as
`DRM_JL_PATH="<DRM.jl>" Rscript <script>` against the installed drmTMB 0.7.0.

**Cell B — Gaussian mean-phylo, `missing = miss_control(response = "include")`, `engine =
"julia"`:**

```
$ok
[1] FALSE
$msg
[1] "Error happens in Julia.\nArgumentError: drm: missing Gaussian responses are currently
supported for fixed-effect univariate location-scale models. Structured, random-effect, and
meta-analysis response-missing support need their own likelihood slice.
Stacktrace:
 [1] drm(...) @ DRM ~/.../DRM.jl/src/gaussian_core.jl:548
 [2] _bridge_fit(...) @ DRM ~/.../DRM.jl/src/bridge.jl:285
 [3] drm_bridge(...) @ DRM ~/.../DRM.jl/src/bridge.jl:49
 ..."
```

No R-side `cli_abort` preceded this — the call reached Julia and Julia raised it. This confirms
the R gate admitted the request (as predicted from its source) and the failure is a live runtime
error, not a hypothetical one.

**Native Julia (no R involved), same model:** script
`/private/tmp/.../scratchpad/native_mean_phylo_missing.jl`, run with `julia --project=.` inside
the DRM.jl checkout, calling `DRM.drm(DRM.bf(@formula(y ~ x + phylo(1|species)), @formula(sigma ~
1)), DRM.Gaussian(); data = data_with_3_missing_y, tree = phy)` directly (`random_balanced_tree`
tree, no drmTMB/JuliaCall in the loop at all):

```
CAUGHT ERROR TYPE: ArgumentError
MESSAGE: ArgumentError: drm: missing Gaussian responses are currently supported for fixed-effect
univariate location-scale models. Structured, random-effect, and meta-analysis response-missing
support need their own likelihood slice.
```

Identical error text, identical origin (`gaussian_core.jl:547-552`), with zero R/bridge code in
the call path. **The refusal is engine-side.**

Sanity check (same script): the identical model/tree with the response made complete (no missing)
fits normally — `ll = -6.3439`, `nobs = 40`, finite — confirming the model and tree setup are
themselves fine and the failure is specific to the missing-response branch.

## 3. The {family × route × mask} matrix — measured outcomes

All cells below were run live (R via `engine = "julia"` unless noted); "R admits" reports whether
`drm_julia_missing_supported()` (as reached from the route the formula actually takes) lets the
call proceed to Julia at all.

| # | Family | Route | Mask (`missing=`) | R admits? | Julia outcome (measured) | Verdict |
|---|--------|-------|--------------------|-----------|---------------------------|---------|
| A | Gaussian | non-phylo (fixed-effect location-scale) | `response="include"` | Yes | **Fits.** `ll = -47.904`, `nobs = 34` (40−6 missing), finite, in range. | Match — R admits, Julia fits. |
| A′ | Gaussian | non-phylo | `response="drop"` (default) | Yes | **Fits.** `ll = -46.335`, `nobs = 34`, finite. | Match. |
| B | Gaussian | **mean-phylo** (`mu ~ x + phylo(1\|sp)`, `sigma ~ 1`) | `response="include"` | Yes | **Throws** `ArgumentError` at `gaussian_core.jl:548` (engine-side; reproduced natively, §2). | **MISMATCH — the predicted cell.** |
| B′ | Gaussian | **mean-phylo** | `response="drop"` (default) | Yes | **Throws**, but a *different*, unrelated-looking error: `"algorithm = :sparse_lbfgs: the number of \`species\` levels (37) must equal the tree's leaf count (40)"` (`location_only.jl:3307`). Cause: the R-side `#694` fix (`drm_julia_drop_missing_rows`, `julia-bridge.R:410-412`) drops the 3 NA-response rows from the *tabular data* before marshalling, but the phylo *tree* payload built alongside it still carries all 40 leaves — the sparse Gaussian mean-phylo route requires an exact species-count/leaf-count match and has no internal re-pruning (unlike the Poisson Laplace route below, row F, which does its own species-level pruning). | **Second, distinct mismatch** — not the one predicted, but the same underlying gap (mean-phylo Gaussian + missing response is not a route DRM.jl's missing-data handling covers), surfacing as a confusing dimension error instead of a clean gate. |
| C | Poisson | mean-phylo (`y ~ x + phylo(1\|sp)`) | `response="drop"` (default) | Yes (drop always admitted) | **Fits.** R pre-drops 3 rows (37 kept); DRM.jl's Laplace phylo route re-derives its own tree/species pruning internally and matches. `ll = -57.356`, `nobs = 37`, finite. | Match — this is the case the existing `test-julia-missing.R` "count phylo… drops rows, matches native" test already exercises. |
| D | Poisson | mean-phylo | `response="include"` | **No** — rejected before any Julia call: `"engine = \"julia\" does not support this missing route yet. ... Supported: response=\"drop\", or response=\"include\" for Gaussian..."` | N/A (never reached Julia). | Not a mismatch — R and Julia agree this is unsupported; R just says so first. |

(Rows A/A′/D reproduce/extend the existing `tests/testthat/test-julia-missing.R` coverage; rows
B, B′, C were run fresh for this slice — C using the same tree/data construction as the existing
Poisson test in that file, to make the Gaussian-vs-Poisson contrast apples-to-apples.)

## 4. VERDICT

**MISMATCH CONFIRMED.** Exact cell: **Gaussian, mean-phylo route (`mu ~ x + phylo(1|group)`,
`sigma ~ 1`), `missing = miss_control(response = "include")`, `engine = "julia"`.**

- drmTMB's `drm_julia_missing_supported()` admits it (`family_type == "gaussian"` is sufficient;
  the function never inspects whether the formula is phylo-structured).
- DRM.jl's `drm()` refuses it with `ArgumentError: drm: missing Gaussian responses are currently
  supported for fixed-effect univariate location-scale models. Structured, random-effect, and
  meta-analysis response-missing support need their own likelihood slice.` — thrown at
  `src/gaussian_core.jl:548`, reproduced identically via a pure-Julia call with no R/bridge in the
  path.
- A live user calling `engine = "julia"` with a mean-phylo Gaussian model and
  `missing = miss_control(response = "include")` gets exactly this: an R-admitted request that
  dies inside Julia with a Julia stack trace, not a clean R-level `cli_abort`.

**Bonus finding (not part of the original prediction, but the same boundary):** the *default*
missing control (`response = "drop"`) for this same mean-phylo-Gaussian cell **also fails**, via a
second, independent bug — the R-side `#694` NA-row-drop and the phylo tree payload go out of sync
for this specific sparse Gaussian route (row B′ above). So there is currently **no** working
`engine = "julia"` path for mean-phylo Gaussian with a missing response, under either `missing`
setting; `response = "include"` fails cleanly (engine ArgumentError) and `response = "drop"` fails
confusingly (dimension-mismatch error naming an unrelated algorithm).

## 5. Bridge-side or engine-side?

**Engine-side**, for the predicted cell (row B). Confirmed two ways: (a) the R bridge's own gate
(`drm_julia_missing_supported`) returns `TRUE` and the call reaches Julia (§2, no `cli_abort`
precedes the failure); (b) the identical `ArgumentError`, from the identical source line, was
reproduced with a native `DRM.drm(...)` call containing no drmTMB/JuliaCall/R code at all (§2).

Row B′ (the `response="drop"` default case) is **jointly bridge-and-engine**: the R-side
`drm_julia_drop_missing_rows` pre-filter (`julia-bridge.R:410-412`) creates the row/tree mismatch
that DRM.jl's sparse-phylo route then trips over — neither side alone is sufficient to explain the
failure; it is an interaction bug between the R-side row-drop and the Julia-side tree-payload
construction.

## 6. Not measured

- **σ-phylo (structured `sigma`) and both-phylo (mu+sigma) routes with `response="include"`**:
  `gaussian_core.jl:428-461` shows this route *does* have its own missing-response handling
  (unlike the mean-only route), and the code comment there explicitly claims it as supported —
  but that specific cell was not run live in this slice (out of scope: the task named mean-phylo
  specifically). Its R-side admission path (whether it goes through the same
  `drm_julia_missing_supported` gate or a different one) was traced from source only, not
  exercised.
- **`biv_gaussian` (bivariate q4) with a missing response** — `family_type %in% c("gaussian",
  "biv_gaussian")` in the R gate suggests the same family-vs-route asymmetry could apply there,
  but this was not tested.
- **`relmat()`/`animal()`/`spatial()` structured terms with a missing response** — these route
  through `drmTMB_julia_structured_bridge()` (a third, separate gate call at
  `julia-bridge.R:4002`) which was read but not exercised live in this slice.
- Whether the row-B′ dimension-mismatch bug also affects the σ-phylo or both-phylo sparse routes
  was not tested — flagged as a plausible but unmeasured extension.
