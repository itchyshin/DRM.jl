# gen_data.R — R oracle for the tweedie() mu INDEPENDENT random-slope
# `(0 + x | id)` parity fixture (#563 S8, second RE cell). Run with drmTMB
# 0.7.0:
#
#   Rscript test/parity/fixtures/tweedie-mu-slope-ranef/gen_data.R
#
# Sibling of test/parity/fixtures/tweedie-mu-ranef/gen_data.R (the ordinary
# random-intercept cell); same DGP shape, different seed and random term
# (`(0 + x | id)` slope-only instead of `(1 | id)` intercept-only).

suppressMessages(library(drmTMB))

new_tweedie_random_slope_data <- function(
  n_id = 40, n_each = 8, seed = 20260902,
  beta_mu = c("(Intercept)" = 0.5, x = 0.3),
  nu = 1.5, phi = 1.0, sd_slope = 0.4
) {
  set.seed(seed)
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  dat <- data.frame(id = id, x = stats::runif(n, -1, 1))
  b_id <- stats::rnorm(n_id, sd = sd_slope)
  b_id <- b_id - mean(b_id)
  names(b_id) <- levels(id)
  eta_mu <- beta_mu[[1L]] + (beta_mu[[2L]] + b_id[id]) * dat$x
  mu <- exp(eta_mu)
  dat$y <- drmTMB:::rtweedie_compound(n, mu = mu, phi = phi, power = nu)
  list(data = dat, beta_mu = beta_mu, nu = nu, phi = phi, sd_slope = sd_slope, b_id = b_id)
}

sim <- new_tweedie_random_slope_data()
cat("n zeros:", sum(sim$data$y == 0), "of", nrow(sim$data), "\n")

fit <- drmTMB(bf(y ~ x + (0 + x | id), nu ~ 1), family = tweedie(), data = sim$data)

cat("convergence:", fit$opt$convergence, "pdHess:", fit$sdr$pdHess, "\n")
cat("coef mu:", coef(fit, "mu"), "\n")
cat("coef sigma (log sigma):", coef(fit, "sigma"), "\n")
cat("coef nu (logit):", coef(fit, "nu"), "\n")
print(fit$sdpars$mu)
cat("loglik:", as.numeric(logLik(fit)), "\n")

write.csv(sim$data, "test/parity/fixtures/tweedie-mu-slope-ranef/data.csv", row.names = FALSE)
