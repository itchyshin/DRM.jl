## gen_bridge_formula_fixtures.R -- generate committed drmTMB numeric parity
## fixtures for the `drm_bridge` R-formula constructs landed by #467:
## `scale()`, `I()`, `factor()`, general `- term` removal, and `(...)^k`
## crossing. Maintainer-only (local R + drmTMB); never required at test time.
## `runparity_bridge_formula.jl` consumes only the generated CSV/TOML.
##
## License boundary: writes generated data/numbers only, never drmTMB source
## (see test/parity/README.md).
##
## Coefficient names: `drm_bridge`'s formula translation materialises
## `scale()`/`I()`/`factor()` into synthetic columns (`__bridge_<kind>_<n>`,
## in formula order) rather than keeping R's own term text, and StatsModels
## spells an interaction `x:z` as `x & z`. Each fixture below carries an
## EXPLICIT R-name -> bridge-name map so `expected.toml` is keyed exactly as
## `drm_bridge(...)`'s output will be -- both sides fit the SAME model, only
## the coefficient label differs by convention.

suppressPackageStartupMessages(library(drmTMB))

repo_root <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg)) {
    return(normalizePath(file.path(dirname(sub("^--file=", "", file_arg[[1]])), "..", "..")))
  }
  normalizePath(getwd())
}

toml_string <- function(x) paste0('"', gsub('"', '\\"', as.character(x), fixed = TRUE), '"')
toml_num <- function(x) {
  if (!is.finite(x)) stop("cannot write non-finite TOML number")
  format(as.numeric(x), digits = 17, scientific = TRUE, trim = TRUE)
}
toml_matrix <- function(M) {
  rows <- apply(M, 1, function(row) paste0("[", paste(vapply(row, toml_num, character(1)), collapse = ", "), "]"))
  paste0("[", paste(rows, collapse = ", "), "]")
}
toml_array <- function(xs) paste0("[", paste(vapply(xs, toml_string, character(1)), collapse = ", "), "]")

## `name_map`: named character vector, `names(name_map)` are drmTMB's own
## per-parameter coefficient names (as returned by `names(coef(fit)$mu)`,
## `names(coef(fit)$sigma)`, ...); values are the bridge's flat
## `"<param>_<coefname>"` key. Every coefficient drmTMB reports must appear.
write_bridge_fixture <- function(slug, data, formula_bridge_text, family_label,
                                  fit, name_map, r_call, seed, note = "") {
  dir <- file.path(repo_root(), "test", "parity", "fixtures", slug)
  if (dir.exists(dir)) unlink(dir, recursive = TRUE)
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  write.csv(data, file.path(dir, "data.csv"), row.names = FALSE)

  cf <- coef(fit)
  r_flat <- character(0)
  for (param in names(cf)) {
    vals <- as.numeric(cf[[param]])
    names(vals) <- paste0(param, ":", names(cf[[param]]))
    r_flat <- c(r_flat, vals)
  }
  missing_map <- setdiff(names(r_flat), names(name_map))
  if (length(missing_map)) {
    stop("write_bridge_fixture(", slug, "): name_map is missing entries for: ",
         paste(missing_map, collapse = ", "))
  }
  bridge_names <- unname(name_map[names(r_flat)])
  if (anyDuplicated(bridge_names)) {
    stop("write_bridge_fixture(", slug, "): name_map produced duplicate bridge names")
  }
  coefs <- setNames(as.numeric(r_flat), bridge_names)

  V <- vcov(fit)
  Vorder_r <- rownames(V)   # drmTMB's own "param:coefname" scheme, same keying as name_map
  missing_v <- setdiff(Vorder_r, names(name_map))
  if (length(missing_v)) {
    stop("write_bridge_fixture(", slug, "): name_map is missing vcov entries for: ",
         paste(missing_v, collapse = ", "))
  }
  vorder_bridge <- unname(name_map[Vorder_r])

  ll <- as.numeric(logLik(fit))
  df <- as.integer(attr(logLik(fit), "df"))
  n <- as.integer(attr(logLik(fit), "nobs"))
  if (is.na(n)) n <- nobs(fit)

  path <- file.path(dir, "expected.toml")
  con <- file(path, "w")
  on.exit(close(con), add = TRUE)
  writeLines(c(
    "[fit]",
    paste0("family = ", toml_string(family_label)),
    paste0("formula = ", toml_string(formula_bridge_text)),
    paste0("loglik = ", toml_num(ll)),
    paste0("aic = ", toml_num(AIC(fit))),
    paste0("df = ", df),
    paste0("n = ", n),
    "",
    "[coef]"
  ), con)
  for (nm in sort(names(coefs))) {
    writeLines(paste0(toml_string(nm), " = ", toml_num(coefs[[nm]])), con)
  }
  writeLines(c(
    "",
    "[vcov]",
    paste0("order = ", toml_array(vorder_bridge)),
    paste0("data = ", toml_matrix(V)),
    "",
    "[tol]",
    "atol_loglik = 1e-3",
    "atol_aic = 1e-3"
  ), con)

  meta_note <- "Generated outputs only; no drmTMB source vendored (MIT-clean)."
  if (nzchar(note)) meta_note <- paste(meta_note, note)
  writeLines(c(
    paste0("drmtmb_version = ", toml_string(as.character(utils::packageVersion("drmTMB")))),
    paste0("generated_on = ", toml_string(as.character(Sys.Date()))),
    paste0("r_call = ", toml_string(r_call)),
    paste0("seed = ", as.integer(seed)),
    paste0("note = ", toml_string(meta_note))
  ), file.path(dir, "expected.meta.toml"))
}

