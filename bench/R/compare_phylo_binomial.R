## compare_phylo_binomial.R - summarize Binomial phylo Julia timing + R support.
##
## Run from repo root after the Julia timing and R smoke runners:
##   Rscript bench/R/compare_phylo_binomial.R

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
results_dir <- file.path(bench_root, "results", "phylo_binomial")
report_dir <- file.path(dirname(bench_root), "report")
dir.create(report_dir, showWarnings = FALSE, recursive = TRUE)

j_path <- file.path(results_dir, "julia_phylo_binomial.json")
r_path <- file.path(results_dir, "r_smoke_phylo_binomial.json")
if (!file.exists(j_path)) stop("Julia results missing: ", j_path)
if (!file.exists(r_path)) stop("R smoke results missing: ", r_path)

j_res <- jsonlite::read_json(j_path, simplifyVector = FALSE)
r_res <- jsonlite::read_json(r_path, simplifyVector = FALSE)

num <- function(x) suppressWarnings(as.numeric(x %||% NA_real_))
fmt <- function(x, f = "%.4f") if (is.finite(x)) sprintf(f, x) else "-"

rows <- lapply(j_res, function(j) {
  data.frame(
    cell_id = as.character(j$cell_id),
    p = as.integer(j$p),
    n = as.integer(j$n),
    julia_time = num(j$time_s_med),
    logLik = num(j$logLik),
    sd_phylo = num(j$sd_phylo),
    julia_converged = isTRUE(j$converged),
    stringsAsFactors = FALSE
  )
})
tbl <- do.call(rbind, rows)

line <- function(row) {
  sprintf("| %-11s | %5d | %5d | %9s | %9s | %7s | %s |",
          row$cell_id, row$p, row$n, fmt(row$julia_time),
          fmt(row$logLik, "%.3f"), fmt(row$sd_phylo, "%.3f"),
          row$julia_converged)
}

r_supported <- isTRUE(r_res[[1]]$supported)
all_conv <- all(tbl$julia_converged)
headline <- sprintf("median Julia time %.4fs", stats::median(tbl$julia_time))
speed_line <- if (r_supported) {
  "- R counterpart speedup available: FAIL - smoke says local-source drmTMB supports the route, but this slice did not run a paired R timing grid."
} else {
  "- R counterpart speedup available: FAIL - local-source drmTMB rejects Binomial phylo today."
}

md <- c(
  "# Binomial phylo sparse-Laplace benchmark",
  "",
  headline,
  "",
  if (r_supported) {
    "Local-source drmTMB smoke fit succeeded, but this slice has not run a paired R timing grid; no R/Julia speedup ratio is claimed."
  } else {
    "Local-source drmTMB currently rejects Binomial `phylo(1 | species)` models, so an R/Julia speedup ratio is unavailable for this slice."
  },
  "",
  "## Julia timings",
  "",
  "| cell | p | n | Julia med/s | logLik | phylo SD | converged |",
  "|:-----|--:|--:|------------:|-------:|---------:|:----------|",
  vapply(seq_len(nrow(tbl)), function(i) line(tbl[i, ]), character(1)),
  "",
  "## R support smoke",
  "",
  sprintf("- `binomial`: %s", if (r_supported) "supported" else "unsupported"),
  "",
  "## Gates",
  "",
  sprintf("- Julia converges in every measured cell: %s", if (all_conv) "PASS" else "FAIL"),
  speed_line,
  "- CPU-aware timing: Julia is run without post-fit SE/sdreport, pins BLAS to one thread, and uses `g_tol = 1e-6` for timing fits.",
  "- Scope: Binomial mean models with `phylo(1 | species)` only; no structured `sigma`, nuisance parameter, q>1 non-Gaussian phylo, or zero/hurdle variant is claimed here.",
  "- Recovery and gradient correctness are covered by `test/test_binomial_phylo_laplace.jl`; this report is a timing/support-status artifact.",
  ""
)

out <- file.path(report_dir, "phylo-binomial-benchmark.md")
writeLines(md, out)
cat(paste(md, collapse = "\n"), "\n")
