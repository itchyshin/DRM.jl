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

## A dpar is not `fitted()` — three instances found

`fitted_distribution()` feeds the dpar straight into a density. For a mixture or
known-variance family the dpar and the fitted value are **different quantities**,
both in range, so shipping the wrong one is silently wrong rather than an error.
Checked every family DRM.jl implements against drmTMB's dpar table
(`R/family-dpq.R`):

| family | drmTMB dpars | DRM.jl status |
|---|---|---|
| gaussian / lognormal / gamma / beta / nbinom2 / beta_binomial | `mu`, `sigma` | agrees |
| poisson / binomial / cumulative_logit | `mu` | agrees |
| student / tweedie / skew_normal | `mu`, `sigma`, `nu` | agrees |
| truncated_nbinom2 | `mu`, `sigma` | agrees — `means[:mu]` is the **untruncated** mean, which is the dpar |
| **zero_one_beta** | `mu`, `sigma`, `zoi`, `coi` | **FIXED** — see below |
| zi_/hurdle_ families | — | not implemented in DRM.jl |

**Fixed: `zero_one_beta`.** drmTMB's `mu` dpar is the interior beta component
mean `plogis(eta_mu)`, which it feeds to `drm_beta_shapes(mu, sigma)`. DRM.jl
stores that as `scales[:beta_mu]` and puts the *unconditional* mean
`(1 - zoi)·mu + zoi·coi` — correct for `fitted()` — in `means[:mu]`. The payload
was shipping the unconditional mean as `mu`. `_bridge_dpars` now maps
`mu ← beta_mu` and drops the non-drmTMB name. Guarded in `test/test_bridge.jl`,
which asserts `dpars["mu"] != fitted` on a fixture with real boundary mass.

**Fixed: `trials`.** It sat in `scales` and so leaked into the dpar set, but
drmTMB's binomial dpar set is `mu` alone — `fitted_distribution_params()`
attaches `params$trials` itself as per-row context. It now ships as its own
payload key, and families without a binomial denominator carry no key at all.

**NOT fixed — needs an owner decision: `meta_V` / known sampling variance.**
`src/gaussian_meta.jl` sets `scales[:sigma] = sqrt(v_i + σ²)` — the **total** SD.
drmTMB's `sigma` dpar for a meta model is the between-study heterogeneity σ
alone, with `V_known` supplied separately and the density forming
`sqrt(V_known + sigma²)` itself. Shipping the total *and* a `V_known` would
**double-count the sampling variance**.

The clean fix is for the meta fit to retain σ and `v` separately, but the obvious
route — adding keys to `fit.scales` — is a **public API break**: `sigma(fit)`
(`src/gaussian_core.jl:975`) returns the bare vector only when `scales` has
exactly one key, so any extra key silently turns `sigma()` into a `Dict` for
every meta fit. That is a deliberate design decision about `sigma()`'s contract,
not a bridge detail, so it is surfaced rather than forced. **Until it is
resolved, the meta cell must not be admitted for post-fit** — `V_known` is
absent and `dpars["sigma"]` is the wrong quantity for the density.

## Remaining for A2a

The in-sample case (R's `newdata = NULL`) is covered. Still open:

- ~~**Fresh data.**~~ **DONE.** `drm_bridge(...; newdata = ...)` now adds
  `"dpars_newdata"` via `predict_parameters(fit, nd; type = :response)`. It
  reads the FORMULA rather than stored `means`/`scales`, so each parameter is
  its own linear predictor through its link — already the dpar drmTMB wants (for
  `zero_one_beta`, `mu` here is `plogis(eta_mu)` with no override needed). The
  key is absent unless `newdata` is passed, and the in-sample block is
  unchanged. This closes the vignette's *"fresh-data Julia prediction is
  currently limited to location parameters"* — `sigma` now comes through on the
  response scale. Guarded in `test/test_bridge.jl`.
- **`V_known`.** Blocked on the `sigma()`-contract decision above.
- **Scale/variance Wald blocks.** The vignette notes the Julia route returns only
  the mean fixed-effect covariance block for the Gaussian phylo route.
- **Non-Gaussian families — checked, four clear.** Measured 2026-08-14 (n = 120,
  `y ~ x`):

  | family | dpars emitted | lengths |
  |---|---|---|
  | poisson | `mu` | 120 — correct, one dpar |
  | nbinom2 | `mu`, `sigma` | 120 |
  | gamma | `mu`, `sigma` | 120 |
  | beta | `mu`, `sigma` | 120 |

  The naming also matches drmTMB, which likewise exposes the dispersion as
  family `sigma` (its 0.7.0 NEWS: *"Family `sigma` … controls `phi = sigma^(-2)`"*),
  consistent with `AGENTS.md`'s `sigma ↔ phi` parity mapping.

  **Extra-shape families — checked, none drop a column.** The silent-absence
  risk is closed:

  | family | dpars emitted |
  |---|---|
  | lognormal | `mu`, `sigma` |
  | student | `mu`, `nu`, `sigma` |
  | tweedie | `mu`, `nu`, `sigma` |
  | zeroonebeta | `mu`, `sigma`, `zoi`, `coi`, `beta_mu` |

  All columns length `n`. Two naming items remain for the R-side mapping, and
  they are naming only, not missing data:

  - `zeroonebeta` emits **`beta_mu`**, which is not a drmTMB dpar name — it needs
    an explicit map (or exclusion) before that cell's post-fit can be admitted.
  - Tweedie's power parameter is `nu` here; `AGENTS.md` lists `nu` in the
    shared grammar, so this is expected to map straight through — confirm
    against drmTMB's Tweedie dpar list before admitting that cell.

  Observed in passing: the A1 guard fired on one of these fits with
  `rcond = 0.0` — a genuinely singular Hessian caught and warned rather than
  crashing, which is the guard working as intended on real data.

## What this does not establish

A payload key is not a promoted capability. No registry row moves to `supported`
without a **native-vs-Julia same-target comparison** (matching coefficients and
logLik within the row's declared tolerance), run against an installed drmTMB
matching the anchor. The installed R package here is **0.6.0** while the anchor
is **0.7.0**, so that comparison is not yet runnable on this machine.
