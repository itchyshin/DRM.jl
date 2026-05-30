## fit_r.R
##
## Fit drmTMB on each fixture CSV, time 5 reruns per fit, and write
## results/r_results.json per the contract in ../CONTRACT.md.
##
## Run from the repo root: `Rscript R/fit_r.R`

suppressPackageStartupMessages({
  ok <- requireNamespace("drmTMB", quietly = TRUE)
  if (!ok) {
    if (!requireNamespace("devtools", quietly = TRUE)) {
      stop("drmTMB not installed and devtools not available to load_all().")
    }
    devtools::load_all("/Users/z3437171/Dropbox/Github Local/drmTMB", quiet = TRUE)
  } else {
    library(drmTMB)
  }
  library(readr)
  library(jsonlite)
  library(ape)
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
repo_root    <- tryCatch(here(), error = function(e) getwd())
fixtures_dir <- file.path(repo_root, "fixtures")
results_dir  <- file.path(repo_root, "results")
dir.create(results_dir, showWarnings = FALSE, recursive = TRUE)

## --- Cell table (must match gen_fixtures.R / CONTRACT.md) ------------------
cells <- list(
  list(id = "u_small", n = 100,  model = "univariate"),
  list(id = "u_med",   n = 500,  model = "univariate"),
  list(id = "u_large", n = 2000, model = "univariate"),
  list(id = "b_small", n = 200,  model = "bivariate"),
  list(id = "b_med",   n = 1000, model = "bivariate")
)

## Build the bf() formula and family object for a cell. b_small uses
## intercept-only sigma/rho formulas; b_med uses ~x1.
cell_spec <- function(cell) {
  if (cell$model == "univariate") {
    list(
      formula = drmTMB::bf(y ~ x1 + x2, sigma ~ x1),
      family  = gaussian()
    )
  } else if (cell$id == "b_small") {
    list(
      formula = drmTMB::bf(
        mu1    = y1 ~ x1,
        mu2    = y2 ~ x1,
        sigma1 = ~ 1,
        sigma2 = ~ 1,
        rho12  = ~ 1
      ),
      family = drmTMB::biv_gaussian()
    )
  } else { # b_med
    list(
      formula = drmTMB::bf(
        mu1    = y1 ~ x1,
        mu2    = y2 ~ x1,
        sigma1 = ~ x1,
        sigma2 = ~ x1,
        rho12  = ~ x1
      ),
      family = drmTMB::biv_gaussian()
    )
  }
}

## Convert coef(fit) (a named list of named numeric vectors keyed by dpar)
## into the flat beta_* fields the contract expects.
extract_betas <- function(fit, model) {
  cf <- coef(fit)  # list keyed by dpar
  if (model == "univariate") {
    list(
      beta_mu    = unname(as.numeric(cf$mu)),
      beta_sigma = unname(as.numeric(cf$sigma))
    )
  } else {
    list(
      beta_mu1    = unname(as.numeric(cf$mu1)),
      beta_mu2    = unname(as.numeric(cf$mu2)),
      beta_sigma1 = unname(as.numeric(cf$sigma1)),
      beta_sigma2 = unname(as.numeric(cf$sigma2)),
      beta_rho12  = unname(as.numeric(cf$rho12))
    )
  }
}

fit_one <- function(cell) {
  csv_path <- file.path(fixtures_dir, paste0(cell$id, ".csv"))
  df <- readr::read_csv(csv_path, show_col_types = FALSE)
  spec <- cell_spec(cell)

  ## Warm-up fit (not timed): amortises TMB compile/load cost.
  warm <- drmTMB::drmTMB(spec$formula, data = df, family = spec$family)

  ## 5 timed reruns. system.time()[["elapsed"]] is wall-clock seconds.
  times <- numeric(5L)
  fits  <- vector("list", 5L)
  for (k in seq_len(5L)) {
    t <- system.time({
      fits[[k]] <- drmTMB::drmTMB(spec$formula, data = df, family = spec$family)
    })
    times[k] <- as.numeric(t[["elapsed"]])
  }
  fit <- fits[[length(fits)]]  # use last fit for coefficients/logLik

  betas <- extract_betas(fit, cell$model)

  res <- list(
    cell_id    = cell$id,
    engine     = "r_drmTMB",
    n          = cell$n,
    model      = cell$model,
    time_s     = mean(times),
    time_s_med = stats::median(times),
    times_all  = times,
    logLik     = as.numeric(logLik(fit)),
    converged  = isTRUE(fit$opt$convergence == 0L),
    n_iter     = as.integer(fit$opt$iterations %||% NA_integer_)
  )
  res <- c(res, betas)
  cat(sprintf(
    "[%s] n=%d  model=%s  mean(time)=%.3fs  med=%.3fs  logLik=%.3f  conv=%s  iter=%s\n",
    cell$id, cell$n, cell$model, res$time_s, res$time_s_med,
    res$logLik, res$converged, format(res$n_iter)
  ))
  res
}

results <- vector("list", length(cells))
for (i in seq_along(cells)) {
  results[[i]] <- fit_one(cells[[i]])
}

## --- Phylogenetic + q=4 cells (CONTRACT.md extension) ----------------------
## These use ape-built trees + drmTMB's phylo() marker. 1 warm-up fit (untimed)
## + 3 timed reruns per cell. phylo_p1000 and q4_p100 may take minutes; each
## timed fit is wrapped in a tryCatch with a 300 s wall-clock cap.

PHYLO_TIMEOUT_S <- 300

## Run an expression with an elapsed-time cap (setTimeLimit on elapsed).
run_with_timeout <- function(expr, timeout_s = PHYLO_TIMEOUT_S) {
  tryCatch(
    {
      setTimeLimit(elapsed = timeout_s, transient = TRUE)
      on.exit(setTimeLimit(elapsed = Inf, transient = TRUE), add = TRUE)
      force(expr)
    },
    error = function(e) {
      structure(list(error = conditionMessage(e)), class = "drm_phylo_err")
    }
  )
}

phylo_uni_cells <- list(
  list(id = "phylo_p50",   p = 50),
  list(id = "phylo_p200",  p = 200),
  list(id = "phylo_p500",  p = 500),
  list(id = "phylo_p1000", p = 1000)
)

fit_one_phylo_uni <- function(cell) {
  csv_path  <- file.path(fixtures_dir, paste0(cell$id, ".csv"))
  tree_path <- file.path(fixtures_dir, paste0(cell$id, "_tree.nwk"))
  df   <- readr::read_csv(csv_path, show_col_types = FALSE)
  tree <- ape::read.tree(tree_path)
  ## drmTMB indexes the random effects by factor level order; aligning to
  ## tree$tip.label is the safest convention.
  df$species <- factor(df$species, levels = tree$tip.label)

  formula <- drmTMB::bf(y ~ x1 + phylo(1 | species, tree = tree))
  family  <- gaussian()

  cat(sprintf("[%s] warm-up fit...\n", cell$id))
  warm_res <- run_with_timeout(
    drmTMB::drmTMB(formula, data = df, family = family),
    timeout_s = PHYLO_TIMEOUT_S
  )
  if (inherits(warm_res, "drm_phylo_err")) {
    cat(sprintf("[%s] warm-up FAILED: %s\n", cell$id, warm_res$error))
    return(list(
      cell_id    = cell$id,
      engine     = "r_drmTMB",
      n          = cell$p,
      p_species  = cell$p,
      model      = "phylo_uni",
      time_s     = NA_real_,
      time_s_med = NA_real_,
      times_all  = rep(NA_real_, 3L),
      logLik     = NA_real_,
      converged  = FALSE,
      n_iter     = NA_integer_,
      note       = paste("warm-up failed:", warm_res$error)
    ))
  }

  times <- rep(NA_real_, 3L)
  fits  <- vector("list", 3L)
  errs  <- character(0)
  for (k in seq_len(3L)) {
    t0  <- proc.time()
    res <- run_with_timeout(
      drmTMB::drmTMB(formula, data = df, family = family),
      timeout_s = PHYLO_TIMEOUT_S
    )
    t1 <- proc.time()
    if (inherits(res, "drm_phylo_err")) {
      errs <- c(errs, res$error)
      cat(sprintf("[%s] timed rerun %d FAILED: %s\n", cell$id, k, res$error))
    } else {
      times[k]  <- as.numeric((t1 - t0)[["elapsed"]])
      fits[[k]] <- res
    }
  }

  good <- which(!vapply(fits, is.null, logical(1L)))
  if (!length(good)) {
    return(list(
      cell_id    = cell$id,
      engine     = "r_drmTMB",
      n          = cell$p,
      p_species  = cell$p,
      model      = "phylo_uni",
      time_s     = NA_real_,
      time_s_med = NA_real_,
      times_all  = times,
      logLik     = NA_real_,
      converged  = FALSE,
      n_iter     = NA_integer_,
      note       = paste("all timed fits failed:", paste(unique(errs), collapse = " | "))
    ))
  }

  fit <- fits[[good[length(good)]]]

  cf <- coef(fit)
  beta_mu <- unname(as.numeric(cf$mu))
  ## sigma is on the log scale (intercept-only here).
  beta_sigma <- unname(as.numeric(cf$sigma))
  ## phylo SD: drmTMB stores it as log_sd_phylo in fit$opt$par; the
  ## fit$sdpars$mu list holds the back-transformed positive SD.
  sigma_phy_hat <- tryCatch(
    {
      sd_vec <- fit$sdpars$mu
      if (length(sd_vec) >= 1L) as.numeric(sd_vec[[1L]]) else NA_real_
    },
    error = function(e) NA_real_
  )
  sigma_eps_hat <- if (length(beta_sigma) >= 1L) exp(beta_sigma[[1L]]) else NA_real_

  ## Use median of valid timed reruns.
  res <- list(
    cell_id    = cell$id,
    engine     = "r_drmTMB",
    n          = cell$p,
    p_species  = cell$p,
    model      = "phylo_uni",
    time_s     = mean(times[good]),
    time_s_med = stats::median(times[good]),
    times_all  = times,
    logLik     = as.numeric(logLik(fit)),
    converged  = isTRUE(fit$opt$convergence == 0L),
    n_iter     = as.integer(fit$opt$iterations %||% NA_integer_),
    beta_mu    = beta_mu,
    sigma_phy  = sigma_phy_hat,
    sigma_eps  = sigma_eps_hat
  )
  notes <- character(0)
  if (length(errs)) {
    notes <- c(notes, paste("partial failure:", paste(unique(errs), collapse = " | ")))
  }
  if (!isTRUE(fit$opt$convergence == 0L)) {
    notes <- c(notes, paste("optimizer non-convergence:",
                            fit$opt$message %||% "unknown"))
  }
  if (length(notes)) {
    res$note <- paste(notes, collapse = "; ")
  }

  cat(sprintf(
    "[%s] p=%d  med(time)=%.3fs  logLik=%.3f  sigma_phy_hat=%.3f  sigma_eps_hat=%.3f  conv=%s\n",
    cell$id, cell$p, res$time_s_med, res$logLik,
    sigma_phy_hat, sigma_eps_hat, res$converged
  ))
  res
}

phylo_uni_results <- lapply(phylo_uni_cells, fit_one_phylo_uni)

## --- q=4 phylogenetic location-scale cell ---------------------------------
fit_q4_p100 <- function() {
  csv_path  <- file.path(fixtures_dir, "q4_p100.csv")
  tree_path <- file.path(fixtures_dir, "q4_p100_tree.nwk")
  df   <- readr::read_csv(csv_path, show_col_types = FALSE)
  tree <- ape::read.tree(tree_path)
  df$species <- factor(df$species, levels = tree$tip.label)

  ## q=4 phylogenetic block: a shared label "p" across all four dpars (mu1,
  ## mu2, sigma1, sigma2) tells drmTMB to fit one 4x4 phylogenetic covariance
  ## block. See drmTMB tests/testthat/test-phylo-gaussian.R for the canonical
  ## form. rho12 is intercept-only.
  formula <- drmTMB::bf(
    mu1    = y1 ~ x1 + phylo(1 | p | species, tree = tree),
    mu2    = y2 ~ x1 + phylo(1 | p | species, tree = tree),
    sigma1 =     ~ phylo(1 | p | species, tree = tree),
    sigma2 =     ~ phylo(1 | p | species, tree = tree),
    rho12  =     ~ 1
  )
  family <- drmTMB::biv_gaussian()

  cat(sprintf("[q4_p100] warm-up fit...\n"))
  warm_res <- run_with_timeout(
    drmTMB::drmTMB(formula, data = df, family = family),
    timeout_s = PHYLO_TIMEOUT_S
  )
  if (inherits(warm_res, "drm_phylo_err")) {
    cat(sprintf("[q4_p100] warm-up FAILED: %s\n", warm_res$error))
    return(list(
      cell_id    = "q4_p100",
      engine     = "r_drmTMB",
      n          = 100L,
      p_species  = 100L,
      model      = "q4",
      time_s     = NA_real_,
      time_s_med = NA_real_,
      times_all  = rep(NA_real_, 3L),
      logLik     = NA_real_,
      converged  = FALSE,
      n_iter     = NA_integer_,
      note       = paste("warm-up failed:", warm_res$error)
    ))
  }

  times <- rep(NA_real_, 3L)
  fits  <- vector("list", 3L)
  errs  <- character(0)
  for (k in seq_len(3L)) {
    t0  <- proc.time()
    res <- run_with_timeout(
      drmTMB::drmTMB(formula, data = df, family = family),
      timeout_s = PHYLO_TIMEOUT_S
    )
    t1 <- proc.time()
    if (inherits(res, "drm_phylo_err")) {
      errs <- c(errs, res$error)
      cat(sprintf("[q4_p100] timed rerun %d FAILED: %s\n", k, res$error))
    } else {
      times[k]  <- as.numeric((t1 - t0)[["elapsed"]])
      fits[[k]] <- res
    }
  }

  good <- which(!vapply(fits, is.null, logical(1L)))
  if (!length(good)) {
    return(list(
      cell_id    = "q4_p100",
      engine     = "r_drmTMB",
      n          = 100L,
      p_species  = 100L,
      model      = "q4",
      time_s     = NA_real_,
      time_s_med = NA_real_,
      times_all  = times,
      logLik     = NA_real_,
      converged  = FALSE,
      n_iter     = NA_integer_,
      note       = paste("all timed fits failed:", paste(unique(errs), collapse = " | "))
    ))
  }
  fit <- fits[[good[length(good)]]]

  cf <- coef(fit)
  beta_mu1    <- unname(as.numeric(cf$mu1))
  beta_mu2    <- unname(as.numeric(cf$mu2))
  beta_sigma1 <- unname(as.numeric(cf$sigma1))
  beta_sigma2 <- unname(as.numeric(cf$sigma2))
  beta_rho12  <- unname(as.numeric(cf$rho12))

  ## Four phylogenetic SDs (mu1, mu2, sigma1, sigma2) — read from fit$sdpars$mu
  ## which holds the back-transformed positive SDs labelled by dpar:term.
  sd_phy_hat <- tryCatch(unname(as.numeric(fit$sdpars$mu)),
                         error = function(e) rep(NA_real_, 4L))
  ## The 6 within-block correlations.
  cor_phy_hat <- tryCatch(unname(as.numeric(fit$corpars$phylo)),
                          error = function(e) rep(NA_real_, 6L))

  res <- list(
    cell_id     = "q4_p100",
    engine      = "r_drmTMB",
    n           = 100L,
    p_species   = 100L,
    model       = "q4",
    time_s      = mean(times[good]),
    time_s_med  = stats::median(times[good]),
    times_all   = times,
    logLik      = as.numeric(logLik(fit)),
    converged   = isTRUE(fit$opt$convergence == 0L),
    n_iter      = as.integer(fit$opt$iterations %||% NA_integer_),
    beta_mu1    = beta_mu1,
    beta_mu2    = beta_mu2,
    beta_sigma1 = beta_sigma1,
    beta_sigma2 = beta_sigma2,
    beta_rho12  = beta_rho12,
    sd_phy      = sd_phy_hat,
    cor_phy     = cor_phy_hat
  )
  notes <- character(0)
  if (length(errs)) {
    notes <- c(notes, paste("partial failure:", paste(unique(errs), collapse = " | ")))
  }
  if (!isTRUE(fit$opt$convergence == 0L)) {
    notes <- c(notes, paste("optimizer non-convergence:",
                            fit$opt$message %||% "unknown"))
  }
  if (length(notes)) {
    res$note <- paste(notes, collapse = "; ")
  }

  cat(sprintf(
    "[q4_p100] med(time)=%.3fs  logLik=%.3f  conv=%s  sd_phy=(%s)\n",
    res$time_s_med, res$logLik, res$converged,
    paste(sprintf("%.3f", sd_phy_hat), collapse = ", ")
  ))
  res
}

q4_result <- fit_q4_p100()

## --- AVONET-scale q=4 phylogenetic location-scale cell --------------------
## p = 354 species, matching the Nakagawa et al. 2025 MEE Model 5 worked
## example. Same drmTMB syntax as q4_p100, just a larger tree. The intent
## here is a concrete R-side wall-clock target: "drmTMB takes X seconds
## on the parrot-scale q=4 PLSM."
##
## Cap each fit at 10 minutes (600 s). If warm-up convergence or wall-clock
## fails, record the failure and skip the 3 timed reruns.
AVONET_TIMEOUT_S <- 600

fit_avonet_q4 <- function() {
  csv_path  <- file.path(fixtures_dir, "avonet_q4.csv")
  tree_path <- file.path(fixtures_dir, "avonet_q4_tree.nwk")
  df   <- readr::read_csv(csv_path, show_col_types = FALSE)
  tree <- ape::read.tree(tree_path)
  df$species <- factor(df$species, levels = tree$tip.label)

  ## Same q=4 PLSM syntax as q4_p100: shared `p` label across all four dpar
  ## terms ties them into one 4x4 phylogenetic covariance block.
  formula <- drmTMB::bf(
    mu1    = y1 ~ x1 + phylo(1 | p | species, tree = tree),
    mu2    = y2 ~ x1 + phylo(1 | p | species, tree = tree),
    sigma1 =     ~ x1 + phylo(1 | p | species, tree = tree),
    sigma2 =     ~ x1 + phylo(1 | p | species, tree = tree),
    rho12  =     ~ 1
  )
  family <- drmTMB::biv_gaussian()
  control <- list(eval.max = 200, iter.max = 200)

  cat(sprintf("[avonet_q4] warm-up fit (cap %d s)...\n", AVONET_TIMEOUT_S))
  warm_t0  <- proc.time()
  warm_res <- run_with_timeout(
    drmTMB::drmTMB(formula, data = df, family = family, control = control),
    timeout_s = AVONET_TIMEOUT_S
  )
  warm_t1 <- proc.time()
  warm_time <- as.numeric((warm_t1 - warm_t0)[["elapsed"]])
  cat(sprintf("[avonet_q4] warm-up done in %.1f s\n", warm_time))

  base <- list(
    cell_id     = "avonet_q4",
    engine      = "r_drmTMB",
    n           = 354L,
    p_species   = 354L,
    model       = "avonet_q4_plsm"
  )

  if (inherits(warm_res, "drm_phylo_err")) {
    cat(sprintf("[avonet_q4] warm-up FAILED: %s\n", warm_res$error))
    return(c(base, list(
      time_s        = NA_real_,
      time_s_med    = NA_real_,
      times_all     = rep(NA_real_, 3L),
      warmup_time_s = warm_time,
      logLik        = NA_real_,
      converged     = FALSE,
      n_iter        = NA_integer_,
      note          = paste("warm-up failed:", warm_res$error)
    )))
  }

  warm_msg     <- warm_res$opt$message %||% NA_character_
  warm_conv    <- isTRUE(warm_res$opt$convergence == 0L)
  cat(sprintf(
    "[avonet_q4] warm-up converged=%s   nlminb msg: %s   logLik=%.3f\n",
    warm_conv, warm_msg, as.numeric(logLik(warm_res))
  ))

  times <- rep(NA_real_, 3L)
  fits  <- vector("list", 3L)
  errs  <- character(0)
  for (k in seq_len(3L)) {
    cat(sprintf("[avonet_q4] timed rerun %d (cap %d s)...\n", k, AVONET_TIMEOUT_S))
    t0  <- proc.time()
    res <- run_with_timeout(
      drmTMB::drmTMB(formula, data = df, family = family, control = control),
      timeout_s = AVONET_TIMEOUT_S
    )
    t1 <- proc.time()
    if (inherits(res, "drm_phylo_err")) {
      errs <- c(errs, res$error)
      cat(sprintf("[avonet_q4] timed rerun %d FAILED: %s\n", k, res$error))
    } else {
      times[k]  <- as.numeric((t1 - t0)[["elapsed"]])
      fits[[k]] <- res
      cat(sprintf("[avonet_q4] timed rerun %d done in %.1f s\n", k, times[k]))
    }
  }

  good <- which(!vapply(fits, is.null, logical(1L)))
  if (!length(good)) {
    return(c(base, list(
      time_s        = NA_real_,
      time_s_med    = NA_real_,
      times_all     = times,
      warmup_time_s = warm_time,
      logLik        = NA_real_,
      converged     = FALSE,
      n_iter        = NA_integer_,
      note          = paste("all timed fits failed:",
                            paste(unique(errs), collapse = " | "))
    )))
  }
  fit <- fits[[good[length(good)]]]

  cf <- coef(fit)
  beta_mu1    <- unname(as.numeric(cf$mu1))
  beta_mu2    <- unname(as.numeric(cf$mu2))
  beta_sigma1 <- unname(as.numeric(cf$sigma1))
  beta_sigma2 <- unname(as.numeric(cf$sigma2))
  beta_rho12  <- unname(as.numeric(cf$rho12))

  ## Four phylogenetic SDs and the 6 within-block correlations.
  sd_phy_hat  <- tryCatch(unname(as.numeric(fit$sdpars$mu)),
                          error = function(e) rep(NA_real_, 4L))
  cor_phy_hat <- tryCatch(unname(as.numeric(fit$corpars$phylo)),
                          error = function(e) rep(NA_real_, 6L))
  cor_phy_names <- tryCatch(names(fit$corpars$phylo),
                            error = function(e) rep(NA_character_, 6L))

  res <- c(base, list(
    time_s        = mean(times[good]),
    time_s_med    = stats::median(times[good]),
    times_all     = times,
    warmup_time_s = warm_time,
    logLik        = as.numeric(logLik(fit)),
    converged     = isTRUE(fit$opt$convergence == 0L),
    n_iter        = as.integer(fit$opt$iterations %||% NA_integer_),
    nlminb_msg    = fit$opt$message %||% NA_character_,
    beta_mu1      = beta_mu1,
    beta_mu2      = beta_mu2,
    beta_sigma1   = beta_sigma1,
    beta_sigma2   = beta_sigma2,
    beta_rho12    = beta_rho12,
    sd_phy        = sd_phy_hat,
    cor_phy_names = cor_phy_names,
    cor_phy       = cor_phy_hat
  ))
  notes <- character(0)
  if (length(errs)) {
    notes <- c(notes, paste("partial failure:",
                            paste(unique(errs), collapse = " | ")))
  }
  if (!isTRUE(fit$opt$convergence == 0L)) {
    notes <- c(notes, paste("optimizer non-convergence:",
                            fit$opt$message %||% "unknown"))
  }
  if (length(notes)) {
    res$note <- paste(notes, collapse = "; ")
  }

  cat(sprintf(
    "[avonet_q4] med(time)=%.3fs  logLik=%.3f  conv=%s  sd_phy=(%s)\n",
    res$time_s_med, res$logLik, res$converged,
    paste(sprintf("%.3f", sd_phy_hat), collapse = ", ")
  ))
  res
}

avonet_q4_result <- fit_avonet_q4()

## --- Merge with any existing r_results.json ------------------------------
out_path <- file.path(results_dir, "r_results.json")

new_entries <- c(phylo_uni_results, list(q4_result), list(avonet_q4_result))
new_ids <- vapply(new_entries, function(x) as.character(x$cell_id), character(1L))
existing <- if (file.exists(out_path)) {
  jsonlite::read_json(out_path, simplifyVector = FALSE)
} else {
  list()
}
## If the headline cells aren't already in the file (e.g. fresh run), include
## the freshly-computed ones from this script too.
existing_ids <- vapply(existing, function(x) as.character(x$cell_id %||% NA_character_),
                       character(1L))
results_ids <- vapply(results, function(x) as.character(x$cell_id), character(1L))

## Headline 5: replace any matching existing entry with the just-fit one (so
## the file stays internally consistent when fixtures change).
final_by_id <- list()
for (i in seq_along(existing)) {
  final_by_id[[existing_ids[[i]]]] <- existing[[i]]
}
for (i in seq_along(results)) {
  final_by_id[[results_ids[[i]]]] <- results[[i]]
}
for (i in seq_along(new_entries)) {
  final_by_id[[new_ids[[i]]]] <- new_entries[[i]]
}

## Deterministic ordering: headline 5 first, then phylo_p50..p1000, then
## q4_p100, then avonet_q4 (parrot-scale).
order_ids <- c(
  "u_small", "u_med", "u_large", "b_small", "b_med",
  "phylo_p50", "phylo_p200", "phylo_p500", "phylo_p1000",
  "q4_p100", "avonet_q4"
)
final <- list()
for (id in order_ids) {
  if (!is.null(final_by_id[[id]])) {
    final[[length(final) + 1L]] <- final_by_id[[id]]
  }
}
## Anything else (in case a future cell sneaks in) gets appended at the end.
other <- setdiff(names(final_by_id), order_ids)
for (id in other) {
  final[[length(final) + 1L]] <- final_by_id[[id]]
}

jsonlite::write_json(final, out_path, auto_unbox = TRUE, pretty = TRUE)
cat(sprintf("\nWrote %s (%d cells)\n", out_path, length(final)))
