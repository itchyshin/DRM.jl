#!/usr/bin/env Rscript
# parity_classc_largep.R — extend the phylo_count_large_p measurement
# (tools/parity_classc.R) past its existing p=300 ceiling, to test the row's
# actual claim_boundary: "large-p phylogenetic random-intercept route".
#
# tools/parity_classc.R itself is NOT modified — its own
# make_phylo_count_fixture(seed, p, m, ...) already takes p as an argument;
# this script reuses that same fixture generator verbatim at a larger p and
# times engine="tmb" (native drmTMB, dense O(p^3) phylo covariance
# factorisation) separately from engine="julia" (DRM.jl's sparse route),
# because the point of this probe is the cost asymmetry between the two
# factorisations, not just coefficient agreement.
#
#   DRM_JL_PATH=$(pwd) NOT_CRAN=true Rscript tools/parity_classc_largep.R [p] [m]
#
# Default p=1000, m=4 (same m as the p=300 Poisson cell in parity_classc.R).
# D-139: state the estimate before running, cap the native-TMB fit with a
# hard wall-clock ceiling so a divergent/hanging dense factorisation cannot
# silently burn the whole time budget — if it fires, that IS the result
# (NO_NATIVE_COMPARATOR_AT_SCALE), not a script bug.

suppressMessages(library(drmTMB))
stopifnot(requireNamespace("ape", quietly = TRUE))

args <- commandArgs(trailingOnly = TRUE)
p <- if (length(args) >= 1) as.integer(args[[1]]) else 1000L
m <- if (length(args) >= 2) as.integer(args[[2]]) else 4L
seed <- 20260824L
tol <- 1e-4
tmb_timeout_sec <- if (length(args) >= 3) as.numeric(args[[3]]) else 1500  # 25 min ceiling

cat(sprintf("=== phylo_count_large_p large-p probe: p=%d, m=%d, seed=%d ===\n", p, m, seed))

# Copied verbatim from tools/parity_classc.R's make_phylo_count_fixture() —
# harness not modified, just called at a different p from here.
make_phylo_count_fixture <- function(seed, p, m, beta = c(0.30, 0.35),
                                      sd_phy = 0.5, size_nb = 4) {
  set.seed(seed)
  tree <- ape::rcoal(p)
  tree$tip.label <- paste0("sp_", seq_len(p))
  A <- ape::vcv(tree, corr = TRUE)
  u <- as.vector(t(chol(A)) %*% rnorm(p)) * sd_phy
  species <- factor(rep(tree$tip.label, each = m), levels = tree$tip.label)
  idx <- rep(seq_len(p), each = m)
  n <- p * m
  x <- rnorm(n)
  eta <- beta[1] + beta[2] * x + u[idx]
  list(
    tree = tree,
    data_pois = data.frame(y = rpois(n, exp(eta)), x = x, species = species),
    data_nb2  = data.frame(
      y = rnbinom(n, mu = exp(eta), size = size_nb), x = x, species = species
    )
  )
}

fx <- make_phylo_count_fixture(seed = seed, p = p, m = m)
tree <- fx$tree
dat <- fx$data_pois
cat(sprintf("Fixture built: n=%d rows, p=%d tips, m=%d reps/tip\n", nrow(dat), p, m))

# --- native TMB, dense O(p^3), wall-clock capped -----------------------
cat(sprintf("Fitting engine = 'tmb' (native, dense phylo factorisation), timeout=%.0fs...\n",
            tmb_timeout_sec))
ft <- NULL
t_tmb <- system.time({
  ft <- tryCatch({
    setTimeLimit(elapsed = tmb_timeout_sec, transient = TRUE)
    on.exit(setTimeLimit(elapsed = Inf, transient = TRUE), add = TRUE)
    drmTMB(bf(y ~ x + phylo(1 | species, tree = tree)),
           family = stats::poisson(link = "log"), data = dat, engine = "tmb")
  }, error = function(e) {
    cat("NATIVE TMB FAILED/TIMED OUT: ", conditionMessage(e), "\n")
    NULL
  })
})
cat(sprintf("  wall clock (tmb): %.2f sec\n", t_tmb[["elapsed"]]))

# --- DRM.jl sparse route -------------------------------------------------
cat("Fitting engine = 'julia' (DRM.jl sparse route)...\n")
fj <- NULL
t_jl <- system.time({
  fj <- tryCatch(
    drmTMB(bf(y ~ x + phylo(1 | species, tree = tree)),
           family = stats::poisson(link = "log"), data = dat, engine = "julia"),
    error = function(e) { cat("JULIA ENGINE FAILED: ", conditionMessage(e), "\n"); NULL }
  )
})
cat(sprintf("  wall clock (julia): %.2f sec\n", t_jl[["elapsed"]]))

# --- verify output is REAL, not silently NA/empty -----------------------
check_real <- function(fit, label) {
  if (is.null(fit)) { cat(sprintf("  %s: NULL fit\n", label)); return(FALSE) }
  co <- unlist(fixef(fit))
  ll <- tryCatch(as.numeric(logLik(fit)), error = function(e) NA_real_)
  ok <- length(co) > 0 && !any(is.na(co)) && is.finite(ll)
  cat(sprintf("  %s: coef=%s logLik=%.4f real=%s\n", label,
              paste(sprintf("%.4f", co), collapse = ","), ll, ok))
  ok
}
ok_tmb <- check_real(ft, "tmb")
ok_jl  <- check_real(fj, "julia")

if (ok_tmb && ok_jl) {
  ct <- unlist(fixef(ft)); cj <- unlist(fixef(fj))
  k <- min(length(ct), length(cj))
  max_abs_coef_diff <- max(abs(ct[seq_len(k)] - cj[seq_len(k)]))
  ll_tmb <- as.numeric(logLik(ft)); ll_jl <- as.numeric(logLik(fj))
  ll_diff <- abs(ll_tmb - ll_jl)
  se_tmb <- tryCatch(sqrt(diag(vcov(ft)))[seq_len(k)], error = function(e) rep(NA_real_, k))
  se_jl  <- tryCatch(sqrt(diag(vcov(fj)))[seq_len(k)], error = function(e) rep(NA_real_, k))
  cat(sprintf("max|coef diff| = %.3e, |logLik diff| = %.3e\n", max_abs_coef_diff, ll_diff))
  cat("SE tmb:   ", paste(sprintf("%.6f", se_tmb), collapse = ", "), "\n")
  cat("SE julia: ", paste(sprintf("%.6f", se_jl), collapse = ", "), "\n")
  status <- if (max_abs_coef_diff < tol && ll_diff < tol) "PARITY_PASS" else "PARITY_FAIL"
  cat("STATUS: ", status, "\n")
} else if (ok_tmb && !ok_jl) {
  cat("STATUS: JULIA_FAILED (native tmb succeeded)\n")
} else if (!ok_tmb && ok_jl) {
  cat("STATUS: NO_NATIVE_COMPARATOR_AT_SCALE (native tmb failed/timed out, DRM.jl succeeded)\n")
} else {
  cat("STATUS: BOTH_FAILED\n")
}

cat(sprintf("\nSUMMARY p=%d m=%d n=%d: tmb=%.2fs julia=%.2fs\n",
            p, m, nrow(dat), t_tmb[["elapsed"]], t_jl[["elapsed"]]))
