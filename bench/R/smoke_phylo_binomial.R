## smoke_phylo_binomial.R - local-source drmTMB support smoke for Binomial phylo.
##
## Run from repo root:
##   Rscript bench/R/smoke_phylo_binomial.R

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
results_dir <- file.path(bench_root, "results", "phylo_binomial")
dir.create(results_dir, showWarnings = FALSE, recursive = TRUE)

set.seed(2606401)
tr <- ape::rcoal(8)
tr$tip.label <- sprintf("sp%02d", seq_len(8))
dat <- data.frame(species = rep(tr$tip.label, each = 4), x = stats::rnorm(32))
prob <- stats::plogis(-0.1 + 0.3 * dat$x)
dat$successes <- stats::rbinom(nrow(dat), size = 8, prob = prob)
dat$failures <- 8 - dat$successes
ctrl <- drmTMB::drm_control(se = FALSE)

out <- tryCatch(
  {
    drmTMB::drmTMB(
      drmTMB::bf(cbind(successes, failures) ~ x + phylo(1 | species, tree = tr)),
      family = binomial(),
      data = dat,
      control = ctrl
    )
    list(family = "binomial", engine = "r_drmTMB", supported = TRUE, note = "fit")
  },
  error = function(e) {
    list(family = "binomial", engine = "r_drmTMB", supported = FALSE,
         note = conditionMessage(e))
  }
)

cat(sprintf("[R smoke binomial] supported=%s\n", out$supported))
jsonlite::write_json(list(out), file.path(results_dir, "r_smoke_phylo_binomial.json"),
                     auto_unbox = TRUE, pretty = TRUE, digits = NA)
