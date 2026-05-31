## compare_crossed_poisson.R — aggregate #70 Julia vs drmTMB benchmark results.
##
## Run from repo root after both fit runners:
##   Rscript bench/R/compare_crossed_poisson.R

suppressPackageStartupMessages(library(jsonlite))

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
results_dir <- file.path(bench_root, "results", "crossed_poisson")
report_dir <- file.path(dirname(bench_root), "report")
dir.create(report_dir, showWarnings = FALSE, recursive = TRUE)

r_path <- file.path(results_dir, "r_crossed_poisson.json")
j_path <- file.path(results_dir, "julia_crossed_poisson.json")
if (!file.exists(r_path)) stop("R results missing: ", r_path)
if (!file.exists(j_path)) stop("Julia results missing: ", j_path)

r_res <- jsonlite::read_json(r_path, simplifyVector = FALSE)
j_res <- jsonlite::read_json(j_path, simplifyVector = FALSE)

idx <- function(x) setNames(x, vapply(x, function(z) as.character(z$cell_id), character(1)))
r_by <- idx(r_res)
j_by <- idx(j_res)
cell_ids <- names(r_by)
missing_j <- setdiff(cell_ids, names(j_by))
if (length(missing_j)) stop("Julia results missing cells: ", paste(missing_j, collapse = ", "))

num <- function(x) suppressWarnings(as.numeric(x %||% NA_real_))
vec <- function(x) as.numeric(unlist(x %||% numeric()))

rows <- lapply(cell_ids, function(id) {
  r <- r_by[[id]]
  j <- j_by[[id]]
  rb <- vec(r$beta_mu)
  jb <- vec(j$beta_mu)
  d_beta <- if (length(rb) == length(jb) && length(rb)) max(abs(rb - jb)) else NA_real_
  sd_diffs <- abs(c(num(r$sd_g) - num(j$sd_g), num(r$sd_h) - num(j$sd_h)))
  d_sd <- max(sd_diffs[is.finite(sd_diffs)], na.rm = TRUE)
  if (!is.finite(d_sd)) d_sd <- NA_real_
  rt <- num(r$time_s_med)
  jt <- num(j$time_s_med)
  data.frame(
    cell_id = id,
    n = as.integer(r$n %||% j$n %||% NA_integer_),
    kind = as.character(r$kind %||% j$kind),
    r_time = rt,
    julia_time = jt,
    speedup = if (is.finite(rt) && is.finite(jt) && jt > 0) rt / jt else NA_real_,
    dlogLik = abs(num(r$logLik) - num(j$logLik)),
    max_d_beta = d_beta,
    max_d_sd = d_sd,
    r_converged = isTRUE(r$converged),
    julia_converged = isTRUE(j$converged),
    stringsAsFactors = FALSE
  )
})
tbl <- do.call(rbind, rows)

fmt <- function(x, f = "%.4f") if (is.finite(x)) sprintf(f, x) else "-"
fmtx <- function(x) if (is.finite(x)) sprintf("%.2fx", x) else "-"
line <- function(row) {
  sprintf("| %-14s | %6d | %-7s | %9s | %9s | %8s | %9s | %9s | %8s | %s/%s |",
          row$cell_id, row$n, row$kind, fmt(row$r_time), fmt(row$julia_time),
          fmtx(row$speedup), fmt(row$dlogLik, "%.3e"), fmt(row$max_d_beta, "%.3e"),
          fmt(row$max_d_sd, "%.3f"), row$r_converged, row$julia_converged)
}

speedups <- tbl$speedup[is.finite(tbl$speedup)]
headline <- if (length(speedups)) {
  sprintf("Measured median speedup R/Julia: %.2fx (min %.2fx, max %.2fx)",
          stats::median(speedups), min(speedups), max(speedups))
} else {
  "Measured median speedup R/Julia: unavailable"
}

medium <- tbl[tbl$cell_id == "crossed_medium", , drop = FALSE]
large <- tbl[tbl$cell_id == "crossed_large", , drop = FALSE]
fixedq <- tbl[tbl$cell_id %in% c("fixedq_n1000", "crossed_medium", "fixedq_n20000"), , drop = FALSE]
fixedq <- fixedq[match(c("fixedq_n1000", "crossed_medium", "fixedq_n20000"), fixedq$cell_id), , drop = FALSE]
speed_gate <- nrow(medium) == 1 && is.finite(medium$speedup) && medium$speedup > 1
headline_gate <- all(c(medium$speedup, large$speedup) >= 2, na.rm = TRUE)
fixedq_gate <- nrow(fixedq) == 3 && all(is.finite(fixedq$speedup)) &&
  all(diff(fixedq$speedup) >= -0.05)

md <- c(
  "# Crossed Poisson sparse-Laplace benchmark (#70)",
  "",
  headline,
  "",
  "| cell | n | kind | R med/s | Julia med/s | speedup | |dLL| | max|dβ| | max|dSD| | conv R/J |",
  "|:-----|--:|:-----|--------:|------------:|--------:|------:|--------:|--------:|:---------|",
  vapply(seq_len(nrow(tbl)), function(i) line(tbl[i, ]), character(1)),
  "",
  "## Gates",
  "",
  sprintf("- Medium crossed cell Julia faster than drmTMB: %s", if (speed_gate) "PASS" else "FAIL"),
  sprintf("- Medium/large crossed cells at least 2x faster: %s", if (headline_gate) "PASS" else "FAIL"),
  sprintf("- Fixed-q speedup does not degrade as n grows: %s", if (fixedq_gate) "PASS" else "FAIL"),
  "- CPU-aware timing: both engines are run without post-fit SE/sdreport; Julia pins BLAS to one thread.",
  "- Correctness gates are reported numerically above; inspect |dLL| separately if constants differ.",
  "- All speedups above are measured from the JSON result files, not extrapolated.",
  ""
)

out <- file.path(report_dir, "crossed-poisson-benchmark.md")
writeLines(md, out)
cat(paste(md, collapse = "\n"), "\n")
