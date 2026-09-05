# engine_speed_grid.R — comprehensive engine="julia" vs engine="tmb" speed grid.
#
# The owner's diagnostic (2026-08-28): at parity, warm per-fit Julia time should
# not LOSE badly to native TMB on any route — a wide warm-time loss is an
# anomaly worth investigating (the FD-step defect surfaced exactly as an
# unexplained per-route anomaly). Two slow readings are EXPECTED and are
# measured separately so they cannot masquerade as defects:
#   * one-time JuliaCall + JIT startup (reported once, not per cell);
#   * R<->Julia marshalling, which dominates millisecond-scale fits — so each
#     cell reports the ratio AND the absolute times, and tiny-fit cells are
#     judged on absolutes, not ratios.
#
# Method: per cell, 1 warm-up + NREP timed fits per engine in ONE R process,
# medians reported. Same data object for both engines (same bytes). Coef
# agreement recorded as a sanity column (this is a TIMING grid; parity proper
# lives in the parity harnesses).
#
#   DRM_JL_PATH=$(pwd) NOT_CRAN=true Rscript tools/engine_speed_grid.R [--pre-run]

suppressMessages(library(drmTMB))
stopifnot(requireNamespace("ape", quietly = TRUE))

PRERUN <- "--pre-run" %in% commandArgs(trailingOnly = TRUE)
NREP <- 5L
out_path <- "docs/dev-log/evidence/engine-speed-grid.tsv"

t_wall <- function(expr) { t0 <- proc.time()[[3]]; force(expr); proc.time()[[3]] - t0 }
med_time <- function(fit_fn, nrep = NREP) {
  fit_fn()                                   # warm-up (JIT/caches)
  ts <- vapply(seq_len(nrep), function(i) t_wall(fit_fn()), 0.0)
  stats::median(ts)
}

mk_phylo <- function(seed, ntip, m, sd_phy = 0.5, unit_height = TRUE) {
  set.seed(seed)
  tree <- ape::rcoal(ntip)
  tree$tip.label <- paste0("sp_", seq_len(ntip))
  if (unit_height) {
    h <- max(diag(ape::vcv(tree))); tree$edge.length <- tree$edge.length / h
  }
  A <- ape::vcv(tree, corr = TRUE)
  u <- as.vector(t(chol(A)) %*% rnorm(ntip)) * sd_phy
  species <- factor(rep(tree$tip.label, each = m), levels = tree$tip.label)
  idx <- rep(seq_len(ntip), each = m)
  n <- ntip * m
  x <- rnorm(n)
  list(tree = tree, species = species, x = x, eta = 0.3 + 0.4 * x + u[idx], n = n)
}

# ---- the grid ---------------------------------------------------------------
# Each cell: id, build() -> env with `dat` (+ tree etc.), and fit(engine).
cells <- list()
add_cell <- function(id, build, fit) cells[[length(cells) + 1L]] <<- list(id = id, build = build, fit = fit)

add_cell("gaussian_locscale_n120",
  function() { set.seed(1); n <- 120; x <- rnorm(n); z <- rnorm(n)
    list(dat = data.frame(y = 0.4 + 0.9 * x + exp(-0.3 + 0.25 * z) * rnorm(n), x = x, z = z)) },
  function(e, env) drmTMB(bf(y ~ x, sigma ~ z), family = gaussian(), data = env$dat, engine = e))

add_cell("gaussian_locscale_n5000",
  function() { set.seed(2); n <- 5000; x <- rnorm(n); z <- rnorm(n)
    list(dat = data.frame(y = 0.4 + 0.9 * x + exp(-0.3 + 0.25 * z) * rnorm(n), x = x, z = z)) },
  function(e, env) drmTMB(bf(y ~ x, sigma ~ z), family = gaussian(), data = env$dat, engine = e))

add_cell("biv_gaussian_rho12_n400",
  function() { set.seed(11); n <- 400; x <- rnorm(n)
    z1 <- rnorm(n); z2 <- 0.6 * z1 + sqrt(1 - 0.36) * rnorm(n)
    list(dat = data.frame(y1 = 0.4 + 0.9 * x + 0.5 * z1, y2 = -0.2 + 0.5 * x + 0.8 * z2, x = x)) },
  function(e, env) drmTMB(bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~1),
                          family = biv_gaussian(), data = env$dat, engine = e))

