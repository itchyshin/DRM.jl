## gen_gaussian_phylo_mean.R -- generate the gaussian_phylo_mean Route A fixture.
##
## Maintainer machine with local R + installed drmTMB. Writes generated
## data/numbers only into test/parity/phylo-mean/gaussian-phylo-mean/.
## Never edits the shared drmTMB checkout. Never vendors drmTMB source.
## Do not edit gen_fixtures.R / runparity.jl.
##
## G0: clone live Route A (seed 111, n_tip=18, n_each=1, ML, sigma ~ 1).
## If that cell fails to converge, shrink/reseed and record — do not
## silently escalate compute.

suppressPackageStartupMessages({
  library(drmTMB)
  library(ape)
})

repo_root <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg)) {
    return(normalizePath(file.path(dirname(sub("^--file=", "", file_arg[[1]])), "..", "..")))
  }
  normalizePath(getwd())
}

toml_string <- function(x) {
  paste0('"', gsub('"', '\\"', as.character(x), fixed = TRUE), '"')
}

toml_num <- function(x) {
  if (!is.finite(x)) stop("cannot write non-finite TOML number: ", x)
  format(as.numeric(x), digits = 17, scientific = TRUE, trim = TRUE)
}

toml_bool <- function(x) {
  if (isTRUE(x)) return("true")
  if (identical(x, FALSE)) return("false")
  "\"NA\""
}

flat_coef <- function(fit) {
  cf <- coef(fit)
  out <- numeric()
  for (param in names(cf)) {
    vals <- as.numeric(cf[[param]])
    nm <- names(cf[[param]])
    if (is.null(nm)) nm <- as.character(seq_along(vals))
    names(vals) <- paste0(param, "_", nm)
    out <- c(out, vals)
  }
  names(out) <- sub(":", "_", names(out), fixed = TRUE)
  out
}

extract_pdHess <- function(fit) {
  tryCatch({
    if (!is.null(fit$sdr) && !is.null(fit$sdr$pdHess)) return(isTRUE(fit$sdr$pdHess))
    if (!is.null(fit$sdreport) && !is.null(fit$sdreport$pdHess)) return(isTRUE(fit$sdreport$pdHess))
    NA
  }, error = function(e) NA)
}

## The row's DEFINING quantity: the fitted phylogenetic SD. Read from the
## sdreport's FINAL fixed-parameter vector (matches `coef(fit)`) -- NOT
## `fit$obj$par`, which holds the fitter's STARTING values and never updates
## post-optimisation (verified 2026-08-24: for this cell `obj$par["log_sd_phylo"]`
## reads -1.97, the start; `sdr$par.fixed["log_sd_phylo"]` reads -11.92, the
## actual MLE -- an 8-log-unit gap). This is on drmTMB's CORRELATION-SCALE
## convention: drmTMB standardises the phylogenetic covariance via
## `ape::vcv(tree, corr = TRUE)` internally, so the value does not depend on
## the tree's raw branch-length height. Cross-checked against the public
## `fit$sdpars$mu` field, which must agree exactly.
extract_sd_phylo <- function(fit, term_label) {
  nm <- names(fit$sdr$par.fixed)
  idx <- which(nm == "log_sd_phylo")
  if (length(idx) != 1) {
    stop("expected exactly one 'log_sd_phylo' fixed parameter, found ", length(idx))
  }
  sd_from_sdr <- as.numeric(exp(fit$sdr$par.fixed[idx]))
  sd_from_sdpars <- tryCatch(as.numeric(fit$sdpars$mu[[term_label]]), error = function(e) NA_real_)
  if (is.finite(sd_from_sdpars) &&
      !isTRUE(all.equal(sd_from_sdr, sd_from_sdpars, tolerance = 1e-8))) {
    stop("sd_phylo mismatch: sdr$par.fixed gives ", sd_from_sdr,
         " but sdpars$mu gives ", sd_from_sdpars)
  }
  sd_from_sdr
}

## Maximum root-to-tip path length -- the tip variance the tree implies when
## DRM.jl's `re_sd()` (RAW branch-length scale) is compared to drmTMB's
## CORRELATION-scale `sd_phylo`: species_corr_scale == raw * sqrt(tree_height).
tree_height <- function(tree) {
  max(ape::node.depth.edgelength(tree)[seq_along(tree$tip.label)])
}

extract_interval_status <- function(fit) {
  ci <- tryCatch(confint(fit, method = "wald"), error = function(e) e)
  if (inherits(ci, "error")) {
    return(paste0("wald_unavailable:", conditionMessage(ci)))
  }
  if (is.null(ci)) return("wald_unavailable")
  nums <- suppressWarnings(as.numeric(as.matrix(ci)))
  if (length(nums) && all(is.finite(nums))) return("wald_finite")
  "wald_unavailable"
}

