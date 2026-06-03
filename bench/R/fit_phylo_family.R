## fit_phylo_family.R -- drmTMB side of the non-Gaussian phylo benchmark.
##
## Run from repo root after fixtures exist:
##   DRMTMB_SOURCE=/path/to/drmTMB Rscript bench/R/fit_phylo_family.R

suppressPackageStartupMessages({
  drmtmb_source <- Sys.getenv("DRMTMB_SOURCE", unset = "")
  if (nzchar(drmtmb_source)) {
    if (!requireNamespace("devtools", quietly = TRUE)) {
      stop("DRMTMB_SOURCE is set but devtools is not available to load_all().")
    }
    devtools::load_all(drmtmb_source, quiet = TRUE)
  } else {
    ok <- requireNamespace("drmTMB", quietly = TRUE)
    if (!ok) stop("drmTMB not installed; set DRMTMB_SOURCE to a source checkout.")
    library(drmTMB)
  }
  library(jsonlite)
})

`%||%` <- function(a, b) if (is.null(a)) b else a

here <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  script_path <- if (length(file_arg)) {
    normalizePath(sub("^--file=", "", file_arg[[1]]))
  } else {
    normalizePath(sys.frames()[[1]]$ofile %||% ".")
  }
  dirname(dirname(script_path))
}

phylo_tree <- function(n_tip) {
  edges <- matrix(integer(), ncol = 2L)
  edge_lengths <- numeric()
  next_node <- n_tip + 1L
  build <- function(tips) {
    if (length(tips) == 1L) return(tips)
    node <- next_node
    next_node <<- next_node + 1L
    mid <- length(tips) / 2L
    left <- build(tips[seq_len(mid)])
    right <- build(tips[seq.int(mid + 1L, length(tips))])
    edges <<- rbind(edges, c(node, left), c(node, right))
    edge_lengths <<- c(edge_lengths, 1, 1)
    node
  }
  build(seq_len(n_tip))
  structure(
    list(
      edge = edges,
      edge.length = edge_lengths,
      tip.label = paste0("sp_", seq_len(n_tip)),
      Nnode = n_tip - 1L
    ),
    class = "phylo"
  )
}

bench_root <- tryCatch(here(), error = function(e) file.path(getwd(), "bench"))
fixtures_dir <- file.path(bench_root, "fixtures", "phylo_family")
results_dir <- file.path(bench_root, "results", "phylo_family")
dir.create(results_dir, showWarnings = FALSE, recursive = TRUE)

cells <- list(
  list(id = "small", p = 16L, n_each = 20L, reps = 3L),
  list(id = "medium", p = 64L, n_each = 20L, reps = 3L)
)
families <- c("nb2", "gamma", "beta")

nsfun <- function(name) getFromNamespace(name, "drmTMB")

family_object <- function(family) {
  switch(
    family,
    nb2 = nsfun("nbinom2")(),
    gamma = stats::Gamma(link = "log"),
    beta = nsfun("beta")(),
    stop("unknown family: ", family)
  )
}

formula_object <- function(family, tree) {
  response <- switch(
    family,
    nb2 = "y_nb",
    gamma = "y_gamma",
    beta = "y_beta",
    stop("unknown family: ", family)
  )
  mu <- stats::as.formula(
    sprintf("%s ~ x + phylo(1 | species, tree = tree)", response)
  )
  do.call(drmTMB::bf, list(mu, sigma ~ 1))
}

coef_block <- function(fit, block) {
  cf <- coef(fit)
  if (is.list(cf) && !is.null(cf[[block]])) return(unname(as.numeric(cf[[block]])))
  if (identical(block, "mu")) return(unname(as.numeric(cf)))
  numeric()
}

nuisance_value <- function(family, fit) {
  sigma <- coef_block(fit, "sigma")
  if (!length(sigma)) return(NA_real_)
  if (identical(family, "nb2")) return(exp(-2 * sigma[[1]]))
  if (identical(family, "gamma") || identical(family, "beta")) return(exp(-2 * sigma[[1]]))
  NA_real_
}

phylo_sd_from_fit <- function(fit) {
  sp <- fit$sdpars$mu
  if (is.null(sp)) return(NA_real_)
  hit <- grep("^phylo\\(1 \\| species\\)", names(sp))
  if (length(hit)) unname(as.numeric(sp[[hit[[1]]]])) else NA_real_
}

fit_one <- function(cell, family) {
  df <- read.csv(file.path(fixtures_dir, paste0(cell$id, ".csv")))
  df$species <- factor(df$species, levels = paste0("sp_", seq_len(cell$p)))
  tree <- phylo_tree(cell$p)
  form <- formula_object(family, tree)
  fam <- family_object(family)
  ctrl <- drmTMB::drm_control(
    se = FALSE,
    optimizer = list(eval.max = 600L, iter.max = 600L)
  )
  warm <- tryCatch(
    drmTMB::drmTMB(form, data = df, family = fam, control = ctrl),
    error = function(e) structure(list(error = conditionMessage(e)), class = "drm_phylo_err")
  )
  if (inherits(warm, "drm_phylo_err")) {
    return(list(
      cell_id = cell$id, family = family, engine = "r_drmTMB",
      n = nrow(df), p = cell$p, time_s = NA_real_, time_s_med = NA_real_,
      times_all = rep(NA_real_, cell$reps), logLik = NA_real_,
      converged = FALSE, beta_mu = numeric(), nuisance = NA_real_,
      sd_phylo = NA_real_, note = paste("warm-up failed:", warm$error)
    ))
  }

  times <- rep(NA_real_, cell$reps)
  fits <- vector("list", cell$reps)
  for (k in seq_len(cell$reps)) {
    t <- system.time({
      fits[[k]] <- drmTMB::drmTMB(form, data = df, family = fam, control = ctrl)
    })
    times[[k]] <- as.numeric(t[["elapsed"]])
  }
  fit <- fits[[length(fits)]]
  beta <- coef_block(fit, "mu")
  res <- list(
    cell_id = cell$id,
    family = family,
    engine = "r_drmTMB",
    n = nrow(df),
    p = cell$p,
    time_s = mean(times),
    time_s_med = stats::median(times),
    times_all = times,
    logLik = as.numeric(logLik(fit)),
    converged = isTRUE(fit$opt$convergence == 0L),
    beta_mu = beta,
    nuisance = nuisance_value(family, fit),
    sd_phylo = phylo_sd_from_fit(fit)
  )
  cat(sprintf(
    "[R %-5s %-6s] p=%d n=%d med=%.4fs conv=%s beta1=%.3f sd=%.3f nuis=%.3f\n",
    family, cell$id, cell$p, nrow(df), res$time_s_med, res$converged,
    if (length(beta) >= 2) beta[[2]] else NA_real_, res$sd_phylo,
    res$nuisance
  ))
  res
}

results <- list()
for (cell in cells) {
  for (family in families) {
    results[[length(results) + 1L]] <- fit_one(cell, family)
  }
}

jsonlite::write_json(
  results, file.path(results_dir, "r_phylo_family.json"),
  auto_unbox = TRUE, pretty = TRUE, digits = NA
)
