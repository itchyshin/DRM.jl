All facts confirmed. The `profile.engine` column is `julia_profile_result`, `miss_control(response = "include")` is the form, the four parm labels are `sd:{mu1,mu2,sigma1,sigma2}:phylo(1 | species)`, the multi-row table carries `profile.boundary`, and a collapsed axis returns `lower = 0`. I have everything needed to write the section in the article's exact voice.

Here is the Rmd block to insert into `vignettes/julia-engine.Rmd` (place it after the "Profile and bootstrap direction" section, before "Contributor workflow"):

```markdown
## Bivariate boundary-honest among-axis SD intervals

The phylogenetic targets above are all univariate: one residual phylogenetic SD
in one `mu` model. The bridge now extends the same boundary-honest interval
discipline to the bivariate Gaussian phylogenetic cell, where the structured
effect is a 4x4 among-axis covariance over the two means and the two log scales.
Here the targets are four among-axis standard deviations, `sd_mu1`, `sd_mu2`,
`sd_sigma1`, and `sd_sigma2`: the among-lineage SD of each axis after shared
ancestry is modelled.

This is the cell where Wald intervals are not just imprecise but unavailable.
An among-axis SD is a non-negative variance component, so its true value can sit
on the boundary at zero. When one axis collapses, the fitted covariance is
near-singular, the Hessian at the optimum stops being positive-definite
(`pdHess = FALSE`), and the native engine cannot invert it to form a symmetric
Wald interval. In that state, native `engine = "tmb"` fits the bivariate
covariance blocks but reports `derived_interval_unavailable` for the
random-effect SDs rather than returning a Wald interval that would be wrong. The
Julia engine sits on top of that fit to supply profile and bootstrap intervals
that the Wald route cannot.

The division of labour is the same as for the univariate cell. Native
`engine = "tmb"` fits the model. The Julia engine adds the boundary-honest
intervals: `confint()` on an `engine = "julia"` bivariate fit returns one row per
admitted among-axis SD, with a collapsed axis reported as `lower = 0` rather than
as a spuriously narrow Wald band.

```{r biv-phylo-fit-shape, eval = FALSE}
bform_biv_phylo <- bf(
  mu1 = leaf_area ~ soil_moisture + phylo(1 | species, tree = tree),
  mu2 = root_mass ~ soil_moisture + phylo(1 | species, tree = tree),
  sigma1 = ~ 1,
  sigma2 = ~ 1,
  rho12 = ~ 1
)

fit_biv_phylo_julia <- drmTMB(
  bform_biv_phylo,
  family = biv_gaussian(),
  data = plant_traits,
  engine = "julia"
)
```

With no `parm`, `confint()` returns all four admitted among-axis SD targets as a
multi-row table. Both `method = "profile"` (the default for variance components)
and `method = "bootstrap"` are available:

```{r biv-phylo-confint-example, eval = FALSE}
confint(
  fit_biv_phylo_julia,
  method = "profile",
  threads = TRUE
)

confint(
  fit_biv_phylo_julia,
  parm = "sd:mu1:phylo(1 | species)",
  method = "bootstrap",
  R = 999,
  seed = 20260609,
  threads = TRUE
)
```

The profile rows are real profile likelihood, not a bootstrap fallback: the
table reports `profile.engine = "julia_profile_result"` and a per-row
`profile.boundary` flag. A row whose axis has collapsed to the boundary returns
`lower = 0` with the upper end carried out as far as the profile remains flat,
and `profile.boundary = TRUE`. This is the boundary-honest behaviour: the
interval admits that the data place no positive lower bound on that axis, instead
of reporting a symmetric Wald band that the non-invertible Hessian could not have
produced.

| Among-axis SD | `parm` label | Reported when the axis collapses |
| --- | --- | --- |
| `sd_mu1` | `sd:mu1:phylo(1 | species)` | `lower = 0`, profile carried to flatness, `profile.boundary = TRUE` |
| `sd_mu2` | `sd:mu2:phylo(1 | species)` | `lower = 0`, profile carried to flatness, `profile.boundary = TRUE` |
| `sd_sigma1` | `sd:sigma1:phylo(1 | species)` | `lower = 0`, profile carried to flatness, `profile.boundary = TRUE` |
| `sd_sigma2` | `sd:sigma2:phylo(1 | species)` | `lower = 0`, profile carried to flatness, `profile.boundary = TRUE` |

### With missing responses

The bivariate among-axis interval path also runs when part of one response is
missing. Because the bivariate Julia route uses a per-cell observed mask, a
`mu1` value can be `NA` for a tip while that tip's `mu2` value is still used, and
the tree is kept whole. The admitted route is `missing = miss_control(response =
"include")`, which fits the observed data rather than dropping or imputing rows:

```{r biv-phylo-missing-shape, eval = FALSE}
plant_traits$leaf_area[sample(nrow(plant_traits), 0.25 * nrow(plant_traits))] <- NA

