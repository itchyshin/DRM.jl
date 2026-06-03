## compare_phylo_gamma_beta.R - summarize Gamma/Beta phylo Julia timing + R support.
##
## Run from repo root after the Julia timing and R smoke runners:
##   Rscript bench/R/compare_phylo_gamma_beta.R

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
results_dir <- file.path(bench_root, "results", "phylo_gamma_beta")
report_dir <- file.path(dirname(bench_root), "report")
dir.create(report_dir, showWarnings = FALSE, recursive = TRUE)

j_path <- file.path(results_dir, "julia_phylo_gamma_beta.json")
r_path <- file.path(results_dir, "r_smoke_phylo_gamma_beta.json")
if (!file.exists(j_path)) stop("Julia results missing: ", j_path)
if (!file.exists(r_path)) stop("R smoke results missing: ", r_path)

j_res <- jsonlite::read_json(j_path, simplifyVector = FALSE)
r_res <- jsonlite::read_json(r_path, simplifyVector = FALSE)

num <- function(x) suppressWarnings(as.numeric(x %||% NA_real_))
fmt <- function(x, f = "%.4f") if (is.finite(x)) sprintf(f, x) else "-"

rows <- lapply(j_res, function(j) {
  data.frame(
    family = as.character(j$family),
    cell_id = as.character(j$cell_id),
    p = as.integer(j$p),
    n = as.integer(j$n),
    julia_time = num(j$time_s_med),
    logLik = num(j$logLik),
    sigma = num(j$sigma),
    sd_phylo = num(j$sd_phylo),
    julia_converged = isTRUE(j$converged),
    stringsAsFactors = FALSE
  )
})
tbl <- do.call(rbind, rows)

line <- function(row) {
  sprintf("| %-5s | %-11s | %5d | %5d | %9s | %9s | %7s | %7s | %s |",
          row$family, row$cell_id, row$p, row$n, fmt(row$julia_time),
          fmt(row$logLik, "%.3f"), fmt(row$sigma, "%.3f"),
          fmt(row$sd_phylo, "%.3f"), row$julia_converged)
}

r_status <- vapply(r_res, function(x) {
  sprintf("- `%s`: %s", x$family, if (isTRUE(x$supported)) "supported" else "unsupported")
}, character(1))

all_conv <- all(tbl$julia_converged)
family_medians <- aggregate(julia_time ~ family, tbl, stats::median)
headline <- paste(
  sprintf("%s median Julia time %.4fs", family_medians$family, family_medians$julia_time),
  collapse = "; "
)

md <- c(
  "# Gamma/Beta phylo sparse-Laplace benchmark",
  "",
  headline,
  "",
  "Local-source drmTMB currently rejects Gamma and Beta `phylo(1 | species)` models, so an R/Julia speedup ratio is unavailable for this slice.",
  "",
  "## Julia timings",
  "",
  "| family | cell | p | n | Julia med/s | logLik | sigma | phylo SD | converged |",
  "|:-------|:-----|--:|--:|------------:|-------:|------:|---------:|:----------|",
  vapply(seq_len(nrow(tbl)), function(i) line(tbl[i, ]), character(1)),
  "",
  "## R support smoke",
  "",
  r_status,
  "",
  "## Gates",
  "",
  sprintf("- Julia converges in every measured cell: %s", if (all_conv) "PASS" else "FAIL"),
  "- R counterpart speedup available: FAIL - local-source drmTMB rejects both Gamma and Beta phylo today.",
  "- CPU-aware timing: Julia is run without post-fit SE/sdreport, pins BLAS to one thread, and uses `g_tol = 1e-6` for timing fits.",
  "- Scope: Gamma/Beta mean models with `phylo(1 | species)` and `sigma ~ 1` only; no structured `sigma`, q>1 non-Gaussian phylo, or binomial-style no-nuisance model is claimed here.",
  "- Recovery and gradient correctness are covered by `test/test_gamma_beta_phylo_laplace.jl`; this report is a timing/support-status artifact.",
  ""
)

out <- file.path(report_dir, "phylo-gamma-beta-benchmark.md")
writeLines(md, out)
cat(paste(md, collapse = "\n"), "\n")
