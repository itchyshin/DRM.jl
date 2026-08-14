# FE non-Gaussian: the parity evidence the R gate asks for

Date: 2026-08-14 · lane: DRM.jl (Claude) · anchor: **installed drmTMB 0.6.0**
(the anchor the campaign GOAL names; its DEFER clause fences re-anchoring to 0.7.0)
· tool: [`tools/parity_fixture.R`](../../../tools/parity_fixture.R)

## The gate, confirmed

At this anchor `engine = "julia"` **refuses** fixed-effect non-Gaussian models:

```
poisson  GATE BLOCKS: `engine = "julia"` routes "poisson" models only with a `phylo()` random intercept.
nbinom2  GATE BLOCKS: `engine = "julia"` routes "nbinom2" models only with a `phylo()` random intercept.
```

The gate registry's own stated reason is the **absence of a coefficient-scale
parity test** (`base_unsupported_family`: *"no coefficient-scale parity test"*;
`plain_binomial_nonphylo`: *"direct Binomial evidence is not an R non-phylo
bridge claim"*), with `review_due` = *"before 0.2.0 bridge promotion"*. The block
is claim discipline, not a missing capability.

## The evidence

Native TMB vs the DRM.jl bridge payload — the payload the bridge *would* return
if the gate opened — on the same seeded data, tolerance 1e-4:

| cell | max abs coef diff | logLik diff | verdict |
|---|---|---|---|
| `fe_poisson` | 1.03e-12 | 1.71e-13 | **PARITY_PASS** |
| `fe_nbinom2` | 2.79e-08 | 2.27e-13 | **PARITY_PASS** |
| `fe_gamma` (log link) | 3.91e-06 | 2.75e-09 | **PARITY_PASS** |

Gaussian cells, which the gate already admits, for calibration:

| cell | max abs coef diff | logLik diff | verdict |
|---|---|---|---|
| `base_gaussian_location_scale` | 4.56e-06 | 4.58e-09 | **PARITY_PASS** |
| `base_gaussian_intercept_only` | 2.49e-10 | 5.26e-13 | **PARITY_PASS** |

The FE non-Gaussian agreement is **tighter than** the already-admitted Gaussian
location-scale cell.

Reproduce:

```bash
DRM_JL_PATH=$(pwd) Rscript tools/parity_fixture.R
```

## What this licenses, and what it does not

**Licenses:** opening the FE non-Gaussian route in the R gate for
Poisson / NB2 / Gamma(log), on coefficient-and-logLik parity evidence, which is
exactly what `review_due` asks for.

**Does not license:** any claim about intervals, coverage, or interval
reliability — only point estimates and logLik were compared. Nor Binomial or
Beta, which were not run here. Nor any RE/phylo cell. Nor promotion of a row to
`supported` without the corresponding R-side gate change and its own tests.

**The gate edit itself is a drmTMB change** and belongs to the narrow lane
(`R/julia-bridge.R` + `tests/testthat/test-julia-*` + `vignettes/julia-engine.Rmd`).
It is not made here: that repo has 9 live lanes and an open 0.7.0 release slice,
so the timing is the owner's call.

## RESOLUTION — the gate edit is NOT ours to make (verified 2026-08-14)

Before editing drmTMB's gate, I checked whether the change already existed. **It
does.** On `origin/main`, `drm_julia_family_tag()` (R/julia-bridge.R ~line 542):

```r
wfg_fe <- c("gaussian", "biv_gaussian", "student", "lognormal",
            "poisson", "nbinom2", "gamma", "beta", "binomial")
if (family_type %in% wfg_fe) {
  return(family_type)
}
```

with the accompanying comment:

> *Workflow G fixed-effect cohort families (Gaussian, bivariate Gaussian,
> Student-t, lognormal, Poisson, NB2, Gamma, Beta, Binomial) **route
> unconditionally** once live coefficient-scale parity exists (#499).*

The `"routes <family> models only with a phylo() random intercept"` abort is
still in the file but is **unreachable for those nine families** — it fires only
for a `phylo_only` family that is not in `wfg_fe`.

**So fixed-effect Poisson / NB2 / Gamma / Beta / Binomial already work through
`engine = "julia"` on drmTMB main.** PR #499 (2026-08-09) delivered it five days
before this campaign began. The refusal reproduced above comes from the
**installed 0.6.0** package, not from drmTMB's current code.

### What that means

- The campaign HEADLINE — *"a plain Poisson/NB2/Gamma/Beta/Binomial GLM CANNOT
  use the Julia engine"* — is **false on drmTMB main** and true only against the
  stale installed build. It is not an actionable code change.
- Writing the gate edit anyway would duplicate an existing implementation in the
  same file: strictly worse than either version alone.
- The parity numbers above retain their value: they **independently corroborate
  the coefficient-scale parity that #499 cited as its own justification**, on
  cells (`fe_poisson`, `fe_nbinom2`, `fe_gamma`) that #499 admitted. They are
  reusable as the standing regression for that route.
- The only action that changes what *this machine* can do is installing drmTMB
  0.7.0 from `origin/main` — an R-library rebuild, and the owner's call.
