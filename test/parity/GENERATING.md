# Generating R-parity fixtures (maintainer recipe)

The parity suite (`runparity.jl`, gated by `DRM_PARITY_TESTS=1`) compares DRM.jl
against **committed drmTMB v0.1.3 reference numbers** — it never calls R at run
time. Those reference numbers are produced **out-of-band** by a maintainer with
local R + drmTMB, then copied in. This file is the recipe.

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

## R snippet shape (maintainer machine, has drmTMB)

Run a fit, then write out the numbers — example for the Gaussian
location–scale case:

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
