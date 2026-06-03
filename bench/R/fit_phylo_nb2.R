## fit_phylo_nb2.R — drmTMB side of the NB2 phylo benchmark.
##
## Run from repo root after fixtures exist:
##   Rscript bench/R/fit_phylo_nb2.R

suppressPackageStartupMessages({
  local_drmTMB <- "/Users/z3437171/Dropbox/Github Local/drmTMB"
  if (dir.exists(local_drmTMB) && requireNamespace("devtools", quietly = TRUE)) {
    devtools::load_all(local_drmTMB, quiet = TRUE)
  } else if (requireNamespace("drmTMB", quietly = TRUE)) {
    library(drmTMB)
  } else {
    stop("drmTMB not installed and devtools not available to load_all().")
  }
  library(ape)
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

bench_root <- tryCatch(here(), error = function(e) file.path(getwd(), "bench"))
fixtures_dir <- file.path(bench_root, "fixtures", "phylo_nb2")
results_dir <- file.path(bench_root, "results", "phylo_nb2")
dir.create(results_dir, showWarnings = FALSE, recursive = TRUE)

cells <- list(
  list(id = "phylo_p100", p = 100, n = 500, reps = 5),
  list(id = "phylo_p500", p = 500, n = 1500, reps = 3),
  list(id = "phylo_p1000", p = 1000, n = 2000, reps = 3),
  list(id = "phylo_p2000", p = 2000, n = 4000, reps = 2)
)

coef_dpar <- function(fit, dpar) {
  cf <- coef(fit)
  if (is.list(cf) && !is.null(cf[[dpar]])) return(unname(as.numeric(cf[[dpar]])))
  numeric()
}

phylo_sd <- function(fit) {
  sp <- fit$sdpars$mu
  if (is.null(sp) || !length(sp)) return(NA_real_)
  nm <- names(sp)
  hit <- grep("phylo|species", nm, ignore.case = TRUE)
  if (!length(hit)) hit <- seq_along(sp)[[1]]
  unname(as.numeric(sp[[hit[[1]]]]))
}

fit_one <- function(cell) {
  df <- read.csv(file.path(fixtures_dir, paste0(cell$id, ".csv")))
  tr <- ape::read.tree(file.path(fixtures_dir, paste0(cell$id, ".nwk")))
  df$species <- factor(df$species, levels = tr$tip.label)
  form <- drmTMB::bf(y ~ x + phylo(1 | species, tree = tr), sigma ~ 1)
  ctrl <- drmTMB::drm_control(se = FALSE)

  warm <- tryCatch(
    drmTMB::drmTMB(form, data = df, family = nbinom2(), control = ctrl),
    error = function(e) structure(list(error = conditionMessage(e)), class = "drm_phylo_err")
  )
  if (inherits(warm, "drm_phylo_err")) {
    return(list(
      cell_id = cell$id, engine = "r_drmTMB", p = cell$p, n = cell$n,
      time_s = NA_real_, time_s_med = NA_real_, times_all = rep(NA_real_, cell$reps),
      logLik = NA_real_, converged = FALSE, beta_mu = numeric(),
      beta_sigma = numeric(), sigma_nb2 = NA_real_, theta_nb2 = NA_real_,
      sd_phylo = NA_real_, note = paste("warm-up failed:", warm$error)
    ))
  }

  times <- rep(NA_real_, cell$reps)
  fits <- vector("list", cell$reps)
  for (k in seq_len(cell$reps)) {
    t <- system.time({
      fits[[k]] <- drmTMB::drmTMB(form, data = df, family = nbinom2(), control = ctrl)
    })
    times[[k]] <- as.numeric(t[["elapsed"]])
  }
  fit <- fits[[length(fits)]]
  beta <- coef_dpar(fit, "mu")
  beta_sigma <- coef_dpar(fit, "sigma")
  sigma_nb2 <- if (length(beta_sigma)) exp(beta_sigma[[1L]]) else NA_real_
  theta_nb2 <- if (is.finite(sigma_nb2) && sigma_nb2 > 0) 1 / sigma_nb2^2 else NA_real_
  res <- list(
    cell_id = cell$id,
    engine = "r_drmTMB",
    p = cell$p,
    n = cell$n,
    time_s = mean(times),
    time_s_med = stats::median(times),
    times_all = times,
    logLik = as.numeric(logLik(fit)),
    converged = isTRUE(fit$opt$convergence == 0L),
    beta_mu = beta,
    beta_sigma = beta_sigma,
    sigma_nb2 = sigma_nb2,
    theta_nb2 = theta_nb2,
    sd_phylo = phylo_sd(fit)
  )
  cat(sprintf("[R %s] p=%d n=%d med=%.4fs logLik=%.3f beta=(%.3f, %.3f) theta=%.3f sd=%.3f\n",
              cell$id, cell$p, cell$n, res$time_s_med, res$logLik,
              beta[[1]], beta[[2]], res$theta_nb2, res$sd_phylo))
  res
}

results <- lapply(cells, fit_one)
jsonlite::write_json(results, file.path(results_dir, "r_phylo_nb2.json"),
                     auto_unbox = TRUE, pretty = TRUE, digits = NA)