## Shared generator for every case below: one continuous covariate `x` with a
## true quadratic mean, a second independent covariate `z`, and a 3-level
## factor `grp` -- exercises scale()/I()/factor()/-term/^k from one seed. Each
## `generate_*()` below subsets `make_data()`'s columns to ONLY what its
## formula references before writing the CSV: `test/parity/loadfixture.jl`'s
## `load_data()` uses `readdlm`, which returns `Matrix{Any}` for the WHOLE
## file the moment any one column is non-numeric (here, `grp`) -- so an
## otherwise-numeric `x`/`z` column would silently come back as `Vector{Any}`
## in Julia, and StatsModels would then (correctly, given that type) treat it
## as categorical instead of continuous. Keeping unused columns out of each
## fixture's CSV sidesteps that `readdlm` quirk without touching the shared
## loader (used by every other fixture too).
make_data <- function(seed) {
  set.seed(seed)
  n <- 150
  x <- rnorm(n)
  z <- rnorm(n)
  grp <- rep(c("hi", "lo", "mid"), length.out = n)
  y <- 1 + 0.5 * x + 0.3 * x^2 + rnorm(n, sd = 0.15)
  data.frame(y = y, x = x, z = z, grp = grp)
}

generate_scale <- function() {
  seed <- 20260824
  dat <- make_data(seed)[, c("y", "x")]   # only what the formula references
  fit <- drmTMB(drm_formula(y ~ scale(x), sigma ~ 1), family = gaussian(), data = dat)
  name_map <- c(
    "mu:(Intercept)"    = "mu_(Intercept)",
    "mu:scale(x)"       = "mu___bridge_scale_1",
    "sigma:(Intercept)" = "sigma_(Intercept)"
  )
  write_bridge_fixture(
    "bridge-scale", dat, "y ~ scale(x); sigma ~ 1", "gaussian", fit, name_map,
    "drmTMB(drm_formula(y ~ scale(x), sigma ~ 1), family = gaussian(), data = dat)",
    seed, "drm_bridge #467: scale() materialises (x - mean(x)) / sd(x) as `__bridge_scale_1`."
  )
}

