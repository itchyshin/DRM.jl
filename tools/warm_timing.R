# tools/warm_timing.R — S12 (#563), root gate G5.
#
# Native-R warm-workflow timing harness (drmTMB, engine="tmb" -- never
# engine="julia"). Reads the SAME fixture CSV/Newick files
# tools/warm_timing_fixtures.jl wrote (never regenerates data), fits each
# registered workflow via drmTMB's own public front end, and writes a TSV with
# the identical column set tools/warm_timing.jl writes so
# tools/warm_timing_compare.jl can join them.
#
# Registry: docs/dev-log/evidence/julia-r-parity/warm-workflow-registry.md
#
# Threading:
#   - TMB::openmp(N) sets TMB's C++ AD-backend OpenMP thread count -- the
#     lever that actually matters for a TMB Laplace fit.
#   - RhpcBLASctl::blas_set_num_threads(N) would additionally pin R's BLAS if
#     installed; on THIS host (Mac, R 4.6.0, checked 2026-09-02) it is NOT
#     installed, so this script falls back to OMP_NUM_THREADS/OPENBLAS_NUM_THREADS
#     env vars (set before the R process starts -- setting them mid-session via
#     Sys.setenv() is NOT guaranteed to change an already-loaded BLAS's active
#     thread count) and prints a warning naming the gap. Install RhpcBLASctl
#     for a stronger guarantee before citing R-side thread scaling as verified.
#
# Usage (run once per thread count; set OMP_NUM_THREADS/OPENBLAS_NUM_THREADS
# in the environment BEFORE starting R, since the BLAS may already be loaded
# by the time this script runs):
#   OMP_NUM_THREADS=N OPENBLAS_NUM_THREADS=N Rscript tools/warm_timing.R \
#       --threads N --reps 3 \
#       --fixtures docs/dev-log/evidence/julia-r-parity/warm-fixtures \
#       --out docs/dev-log/evidence/julia-r-parity/warm-timing-r-tN.tsv
#   (add --workflow NAME to run a single workflow, e.g. for the smoke pre-run)

suppressMessages(library(drmTMB))
suppressMessages(library(ape))

# ---- CLI --------------------------------------------------------------------

parse_args <- function(argv) {
  a <- list(threads = NULL, reps = 3L, out = NULL,
            fixtures = "docs/dev-log/evidence/julia-r-parity/warm-fixtures",
            workflow = NULL)
  i <- 1L
  while (i <= length(argv)) {
    key <- argv[i]
    if (key == "--threads") { a$threads <- as.integer(argv[i + 1]); i <- i + 2L }
    else if (key == "--reps") { a$reps <- as.integer(argv[i + 1]); i <- i + 2L }
    else if (key == "--out") { a$out <- argv[i + 1]; i <- i + 2L }
    else if (key == "--fixtures") { a$fixtures <- argv[i + 1]; i <- i + 2L }
    else if (key == "--workflow") { a$workflow <- argv[i + 1]; i <- i + 2L }
    else stop("warm_timing.R: unknown arg ", key)
  }
  if (is.null(a$threads)) stop("warm_timing.R: --threads N is required")
  if (is.null(a$out)) stop("warm_timing.R: --out FILE is required")
  a
}
args <- parse_args(commandArgs(trailingOnly = TRUE))

# ---- thread control -----------------------------------------------------

TMB::openmp(args$threads)
if (requireNamespace("RhpcBLASctl", quietly = TRUE)) {
  RhpcBLASctl::blas_set_num_threads(args$threads)
} else {
  cat(sprintf("WARNING: RhpcBLASctl not installed -- R BLAS thread count NOT pinned to %d at runtime; only TMB::openmp(%d) is active. Set OMP_NUM_THREADS=%d OPENBLAS_NUM_THREADS=%d before starting R for a stronger guarantee.\n",
              args$threads, args$threads, args$threads, args$threads))
}

# ---- timing helper (mirrors tools/bench_fit_h2h.R's time_median) ------------

time_reps <- function(f, k) {
  times <- numeric(k); val <- NULL
  for (i in seq_len(k)) {
    t0 <- proc.time()[["elapsed"]]
    val <- f()
    times[i] <- proc.time()[["elapsed"]] - t0
  }
  list(val = val, times = times, median_s = stats::median(times), min_s = min(times))
}