## Live Route A clone (drmTMB test-julia-tmb-parity.R drm_parity_fit_route_a).
simulate_route_a <- function(seed, n_tip) {
  set.seed(as.integer(seed))
  n <- as.integer(n_tip)
  tree <- ape::rcoal(n)
  species <- tree$tip.label
  dat <- data.frame(
    species = sample(species),
    x = seq(-1, 1, length.out = n)
  )
  phy <- stats::setNames(stats::rnorm(n, 0, 0.45), species)
  dat$y <- 0.4 + 0.7 * dat$x + phy[dat$species] + stats::rnorm(n, 0, 0.35)
  list(data = dat, tree = tree, seed = as.integer(seed), n_tip = n, n_each = 1L, with_x = TRUE)
}

## S1 fallback: bridge-smoke class (n_tip=16, n_each=4) if 1-obs/tip fails.
simulate_fallback <- function(seed, n_tip, n_each) {
  set.seed(as.integer(seed))
  tree <- ape::rcoal(as.integer(n_tip))
  tree$tip.label <- paste0("sp_", seq_len(n_tip))
  A <- ape::vcv(tree, corr = TRUE)
  L <- t(chol(A))
  u <- as.numeric(L %*% stats::rnorm(n_tip, 0, 0.45))
  tip <- rep(seq_len(n_tip), each = as.integer(n_each))
  n <- length(tip)
  x <- seq(-1, 1, length.out = n)
  dat <- data.frame(
    y = 0.4 + 0.7 * x + u[tip] + stats::rnorm(n, 0, 0.35),
    x = x,
    species = factor(tree$tip.label[tip], levels = tree$tip.label)
  )
  list(data = dat, tree = tree, seed = as.integer(seed),
       n_tip = as.integer(n_tip), n_each = as.integer(n_each), with_x = TRUE)
}

fit_cell <- function(cell) {
  tree <- cell$tree
  dat <- cell$data
  form <- drmTMB::bf(
    y ~ x + phylo(1 | species, tree = tree),
    sigma ~ 1
  )
  drmTMB::drmTMB(form, family = stats::gaussian(), data = dat, engine = "tmb")
}

formula_text <- function() {
  "y ~ x + phylo(1 | species); sigma ~ 1"
}

r_call_text <- function() {
  "drmTMB(bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1), family = gaussian(), data = dat, engine = \"tmb\")"
}

