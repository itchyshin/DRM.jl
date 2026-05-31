## fit_crossed_poisson.R — drmTMB side of #70 crossed Poisson benchmark.
##
## Run from repo root after fixtures exist:
##   Rscript bench/R/fit_crossed_poisson.R

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
fixtures_dir <- file.path(bench_root, "fixtures", "crossed_poisson")
results_dir <- file.path(bench_root, "results", "crossed_poisson")
dir.create(results_dir, showWarnings = FALSE, recursive = TRUE)

cells <- list(
  list(id = "single_control", kind = "single", G = 50, H = 0, n = 1500, reps = 5),
  list(id = "crossed_small", kind = "crossed", G = 20, H = 20, n = 1000, reps = 5),
  list(id = "crossed_medium", kind = "crossed", G = 50, H = 50, n = 5000, reps = 5),
  list(id = "crossed_large", kind = "crossed", G = 100, H = 100, n = 20000, reps = 3),
  list(id = "fixedq_n1000", kind = "crossed", G = 50, H = 50, n = 1000, reps = 5),
  list(id = "fixedq_n20000", kind = "crossed", G = 50, H = 50, n = 20000, reps = 3)
)

re_sd_from_fit <- function(fit, term) {
  sp <- fit$sdpars$mu
  if (is.null(sp)) return(NA_real_)
  nm <- names(sp)
  hit <- which(nm == paste0("(1 | ", term, ")"))
  if (length(hit)) unname(as.numeric(sp[[hit[[1]]]])) else NA_real_
}

coef_mu <- function(fit) {
  cf <- coef(fit)
  if (is.list(cf) && !is.null(cf$mu)) return(unname(as.numeric(cf$mu)))
  unname(as.numeric(cf))
}

fit_one <- function(cell) {
  df <- read.csv(file.path(fixtures_dir, paste0(cell$id, ".csv")))
  df$g <- factor(df$g)
  df$h <- factor(df$h)
  form <- if (identical(cell$kind, "single")) {
    drmTMB::bf(y ~ x + (1 | g))
  } else {
    drmTMB::bf(y ~ x + (1 | g) + (1 | h))
  }

  ctrl <- drmTMB::drm_control(se = FALSE)
  warm <- tryCatch(
    drmTMB::drmTMB(form, data = df, family = poisson(), control = ctrl),
    error = function(e) structure(list(error = conditionMessage(e)), class = "drm_crossed_err")
  )
  if (inherits(warm, "drm_crossed_err")) {
    return(list(
      cell_id = cell$id, engine = "r_drmTMB", kind = cell$kind, n = cell$n,
      G = cell$G, H = cell$H, time_s = NA_real_, time_s_med = NA_real_,
      times_all = rep(NA_real_, cell$reps), logLik = NA_real_,
      converged = FALSE, beta_mu = numeric(), sd_g = NA_real_, sd_h = NA_real_,
      note = paste("warm-up failed:", warm$error)
    ))
  }

  times <- rep(NA_real_, cell$reps)
  fits <- vector("list", cell$reps)
  for (k in seq_len(cell$reps)) {
    t <- system.time({
      fits[[k]] <- drmTMB::drmTMB(form, data = df, family = poisson(), control = ctrl)
    })
    times[[k]] <- as.numeric(t[["elapsed"]])
  }
  fit <- fits[[length(fits)]]
  beta <- coef_mu(fit)
  res <- list(
    cell_id = cell$id,
    engine = "r_drmTMB",
    kind = cell$kind,
    n = cell$n,
    G = cell$G,
    H = cell$H,
    time_s = mean(times),
    time_s_med = stats::median(times),
    times_all = times,
    logLik = as.numeric(logLik(fit)),
    converged = isTRUE(fit$opt$convergence == 0L),
    beta_mu = beta,
    sd_g = re_sd_from_fit(fit, "g"),
    sd_h = if (identical(cell$kind, "crossed")) re_sd_from_fit(fit, "h") else NA_real_
  )
  cat(sprintf(
    "[R %s] n=%d med=%.4fs logLik=%.3f beta=(%.3f, %.3f) sd_g=%.3f sd_h=%.3f\n",
    cell$id, cell$n, res$time_s_med, res$logLik, beta[[1]], beta[[2]], res$sd_g, res$sd_h
  ))
  res
}

results <- lapply(cells, fit_one)
jsonlite::write_json(results, file.path(results_dir, "r_crossed_poisson.json"),
                     auto_unbox = TRUE, pretty = TRUE, digits = NA)
