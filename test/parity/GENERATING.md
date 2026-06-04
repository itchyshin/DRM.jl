# Generating R-parity fixtures (maintainer recipe)

The parity suite (`runparity.jl`, gated by `DRM_PARITY_TESTS=1`) compares DRM.jl
against **committed drmTMB v0.1.3 reference numbers** — it never calls R at run
time. Those reference numbers are produced **out-of-band** by a maintainer with
local R + drmTMB using `gen_fixtures.R`. This file is the recipe.

## License boundary (read first)

- drmTMB is **GPL (≥3)**; DRM.jl is **MIT**.
- Commit **generated numeric outputs only** — coefficients, vcov, logLik, AIC,
  and the input data. Numbers are facts, not GPL code, so this stays MIT-clean.
- **Never vendor drmTMB source** (no `.R` / `.cpp` / `.hpp` copied or adapted)
  and do not paste drmTMB code into any fixture or doc.
- Record provenance (drmTMB version, the R call, seed, date) in a sidecar
  `expected.meta.toml`. Rose audits this boundary before every tag.

## One case = one folder

```
test/parity/fixtures/<slug>/
├── data.csv            # input data DRM.jl re-fits (header row, comma-separated)
├── expected.toml       # drmTMB reference numbers (format below)
└── expected.meta.toml  # provenance only — NO drmTMB code
```

Use the tutorial slug (`gaussian-locscale`, `robust-student`, …) so a parity
case lines up 1:1 with the article it backs. A folder name starting with `_`
(e.g. `_selftest`) is skipped by the runner.

## Generator

From the repository root:

```sh
Rscript --vanilla test/parity/gen_fixtures.R
```

The script writes the six canonical fixture folders:

- `gaussian-locscale`
- `gaussian-bivariate-rho12`
- `meta-analysis-V`
- `robust-student`
- `count-nbinom2`
- `proportion-beta`

The generator records the exact `drmTMB` package version in each
`expected.meta.toml`. To force the pinned tag without modifying the user's
normal R library, prepend a temporary library containing `drmTMB 0.1.3` before
sourcing the script.

## R snippet shape

The generator does this pattern for each case — run a fit, then write out the
numbers. Example for the Gaussian location–scale case:

```r
set.seed(1)
dat <- data.frame(x = rnorm(200))
dat$y <- 1.2 - 0.44 * dat$x + exp(0.12 + 0.09 * dat$x) * rnorm(200)

fit <- drmTMB(drm_formula(y ~ x, sigma ~ x), family = gaussian(), data = dat)

# write data.csv and the numeric outputs (coef / vcov / logLik / AIC / df / n)
# into expected.toml in the format below. Use the flat naming
# "<param>_<coefname>", e.g. "mu_(Intercept)", "sigma_x".
write.csv(dat, "data.csv", row.names = FALSE)
# ... emit expected.toml from coef(fit), vcov(fit), logLik(fit), AIC(fit) ...
```

For `meta-analysis-V`, local drmTMB uses `meta_V(V = v)` in the R call; DRM.jl's
runner uses the current Julia marker spelling `meta_V(v)`.

For NB2 and Student, generated coefficients are written on DRM.jl's public
working scale:

- NB2: drmTMB `log(σ)` becomes DRM.jl `log(θ) = -2 log(σ)`.
- Student: drmTMB `log(ν - 2)` becomes DRM.jl `log(ν)`.

The corresponding covariance rows/columns are transformed by the same
Jacobians before writing `[vcov]`.

## `expected.toml` format

```toml
[fit]
family  = "gaussian"
formula = "y ~ x; sigma ~ x"   # the two location–scale formulas, ';'-separated
loglik  = -256.51
aic     = 521.02
df      = 4
n       = 200

[coef]                          # flat "<param>_<coefname>" => point estimate
"mu_(Intercept)"    =  1.2031
"mu_x"              = -0.4417
"sigma_(Intercept)" =  0.1185
"sigma_x"           =  0.0902

[vcov]                          # optional; row-major matrix in `order`
order = ["mu_(Intercept)", "mu_x", "sigma_(Intercept)", "sigma_x"]
data  = [[ ... ], [ ... ], [ ... ], [ ... ]]

[tol]                           # optional per-case tolerance overrides
# atol_loglik = 1e-3
```

The runner reads `[fit].formula` to rebuild the DRM.jl `bf(@formula(y ~ x),
@formula(sigma ~ x))` bundle, re-fits by ML, and applies the tolerance table in
`../README.md`. The `coef` names must match `drm_coef_named(fit)` exactly.

## `expected.meta.toml` (provenance only)

```toml
drmtmb_version = "0.1.3"
generated_on   = "2026-06-02"
r_call         = "drmTMB(drm_formula(y ~ x, sigma ~ x), family = gaussian(), data = dat)"
seed           = 1
note           = "Generated outputs only; no drmTMB source vendored (MIT-clean)."
```
