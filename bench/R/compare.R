## compare.R
##
## Aggregate r_results.json + julia_results.json into report/summary.md and
## print the same table to stdout. Gates from CONTRACT.md:
##   |Delta logLik| < 1e-3
##   max |Delta coef| < 1e-2
##   median speedup R/Julia is a headline figure, not a hard gate.
##
## Run from the repo root: `Rscript R/compare.R`

suppressPackageStartupMessages({
  library(jsonlite)
})

`%||%` <- function(a, b) if (is.null(a)) b else a

## --- Resolve repo root regardless of working directory --------------------
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
repo_root   <- tryCatch(here(), error = function(e) getwd())
results_dir <- file.path(repo_root, "results")
report_dir  <- file.path(repo_root, "report")
dir.create(report_dir, showWarnings = FALSE, recursive = TRUE)

r_path <- file.path(results_dir, "r_results.json")
j_path <- file.path(results_dir, "julia_results.json")

if (!file.exists(r_path)) {
  stop("R results not found at ", r_path, " — run R/fit_r.R first.")
}
if (!file.exists(j_path)) {
  cat("Julia results not yet present at ", j_path, " — exiting gracefully.\n",
      sep = "")
  quit(status = 0L)
}

r_res <- jsonlite::read_json(r_path,  simplifyVector = FALSE)
j_res <- jsonlite::read_json(j_path,  simplifyVector = FALSE)

if (!length(j_res)) {
  cat("Julia results file at ", j_path, " is empty — nothing to compare yet.\n",
      sep = "")
  quit(status = 0L)
}

index_by_cell <- function(lst) {
  ids <- vapply(lst, function(x) as.character(x$cell_id), character(1L))
  setNames(lst, ids)
}
r_by <- index_by_cell(r_res)
j_by <- index_by_cell(j_res)
## Print one row per R cell so the phylo/q4 cells show up even when Julia
## hasn't fit them yet (q4 is documented out-of-scope for the POC).
cell_ids <- names(r_by)
if (!length(cell_ids)) {
  cat("No R results — nothing to compare.\n")
  quit(status = 0L)
}

beta_keys_for <- function(model) {
  switch(
    as.character(model),
    univariate = c("beta_mu", "beta_sigma"),
    phylo_uni  = c("beta_mu"),
    q4         = c("beta_mu1", "beta_mu2", "beta_sigma1", "beta_sigma2", "beta_rho12"),
    c("beta_mu1", "beta_mu2", "beta_sigma1", "beta_sigma2", "beta_rho12")
  )
}

## Print order: 5 headline cells first, then 4 phylo cells, then q4.
display_order <- c(
  "u_small", "u_med", "u_large", "b_small", "b_med",
  "phylo_p50", "phylo_p200", "phylo_p500", "phylo_p1000",
  "q4_p100"
)
ordered_ids <- c(
  intersect(display_order, cell_ids),
  setdiff(cell_ids, display_order)
)

per_cell <- lapply(ordered_ids, function(cid) {
  r <- r_by[[cid]]
  j <- j_by[[cid]]
  model <- r$model %||% (if (!is.null(j)) j$model else NULL) %||% "univariate"
  keys  <- beta_keys_for(model)

  has_julia <- !is.null(j)

  ## Pull numeric vectors and compute max absolute coef difference across
  ## all beta_* vectors (absolute scale, per the contract).
  if (has_julia) {
    coef_diffs <- vapply(keys, function(k) {
      rv <- as.numeric(unlist(r[[k]]))
      jv <- as.numeric(unlist(j[[k]]))
      if (length(rv) == 0L || length(jv) == 0L || length(rv) != length(jv)) {
        return(NA_real_)
      }
      max(abs(rv - jv))
    }, numeric(1L))
    max_dcoef <- if (all(is.na(coef_diffs))) NA_real_ else max(coef_diffs, na.rm = TRUE)
  } else {
    max_dcoef <- NA_real_
  }

  r_time <- as.numeric(r$time_s_med %||% r$time_s %||% NA_real_)
  j_time <- if (has_julia) as.numeric(j$time_s_med %||% j$time_s %||% NA_real_) else NA_real_
  speedup <- if (is.finite(r_time) && is.finite(j_time) && j_time > 0) {
    r_time / j_time
  } else {
    NA_real_
  }

  dll <- if (has_julia) {
    abs(as.numeric(r$logLik) - as.numeric(j$logLik))
  } else {
    NA_real_
  }

  julia_status <- if (has_julia) {
    "fit"
  } else if (identical(as.character(model), "q4")) {
    "POC scope: needs Laplace"
  } else {
    "no julia result"
  }

  data.frame(
    cell_id      = cid,
    n            = as.integer(r$n %||% (if (!is.null(j)) j$n else NA_integer_) %||% NA_integer_),
    r_time       = r_time,
    julia_time   = j_time,
    speedup      = speedup,
    dlogLik      = dll,
    max_dcoef    = max_dcoef,
    julia_status = julia_status,
    stringsAsFactors = FALSE
  )
})
tbl <- do.call(rbind, per_cell)