add_cell("gaussian_phylo_mean_ntip64",
  function() { fx <- mk_phylo(404, 64, 4)
    dat <- data.frame(y = fx$eta + 0.4 * rnorm(fx$n), x = fx$x, species = fx$species)
    list(dat = dat, tree = fx$tree) },
  function(e, env) { tree <- env$tree
    drmTMB(bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1),
           family = gaussian(), data = env$dat, engine = e) })

add_cell("poisson_phylo_p100",
  function() { fx <- mk_phylo(20260824, 100, 4, unit_height = FALSE)
    dat <- data.frame(y = rpois(fx$n, exp(fx$eta)), x = fx$x, species = fx$species)
    list(dat = dat, tree = fx$tree) },
  function(e, env) { tree <- env$tree
    drmTMB(bf(y ~ x + phylo(1 | species, tree = tree)), family = poisson(),
           data = env$dat, engine = e) })

add_cell("poisson_phylo_p1000",
  function() { fx <- mk_phylo(20260824, 1000, 4, unit_height = FALSE)
    dat <- data.frame(y = rpois(fx$n, exp(fx$eta)), x = fx$x, species = fx$species)
    list(dat = dat, tree = fx$tree) },
  function(e, env) { tree <- env$tree
    drmTMB(bf(y ~ x + phylo(1 | species, tree = tree)), family = poisson(),
           data = env$dat, engine = e) })

add_cell("nb2_phylo_p300",
  function() { fx <- mk_phylo(20260824, 300, 4, unit_height = FALSE)
    dat <- data.frame(y = rnbinom(fx$n, mu = exp(fx$eta), size = 4), x = fx$x, species = fx$species)
    list(dat = dat, tree = fx$tree) },
  function(e, env) { tree <- env$tree
    drmTMB(bf(y ~ x + phylo(1 | species, tree = tree)), family = nbinom2(),
           data = env$dat, engine = e) })

add_cell("gamma_phylo_12x6",
  function() { fx <- mk_phylo(411, 12, 6)
    dat <- data.frame(y = rgamma(fx$n, shape = 8, rate = 8 / exp(fx$eta)), x = fx$x, species = fx$species)
    list(dat = dat, tree = fx$tree) },
  function(e, env) { tree <- env$tree
    drmTMB(bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1),
           family = Gamma(link = "log"), data = env$dat, engine = e) })

add_cell("binomial_phylo_24x5",
  function() { fx <- mk_phylo(11, 24, 5, sd_phy = 0.8)
    dat <- data.frame(y = rbinom(fx$n, 1, plogis(fx$eta)), x = fx$x, species = fx$species)
    list(dat = dat, tree = fx$tree) },
  function(e, env) { tree <- env$tree
    drmTMB(bf(y ~ x + phylo(1 | species, tree = tree)), family = stats::binomial(),
           data = env$dat, engine = e) })

add_cell("beta_phylo_12x6",
  function() { fx <- mk_phylo(411, 12, 6)
    dat <- data.frame(y = pmin(pmax(plogis(fx$eta) + 0.03 * rnorm(fx$n), 1e-3), 1 - 1e-3),
                      x = fx$x, species = fx$species)
    list(dat = dat, tree = fx$tree) },
  function(e, env) { tree <- env$tree
    drmTMB(bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1),
           family = drmTMB::beta(), data = env$dat, engine = e) })

mk_relmat <- function(seed, G = 25, m = 6) {
  set.seed(seed)
  Z <- matrix(rnorm(G * G), G, G); K <- crossprod(Z) / G
  K <- K / mean(diag(K)); rownames(K) <- colnames(K) <- paste0("g", seq_len(G))
  g <- factor(rep(rownames(K), each = m), levels = rownames(K))
  u <- as.vector(t(chol(K + diag(1e-8, G))) %*% rnorm(G)) * 0.5
  n <- G * m; x <- rnorm(n)
  list(K = K, g = g, x = x, eta = 0.3 + 0.4 * x + u[as.integer(g)], n = n)
}

