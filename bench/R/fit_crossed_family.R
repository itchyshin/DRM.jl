## fit_crossed_family.R -- drmTMB side of the #80 crossed-family benchmark.
##
## Run from repo root after fixtures exist:
##   Rscript bench/R/fit_crossed_family.R

suppressPackageStartupMessages({
  ok <- requireNamespace("drmTMB", quietly = TRUE)
  if (!ok) {
    if (!requireNamespace("devtools", quietly = TRUE)) {
      stop("drmTMB not installed and devtools not available to load_all().")
    }
    devtools::load_all("/Users/z3437171/Dropbox/Github Local/drmTMB", quiet = TRUE)
  } else {
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

bench_root <- tryCatch(here(), error = function(e) file.path(getwd(), "bench"))
fixtures_dir <- file.path(bench_root, "fixtures", "crossed_family")
results_dir <- file.path(bench_root, "results", "crossed_family")
dir.create(results_dir, showWarnings = FALSE, recursive = TRUE)

cells <- list(
  list(id = "small", G = 20, H = 20, n = 1000, reps = 3),
  list(id = "medium", G = 50, H = 50, n = 5000, reps = 3),
  list(id = "fixedq_n20000", G = 50, H = 50, n = 20000, reps = 2)
)

families <- c("poisson", "binomial", "nb2", "gamma", "beta")

families_for <- function(cell) {
  if (cell$n > 5000) setdiff(families, "beta") else families
}

nsfun <- function(name) getFromNamespace(name, "drmTMB")

family_object <- function(family) {
  switch(
    family,
    poisson = stats::poisson(),
    binomial = stats::binomial(),
    nb2 = nsfun("nbinom2")(),
    gamma = stats::Gamma(link = "log"),
    beta = nsfun("beta")(),
    stop("unknown family: ", family)
  )
}

formula_object <- function(family) {
  if (identical(family, "binomial")) {
    return(do.call(drmTMB::bf, list(cbind(s, fail) ~ x + (1 | g) + (1 | h))))
  }
  response <- switch(
    family,
    poisson = "y_pois",
    nb2 = "y_nb",
    gamma = "y_gamma",
    beta = "y_beta",
    stop("unknown family: ", family)
  )
  mu <- stats::as.formula(sprintf("%s ~ x + (1 | g) + (1 | h)", response))
  if (identical(family, "poisson")) {
    return(do.call(drmTMB::bf, list(mu)))
  } else {
    do.call(drmTMB::bf, list(mu, sigma ~ 1))
  }
}

coef_block <- function(fit, block) {
  cf <- coef(fit)
  if (is.list(cf) && !is.null(cf[[block]])) return(unname(as.numeric(cf[[block]])))
  if (identical(block, "mu")) return(unname(as.numeric(cf)))
  numeric()
}

re_sd_from_fit <- function(fit, term) {
  sp <- fit$sdpars$mu
  if (is.null(sp)) return(NA_real_)
  nm <- names(sp)
  hit <- which(nm == paste0("(1 | ", term, ")"))
  if (length(hit)) unname(as.numeric(sp[[hit[[1]]]])) else NA_real_
}

nuisance_value <- function(family, fit) {
  sigma <- coef_block(fit, "sigma")
  if (!length(sigma)) return(NA_real_)
  if (identical(family, "nb2")) return(exp(-2 * sigma[[1]]))
  if (identical(family, "gamma") || identical(family, "beta")) return(exp(-2 * sigma[[1]]))
  NA_real_
}

fit_one <- function(cell, family) {
  df <- read.csv(file.path(fixtures_dir, paste0(cell$id, ".csv")))
  df$g <- factor(df$g)
  df$h <- factor(df$h)
  form <- formula_object(family)
  fam <- family_object(family)
  ctrl <- drmTMB::drm_control(se = FALSE)
  warm <- tryCatch(
    drmTMB::drmTMB(form, data = df, family = fam, control = ctrl),
    error = function(e) structure(list(error = conditionMessage(e)), class = "drm_crossed_err")
  )
  if (inherits(warm, "drm_crossed_err")) {
    return(list(
      cell_id = cell$id, family = family, engine = "r_drmTMB", n = cell$n,
      G = cell$G, H = cell$H, time_s = NA_real_, time_s_med = NA_real_,
      times_all = rep(NA_real_, cell$reps), logLik = NA_real_,
      converged = FALSE, beta_mu = numeric(), nuisance = NA_real_,
      sd_g = NA_real_, sd_h = NA_real_, note = paste("warm-up failed:", warm$error)
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
    n = cell$n,
    G = cell$G,
    H = cell$H,
    time_s = mean(times),
    time_s_med = stats::median(times),
    times_all = times,
    logLik = as.numeric(logLik(fit)),
    converged = isTRUE(fit$opt$convergence == 0L),
    beta_mu = beta,
    nuisance = nuisance_value(family, fit),
    sd_g = re_sd_from_fit(fit, "g"),
    sd_h = re_sd_from_fit(fit, "h")
  )
  cat(sprintf(
    "[R %-8s %-13s] n=%d med=%.4fs conv=%s beta1=%.3f sd=(%.3f,%.3f) nuis=%.3f\n",
    family, cell$id, cell$n, res$time_s_med, res$converged,
    if (length(beta) >= 2) beta[[2]] else NA_real_, res$sd_g, res$sd_h,
    res$nuisance
  ))
  res
}

results <- list()
for (cell in cells) {
  for (family in families_for(cell)) {
    results[[length(results) + 1L]] <- fit_one(cell, family)
  }
}

jsonlite::write_json(results, file.path(results_dir, "r_crossed_family.json"),
                     auto_unbox = TRUE, pretty = TRUE, digits = NA)