fmt_num <- function(x, fmt) if (is.finite(x)) sprintf(fmt, x) else "      -"
fmt_speedup <- function(x) if (is.finite(x)) sprintf("%7.1fx", x) else "      -"

fmt_row <- function(row) {
  julia_cell <- if (identical(row$julia_status, "fit")) {
    fmt_num(row$julia_time, "%8.4f")
  } else {
    sprintf("%-23s", row$julia_status)
  }
  sprintf(
    "| %-11s | %5d | %8.4f | %s | %8s | %s | %s |",
    row$cell_id, row$n,
    row$r_time, julia_cell,
    fmt_speedup(row$speedup),
    fmt_num(row$dlogLik, "%.3e"),
    fmt_num(row$max_dcoef, "%.3e")
  )
}

header <- c(
  "| cell_id     |     n | R time/s | Jl time/s               | speedup  |  |dLL|     | max|dCoef|  |",
  "|:------------|------:|---------:|:------------------------|---------:|-----------:|------------:|"
)
body <- vapply(seq_len(nrow(tbl)), function(i) fmt_row(tbl[i, ]), character(1L))

speedups <- tbl$speedup[is.finite(tbl$speedup)]
headline <- if (length(speedups) >= 1L) {
  sprintf(
    "Median speedup R/Julia: %.1fx, max %.1fx, min %.1fx",
    stats::median(speedups), max(speedups), min(speedups)
  )
} else {
  "Median speedup R/Julia: (unavailable)"
}

## Gate evaluation (loose POC gates from the contract)
gate_dll  <- 1e-3
gate_dcf  <- 1e-2
dll_pass  <- all(tbl$dlogLik   < gate_dll, na.rm = TRUE)
dcf_pass  <- all(tbl$max_dcoef < gate_dcf, na.rm = TRUE)
gate_lines <- c(
  sprintf("- |dLogLik| < %g for all cells: %s", gate_dll,
          if (dll_pass) "PASS" else "FAIL"),
  sprintf("- max |dCoef| < %g for all cells: %s", gate_dcf,
          if (dcf_pass) "PASS" else "FAIL"),
  "- Median speedup R/Julia: informational, no hard gate at POC stage."
)
overall <- if (dll_pass && dcf_pass) "Overall: PASS" else "Overall: FAIL"

## Build summary.md
md <- c(
  "# drmTMB vs Julia POC benchmark — summary",
  "",
  headline,
  "",
  header,
  body,
  "",
  "## Gate check",
  "",
  gate_lines,
  "",
  overall,
  ""
)

out_md <- file.path(report_dir, "summary.md")
writeLines(md, out_md)

## Print same table + headline to stdout
cat(headline, "\n", sep = "")
cat(paste(header, collapse = "\n"), "\n", sep = "")
cat(paste(body,   collapse = "\n"), "\n", sep = "")
cat("\n", paste(gate_lines, collapse = "\n"), "\n", sep = "")
cat(overall, "\n\n", sep = "")
cat("Wrote ", out_md, "\n", sep = "")