fit_converged <- function(fit) tryCatch(isTRUE(fit$opt$convergence == 0L), error = function(e) NA)
fit_loglik <- function(fit) tryCatch(as.numeric(stats::logLik(fit)), error = function(e) NA_real_)

# ---- workflow registry (must match warm-workflow-registry.md) ---------------

read_tree <- function(path) ape::read.tree(path)

workflows <- list(
  gauss_mixed_phylo_mean = function(fixdir) {
    d <- read.csv(file.path(fixdir, "gauss_mixed_phylo_mean.csv"), stringsAsFactors = FALSE)
    d$study <- as.integer(d$study)
    tree <- read_tree(file.path(fixdir, "gauss_mixed_phylo_mean.nwk"))
    f <- bf(y ~ x + (1 | study) + phylo(1 | species), sigma ~ 1)
    list(fit = function() drmTMB(f, family = stats::gaussian(), data = d, tree = tree, engine = "tmb"),
         data = d)
  },
  gauss_lss_sd_group = function(fixdir) {
    d <- read.csv(file.path(fixdir, "gauss_lss_sd_group.csv"), stringsAsFactors = FALSE)
    d$g <- as.integer(d$g)
    f <- bf(y ~ x + (1 | g), sigma ~ z, sd(g) ~ z)
    list(fit = function() drmTMB(f, family = stats::gaussian(), data = d, engine = "tmb"),
         data = d)
  },
  gauss_lss_sd_phylo = function(fixdir) {
    d <- read.csv(file.path(fixdir, "gauss_lss_sd_phylo.csv"), stringsAsFactors = FALSE)
    tree <- read_tree(file.path(fixdir, "gauss_lss_sd_phylo.nwk"))
    f <- bf(y ~ x + phylo(1 | species), sigma ~ x, sd(species, level = "phylogenetic") ~ x)
    list(fit = function() drmTMB(f, family = stats::gaussian(), data = d, tree = tree, engine = "tmb"),
         data = d)
  },
  biv_q4_phylo_ml = function(fixdir) {
    d <- read.csv(file.path(fixdir, "biv_q4_phylo.csv"), stringsAsFactors = FALSE)
    tree <- read_tree(file.path(fixdir, "biv_q4_phylo.nwk"))
    f <- bf(mu1 = y1 ~ x + phylo(1 | p | species), mu2 = y2 ~ x + phylo(1 | p | species),
            sigma1 = ~1, sigma2 = ~1, rho12 = ~1)
    list(fit = function() drmTMB(f, family = biv_gaussian(), data = d, tree = tree, REML = FALSE, engine = "tmb"),
         data = d)
  },
  biv_q4_phylo_reml = function(fixdir) {
    d <- read.csv(file.path(fixdir, "biv_q4_phylo.csv"), stringsAsFactors = FALSE)
    tree <- read_tree(file.path(fixdir, "biv_q4_phylo.nwk"))
    f <- bf(mu1 = y1 ~ x + phylo(1 | p | species), mu2 = y2 ~ x + phylo(1 | p | species),
            sigma1 = ~1, sigma2 = ~1, rho12 = ~1)
    list(fit = function() drmTMB(f, family = biv_gaussian(), data = d, tree = tree, REML = TRUE, engine = "tmb"),
         data = d)
  },
  bernoulli_mixed = function(fixdir) {
    d <- read.csv(file.path(fixdir, "bernoulli_mixed.csv"), stringsAsFactors = FALSE)
    d$g <- as.integer(d$g)
    f <- bf(y ~ x + (1 | g))
    list(fit = function() drmTMB(f, family = stats::binomial(), data = d, engine = "tmb"),
         data = d)
  },
  poisson_mixed = function(fixdir) {
    d <- read.csv(file.path(fixdir, "poisson_mixed.csv"), stringsAsFactors = FALSE)
    d$g <- as.integer(d$g)
    f <- bf(y ~ x + (1 | g))
    list(fit = function() drmTMB(f, family = stats::poisson(), data = d, engine = "tmb"),
         data = d)
  },
  lognormal_locscale = function(fixdir) {
    d <- read.csv(file.path(fixdir, "lognormal_locscale.csv"), stringsAsFactors = FALSE)
    f <- bf(y ~ x, sigma ~ z)
    list(fit = function() drmTMB(f, family = drmTMB::lognormal(), data = d, engine = "tmb"),
         data = d)
  },
  meta_analysis_meta_V = function(fixdir) {
    d <- read.csv(file.path(fixdir, "meta_analysis.csv"), stringsAsFactors = FALSE)
    f <- bf(y ~ x + meta_V(v), sigma ~ 1)
    list(fit = function() drmTMB(f, family = stats::gaussian(), data = d, engine = "tmb"),
         data = d)
  },
  large_sparse_lss_p2000 = function(fixdir) {
    d <- read.csv(file.path(fixdir, "large_sparse_lss_p2000.csv"), stringsAsFactors = FALSE)
    tree <- read_tree(file.path(fixdir, "large_sparse_lss_p2000.nwk"))
    f <- bf(y ~ x + phylo(1 | species), sigma ~ x, sd(species, level = "phylogenetic") ~ x)
    list(fit = function() drmTMB(f, family = stats::gaussian(), data = d, tree = tree, engine = "tmb"),
         data = d)
  }
)

