## gen_fixtures.R -- generate committed drmTMB numeric parity fixtures.
##
## This script is for maintainer machines with local R + drmTMB. It is never
## required at test time; `runparity.jl` consumes only the generated CSV/TOML
## fixtures. License boundary: write generated data/numbers only, never source.

suppressPackageStartupMessages(library(drmTMB))

repo_root <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg)) {
    return(normalizePath(file.path(dirname(sub("^--file=", "", file_arg[[1]])), "..", "..")))
  }
  normalizePath(getwd())
}

toml_string <- function(x) {
  paste0('"', gsub('"', '\\"', as.character(x), fixed = TRUE), '"')
}

toml_num <- function(x) {
  if (!is.finite(x)) stop("cannot write non-finite TOML number")
  format(as.numeric(x), digits = 17, scientific = TRUE, trim = TRUE)
}

toml_array <- function(xs) {
  paste0("[", paste(vapply(xs, toml_string, character(1)), collapse = ", "), "]")
}

toml_matrix <- function(M) {
  rows <- apply(M, 1, function(row) {
    paste0("[", paste(vapply(row, toml_num, character(1)), collapse = ", "), "]")
  })
  paste0("[", paste(rows, collapse = ", "), "]")
}

flat_coef <- function(fit) {
  cf <- coef(fit)
  out <- numeric()
  for (param in names(cf)) {
    vals <- as.numeric(cf[[param]])
    names(vals) <- paste0(param, "_", names(cf[[param]]))
    out <- c(out, vals)
  }
  out
}

vcov_order <- function(fit) {
  sub(":", "_", rownames(vcov(fit)), fixed = TRUE)
}

transform_expected <- function(case, coefs, V, order) {
  deriv <- rep(1.0, length(order))
  names(deriv) <- order

  if (case == "count-nbinom2") {
    idx <- startsWith(names(coefs), "sigma_")
    coefs[idx] <- -2.0 * coefs[idx]
    deriv[startsWith(names(deriv), "sigma_")] <- -2.0
  }

  if (case == "robust-student") {
    idx <- startsWith(names(coefs), "nu_")
    raw <- coefs[idx]
    coefs[idx] <- log(exp(raw) + 2.0)
    deriv[names(raw)] <- exp(raw) / (exp(raw) + 2.0)
  }

  D <- diag(deriv[order], nrow = length(order))
  list(coef = coefs, vcov = D %*% V %*% D)
}

write_expected <- function(dir, family, formula, fit, case) {
  coefs <- flat_coef(fit)
  V <- vcov(fit)
  order <- vcov_order(fit)
  names(coefs) <- sub(":", "_", names(coefs), fixed = TRUE)

  transformed <- transform_expected(case, coefs, V, order)
  coefs <- transformed$coef
  V <- transformed$vcov

  ll <- as.numeric(logLik(fit))
  df <- as.integer(attr(logLik(fit), "df"))
  n <- as.integer(attr(logLik(fit), "nobs"))
  if (is.na(n)) n <- nobs(fit)

  path <- file.path(dir, "expected.toml")
  con <- file(path, "w")
  on.exit(close(con), add = TRUE)
  writeLines(c(
    "[fit]",
    paste0("family = ", toml_string(family)),
    paste0("formula = ", toml_string(formula)),
    paste0("loglik = ", toml_num(ll)),
    paste0("aic = ", toml_num(AIC(fit))),
    paste0("df = ", df),
    paste0("n = ", n),
    "",
    "[coef]"
  ), con)
  for (name in sort(names(coefs))) {
    writeLines(paste0(toml_string(name), " = ", toml_num(coefs[[name]])), con)
  }
  writeLines(c(
    "",
    "[vcov]",
    paste0("order = ", toml_array(order)),
    paste0("data = ", toml_matrix(V)),
    "",
    "[tol]",
    "atol_loglik = 1e-3",
    "atol_aic = 1e-3"
  ), con)
}

write_meta <- function(dir, r_call, seed, note_extra = "") {
  note <- "Generated outputs only; no drmTMB source vendored."
  if (nzchar(note_extra)) note <- paste(note, note_extra)
  lines <- c(
    paste0("drmtmb_version = ", toml_string(as.character(utils::packageVersion("drmTMB")))),
    paste0("generated_on = ", toml_string(as.character(Sys.Date()))),
    paste0("r_call = ", toml_string(r_call)),
    paste0("seed = ", as.integer(seed)),
    paste0("note = ", toml_string(note))
  )
  writeLines(lines, file.path(dir, "expected.meta.toml"))
}

write_case <- function(slug, seed, data, formula, family_label, r_call, fit,
                       note_extra = "") {
  dir <- file.path(repo_root(), "test", "parity", "fixtures", slug)
  if (dir.exists(dir)) unlink(dir, recursive = TRUE)
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  write.csv(data, file.path(dir, "data.csv"), row.names = FALSE)
  write_expected(dir, family_label, formula, fit, slug)
  write_meta(dir, r_call, seed, note_extra)
}

