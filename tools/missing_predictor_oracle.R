# Independent mathematical test oracle, not a fitting engine.
# y|x ~ Normal(a + b*x, sigma^2); x is Gaussian or Bernoulli.
# All covariates and parameters are conditioned on. Constants are retained.
joint_mi_loglik <- function(x, y, parameters, family) {
  family <- match.arg(family, c("gaussian", "bernoulli"))
  stopifnot(is.numeric(x), is.numeric(y), length(x) == length(y), length(x) > 0L,
            all(is.finite(x) | is.na(x)), all(is.finite(y) | is.na(y)))
  n <- length(x)
  expand <- function(key, positive = FALSE) {
    v <- parameters[[key]]
    stopifnot(is.numeric(v), length(v) %in% c(1L,n), all(is.finite(v)))
    if (positive) stopifnot(all(v > 0))
    rep(v, length.out = n)
  }
  a <- expand("a"); b <- expand("b"); sigma <- expand("sigma", TRUE)
  if (family == "gaussian") {
    m <- expand("m"); tau <- expand("tau", TRUE)
  } else {
    prob <- expand("prob")
    stopifnot(all(prob >= 0 & prob <= 1), all(is.na(x) | x %in% c(0,1)))
  }
  contribution <- numeric(n)
  for (i in seq_len(n)) {
    if (!is.na(x[i])) {
      contribution[i] <- if (family == "gaussian") {
        dnorm(x[i], m[i], tau[i], log = TRUE)
      } else dbinom(x[i], 1, prob[i], log = TRUE)
      if (!is.na(y[i])) contribution[i] <- contribution[i] +
        dnorm(y[i], a[i] + b[i]*x[i], sigma[i], log = TRUE)
    } else if (!is.na(y[i])) {
      if (family == "gaussian") {
        contribution[i] <- dnorm(y[i], a[i] + b[i]*m[i],
          sqrt(sigma[i]^2 + b[i]^2*tau[i]^2), log = TRUE)
      } else {
        terms <- dbinom(c(0,1), 1, prob[i], log = TRUE) +
          dnorm(y[i], a[i] + b[i]*c(0,1), sigma[i], log = TRUE)
        peak <- max(terms)
        contribution[i] <- if (is.infinite(peak)) peak else peak + log(sum(exp(terms-peak)))
      }
    }
    # Both missing integrates to one, leaving the initialized log contribution 0.
  }
  sum(contribution)
}