generate_I <- function() {
  seed <- 20260824
  dat <- make_data(seed)[, c("y", "x")]   # only what the formula references
  fit <- drmTMB(drm_formula(y ~ x + I(x^2), sigma ~ 1), family = gaussian(), data = dat)
  name_map <- c(
    "mu:(Intercept)"    = "mu_(Intercept)",
    "mu:x"              = "mu_x",
    "mu:I(x^2)"         = "mu___bridge_I_1",
    "sigma:(Intercept)" = "sigma_(Intercept)"
  )
  write_bridge_fixture(
    "bridge-I", dat, "y ~ x + I(x^2); sigma ~ 1", "gaussian", fit, name_map,
    "drmTMB(drm_formula(y ~ x + I(x^2), sigma ~ 1), family = gaussian(), data = dat)",
    seed, "drm_bridge #467: I(x^2) evaluated via the safe restricted-arithmetic evaluator, materialised as `__bridge_I_1`."
  )
}

generate_factor <- function() {
  seed <- 20260824
  dat <- make_data(seed)[, c("y", "grp")]   # only what the formula references
  fit <- drmTMB(drm_formula(y ~ factor(grp), sigma ~ 1), family = gaussian(), data = dat)
  name_map <- c(
    "mu:(Intercept)"    = "mu_(Intercept)",
    "mu:factor(grp)lo"  = "mu___bridge_factor_1: lo",
    "mu:factor(grp)mid" = "mu___bridge_factor_1: mid",
    "sigma:(Intercept)" = "sigma_(Intercept)"
  )
  write_bridge_fixture(
    "bridge-factor", dat, "y ~ factor(grp); sigma ~ 1", "gaussian", fit, name_map,
    "drmTMB(drm_formula(y ~ factor(grp), sigma ~ 1), family = gaussian(), data = dat)",
    seed, "drm_bridge #467: factor(grp) materialised as a Vector{Any} copy (natural-order categorical dispatch), `__bridge_factor_1`; baseline level `hi` (sort(unique(.))'s first) matches R's contr.treatment default."
  )
}

generate_minus_term <- function() {
  seed <- 20260824
  dat <- make_data(seed)[, c("y", "x", "z")]   # only what the formula references
  fit <- drmTMB(drm_formula(y ~ x + z - z, sigma ~ 1), family = gaussian(), data = dat)
  name_map <- c(
    "mu:(Intercept)"    = "mu_(Intercept)",
    "mu:x"              = "mu_x",
    "sigma:(Intercept)" = "sigma_(Intercept)"
  )
  write_bridge_fixture(
    "bridge-minus-term", dat, "y ~ x + z - z; sigma ~ 1", "gaussian", fit, name_map,
    "drmTMB(drm_formula(y ~ x + z - z, sigma ~ 1), family = gaussian(), data = dat)",
    seed, "drm_bridge #467: general `- term` removal (z listed then removed); equivalent to `y ~ x`."
  )
}

generate_power <- function() {
  seed <- 20260824
  dat <- make_data(seed)[, c("y", "x", "z")]   # only what the formula references
  fit <- drmTMB(drm_formula(y ~ (x + z)^2, sigma ~ 1), family = gaussian(), data = dat)
  name_map <- c(
    "mu:(Intercept)"    = "mu_(Intercept)",
    "mu:x"              = "mu_x",
    "mu:z"              = "mu_z",
    "mu:x:z"            = "mu_x & z",
    "sigma:(Intercept)" = "sigma_(Intercept)"
  )
  write_bridge_fixture(
    "bridge-power", dat, "y ~ (x+z)^2; sigma ~ 1", "gaussian", fit, name_map,
    "drmTMB(drm_formula(y ~ (x + z)^2, sigma ~ 1), family = gaussian(), data = dat)",
    seed, "drm_bridge #467: (...)^k crossing expanded to main effects + interactions before @formula; `x:z` is StatsModels' `x & z`."
  )
}

.parity_only <- strsplit(Sys.getenv("DRM_PARITY_ONLY", unset = ""), ",", fixed = TRUE)[[1]]
.parity_only <- trimws(.parity_only[.parity_only != ""])
.run <- function(slug, fn) if (length(.parity_only) == 0L || slug %in% .parity_only) fn()

.run("bridge-scale", generate_scale)
.run("bridge-I", generate_I)
.run("bridge-factor", generate_factor)
.run("bridge-minus-term", generate_minus_term)
.run("bridge-power", generate_power)

message("Generated drm_bridge formula-construct parity fixtures under test/parity/fixtures/bridge-*")