for (fam in c("gaussian", "poisson", "nbinom2", "gamma")) {
  local({
    fam_local <- fam
    add_cell(paste0(fam_local, "_relmat_G25"),
      function() { fx <- mk_relmat(77)
        y <- switch(fam_local,
          gaussian = fx$eta + 0.4 * rnorm(fx$n),
          poisson  = rpois(fx$n, exp(fx$eta)),
          nbinom2  = rnbinom(fx$n, mu = exp(fx$eta), size = 4),
          gamma    = rgamma(fx$n, shape = 8, rate = 8 / exp(fx$eta)))
        list(dat = data.frame(y = y, x = fx$x, g = fx$g), K = fx$K) },
      function(e, env) { K <- env$K
        famobj <- switch(fam_local, gaussian = gaussian(), poisson = poisson(),
                         nbinom2 = nbinom2(), gamma = Gamma(link = "log"))
        drmTMB(bf(y ~ x + relmat(1 | g, K = K), sigma ~ 1), family = famobj,
               data = env$dat, engine = e) })
  })
}

add_cell("binomial_trials_fe",
  function() { set.seed(3); n <- 300; x <- rnorm(n); tr <- rep(20L, n)
    p <- plogis(-0.2 + 0.5 * x)
    list(dat = data.frame(s = rbinom(n, tr, p), f = tr - rbinom(n, tr, p), x = x)) },
  function(e, env) drmTMB(bf(cbind(s, f) ~ x), family = stats::binomial(),
                          data = env$dat, engine = e))

add_cell("biv_q4_phylo_reml_ntip16",
  function() { fx <- mk_phylo(433, 16, 3)
    n <- fx$n
    dat <- data.frame(y1 = fx$eta + 0.4 * rnorm(n), y2 = 0.5 * fx$eta + 0.5 * rnorm(n),
                      x = fx$x, species = fx$species)
    list(dat = dat, tree = fx$tree) },
  function(e, env) { tree <- env$tree
    drmTMB(bf(mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
              mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
              sigma1 = ~ 1 + phylo(1 | p | species, tree = tree),
              sigma2 = ~ 1 + phylo(1 | p | species, tree = tree),
              rho12 = ~ 1),
           family = biv_gaussian(), data = env$dat, engine = e, REML = TRUE) })

pre_ids <- c("gaussian_locscale_n120", "poisson_phylo_p100", "biv_q4_phylo_reml_ntip16")
if (PRERUN) cells <- Filter(function(c) c$id %in% pre_ids, cells)

# ---- run --------------------------------------------------------------------
startup <- t_wall(drmTMB:::drm_julia_setup())
cat(sprintf("one-time julia startup: %.1f s\n", startup))

rows <- list()
for (cell in cells) {
  env <- cell$build()
  res <- list(cell = cell$id, tmb_med_s = NA_real_, julia_med_s = NA_real_,
              speedup = NA_real_, max_abs_coef_diff = NA_real_, note = "")
  ok <- TRUE
  ft <- tryCatch(cell$fit("tmb", env), error = function(e) { res$note <<- paste("tmb:", conditionMessage(e)); ok <<- FALSE; NULL })
  fj <- tryCatch(cell$fit("julia", env), error = function(e) { res$note <<- paste(res$note, "julia:", conditionMessage(e)); ok <<- FALSE; NULL })
  if (ok) {
    res$max_abs_coef_diff <- tryCatch(
      max(abs(unlist(fixef(ft)) - unlist(fixef(fj))[seq_along(unlist(fixef(ft)))])),
      error = function(e) NA_real_)
    res$tmb_med_s   <- med_time(function() cell$fit("tmb", env))
    res$julia_med_s <- med_time(function() cell$fit("julia", env))
    res$speedup <- res$tmb_med_s / res$julia_med_s
  }
  rows[[length(rows) + 1L]] <- as.data.frame(res, stringsAsFactors = FALSE)
  cat(sprintf("%-28s tmb=%.3fs julia=%.3fs speedup=%.2fx coefdiff=%.2e %s\n",
              res$cell, res$tmb_med_s, res$julia_med_s, res$speedup,
              res$max_abs_coef_diff, res$note))
}

tab <- do.call(rbind, rows)
tab$julia_startup_s <- startup
tab$nrep <- NREP
if (!PRERUN) {
  source(file.path("tools", "drmtmb_provenance_lib.R"))
  tab$drmtmb_code_hash <- drmtmb_code_hash()
  dir.create(dirname(out_path), showWarnings = FALSE, recursive = TRUE)
  write.table(tab, out_path, sep = "\t", row.names = FALSE, quote = FALSE)
  cat("wrote ", out_path, "\n", sep = "")
}