write_fixture <- function(cell, fit, out_dir) {
  if (dir.exists(out_dir)) unlink(out_dir, recursive = TRUE)
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

  utils::write.csv(cell$data, file.path(out_dir, "data.csv"), row.names = FALSE)
  ape::write.tree(cell$tree, file.path(out_dir, "tree.newick"))

  coefs <- flat_coef(fit)
  ll <- as.numeric(stats::logLik(fit))
  n <- nrow(cell$data)
  converged <- isTRUE(identical(fit$opt$convergence, 0L) || identical(fit$opt$convergence, 0))
  pd <- extract_pdHess(fit)
  interval_status <- extract_interval_status(fit)
  sd_phylo_corr <- extract_sd_phylo(fit, "phylo(1 | species)")
  h <- tree_height(cell$tree)

  con <- file(file.path(out_dir, "expected.toml"), "w")
  on.exit(close(con), add = TRUE)
  writeLines(c(
    "[fit]",
    paste0("family = ", toml_string("gaussian")),
    paste0("formula = ", toml_string(formula_text())),
    paste0("method = ", toml_string("ML")),
    paste0("engine = ", toml_string("tmb")),
    paste0("loglik = ", toml_num(ll)),
    paste0("n = ", as.integer(n)),
    "",
    "[coef]"
  ), con)
  for (name in sort(names(coefs))) {
    writeLines(paste0(toml_string(name), " = ", toml_num(coefs[[name]])), con)
  }
  writeLines(c(
    "",
    "# The row's DEFINING quantity: the fitted phylogenetic SD, on drmTMB's",
    "# CORRELATION-SCALE convention (ape::vcv(tree, corr = TRUE) standardises the",
    "# tip variance to 1, independent of the tree's raw branch-length height).",
    "# DRM.jl's re_sd(fit)[:species] is on the RAW branch-length scale instead",
    "# (tip variance = tree_height); the two are related by",
    "#   species_corr_scale == re_sd(fit)[:species] * sqrt(tree_height)",
    "# tree_height is recorded in expected.meta.toml.",
    "[re_sd]"
  ), con)
  writeLines(paste0("species_corr_scale = ", toml_num(sd_phylo_corr)), con)
  writeLines(c(
    "",
    "[status]",
    paste0("converged = ", toml_bool(converged)),
    paste0("pdHess = ", toml_bool(pd)),
    paste0("interval_status = ", toml_string(interval_status)),
    "",
    "[tol]",
    "atol_loglik = 1e-6",
    "atol_coef = 1e-5",
    "rtol_coef = 1e-5",
    "# re_sd is a boundary-adjacent variance-component estimate (see note in",
    "# expected.meta.toml): a coefficient-tight tolerance is not meaningful here.",
    "atol_re_sd = 1e-4"
  ), con)

  note <- paste(
    "Generated outputs only; no drmTMB source vendored.",
    "Workflow G fixtures remain 0.6.0 / ML / no tree.",
    "This cell is 0.7.0 ML + tree, outside the fixtures/ glob.",
    "Not a TSV supported flip. Not the last fixture-gap.",
    "ML, univariate, sigma ~ 1. Tight ML tols (not #434 atol_loglik=6).",
    "Live Route A clone unless a recorded reseed was required.",
    "re_sd added (promotion-gap fix): the phylo SD is now a compared quantity.",
    "At seed 111 the phylo variance component is boundary-adjacent -- confirmed",
    "by direct nll evaluation, the profiled negative log-likelihood changes by",
    "< 1e-4 for log_sd_phylo over [-30, -10], so the exact reported value is",
    "dominated by each engine's own optimizer stopping tolerance, not a tightly",
    "recoverable quantity. Both engines agree the phylo signal is negligible;",
    "the sqrt(tree_height) SCALE CONVENTION itself was verified separately by a",
    "3-height round trip (tree rescaled to 0.5/1.0/3.0) documented in",
    "test_parity_gaussian_phylo_mean.jl, not by this near-zero fixture alone."
  )
  # #473 (comparator provenance) is open and `tools/drmtmb_provenance.R` does
  # not exist in this checkout, so `drmtmb_built` is read directly from the
  # installed package's DESCRIPTION rather than via `--toml`; no
  # `drmtmb_code_hash` is recorded (that needs the not-yet-shipped tool's
  # exact hash recipe).
  writeLines(c(
    paste0("drmtmb_version = ", toml_string(as.character(utils::packageVersion("drmTMB")))),
    paste0("drmtmb_built = ", toml_string(as.character(utils::packageDescription("drmTMB")$Built))),
    paste0("generated_on = ", toml_string(as.character(Sys.Date()))),
    paste0("r_call = ", toml_string(r_call_text())),
    paste0("seed = ", as.integer(cell$seed)),
    paste0("n_tip = ", as.integer(cell$n_tip)),
    paste0("n_each = ", as.integer(cell$n_each)),
    paste0("with_x = ", toml_bool(cell$with_x)),
    paste0("tree_height = ", toml_num(h)),
    paste0("note = ", toml_string(note))
  ), file.path(out_dir, "expected.meta.toml"))
}

attempts <- list(
  list(kind = "route_a", seed = 111L, n_tip = 18L, n_each = 1L),
  list(kind = "route_a", seed = 112L, n_tip = 18L, n_each = 1L),
  list(kind = "fallback", seed = 20260817L, n_tip = 16L, n_each = 4L)
)

out_dir <- file.path(repo_root(), "test", "parity", "phylo-mean", "gaussian-phylo-mean")
ok <- FALSE
log_lines <- character()

for (att in attempts) {
  msg <- sprintf("attempt kind=%s seed=%s n_tip=%s n_each=%s",
                 att$kind, att$seed, att$n_tip, att$n_each)
  message(msg)
  log_lines <- c(log_lines, msg)
  cell <- if (identical(att$kind, "route_a")) {
    simulate_route_a(att$seed, att$n_tip)
  } else {
    simulate_fallback(att$seed, att$n_tip, att$n_each)
  }
  fit <- tryCatch(fit_cell(cell), error = function(e) e)
  if (inherits(fit, "error")) {
    log_lines <- c(log_lines, paste("  error:", conditionMessage(fit)))
    next
  }
  conv <- tryCatch(fit$opt$convergence, error = function(e) NA)
  ll <- tryCatch(as.numeric(stats::logLik(fit)), error = function(e) NA_real_)
  line <- sprintf("  convergence=%s logLik=%s", conv, ll)
  message(line)
  log_lines <- c(log_lines, line)
  if (identical(conv, 0L) || identical(conv, 0)) {
    write_fixture(cell, fit, out_dir)
    ok <- TRUE
    log_lines <- c(log_lines, paste("  wrote", out_dir))
    log_lines <- c(log_lines, paste("  coef names:", paste(names(flat_coef(fit)), collapse = ", ")))
    break
  }
}

cat(paste(log_lines, collapse = "\n"), "\n")
if (!ok) {
  stop("HANDS TO Codex: no converged native-TMB ML cell on Mac-small attempts. Do not escalate to Totoro.")
}
invisible(NULL)
