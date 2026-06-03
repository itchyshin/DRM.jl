## gen_phylo_nb2.R — deterministic NB2 phylo fixtures.
##
## Run from repo root:
##   Rscript bench/R/gen_phylo_nb2.R

suppressPackageStartupMessages({
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
fixtures_dir <- file.path(bench_root, "fixtures", "phylo_nb2")
dir.create(fixtures_dir, showWarnings = FALSE, recursive = TRUE)

cells <- list(
  list(id = "phylo_p100", p = 100, m = 5, n = 500, reps = 5, seed = 2606201),
  list(id = "phylo_p500", p = 500, m = 3, n = 1500, reps = 3, seed = 2606202),
  list(id = "phylo_p1000", p = 1000, m = 2, n = 2000, reps = 3, seed = 2606203),
  list(id = "phylo_p2000", p = 2000, m = 2, n = 4000, reps = 2, seed = 2606204)
)

scale_tree_height_one <- function(tr) {
  h <- max(ape::node.depth.edgelength(tr)[seq_along(tr$tip.label)])
  tr$edge.length <- tr$edge.length / h
  tr
}

simulate_cell <- function(cell) {
  set.seed(cell$seed)
  tr <- ape::rcoal(cell$p)
  tr$tip.label <- sprintf("sp%04d", seq_len(cell$p))
  tr <- scale_tree_height_one(tr)

  beta <- c(0.10, 0.30)
  sigma_phy <- 0.40
  sigma_nb2 <- 0.55
  theta_nb2 <- 1 / sigma_nb2^2
  b <- ape::rTraitCont(tr, model = "BM", sigma = sigma_phy)
  species <- rep(tr$tip.label, each = cell$m)
  x <- stats::rnorm(length(species))
  eta <- beta[[1]] + beta[[2]] * x + b[species]
  mu <- exp(eta)
  y <- stats::rnbinom(length(species), size = theta_nb2, mu = mu)

  df <- data.frame(y = y, x = x, species = species)
  write.csv(df, file.path(fixtures_dir, paste0(cell$id, ".csv")), row.names = FALSE)
  ape::write.tree(tr, file = file.path(fixtures_dir, paste0(cell$id, ".nwk")))
  jsonlite::write_json(
    list(
      cell_id = cell$id,
      p = cell$p,
      m = cell$m,
      n = length(species),
      beta = beta,
      sigma_phy = sigma_phy,
      sigma_nb2 = sigma_nb2,
      theta_nb2 = theta_nb2,
      seed = cell$seed
    ),
    file.path(fixtures_dir, paste0(cell$id, "_truth.json")),
    auto_unbox = TRUE,
    pretty = TRUE,
    digits = NA
  )
  cat(sprintf("[fixture %s] p=%d n=%d mean_y=%.3f theta=%.3f\n",
              cell$id, cell$p, length(species), mean(y), theta_nb2))
}

invisible(lapply(cells, simulate_cell))
