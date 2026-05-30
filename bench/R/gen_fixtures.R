## gen_fixtures.R
##
## Generate the 5 CSV fixtures + truth JSON files for the drmTMB vs Julia POC
## benchmark, per the contract in ../CONTRACT.md.
##
## Run from the repo root: `Rscript R/gen_fixtures.R`

suppressPackageStartupMessages({
  library(MASS)      # mvrnorm
  library(readr)     # write_csv
  library(jsonlite)  # write_json
  library(ape)       # rcoal, vcv, write.tree
})

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
`%||%` <- function(a, b) if (is.null(a)) b else a
repo_root <- tryCatch(here(), error = function(e) getwd())
fixtures_dir <- file.path(repo_root, "fixtures")
dir.create(fixtures_dir, showWarnings = FALSE, recursive = TRUE)

## --- Cell table (1-indexed; matches CONTRACT.md) --------------------------
cells <- list(
  list(id = "u_small", n = 100,  model = "univariate"),
  list(id = "u_med",   n = 500,  model = "univariate"),
  list(id = "u_large", n = 2000, model = "univariate"),
  list(id = "b_small", n = 200,  model = "bivariate"),
  list(id = "b_med",   n = 1000, model = "bivariate")
)

## True parameters (from contract)
truth_univariate <- list(
  beta_mu    = c(1.0, 0.5, -0.3),
  beta_sigma = c(0.2, 0.15)
)
truth_b_small <- list(
  beta_mu1    = c(1.0, 0.4),
  beta_mu2    = c(-0.5, 0.6),
  beta_sigma1 = c(0.1),
  beta_sigma2 = c(-0.05),
  beta_rho12  = c(0.4)
)
truth_b_med <- list(
  beta_mu1    = c(1.0, 0.4),
  beta_mu2    = c(-0.5, 0.6),
  beta_sigma1 = c(0.1, 0.2),
  beta_sigma2 = c(-0.05, 0.1),
  beta_rho12  = c(0.4, 0.3)
)

simulate_cell <- function(cell, idx) {
  set.seed(42 + idx)
  n <- cell$n
  x1 <- rnorm(n)
  x2 <- rnorm(n)

  if (cell$model == "univariate") {
    bmu <- truth_univariate$beta_mu      # length 3: intercept, x1, x2
    bsg <- truth_univariate$beta_sigma   # length 2: intercept, x1
    mu    <- bmu[1] + bmu[2] * x1 + bmu[3] * x2
    sigma <- exp(bsg[1] + bsg[2] * x1)
    y <- rnorm(n, mu, sigma)
    df <- data.frame(y = y, x1 = x1, x2 = x2)
    truth <- list(
      cell_id    = cell$id,
      n          = n,
      model      = "univariate",
      beta_mu    = bmu,
      beta_sigma = bsg
    )
  } else {
    if (cell$id == "b_small") {
      tr <- truth_b_small
    } else {
      tr <- truth_b_med
    }
    bmu1 <- tr$beta_mu1
    bmu2 <- tr$beta_mu2
    bsg1 <- tr$beta_sigma1
    bsg2 <- tr$beta_sigma2
    brh  <- tr$beta_rho12

    mu1 <- bmu1[1] + bmu1[2] * x1
    mu2 <- bmu2[1] + bmu2[2] * x1
    s1  <- if (length(bsg1) == 1L) rep(exp(bsg1[1]), n) else exp(bsg1[1] + bsg1[2] * x1)
    s2  <- if (length(bsg2) == 1L) rep(exp(bsg2[1]), n) else exp(bsg2[1] + bsg2[2] * x1)
    eta <- if (length(brh) == 1L) rep(brh[1], n) else brh[1] + brh[2] * x1
    rho <- 0.99999999 * tanh(eta)

    ## Per-row Cholesky (because Sigma_i may vary with i)
    Y <- matrix(NA_real_, n, 2)
    for (i in seq_len(n)) {
      S <- matrix(
        c(s1[i]^2,                rho[i] * s1[i] * s2[i],
          rho[i] * s1[i] * s2[i], s2[i]^2),
        nrow = 2L
      )
      Y[i, ] <- MASS::mvrnorm(1L, mu = c(mu1[i], mu2[i]), Sigma = S)
    }
    df <- data.frame(y1 = Y[, 1], y2 = Y[, 2], x1 = x1, x2 = x2)
    truth <- list(
      cell_id     = cell$id,
      n           = n,
      model       = "bivariate",
      beta_mu1    = bmu1,
      beta_mu2    = bmu2,
      beta_sigma1 = bsg1,
      beta_sigma2 = bsg2,
      beta_rho12  = brh
    )
  }

  csv_path   <- file.path(fixtures_dir, paste0(cell$id, ".csv"))
  truth_path <- file.path(fixtures_dir, paste0(cell$id, "_truth.json"))
  readr::write_csv(df, csv_path)
  jsonlite::write_json(truth, truth_path, auto_unbox = TRUE, pretty = TRUE)
  cat(sprintf("wrote %s (%d rows, %d cols) + %s\n",
              basename(csv_path), nrow(df), ncol(df), basename(truth_path)))
  invisible(NULL)
}

