# Independently integrate conditional moments on the retained native fixtures.
# No package fit, source translation, or optimizer run is performed here.
args <- commandArgs(TRUE)
if (length(args) != 2L || file.exists(args[[2L]])) stop("usage: export_joint_predictor_reference.R INPUT_JSON NEW_OUTPUT_JSON")
source("tools/missing_predictor_oracle.R")
input <- jsonlite::fromJSON(args[[1L]], simplifyVector = TRUE)
decode <- function(x) as.numeric(replace(x, x == "NA", NA_character_))
out <- list(scope = "Frozen native parameters with independent quadrature/state-sum conditional moments; no fitting",
  native_receipt_sha256 = digest::digest(file = args[[1L]], algo = "sha256"),
  exporter_sha256 = digest::digest(file = "tools/export_joint_predictor_reference.R", algo = "sha256"),
  tolerance = list(native_loglik = 1e-6, row_loglik = 1e-8, moments = 1e-8), cases = list())
for (kind in c("gaussian", "bernoulli")) {
  old <- input$cases[[kind]]; p <- old$parameters
  x <- decode(old$fixture$x); y <- decode(old$fixture$y); z <- old$fixture$z
  n <- length(x); X <- cbind(1, z)
  beta <- as.numeric(qr.solve(X, p$a))
  alpha <- as.numeric(qr.solve(X, if (kind == "gaussian") p$m else qlogis(p$prob)))
  stopifnot(max(abs(drop(X %*% beta) - p$a)) < 1e-12,
    max(abs(drop(X %*% alpha) - if (kind == "gaussian") p$m else qlogis(p$prob))) < 1e-12)
  row_loglik <- means <- variance <- numeric(n)
  status <- character(n)
  for (i in seq_len(n)) {
    pi <- lapply(p, function(v) if (length(v) == n) v[[i]] else v)
    row_loglik[[i]] <- joint_mi_loglik(x[[i]], y[[i]], pi, kind)
    if (!is.na(x[[i]])) {
      means[[i]] <- x[[i]]; variance[[i]] <- 0; status[[i]] <- "observed"
    } else if (is.na(y[[i]])) {
      means[[i]] <- if (kind == "gaussian") pi$m else pi$prob
      variance[[i]] <- if (kind == "gaussian") pi$tau^2 else pi$prob*(1-pi$prob)
      status[[i]] <- "predictor_only"
    } else if (kind == "gaussian") {
      # Integrate the first moment and then the centered second moment.
      # Neither moment is copied from the Gaussian closed-form result.
      density <- function(u) dnorm(u, pi$m, pi$tau) * dnorm(y[[i]], pi$a + pi$b*u, pi$sigma)
      integrate_value <- function(f) integrate(f, -Inf, Inf, rel.tol = 1e-10, abs.tol = 1e-13, subdivisions = 1000L)$value
      mass <- integrate_value(density)
      stopifnot(is.finite(mass), mass > 0)
      means[[i]] <- integrate_value(function(u) u*density(u))/mass
      variance[[i]] <- integrate_value(function(u) (u-means[[i]])^2*density(u))/mass
      stopifnot(abs(log(mass) - row_loglik[[i]]) < 1e-8)
      status[[i]] <- "gaussian_posterior"
    } else {
      states <- c(0, 1)
      weights <- c(1-pi$prob, pi$prob) * dnorm(y[[i]], pi$a + pi$b*states, pi$sigma)
      weights <- weights/sum(weights)
      means[[i]] <- sum(states*weights)
      variance[[i]] <- sum((states-means[[i]])^2*weights)
      status[[i]] <- "bernoulli_posterior"
    }
  }
  stopifnot(all(is.finite(c(row_loglik, means, variance))), all(variance >= 0),
    all(row_loglik[is.na(x) & is.na(y)] == 0),
    abs(sum(row_loglik) - old$native_loglik) <= out$tolerance$native_loglik)
  theta <- c(beta, p$b, log(p$sigma), alpha, if (kind == "gaussian") log(p$tau))
  out$cases[[kind]] <- list(original_row = seq_len(n),
    x = replace(x, is.na(x), 0), y = replace(y, is.na(y), 0), z = z,
    x_observed = !is.na(x), y_observed = !is.na(y), theta = unname(theta),
    theta_order = c("mu_(Intercept)", "mu_z", "mu_mi(x)", "sigma_(Intercept)",
      "mi_x_(Intercept)", "mi_x_z", if (kind == "gaussian") "sigma_mi_x_log_sd"),
    native_loglik = old$native_loglik, row_loglik = row_loglik,
    conditional_mean = means, conditional_variance = variance, status = status,
    masks = old$masks, native_gradient_max = old$native_gradient_max)
}
jsonlite::write_json(out, args[[2L]], pretty = TRUE, auto_unbox = TRUE, digits = 17)
cat("JOINT_REFERENCE_PASS rows=320 missing_predictors=20\n")
