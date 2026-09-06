# gen_data.R — R oracle for the cumulative_logit() mu INDEPENDENT random-slope
# `(0 + x | id)` parity fixture (#563 S8, second RE cell). Run with drmTMB
# 0.7.0:
#
#   Rscript test/parity/fixtures/cumlogit-mu-slope-ranef/gen_data.R
#
# DGP and seed copied verbatim from drmTMB's own Arc 2b sentinel
# (tests/testthat/test-arc2b-mu-random-slope.R, `base_slope()` +
# the "cumulative_logit mu supports an independent random slope" test) so the
# ground truth is drmTMB's own proven-recovering DGP, not a re-derived one.

suppressMessages(library(drmTMB))

base_slope <- function(seed, n_id = 40L, n_each = 15L, slope_sd = 0.5) {
  set.seed(seed)
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  x <- stats::rnorm(n)
  slope <- stats::rnorm(n_id, sd = slope_sd)
  slope <- slope - mean(slope)
  list(id = id, n = n, x = x, slope = slope, eta_slope = slope[id] * x,
       slope_sd = slope_sd)
}

b <- base_slope(20260724)
cut <- c(-1, 0, 1)
lat <- 0.8 * b$x + b$eta_slope + stats::rlogis(b$n)
y <- ordered(findInterval(lat, cut) + 1L, levels = 1:4)
dat <- data.frame(y = y, x = b$x, id = b$id)

fit <- drmTMB(bf(y ~ x + (0 + x | id)), family = cumulative_logit(), data = dat)

cat("convergence:", fit$opt$convergence, "pdHess:", fit$sdr$pdHess, "\n")
cat("coef mu (slope):", coef(fit, "mu"), "\n")
cat("cutpoints:", unname(fit$ordinal$cutpoints), "\n")
cat("sd_slope estimate:", unname(fit$sdpars$mu[["(0 + x | id)"]]), "\n")
cat("loglik:", as.numeric(logLik(fit)), "\n")

res <- tryCatch(
  drmTMB(bf(y ~ x + (0 + x | p | id)), family = cumulative_logit(), data = dat),
  error = function(e) conditionMessage(e)
)
cat("correlated-block-fit error:", res, "\n")

dat$y_int <- as.integer(dat$y)
write.csv(dat[, c("id", "x", "y_int")], "test/parity/fixtures/cumlogit-mu-slope-ranef/data.csv",
          row.names = FALSE)