generate_gaussian <- function() {
  seed <- 20260604
  set.seed(seed)
  n <- 180
  dat <- data.frame(x = rnorm(n))
  dat$y <- 0.4 - 0.6 * dat$x + exp(-0.2 + 0.3 * dat$x) * rnorm(n)
  fit <- drmTMB(drm_formula(y ~ x, sigma ~ x), family = gaussian(), data = dat)
  write_case(
    "gaussian-locscale", seed, dat, "y ~ x; sigma ~ x", "gaussian",
    "drmTMB(drm_formula(y ~ x, sigma ~ x), family = gaussian(), data = dat)",
    fit
  )
}

generate_bivariate <- function() {
  seed <- 20260605
  set.seed(seed)
  n <- 180
  x <- rnorm(n)
  z1 <- rnorm(n)
  z2 <- rnorm(n)
  mu1 <- 0.2 + 0.4 * x
  mu2 <- -0.1 + 0.3 * x
  sigma1 <- exp(-0.1)
  sigma2 <- exp(0.15)
  rho <- tanh(0.35)
  dat <- data.frame(
    y1 = mu1 + sigma1 * z1,
    y2 = mu2 + sigma2 * (rho * z1 + sqrt(1 - rho^2) * z2),
    x = x
  )
  fit <- drmTMB(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ x,
       sigma1 = sigma1 ~ 1, sigma2 = sigma2 ~ 1, rho12 = rho12 ~ 1),
    family = biv_gaussian(), data = dat
  )
  write_case(
    "gaussian-bivariate-rho12", seed, dat,
    paste(
      "mu1 = y1 ~ x", "mu2 = y2 ~ x", "sigma1 = sigma1 ~ 1",
      "sigma2 = sigma2 ~ 1", "rho12 = rho12 ~ 1", sep = "; "
    ),
    "biv_gaussian",
    paste(
      "drmTMB(bf(mu1 = y1 ~ x, mu2 = y2 ~ x,",
      "sigma1 = sigma1 ~ 1, sigma2 = sigma2 ~ 1, rho12 = rho12 ~ 1),",
      "family = biv_gaussian(), data = dat)"
    ),
    fit
  )
}

generate_meta <- function() {
  seed <- 20260606
  set.seed(seed)
  n <- 160
  x <- rnorm(n)
  v <- (0.12 + 0.25 * runif(n))^2
  y <- 0.2 + 0.5 * x + sqrt(v + 0.35^2) * rnorm(n)
  dat <- data.frame(y = y, x = x, v = v)
  fit <- drmTMB(drm_formula(y ~ x + meta_V(V = v), sigma ~ 1),
                family = gaussian(), data = dat)
  write_case(
    "meta-analysis-V", seed, dat, "y ~ x + meta_V(v); sigma ~ 1", "gaussian",
    "drmTMB(drm_formula(y ~ x + meta_V(V = v), sigma ~ 1), family = gaussian(), data = dat)",
    fit,
    "R drmTMB uses named meta_V(V = v); DRM.jl runner uses meta_V(v)."
  )
}

generate_student <- function() {
  seed <- 20260607
  set.seed(seed)
  n <- 180
  x <- rnorm(n)
  y <- 0.2 + 0.4 * x + 0.7 * rt(n, df = 6)
  dat <- data.frame(y = y, x = x)
  fit <- drmTMB(drm_formula(y ~ x, sigma ~ 1, nu ~ 1),
                family = student(), data = dat)
  write_case(
    "robust-student", seed, dat, "y ~ x; sigma ~ 1; nu ~ 1", "student",
    "drmTMB(drm_formula(y ~ x, sigma ~ 1, nu ~ 1), family = student(), data = dat)",
    fit,
    "Student nu is transformed from drmTMB log(nu - 2) to DRM.jl log(nu)."
  )
}

generate_nbinom2 <- function() {
  seed <- 20260608
  set.seed(seed)
  n <- 180
  x <- rnorm(n)
  mu <- exp(0.3 + 0.45 * x)
  theta <- 2.5
  y <- rnbinom(n, size = theta, mu = mu)
  dat <- data.frame(y = y, x = x)
  fit <- drmTMB(drm_formula(y ~ x, sigma ~ 1),
                family = nbinom2(), data = dat)
  write_case(
    "count-nbinom2", seed, dat, "y ~ x; sigma ~ 1", "nbinom2",
    "drmTMB(drm_formula(y ~ x, sigma ~ 1), family = nbinom2(), data = dat)",
    fit,
    "NB2 sigma is transformed from drmTMB log(sigma) to DRM.jl log(theta)."
  )
}

generate_beta <- function() {
  seed <- 20260609
  set.seed(seed)
  n <- 180
  x <- rnorm(n)
  eta <- -0.2 + 0.5 * x
  p <- plogis(eta)
  phi <- 12
  y <- rbeta(n, p * phi, (1 - p) * phi)
  dat <- data.frame(y = y, x = x)
  fit <- drmTMB(drm_formula(y ~ x, sigma ~ 1),
                family = beta(), data = dat)
  write_case(
    "proportion-beta", seed, dat, "y ~ x; sigma ~ 1", "beta",
    "drmTMB(drm_formula(y ~ x, sigma ~ 1), family = beta(), data = dat)",
    fit
  )
}

dir.create(file.path(repo_root(), "test", "parity", "fixtures"),
           recursive = TRUE, showWarnings = FALSE)

generate_gaussian()
generate_bivariate()
generate_meta()
generate_student()
generate_nbinom2()
generate_beta()

message("Generated drmTMB parity fixtures under test/parity/fixtures/")
