# A2a — the result-shape contract for `engine = "julia"` post-fit

Date: 2026-08-14 · lane: DRM.jl (Claude) · arc A2a of the `engine = "julia"`
catch-up campaign · read against drmTMB **0.7.0 @ `origin/main` `f5ec53634`**

## The finding

The campaign scoped "distributional outputs & adequacy" as five missing exports
(`fitted_distribution`, `centile_chart`, `exceedance`, `qq_plot`, `worm_plot`).
Reading drmTMB's actual sources shows that is the wrong shape for the work:
**they are not five independent capabilities, they are one.**

Call-site counts on `origin/main`:

| File | funnels through |
|---|---|
| `R/distributional-outputs.R` (`centile_chart`, `exceedance`) | `fitted_distribution()` ×18, `predict_parameters()` ×3 |
| `R/adequacy-plots.R` (`qq_plot`, `worm_plot`) | `residuals()` ×8, `fitted_distribution()` ×2 |
| `R/family-dpq.R` (`fitted_distribution`) | `predict_parameters()` ×5, `residuals()` ×3, `simulate()` ×2 |

`fitted_distribution.drmTMB()` returns `d`/`p`/`q` closures built from two
things:

1. `drm_family_dpq(object)` — density machinery derived **from the family**,
   entirely R-side. DRM.jl supplies nothing here.
2. `fitted_distribution_params(object, newdata, dpars, response)` — which calls

   ```r
   predict_parameters(object, newdata = newdata, dpar = request_dpars,
                      type = "response", include_newdata = FALSE)
   ```

   and assembles **one column per dpar**, aborting if the columns have
   inconsistent lengths.

**So the whole adequacy + distributional-outputs surface reduces to: can the R
side obtain per-observation, response-scale values for every dpar of a
Julia-engine fit?** Porting five functions to Julia would have been wasted work.

## What was missing

`drm_bridge()` marshalled `fitted`, `residuals`, `sigma`, and `corpairs` — but
no per-dpar block. `sigma` alone is not enough: the R side needs each dpar keyed
by its drmTMB name, with equal lengths.

## What landed

`_bridge_dpars(fit)` in `src/bridge.jl`, exposed as the payload key `"dpars"`.
It merges `fit.means` and `fit.scales` into `Dict{String,Vector{Float64}}` keyed
by dpar name, on the response scale.

Verified on a Gaussian location–scale fit (`y ~ x; sigma ~ x`, n = 80):

```
dpar names: ["mu", "sigma"]
  mu:    n=80  finite=true   ≈ fitted(native)
  sigma: n=80  finite=true   ≈ sigma(native)
all dpar columns same length: true (== nobs)
```

Guarded by `test/test_bridge.jl`, which asserts the exact invariant
`fitted_distribution_params()` enforces.

## Remaining for A2a

The in-sample case (R's `newdata = NULL`) is covered. Still open:

- **Fresh data.** `predict_parameters(fit, newdata; type = :response)` exists in
  `src/gaussian_core.jl:1203` but is not marshalled. The vignette records the
  gap: *fresh-data Julia prediction is currently limited to location parameters*.
- **`V_known`.** `fitted_distribution_params()` sets `params$V_known` from
  `known_v_diag(object)` / `drm_newdata_v_known()`. Meta-analysis cells need it.
- **`trials`.** Required for `binomial` / `beta_binomial` model types.
- **Scale/variance Wald blocks.** The vignette notes the Julia route returns only
  the mean fixed-effect covariance block for the Gaussian phylo route.
- **Non-Gaussian families.** `_bridge_dpars` reads `means`/`scales` generically,
  so families carrying extra shape parameters (NB2 size, Gamma shape, Beta φ,
  Tweedie p, ZI/hurdle) need checking that those land in one of those dicts —
  otherwise their dpar column will be silently absent.

## What this does not establish

A payload key is not a promoted capability. No registry row moves to `supported`
without a **native-vs-Julia same-target comparison** (matching coefficients and
logLik within the row's declared tolerance), run against an installed drmTMB
matching the anchor. The installed R package here is **0.6.0** while the anchor
is **0.7.0**, so that comparison is not yet runnable on this machine.