# ---- run --------------------------------------------------------------------

commit <- tryCatch(system2("git", c("rev-parse", "--short", "HEAD"), stdout = TRUE, stderr = FALSE),
                    error = function(e) "unknown")
if (length(commit) == 0 || !nzchar(commit)) commit <- "unknown"

names_to_run <- if (!is.null(args$workflow)) args$workflow else names(workflows)
stopifnot(all(names_to_run %in% names(workflows)))

rows <- character(0)
header <- paste("engine", "workflow", "leg", "threads", "reps", "median_s", "min_s",
                 "converged", "loglik", "r_version", "blas_threads", "commit", sep = "\t")
rows <- c(rows, header)

for (wname in names_to_run) {
  cat(sprintf("== %s ==\n", wname))
  w <- workflows[[wname]](args$fixtures)
  cat("  warm-up (untimed) ... ")
  fit0 <- w$fit()
  ci0 <- tryCatch(confint(fit0), error = function(e) NULL)
  pr0 <- tryCatch(predict(fit0, newdata = w$data), error = function(e) NULL)
  cat("done\n")

  r_fit <- time_reps(w$fit, args$reps)
  conv <- fit_converged(r_fit$val); ll <- fit_loglik(r_fit$val)
  cat(sprintf("  fit:         median=%.4fs min=%.4fs conv=%s loglik=%.4f\n",
              r_fit$median_s, r_fit$min_s, conv, ll))
  rows <- c(rows, paste("drmTMB", wname, "fit", args$threads, args$reps,
                         sprintf("%.6f", r_fit$median_s), sprintf("%.6f", r_fit$min_s),
                         conv, sprintf("%.6f", ll), R.version.string, args$threads, commit, sep = "\t"))

  fitref <- r_fit$val
  r_unc <- time_reps(function() confint(fitref), args$reps)
  cat(sprintf("  uncertainty: median=%.4fs min=%.4fs\n", r_unc$median_s, r_unc$min_s))
  rows <- c(rows, paste("drmTMB", wname, "uncertainty", args$threads, args$reps,
                         sprintf("%.6f", r_unc$median_s), sprintf("%.6f", r_unc$min_s),
                         conv, sprintf("%.6f", ll), R.version.string, args$threads, commit, sep = "\t"))

  r_pred <- time_reps(function() predict(fitref, newdata = w$data), args$reps)
  cat(sprintf("  predict:     median=%.4fs min=%.4fs\n", r_pred$median_s, r_pred$min_s))
  rows <- c(rows, paste("drmTMB", wname, "predict", args$threads, args$reps,
                         sprintf("%.6f", r_pred$median_s), sprintf("%.6f", r_pred$min_s),
                         conv, sprintf("%.6f", ll), R.version.string, args$threads, commit, sep = "\t"))
}

dir.create(dirname(args$out), showWarnings = FALSE, recursive = TRUE)
writeLines(rows, args$out)
cat("wrote ", args$out, "\n", sep = "")
