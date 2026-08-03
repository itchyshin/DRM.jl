## bridge_six_cell_timing.R — #372 R arm (local drmTMB wall-clock)
##
## Times the six #370 bridge fixture cells with installed drmTMB.
## Records packageVersion exactly (Rose fence). Does NOT vendor GPL source.
##
## Run from repo root:
##   OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 \
##     Rscript --vanilla bench/R/bridge_six_cell_timing.R
##
## Env:
##   DRM_372_REPS   timed reps after one warmup (default 5)
##   DRM_372_CELLS  comma-separated cell ids (default: all six)

suppressPackageStartupMessages({
  if (!requireNamespace("drmTMB", quietly = TRUE)) {
    stop("drmTMB is not installed — R arm blocked for #372.")
  }
  library(drmTMB)
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("jsonlite required to write timing JSON.")
  }
})

`%||%` <- function(a, b) if (is.null(a)) b else a

args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
repo_root <- if (length(file_arg)) {
  script_path <- normalizePath(sub("^--file=", "", file_arg[[1]]))
  normalizePath(file.path(dirname(script_path), "..", ".."))
} else {
  normalizePath(getwd())
}

fixtures_root <- file.path(repo_root, "test", "parity", "fixtures")
results_dir <- file.path(repo_root, "bench", "results", "bridge_six_cell_372")
dir.create(results_dir, recursive = TRUE, showWarnings = FALSE)

cohort_default <- c(
  "gaussian-locscale",
  "gaussian-bivariate-rho12",
  "robust-student",
  "count-nbinom2",
  "proportion-beta",
  "meta-analysis-V"
)

cells_env <- Sys.getenv("DRM_372_CELLS", unset = "")
cells <- if (nzchar(cells_env)) {
  strsplit(cells_env, ",", fixed = TRUE)[[1]]
} else {
  cohort_default
}
reps <- as.integer(Sys.getenv("DRM_372_REPS", unset = "5"))
if (is.na(reps) || reps < 1L) reps <- 5L

## Fit constructors mirror test/parity/gen_fixtures.R call shapes (no GPL copy —
## only the public drmTMB API surface used by the generator recipe).
fit_cell <- function(cell, dat) {
  if (identical(cell, "gaussian-locscale")) {
    drmTMB(drm_formula(y ~ x, sigma ~ x), family = gaussian(), data = dat)
  } else if (identical(cell, "gaussian-bivariate-rho12")) {
    drmTMB(
      bf(
        mu1 = y1 ~ x, mu2 = y2 ~ x,
        sigma1 = sigma1 ~ 1, sigma2 = sigma2 ~ 1, rho12 = rho12 ~ 1
      ),
      family = biv_gaussian(), data = dat
    )
  } else if (identical(cell, "robust-student")) {
    drmTMB(drm_formula(y ~ x, sigma ~ 1, nu ~ 1), family = student(), data = dat)
  } else if (identical(cell, "count-nbinom2")) {
    drmTMB(drm_formula(y ~ x, sigma ~ 1), family = nbinom2(), data = dat)
  } else if (identical(cell, "proportion-beta")) {
    drmTMB(drm_formula(y ~ x, sigma ~ 1), family = beta(), data = dat)
  } else if (identical(cell, "meta-analysis-V")) {
    drmTMB(
      drm_formula(y ~ x + meta_V(V = v), sigma ~ 1),
      family = gaussian(), data = dat
    )
  } else {
    stop("unknown cell: ", cell)
  }
}

time_cell <- function(cell) {
  dir <- file.path(fixtures_root, cell)
  csv <- file.path(dir, "data.csv")
  if (!dir.exists(dir) || !file.exists(csv)) {
    return(list(
      cell = cell, ok = FALSE, note = paste("missing fixture:", dir),
      median_s = NA_real_, min_s = NA_real_, max_s = NA_real_,
      times_s = numeric(0), logLik = NA_real_, n = NA_integer_
    ))
  }
  dat <- read.csv(csv, stringsAsFactors = FALSE)
  note <- ""
  ok <- TRUE
  times <- numeric(reps)
  ll <- NA_real_
  tryCatch({
    invisible(fit_cell(cell, dat)) # warmup discard
    for (i in seq_len(reps)) {
      t0 <- proc.time()[["elapsed"]]
      fit <- fit_cell(cell, dat)
      times[i] <- proc.time()[["elapsed"]] - t0
      ll <- as.numeric(logLik(fit))
    }
  }, error = function(e) {
    ok <<- FALSE
    note <<- conditionMessage(e)
  })
  list(
    cell = cell,
    ok = ok,
    note = note,
    n = nrow(dat),
    reps = reps,
    warmup_discarded = TRUE,
    times_s = times,
    median_s = if (ok) as.numeric(stats::median(times)) else NA_real_,
    min_s = if (ok) min(times) else NA_real_,
    max_s = if (ok) max(times) else NA_real_,
    logLik = ll
  )
}

rows <- lapply(cells, function(cell) {
  message("timing R drmTMB cell=", cell, " reps=", reps)
  time_cell(cell)
})

out <- list(
  arm = "r_drmTMB",
  issued = "#372",
  timestamp_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  drmTMB_version = as.character(packageVersion("drmTMB")),
  R_version = R.version.string,
  hostname = Sys.info()[["nodename"]],
  omp_num_threads = Sys.getenv("OMP_NUM_THREADS", unset = ""),
  openblas_num_threads = Sys.getenv("OPENBLAS_NUM_THREADS", unset = ""),
  mkl_num_threads = Sys.getenv("MKL_NUM_THREADS", unset = ""),
  reps = reps,
  cells = rows
)

out_path <- file.path(results_dir, "r_bridge_six_cell.json")
jsonlite::write_json(out, out_path, auto_unbox = TRUE, pretty = TRUE, digits = 12)
cat("wrote ", out_path, "\n", sep = "")
for (r in rows) {
  if (isTRUE(r$ok)) {
    cat(r$cell, " median_s=", r$median_s, " min_s=", r$min_s, "\n", sep = "")
  } else {
    cat(r$cell, " FAILED: ", r$note, "\n", sep = "")
  }
}
