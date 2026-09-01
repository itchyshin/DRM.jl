source("tools/missing_predictor_oracle.R")
p <- list(a = 0.4, b = 1.3, sigma = 0.8, m = -0.2, tau = 0.6)
for (x in c(0.3, NA_real_)) for (y in c(0.9, NA_real_)) {
  value <- joint_mi_loglik(x, y, p, "gaussian")
  integrand <- function(u) dnorm(u, p$m, p$tau) *
    if (is.na(y)) 1 else dnorm(y, p$a + p$b*u, p$sigma)
  expected <- if (is.na(x)) log(integrate(integrand, -Inf, Inf, rel.tol = 1e-10)$value) else log(integrand(x))
  stopifnot(abs(value - expected) < 1e-8)
}
p$b <- 0
stopifnot(abs(joint_mi_loglik(NA_real_, 0.9, p, "gaussian") - dnorm(0.9,p$a,p$sigma,log=TRUE)) < 1e-12)
p$b <- 1.3
for (prob in c(0, 0.3, 1)) {
  p$prob <- prob
  for (x in c(0, 1, NA_real_)) for (y in c(0.9, NA_real_)) {
    masses <- c(1-prob, prob)
    if (!is.na(y)) masses <- masses * dnorm(y, p$a + p$b*c(0,1), p$sigma)
    expected <- if (is.na(x)) log(sum(masses)) else log(masses[x+1])
    value <- joint_mi_loglik(x, y, p, "bernoulli")
    stopifnot(identical(value,expected) || isTRUE(all.equal(value,expected,tolerance=1e-12)))
  }
}
stopifnot(inherits(try(joint_mi_loglik(2, 0.9, p, "bernoulli"),silent=TRUE),'try-error'))
cat("MISSING_PREDICTOR_ORACLE_PASS\n")