fit_biv_phylo_miss <- drmTMB(
  bform_biv_phylo,
  family = biv_gaussian(),
  data = plant_traits,
  missing = miss_control(response = "include"),
  engine = "julia"
)

confint(fit_biv_phylo_miss, method = "profile", threads = TRUE)
```

This is the only admitted missing-data route through the bridge. `response =
"include"` is admitted for Gaussian and bivariate Gaussian responses; predictor
missingness, imputation, and other `miss_control()` settings stay TMB-native and
still error early.

### Status and honest limits

| Model cell | Native `engine = "tmb"` | Julia engine adds |
| --- | --- | --- |
| Bivariate Gaussian `phylo(1 | species)` among-axis SDs | fits the 4x4 covariance blocks; Wald SD intervals are `derived_interval_unavailable` when `pdHess = FALSE` | profile (default) and bootstrap intervals for the four among-axis SDs, with `lower = 0` at a collapsed axis |
| Same cell with `missing = miss_control(response = "include")` | observed-data fit | same four boundary-honest among-axis SD intervals on the observed-data fit |

The principle is the same one used for fixed effects elsewhere in this article.
Wald is enough for fixed effects unless `pdHess = FALSE`; for random-effect
variance components such as these among-axis SDs, use profile (default) or
bootstrap, and refuse Wald rather than report an interval the Hessian could not
support. The bridge gives Wald for the fixed effects, profile or bootstrap for
the SDs, and correctly declines Wald for the SDs.

Two limits stay explicit. The boundary call itself, `lower = 0` at a collapsed
axis, is the robust, verified part. But profile coverage for a small number of
tips near the boundary is irreducibly uncertain, so this route does not claim
calibrated small-sample coverage. Bootstrap undercoverage on the scale axes is
measured rather than assumed, at roughly 0.52 in the runs to date, so prefer the
profile default for these targets and read a bootstrap interval as a
simulation-based cross-check, not a calibrated band. As elsewhere, this is
endpoint-honesty for an admitted cell, not a coverage study.
```

Key facts the draft pins to the verified contract:
- Targets are the four among-axis SDs `sd_mu1`/`sd_mu2`/`sd_sigma1`/`sd_sigma2`; R `parm` labels are `paste0("sd:", dpar, ":", term)` -> `sd:mu1:phylo(1 | species)` etc. (`drmTMB/R/julia-bridge.R:1115`).
- `confint(fit, parm = NULL)` returns the four-row multi table; collapsed axis -> `lower = 0`, `profile.boundary = TRUE`, `profile.engine = "julia_profile_result"` (real `profile_sigma_a`, not a bootstrap fallback) (`julia-bridge.R:1660`, `DRM.jl/src/profile_q4_phylo.jl`, `DRM.jl/src/bridge.jl:453`).
- Missing path is exactly `missing = miss_control(response = "include")`, admitted for `biv_gaussian` via the per-cell observed mask (`julia-bridge.R` missing-guard diff; `miss_control` in `R/missing-data.R:37`).
- Native `engine = "tmb"` fits the covariance blocks but yields `derived_interval_unavailable` for the SDs at `pdHess = FALSE`; Julia adds the boundary CIs.
- All chunks are `eval = FALSE` (JuliaCall/branch-dependent), matching the article's existing convention.
- Coverage hedges (profile small-p uncertain; bootstrap scale-axis undercoverage ~0.52 measured; boundary call is the robust verified part) are stated, matching the article's "this is X, not a coverage study" voice; no "calibrated" claim is made.

Insertion point: after the "Profile and bootstrap direction" section (ends `julia-engine.Rmd:843`), before "## Contributor workflow" (`:845`).