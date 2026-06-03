# Decision: verified drmTMB API snapshot (parity source of truth)

**Date:** 2026-06-03 · **Resolves:** #7 · **Owner:** Shannon

The Rosetta page (`docs/src/rosetta.md`) carried best-effort R-side spellings,
some of which were guesses (and at least one wrong: `zero_one_inflated_beta`).
This note records the **authoritative drmTMB API**, read directly from the
package, so the R column on every parity page can be reconciled against a fixed
reference rather than re-guessed.

**Source.** github.com/itchyshin/drmTMB — `NAMESPACE` (exported symbols) plus
`_pkgdown.yml` (article/reference index). Verified 2026-06-03. Generated
outputs / metadata only; no GPL source vendored (license boundary holds).

## Family / model constructors (exact R spellings)

drmTMB-defined:

- `beta`
- `beta_binomial`
- `biv_gaussian`  (bivariate; paired with `bf(..., rho12 = ~ …)`)
- `lognormal`
- `nbinom2`
- `student`
- `truncated_nbinom2`
- `tweedie`
- `zero_one_beta`
- `cumulative_logit`

Base-R `stats` families reused (NOT redefined by drmTMB):

- `gaussian()`, `poisson()`, `Gamma()`, `binomial()`

## Formula helpers

- `bf`, `drm_formula`

## Structured-effect markers

- `animal`, `phylo`, `phylo_interaction`, `relmat`, `spatial`

## Meta-analysis

- `meta_V`, `meta_vcov_bivariate`
- deprecated: `meta_known_V`, `gr`

## Post-fit S3 methods

`coef`, `vcov`, `confint`, `logLik`, `nobs`, `deviance`, `df.residual`,
`fitted`, `residuals`, `predict`, `simulate`, `sigma`, `ranef`, `fixef`,
`summary`, `print`, `profile`, `is_converged`, `check_drm`, `weights`

## Other exported helpers

`corpair`, `corpairs`, `rho12`, `marginal_parameters`, `predict_parameters`,
`prediction_grid`, `profile_targets`, `structured_effects`, `drm_control`,
`plot_corpairs`, `plot_parameter_surface`

## DRM.jl parity gaps (checklist)

Accessors / helpers drmTMB exports that DRM.jl currently lacks (marked
"planned (parity gap)" in the Rosetta accessor table):

- [ ] `rho12(fit)` — bivariate residual correlation accessor
- [ ] `is_converged(fit)` — boolean convergence flag (DRM.jl has `check_drm`)
- [ ] `deviance(fit)`
- [ ] `df.residual(fit)`
- [ ] `summary(fit)` method (DRM.jl uses `show` / `coeftable`)
- [ ] `marginal_parameters(fit)`
- [ ] `predict_parameters(fit, newdata)`
- [ ] `prediction_grid(...)`
- [ ] `family(fit)` accessor
- [ ] `weights(fit)` accessor

Articles / markers DRM.jl still lacks:

- [ ] `bipartite-phylogenetic-interactions` article
- [ ] `phylo_interaction` structured-effect marker

This list is the parity checklist; close items via GitHub Issues as the
corresponding accessors / articles land.
