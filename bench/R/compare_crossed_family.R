## compare_crossed_family.R -- aggregate #80 Julia vs drmTMB family benchmark.
##
## Run from repo root after both fit runners:
##   Rscript bench/R/compare_crossed_family.R

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
results_dir <- file.path(bench_root, "results", "crossed_family")
report_dir <- file.path(dirname(bench_root), "report")
dir.create(report_dir, showWarnings = FALSE, recursive = TRUE)

r_path <- file.path(results_dir, "r_crossed_family.json")
j_path <- file.path(results_dir, "julia_crossed_family.json")
if (!file.exists(r_path)) stop("R results missing: ", r_path)
if (!file.exists(j_path)) stop("Julia results missing: ", j_path)

r_res <- jsonlite::read_json(r_path, simplifyVector = FALSE)
j_res <- jsonlite::read_json(j_path, simplifyVector = FALSE)

key <- function(x) paste(as.character(x$cell_id), as.character(x$family), sep = "::")
idx <- function(x) setNames(x, vapply(x, key, character(1)))
r_by <- idx(r_res)
j_by <- idx(j_res)
missing_j <- setdiff(names(r_by), names(j_by))
if (length(missing_j)) stop("Julia results missing cells: ", paste(missing_j, collapse = ", "))

num <- function(x) suppressWarnings(as.numeric(x %||% NA_real_))
vec <- function(x) as.numeric(unlist(x %||% numeric()))

rows <- lapply(names(r_by), function(id) {
  r <- r_by[[id]]
  j <- j_by[[id]]
  rb <- vec(r$beta_mu)
  jb <- vec(j$beta_mu)
  d_beta <- if (length(rb) == length(jb) && length(rb)) max(abs(rb - jb)) else NA_real_
  sd_diffs <- abs(c(num(r$sd_g) - num(j$sd_g), num(r$sd_h) - num(j$sd_h)))
  finite_sd <- sd_diffs[is.finite(sd_diffs)]
  d_sd <- if (length(finite_sd)) max(finite_sd) else NA_real_
  rt <- num(r$time_s_med)
  jt <- num(j$time_s_med)
  data.frame(
    cell_id = as.character(r$cell_id %||% j$cell_id),
    family = as.character(r$family %||% j$family),
    n = as.integer(r$n %||% j$n %||% NA_integer_),
    r_time = rt,
    julia_time = jt,
    speedup = if (is.finite(rt) && is.finite(jt) && jt > 0) rt / jt else NA_real_,
    dlogLik = abs(num(r$logLik) - num(j$logLik)),
    max_d_beta = d_beta,
    d_nuisance = abs(num(r$nuisance) - num(j$nuisance)),
    max_d_sd = d_sd,
    r_converged = isTRUE(r$converged),
    julia_converged = isTRUE(j$converged),
    r_note = as.character(r$note %||% ""),
    stringsAsFactors = FALSE
  )
})
tbl <- do.call(rbind, rows)

fmt <- function(x, f = "%.4f") if (is.finite(x)) sprintf(f, x) else "-"
fmtx <- function(x) if (is.finite(x)) sprintf("%.2fx", x) else "-"
line <- function(row) {
  sprintf("| %-13s | %-8s | %6d | %9s | %9s | %8s | %9s | %9s | %8s | %8s | %s/%s |",
          row$cell_id, row$family, row$n, fmt(row$r_time), fmt(row$julia_time),
          fmtx(row$speedup), fmt(row$max_d_beta, "%.3e"),
          fmt(row$d_nuisance, "%.3f"), fmt(row$max_d_sd, "%.3f"),
          fmt(row$dlogLik, "%.3e"), row$r_converged, row$julia_converged)
}

ok_speed <- tbl[is.finite(tbl$speedup) & tbl$r_converged & tbl$julia_converged, , drop = FALSE]
headline <- if (nrow(ok_speed)) {
  sprintf("Measured median speedup R/Julia across successful paired cells: %.2fx (min %.2fx, max %.2fx)",
          stats::median(ok_speed$speedup), min(ok_speed$speedup), max(ok_speed$speedup))
} else {
  "Measured median speedup R/Julia across successful paired cells: unavailable"
}

medium <- tbl[tbl$cell_id == "medium" & is.finite(tbl$speedup), , drop = FALSE]
medium_gate <- nrow(medium) > 0 && all(medium$speedup > 1)
headline_gate <- nrow(medium) > 0 && all(medium$speedup >= 2)
parity_gate <- nrow(ok_speed) > 0 &&
  all(ok_speed$max_d_beta < 1e-2, na.rm = TRUE) &&
  all(ok_speed$max_d_sd < 0.08, na.rm = TRUE)

failure_rows <- tbl[nzchar(tbl$r_note), c("cell_id", "family", "r_note"), drop = FALSE]
failure_text <- if (nrow(failure_rows)) {
  c("## R failures/time-limited cells", "",
    apply(failure_rows, 1, function(z) sprintf("- `%s` `%s`: %s", z[[1]], z[[2]], z[[3]])))
} else {
  c("## R failures/time-limited cells", "", "- None recorded by the R runner.")
}

md <- c(
  "# Crossed non-Gaussian sparse-Laplace family benchmark (#80)",
  "",
  headline,
  "",
  "| cell | family | n | R med/s | Julia med/s | speedup | max d_beta | d nuisance | max d_SD | abs d_LL | conv R/J |",
  "|:-----|:-------|--:|--------:|------------:|--------:|--------:|-----------:|--------:|------:|:---------|",
  vapply(seq_len(nrow(tbl)), function(i) line(tbl[i, ]), character(1)),
  "",
  "## Gates",
  "",
  sprintf("- Every successful medium family cell Julia faster than drmTMB: %s", if (medium_gate) "PASS" else "FAIL"),
  sprintf("- Every successful medium family cell at least 2x faster: %s", if (headline_gate) "PASS" else "FAIL"),
  sprintf("- Coefficient and RE-SD parity on successful paired cells: %s", if (parity_gate) "PASS" else "FAIL"),
  "- CPU-aware timing: both engines run without post-fit SE/sdreport; Julia pins BLAS to one thread.",
  "- `|dLL|` is reported as an objective-parity diagnostic; constants may differ by family.",
  "- All speedups above are measured from JSON result files, not extrapolated.",
  "",
  failure_text,
  ""
)

out <- file.path(report_dir, "crossed-family-benchmark.md")
writeLines(md, out)
cat(paste(md, collapse = "\n"), "\n")
