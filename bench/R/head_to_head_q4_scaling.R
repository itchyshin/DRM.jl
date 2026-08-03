## head_to_head_q4_scaling.R — #376 R arm (drmTMB public API wall-clock)
##
## Times the same fixtures exported by bench/head_to_head_q4_scaling.jl.
## Records packageVersion exactly (Rose fence). Does NOT vendor GPL source.
##
## Run from repo root (after Julia export):
##   OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 \
##     R_LIBS_USER=$HOME/R/lib \
##     Rscript --vanilla bench/R/head_to_head_q4_scaling.R
##
## Env:
##   DRM_376_PS    comma-separated tip counts (default: discover fixtures)
##   DRM_376_NREP  observations per species (default: 4)
##   DRM_376_REPS  timed reps after one warmup (default: 3)
##   DRM_376_TIMEOUT_S  per-fit timeout seconds (default: 3600)
##   R_LIBS / R_LIBS_USER  must expose installed drmTMB + ape + jsonlite
##                         (stdlib utils::read.csv — no readr required)

suppressPackageStartupMessages({
  if (!requireNamespace("drmTMB", quietly = TRUE)) {
    stop("drmTMB is not installed — R arm blocked for #376.")
  }
  library(drmTMB)
  if (!requireNamespace("ape", quietly = TRUE)) {
    stop("ape required to read Newick fixtures.")
  }
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

fix_dir <- file.path(repo_root, "bench", "results", "q4_scaling_h2h_376")
fix_root <- file.path(fix_dir, "fixtures")
dir.create(fix_dir, recursive = TRUE, showWarnings = FALSE)

nrep <- as.integer(Sys.getenv("DRM_376_NREP", unset = "4"))
reps <- as.integer(Sys.getenv("DRM_376_REPS", unset = "3"))
if (is.na(reps) || reps < 1L) reps <- 3L
timeout_s <- as.numeric(Sys.getenv("DRM_376_TIMEOUT_S", unset = "3600"))
if (is.na(timeout_s) || timeout_s <= 0) timeout_s <- 3600

ps_env <- Sys.getenv("DRM_376_PS", unset = "")
if (nzchar(ps_env)) {
  ps <- as.integer(strsplit(ps_env, ",", fixed = TRUE)[[1]])
} else {
  dirs <- list.dirs(fix_root, full.names = FALSE, recursive = FALSE)
  ps <- sort(as.integer(sub("^p([0-9]+)_nrep.*$", "\\1", dirs[grepl("^p[0-9]+_nrep", dirs)])))
  ps <- ps[is.finite(ps)]
}
if (!length(ps)) {
  stop("No fixtures found under ", fix_root, " — run Julia export first.")
}

## Soft timeout via setTimeLimit (CPU time). Wall-clock heavy fits may still
## overrun on some platforms; failures are recorded as R-blocked cells.
run_fit <- function(expr) {
  tryCatch(
    {
      setTimeLimit(cpu = timeout_s, elapsed = timeout_s, transient = TRUE)
      on.exit(setTimeLimit(cpu = Inf, elapsed = Inf, transient = TRUE), add = TRUE)
      force(expr)
    },
    error = function(e) structure(list(error = conditionMessage(e)), class = "drm_376_err")
  )
}

fit_one <- function(p) {
  dest <- file.path(fix_root, sprintf("p%d_nrep%d", p, nrep))
  csv_path <- file.path(dest, "data.csv")
  nwk_path <- file.path(dest, "tree.nwk")
  if (!file.exists(csv_path) || !file.exists(nwk_path)) {
    return(list(
      p = p, nrep = nrep, ok = FALSE,
      note = paste("missing fixture at", dest)
    ))
  }
  df <- utils::read.csv(csv_path, stringsAsFactors = FALSE)
  tree <- ape::read.tree(nwk_path)
  df$species <- factor(as.character(df$species), levels = tree$tip.label)

  formula <- drmTMB::bf(
    mu1    = y1 ~ x1 + phylo(1 | p | species, tree = tree),
    mu2    = y2 ~ x1 + phylo(1 | p | species, tree = tree),
    sigma1 =     ~ phylo(1 | p | species, tree = tree),
    sigma2 =     ~ phylo(1 | p | species, tree = tree),
    rho12  =     ~ 1
  )
  family <- drmTMB::biv_gaussian()

  cat(sprintf("[R p=%d] warmup...\n", p))
  warm <- run_fit(drmTMB::drmTMB(formula, data = df, family = family))
  if (inherits(warm, "drm_376_err")) {
    cat(sprintf("[R p=%d] warmup FAILED: %s\n", p, warm$error))
    return(list(
      p = as.integer(p),
      nrep = as.integer(nrep),
      n = nrow(df),
      ok = FALSE,
      note = paste("warmup failed:", warm$error)
    ))
  }

  times <- rep(NA_real_, reps)
  last <- warm
  notes <- character(0)
  for (k in seq_len(reps)) {
    cat(sprintf("[R p=%d] timed rep %d/%d...\n", p, k, reps))
    t0 <- proc.time()
    res <- run_fit(drmTMB::drmTMB(formula, data = df, family = family))
    t1 <- proc.time()
    if (inherits(res, "drm_376_err")) {
      notes <- c(notes, res$error)
      cat(sprintf("[R p=%d] rep %d FAILED: %s\n", p, k, res$error))
    } else {
      times[k] <- as.numeric((t1 - t0)[["elapsed"]])
      last <- res
    }
  }
  good <- which(is.finite(times))
  if (!length(good)) {
    return(list(
      p = as.integer(p),
      nrep = as.integer(nrep),
      n = nrow(df),
      ok = FALSE,
      times_s = times,
      note = paste("all timed fits failed:", paste(unique(notes), collapse = " | "))
    ))
  }

  conv <- tryCatch(isTRUE(last$opt$convergence == 0L), error = function(e) NA)
  ll <- tryCatch(as.numeric(logLik(last)), error = function(e) NA_real_)
  list(
    p = as.integer(p),
    nrep = as.integer(nrep),
    n = as.integer(nrow(df)),
    reps = as.integer(reps),
    warmup_discarded = TRUE,
    times_s = times,
    median_s = as.numeric(stats::median(times[good])),
    min_s = as.numeric(min(times[good])),
    max_s = as.numeric(max(times[good])),
    logLik = ll,
    converged = conv,
    ok = TRUE,
    note = if (length(notes)) paste(unique(notes), collapse = " | ") else ""
  )
}

rows <- lapply(ps, fit_one)

payload <- list(
  issue = 376L,
  arm = "r_drmTMB",
  model = "q4_plsm_per_dim_variance_nrep4",
  shape = "balanced",
  timestamp_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
  hostname = Sys.info()[["nodename"]],
  r_version = paste(R.version$major, R.version$minor, sep = "."),
  drmTMB_version = as.character(utils::packageVersion("drmTMB")),
  ape_version = as.character(utils::packageVersion("ape")),
  omp_num_threads = Sys.getenv("OMP_NUM_THREADS", unset = NA_character_),
  openblas_num_threads = Sys.getenv("OPENBLAS_NUM_THREADS", unset = NA_character_),
  nrep = as.integer(nrep),
  reps = as.integer(reps),
  timeout_s = timeout_s,
  rows = rows
)

out_path <- file.path(fix_dir, "r_q4_scaling.json")
jsonlite::write_json(payload, out_path, auto_unbox = TRUE, pretty = TRUE, digits = 12)
cat("wrote ", out_path, "\n", sep = "")