for (i in seq_along(cells)) {
  simulate_cell(cells[[i]], i)
}

## --- Phylogenetic univariate cells -----------------------------------------
## See CONTRACT.md "Phylogenetic cells". One observation per species; tree
## generated via ape::rcoal(p) with cell-specific seeds. Both R and Julia
## read the species-keyed CSV; Julia also reads <cell>_sigma_phy.csv. R also
## reads <cell>_tree.nwk via ape::read.tree() because drmTMB's phylo() needs
## the actual tree, not just the covariance matrix.
phylo_uni_cells <- list(
  list(id = "phylo_p50",   p = 50,   p_index = 0),
  list(id = "phylo_p200",  p = 200,  p_index = 1),
  list(id = "phylo_p500",  p = 500,  p_index = 2),
  list(id = "phylo_p1000", p = 1000, p_index = 3)
)

simulate_phylo_uni <- function(cell) {
  set.seed(142 + cell$p_index)
  p <- cell$p
  tree <- ape::rcoal(p)                # ultrametric, tips "t1".."tp"
  Sigma_phy <- ape::vcv(tree)          # p x p phylogenetic covariance
  ## Defensive: make sure column ordering matches tip labels.
  Sigma_phy <- Sigma_phy[tree$tip.label, tree$tip.label]

  beta_mu   <- c(1.0, 0.5)
  sigma_phy <- 0.8
  sigma_eps <- 0.3

  x1       <- rnorm(p)
  mu_fixed <- beta_mu[1] + beta_mu[2] * x1
  z_phy    <- as.numeric(MASS::mvrnorm(
    n     = 1L,
    mu    = rep(0, p),
    Sigma = sigma_phy^2 * Sigma_phy
  ))
  eps <- rnorm(p, mean = 0, sd = sigma_eps)
  y   <- mu_fixed + z_phy + eps

  df <- data.frame(
    y       = y,
    x1      = x1,
    species = tree$tip.label,    # character; matches columns of Sigma_phy
    stringsAsFactors = FALSE
  )

  csv_path   <- file.path(fixtures_dir, paste0(cell$id, ".csv"))
  tree_path  <- file.path(fixtures_dir, paste0(cell$id, "_tree.nwk"))
  sigma_path <- file.path(fixtures_dir, paste0(cell$id, "_sigma_phy.csv"))
  truth_path <- file.path(fixtures_dir, paste0(cell$id, "_truth.json"))

  readr::write_csv(df, csv_path)
  ape::write.tree(tree, tree_path)

  ## Sigma_phy as p x p numeric matrix with headers s1..sp.
  Sigma_out <- as.data.frame(unname(Sigma_phy))
  colnames(Sigma_out) <- paste0("s", seq_len(p))
  readr::write_csv(Sigma_out, sigma_path)

  truth <- list(
    cell_id   = cell$id,
    n         = as.integer(p),
    p_species = as.integer(p),
    model     = "phylo_uni",
    beta_mu   = beta_mu,
    sigma_phy = sigma_phy,
    sigma_eps = sigma_eps
  )
  jsonlite::write_json(truth, truth_path, auto_unbox = TRUE, pretty = TRUE)

  cat(sprintf(
    "wrote %s (%d rows) + %s + %s + %s\n",
    basename(csv_path), nrow(df), basename(tree_path),
    basename(sigma_path), basename(truth_path)
  ))
  invisible(NULL)
}

for (cell in phylo_uni_cells) {
  simulate_phylo_uni(cell)
}

