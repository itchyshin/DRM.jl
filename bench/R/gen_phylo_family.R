## gen_phylo_family.R -- deterministic non-Gaussian phylo benchmark fixtures.
##
## Run from repo root:
##   DRMTMB_SOURCE=/path/to/drmTMB Rscript bench/R/gen_phylo_family.R

suppressPackageStartupMessages({
  drmtmb_source <- Sys.getenv("DRMTMB_SOURCE", unset = "")
  if (nzchar(drmtmb_source)) {
    if (!requireNamespace("devtools", quietly = TRUE)) {
      stop("DRMTMB_SOURCE is set but devtools is not available to load_all().")
    }
    devtools::load_all(drmtmb_source, quiet = TRUE)
  } else if (!requireNamespace("drmTMB", quietly = TRUE)) {
    stop("drmTMB not installed; set DRMTMB_SOURCE to a source checkout.")
  }
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

phylo_tree <- function(n_tip) {
  stopifnot(n_tip >= 2L, log2(n_tip) == floor(log2(n_tip)))
  edges <- matrix(integer(), ncol = 2L)
  edge_lengths <- numeric()
  next_node <- n_tip + 1L
  build <- function(tips) {
    if (length(tips) == 1L) return(tips)
    node <- next_node
    next_node <<- next_node + 1L
    mid <- length(tips) / 2L
    left <- build(tips[seq_len(mid)])
    right <- build(tips[seq.int(mid + 1L, length(tips))])
    edges <<- rbind(edges, c(node, left), c(node, right))
    edge_lengths <<- c(edge_lengths, 1, 1)
    node
  }
  build(seq_len(n_tip))
  structure(
    list(
      edge = edges,
      edge.length = edge_lengths,
      tip.label = paste0("sp_", seq_len(n_tip)),
      Nnode = n_tip - 1L
    ),
    class = "phylo"
  )
}

write_matrix_csv <- function(path, x) {
  write.table(
    x, file = path, sep = ",", row.names = FALSE, col.names = FALSE,
    quote = FALSE
  )
}

bench_root <- tryCatch(here(), error = function(e) file.path(getwd(), "bench"))
fixtures_dir <- file.path(bench_root, "fixtures", "phylo_family")
dir.create(fixtures_dir, showWarnings = FALSE, recursive = TRUE)

cells <- list(
  list(id = "small", p = 16L, n_each = 20L, reps = 3L),
  list(id = "medium", p = 64L, n_each = 20L, reps = 3L)
)

for (j in seq_along(cells)) {
  cell <- cells[[j]]
  set.seed(20260603 + j)
  tree <- phylo_tree(cell$p)
  K <- drmTMB:::drm_phylo_tip_covariance(tree)
  u <- as.vector(t(chol(K)) %*% stats::rnorm(cell$p, sd = 0.35))
  names(u) <- tree$tip.label
  species <- rep(tree$tip.label, each = cell$n_each)
  x <- stats::rnorm(length(species))
  eta <- 0.10 + 0.45 * x + u[species]
  mu <- exp(eta)
  prob <- stats::plogis(eta)
  nb_size <- 3.0
  gamma_shape <- 7.0
  beta_precision <- 25.0
  dat <- data.frame(
    species = species,
    x = x,
    y_nb = stats::rnbinom(length(species), size = nb_size, mu = mu),
    y_gamma = stats::rgamma(length(species), shape = gamma_shape, scale = mu / gamma_shape),
    y_beta = stats::rbeta(
      length(species),
      shape1 = prob * beta_precision,
      shape2 = (1 - prob) * beta_precision
    )
  )
  write.csv(dat, file.path(fixtures_dir, paste0(cell$id, ".csv")), row.names = FALSE)
  write_matrix_csv(file.path(fixtures_dir, paste0(cell$id, "_K.csv")), K)
  cat(sprintf(
    "wrote %s p=%d n=%d\n",
    cell$id, cell$p, nrow(dat)
  ))
}
