## smoke_phylo_gamma_beta.R — local-source drmTMB support smoke for Gamma/Beta phylo.
##
## Run from repo root:
##   Rscript bench/R/smoke_phylo_gamma_beta.R

suppressPackageStartupMessages({
  local_drmTMB <- "/Users/z3437171/Dropbox/Github Local/drmTMB"
  if (dir.exists(local_drmTMB) && requireNamespace("devtools", quietly = TRUE)) {
    devtools::load_all(local_drmTMB, quiet = TRUE)
  } else if (requireNamespace("drmTMB", quietly = TRUE)) {
    library(drmTMB)
  } else {
    stop("drmTMB not installed and devtools not available to load_all().")
  }
  library(ape)
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
results_dir <- file.path(bench_root, "results", "phylo_gamma_beta")
dir.create(results_dir, showWarnings = FALSE, recursive = TRUE)

set.seed(2606301)
tr <- ape::rcoal(8)
tr$tip.label <- sprintf("sp%02d", seq_len(8))
dat <- data.frame(species = rep(tr$tip.label, each = 3), x = stats::rnorm(24))
dat$y_gamma <- stats::rgamma(24, shape = 4, scale = exp(0.1 + 0.2 * dat$x) / 4)
dat$y_beta <- stats::rbeta(24, 6, 6)
ctrl <- drmTMB::drm_control(se = FALSE)

try_fit <- function(family, expr) {
  out <- tryCatch(
    {
      force(expr)
      list(family = family, engine = "r_drmTMB", supported = TRUE, note = "fit")
    },
    error = function(e) {
      list(family = family, engine = "r_drmTMB", supported = FALSE,
           note = conditionMessage(e))
    }
  )
  cat(sprintf("[R smoke %s] supported=%s\n", family, out$supported))
  out
}

results <- list(
  try_fit(
    "gamma",
    drmTMB::drmTMB(
      drmTMB::bf(y_gamma ~ x + phylo(1 | species, tree = tr), sigma ~ 1),
      family = Gamma(link = "log"),
      data = dat,
      control = ctrl
    )
  ),
  try_fit(
    "beta",
    drmTMB::drmTMB(
      drmTMB::bf(y_beta ~ x + phylo(1 | species, tree = tr), sigma ~ 1),
      family = beta(),
      data = dat,
      control = ctrl
    )
  )
)

jsonlite::write_json(results, file.path(results_dir, "r_smoke_phylo_gamma_beta.json"),
                     auto_unbox = TRUE, pretty = TRUE, digits = NA)