## --- q=4 phylogenetic location-scale bivariate cell ------------------------
## See CONTRACT.md "Bivariate Gaussian + q=4 location-scale phylogenetic
## block". One observation per species, p = 100. Phylogenetic random
## intercepts on all four of (mu1, mu2, log_sigma1, log_sigma2); the truth
## draws them independently across the four axes (block-diagonal special
## case) but drmTMB still has to estimate the full 4x4 block.
simulate_q4_p100 <- function() {
  set.seed(200)
  p <- 100L
  tree <- ape::rcoal(p)
  Sigma_phy <- ape::vcv(tree)
  Sigma_phy <- Sigma_phy[tree$tip.label, tree$tip.label]

  beta_mu1         <- c(1.0, 0.4)
  beta_mu2         <- c(-0.5, 0.6)
  sigma1_intercept <- 0.1
  sigma2_intercept <- -0.05
  rho12_intercept  <- 0.4
  sd_phy           <- c(0.7, 0.7, 0.3, 0.3) # for (mu1, mu2, log_sigma1, log_sigma2)

  x1 <- rnorm(p)

  ## Four independent MVN draws on the tree, one per dpar.
  z_mu1        <- as.numeric(MASS::mvrnorm(1L, rep(0, p), sd_phy[1]^2 * Sigma_phy))
  z_mu2        <- as.numeric(MASS::mvrnorm(1L, rep(0, p), sd_phy[2]^2 * Sigma_phy))
  z_log_sigma1 <- as.numeric(MASS::mvrnorm(1L, rep(0, p), sd_phy[3]^2 * Sigma_phy))
  z_log_sigma2 <- as.numeric(MASS::mvrnorm(1L, rep(0, p), sd_phy[4]^2 * Sigma_phy))

  mu1 <- beta_mu1[1] + beta_mu1[2] * x1 + z_mu1
  mu2 <- beta_mu2[1] + beta_mu2[2] * x1 + z_mu2
  s1  <- exp(sigma1_intercept + z_log_sigma1)
  s2  <- exp(sigma2_intercept + z_log_sigma2)
  rho <- rep(0.99999999 * tanh(rho12_intercept), p)

  Y <- matrix(NA_real_, p, 2L)
  for (i in seq_len(p)) {
    S <- matrix(
      c(s1[i]^2,                rho[i] * s1[i] * s2[i],
        rho[i] * s1[i] * s2[i], s2[i]^2),
      nrow = 2L
    )
    Y[i, ] <- MASS::mvrnorm(1L, mu = c(mu1[i], mu2[i]), Sigma = S)
  }

  df <- data.frame(
    y1      = Y[, 1],
    y2      = Y[, 2],
    x1      = x1,
    species = tree$tip.label,
    stringsAsFactors = FALSE
  )

  csv_path   <- file.path(fixtures_dir, "q4_p100.csv")
  tree_path  <- file.path(fixtures_dir, "q4_p100_tree.nwk")
  sigma_path <- file.path(fixtures_dir, "q4_p100_sigma_phy.csv")
  truth_path <- file.path(fixtures_dir, "q4_p100_truth.json")

  readr::write_csv(df, csv_path)
  ape::write.tree(tree, tree_path)
  Sigma_out <- as.data.frame(unname(Sigma_phy))
  colnames(Sigma_out) <- paste0("s", seq_len(p))
  readr::write_csv(Sigma_out, sigma_path)

  truth <- list(
    cell_id          = "q4_p100",
    n                = as.integer(p),
    p_species        = as.integer(p),
    model            = "q4",
    beta_mu1         = beta_mu1,
    beta_mu2         = beta_mu2,
    sigma1_intercept = sigma1_intercept,
    sigma2_intercept = sigma2_intercept,
    rho12_intercept  = rho12_intercept,
    sd_phy           = sd_phy
  )
  jsonlite::write_json(truth, truth_path, auto_unbox = TRUE, pretty = TRUE)

  cat(sprintf(
    "wrote %s (%d rows) + %s + %s + %s\n",
    basename(csv_path), nrow(df), basename(tree_path),
    basename(sigma_path), basename(truth_path)
  ))
  invisible(NULL)
}

simulate_q4_p100()

## --- AVONET-scale q=4 phylogenetic location-scale cell ---------------------
## See Nakagawa et al. 2025 MEE, Section 3.3 (Model 5): bivariate PLSM on 354
## parrot species, beak width x beak depth, with centered log body mass as a
## covariate. All four of (mu1, mu2, log_sigma1, log_sigma2) carry a
## phylogenetic random effect tied through one shared 4x4 covariance block
## Sigma_a. Truth values are informed by the paper's headline posteriors
## (Figure 5f-h):
##   - sd_phy = (0.8, 0.8, 0.3, 0.3) for (l_width, l_depth, s_width, s_depth)
##   - rho_a(l1l2) = 0.89 (mean-mean coev),
##     rho_a(s1s2) = 0.82 (var-var coev),
##     rho_a(l1s1) = 0.36 (within-trait mean-var, width),
##     rho_a(l2s2) = 0.28 (within-trait mean-var, depth),
##     other off-diagonals near 0.
## Simulation uses the Kronecker structure vec(U) ~ MVN(0, Sigma_phy %x% Lambda_phy)
## via U = chol(Lambda_phy) %*% Z %*% chol(Sigma_phy)' for Z ~ N(0, I_{4 x p}).
simulate_avonet_q4 <- function() {
  set.seed(300)
  p <- 354L
  tree <- ape::rcoal(p)
  Sigma_phy <- ape::vcv(tree)
  Sigma_phy <- Sigma_phy[tree$tip.label, tree$tip.label]

  ## Fixed effects (informed by paper Section 3.3 / Figure 5f).
  beta_mu1    <- c(0.0, 0.5)    # mu1 (cbeak_width): intercept, cmass slope
  beta_mu2    <- c(0.0, 0.5)    # mu2 (cbeak_depth)
  beta_sigma1 <- c(-2.0, 0.1)   # log SD for width: baseline, mild heterosc.
  beta_sigma2 <- c(-2.0, 0.1)   # log SD for depth
  rho12_intercept <- atanh(0.5 / 0.99999999)  # gives ρ_resid ≈ 0.5

  ## 4x4 phylogenetic covariance Lambda_phy.
  log_sd_phy <- log(c(0.8, 0.8, 0.3, 0.3))   # (l1, l2, s1, s2)
  sd_phy <- exp(log_sd_phy)
  ## Headline correlations from the paper (Section 3.3 / Figure 5h).
  rho_l1l2 <- 0.89   # mean-mean (l_width vs l_depth)
  rho_s1s2 <- 0.82   # var-var (s_width vs s_depth)
  rho_l1s1 <- 0.36   # within-trait, width
  rho_l2s2 <- 0.28   # within-trait, depth (per user spec)
  ## The "other" cross off-diagonals (l1s2 and l2s1). User spec called these
  ## "near zero", but with the four headline values above strict-zero gives a
  ## non-PD correlation matrix (min eigenvalue ≈ -0.18). We use the minimum
  ## off-diagonal value that yields a comfortable PD margin (min eig ≈ +0.02).
  ## This is also closer to the paper's actual Figure 5h, which shows
  ## sl_width-depth_cor ≈ 0.28 and ls_width-depth_cor ≈ -0.04.
  rho_l1s2_cross <- 0.20
  rho_l2s1_cross <- 0.20
  Cor_phy <- diag(4L)
  Cor_phy[1L, 2L] <- Cor_phy[2L, 1L] <- rho_l1l2
  Cor_phy[3L, 4L] <- Cor_phy[4L, 3L] <- rho_s1s2
  Cor_phy[1L, 3L] <- Cor_phy[3L, 1L] <- rho_l1s1
  Cor_phy[2L, 4L] <- Cor_phy[4L, 2L] <- rho_l2s2
  Cor_phy[1L, 4L] <- Cor_phy[4L, 1L] <- rho_l1s2_cross
  Cor_phy[2L, 3L] <- Cor_phy[3L, 2L] <- rho_l2s1_cross
  Lambda_phy <- diag(sd_phy) %*% Cor_phy %*% diag(sd_phy)

  ## Sanity check: PD via eigen.
  eig <- eigen(Lambda_phy, symmetric = TRUE, only.values = TRUE)$values
  if (min(eig) <= 0) {
    stop("Lambda_phy is not positive definite; min eigenvalue = ",
         min(eig))
  }
  cat(sprintf("  avonet_q4 Lambda_phy min eigenvalue = %+.4f\n", min(eig)))

  ## Covariate (stands in for cmass — centered log body mass).
  x1 <- rnorm(p)

  ## Sanity-check the Kronecker simulation at small p before scaling to 354.
  ## Draw U_small ~ MVN(0, Sigma_phy_small %x% Lambda_phy) via the matrix
  ## decomposition U = chol(Lambda) %*% Z %*% chol(Sigma)' and verify that
  ## empirical covariance ~ Lambda_phy at moderate replication.
  sanity_ok <- local({
    set.seed(301)
    p_small <- 10L
    tree_s <- ape::rcoal(p_small)
    Sigma_s <- ape::vcv(tree_s)[tree_s$tip.label, tree_s$tip.label]
    L_lam <- t(chol(Lambda_phy))           # 4x4, lower
    L_sig <- t(chol(Sigma_s))              # p_small x p_small, lower
    ## Build empirical block by averaging over many replicates: per replicate
    ## we get U_4xp; cov of vec(U) across reps approximates Sigma_s %x% Lambda.
    nrep <- 5000L
    acc <- matrix(0, 4L, 4L)
    for (r in seq_len(nrep)) {
      Z <- matrix(rnorm(4L * p_small), nrow = 4L)
      U <- L_lam %*% Z %*% t(L_sig)         # 4 x p_small
      ## E[U %*% Sigma_s^{-1} %*% U'] / p_small ≈ Lambda_phy if Sigma is the col cov.
      acc <- acc + U %*% solve(Sigma_s) %*% t(U) / p_small
    }
    Lambda_hat <- acc / nrep
    err <- max(abs(Lambda_hat - Lambda_phy)) / max(abs(Lambda_phy))
    cat(sprintf(
      "  avonet_q4 Kronecker sanity check: max rel err in Lambda_phy = %.4f (5000 reps, p=10)\n",
      err
    ))
    err < 0.10
  })
  if (!sanity_ok) {
    warning("avonet_q4 Kronecker sanity check exceeded 10% relative error; ",
            "simulation may be miscalibrated.")
  }

  ## Real draw: U_4xp ~ MVN structured as Sigma_phy %x% Lambda_phy.
  L_lam <- t(chol(Lambda_phy))             # 4 x 4 lower triangular
  L_sig <- t(chol(Sigma_phy))              # p x p lower triangular
  Z <- matrix(rnorm(4L * p), nrow = 4L)
  U <- L_lam %*% Z %*% t(L_sig)            # 4 x p; rows = (l1, l2, s1, s2)

  mu1 <- beta_mu1[1] + beta_mu1[2] * x1 + U[1L, ]
  mu2 <- beta_mu2[1] + beta_mu2[2] * x1 + U[2L, ]
  s1  <- exp(beta_sigma1[1] + beta_sigma1[2] * x1 + U[3L, ])
  s2  <- exp(beta_sigma2[1] + beta_sigma2[2] * x1 + U[4L, ])
  rho <- rep(0.99999999 * tanh(rho12_intercept), p)

  Y <- matrix(NA_real_, p, 2L)
  for (i in seq_len(p)) {
    S <- matrix(
      c(s1[i]^2,                rho[i] * s1[i] * s2[i],
        rho[i] * s1[i] * s2[i], s2[i]^2),
      nrow = 2L
    )
    Y[i, ] <- MASS::mvrnorm(1L, mu = c(mu1[i], mu2[i]), Sigma = S)
  }

  df <- data.frame(
    y1      = Y[, 1],
    y2      = Y[, 2],
    x1      = x1,
    species = tree$tip.label,
    stringsAsFactors = FALSE
  )

  csv_path   <- file.path(fixtures_dir, "avonet_q4.csv")
  tree_path  <- file.path(fixtures_dir, "avonet_q4_tree.nwk")
  sigma_path <- file.path(fixtures_dir, "avonet_q4_sigma_phy.csv")
  truth_path <- file.path(fixtures_dir, "avonet_q4_truth.json")

  readr::write_csv(df, csv_path)
  ape::write.tree(tree, tree_path)
  Sigma_out <- as.data.frame(unname(Sigma_phy))
  colnames(Sigma_out) <- paste0("s", seq_len(p))
  readr::write_csv(Sigma_out, sigma_path)

  truth <- list(
    cell_id          = "avonet_q4",
    n                = as.integer(p),
    p_species        = as.integer(p),
    model            = "avonet_q4_plsm",
    beta_mu1         = beta_mu1,
    beta_mu2         = beta_mu2,
    beta_sigma1      = beta_sigma1,
    beta_sigma2      = beta_sigma2,
    rho12_intercept  = rho12_intercept,
    log_sd_phy       = log_sd_phy,
    sd_phy           = sd_phy,
    rho_l1l2         = rho_l1l2,
    rho_s1s2         = rho_s1s2,
    rho_l1s1         = rho_l1s1,
    rho_l2s2         = rho_l2s2,
    rho_l1s2_cross   = rho_l1s2_cross,
    rho_l2s1_cross   = rho_l2s1_cross,
    Lambda_phy       = Lambda_phy,
    Cor_phy          = Cor_phy
  )
  jsonlite::write_json(truth, truth_path, auto_unbox = TRUE, pretty = TRUE)

  cat(sprintf(
    "wrote %s (%d rows) + %s + %s + %s\n",
    basename(csv_path), nrow(df), basename(tree_path),
    basename(sigma_path), basename(truth_path)
  ))
  invisible(NULL)
}

simulate_avonet_q4()

cat(sprintf("\nFixtures written to %s\n", fixtures_dir))
