# parity_fixture.R — native-vs-Julia same-target comparison per bridge cell.
#
# The promotion gate. A drmTMB capability row may only move toward `supported`
# on evidence that `engine = "julia"` and `engine = "tmb"` fit the SAME target
# and agree — matching coefficients and logLik within a declared tolerance.
# Direct DRM.jl evidence is not R-via-Julia bridge support, so this must run
# through drmTMB itself.
#
#   DRM_JL_PATH=/path/to/DRM.jl Rscript tools/parity_fixture.R
#
# Writes a TSV of results next to this script's --out argument (default below).

suppressMessages(library(drmTMB))

out_path <- "docs/dev-log/evidence/parity-fixtures.tsv"
tol <- 1e-4

cells <- list(
  list(
    id      = "base_gaussian_location_scale",
    label   = "Gaussian location-scale, fixed effects",
    build   = function() {
      set.seed(20260814)
      n <- 120
      x <- rnorm(n); z <- rnorm(n)
      data.frame(y = 0.4 + 0.9 * x + exp(-0.3 + 0.25 * z) * rnorm(n), x = x, z = z)
    },
    formula = function() bf(y ~ x, sigma ~ z),
    family  = function() gaussian()
  ),
  list(
    id      = "base_gaussian_intercept_only",
    label   = "Gaussian, intercept-only sigma",
    build   = function() {
      set.seed(99)
      n <- 100
      x <- rnorm(n)
      data.frame(y = 1.2 - 0.6 * x + 0.7 * rnorm(n), x = x)
    },
    formula = function() bf(y ~ x, sigma ~ 1),
    family  = function() gaussian()
  )
)

# Fixed-effect non-Gaussian cells. The R gate REFUSES these through
# `engine = "julia"` ("routes <family> models only with a phylo() random
# intercept"), and the gate registry's stated reason is the absence of a
# coefficient-scale parity test. So compare native TMB against the DRM.jl bridge
# payload directly — the payload the bridge WOULD return if the gate opened.
# This is the evidence the gate's own `review_due` asks for.
fe_cells <- list(
  list(id = "fe_poisson", label = "Poisson, fixed effects", jfam = "poisson",
       family = function() poisson(),
       build = function() { set.seed(4242); n <- 150; x <- rnorm(n)
                            data.frame(y = rpois(n, exp(0.6 + 0.4 * x)), x = x) }),
  list(id = "fe_nbinom2", label = "NegBinomial2, fixed effects", jfam = "nbinom2",
       family = function() nbinom2(),
       build = function() { set.seed(4242); n <- 150; x <- rnorm(n)
                            data.frame(y = rnbinom(n, mu = exp(0.6 + 0.4 * x), size = 3), x = x) }),
  list(id = "fe_gamma", label = "Gamma (log link), fixed effects", jfam = "gamma",
       family = function() Gamma(link = "log"),
       build = function() { set.seed(4242); n <- 150; x <- rnorm(n)
                            data.frame(y = rgamma(n, shape = 4, rate = 4 / exp(0.5 + 0.3 * x)), x = x) })
)

# Bivariate lognormal (drmTMB biv_lognormal). Compared native-TMB vs the DRM.jl
# bridge payload: `engine = "julia"` does not route this family at the anchor, so
# this is capability parity for the Julia implementation, NOT bridge admission.
biv_cells <- list(
  list(id = "biv_lognormal", label = "Bivariate lognormal, fixed effects",
       jfam = "biv_lognormal",
       family = function() biv_lognormal(),
       formula = function() bf(mu1 = y1 ~ x, mu2 = y2 ~ x,
                               sigma1 = ~ 1, sigma2 = ~ 1, rho12 = ~ 1),
       jformula = list(mu1 = "y1 ~ x", mu2 = "y2 ~ x", sigma1 = "sigma1 ~ 1",
                       sigma2 = "sigma2 ~ 1", rho12 = "rho12 ~ 1"),
       build = function() {
         set.seed(11); n <- 500; x <- rnorm(n)
         s1 <- 0.5; s2 <- 0.8; rho <- 0.6
         z1 <- rnorm(n); z2 <- rho * z1 + sqrt(1 - rho^2) * rnorm(n)
         data.frame(y1 = exp(0.4 + 0.9 * x + s1 * z1),
                    y2 = exp(-0.2 + 0.5 * x + s2 * z2), x = x)
       }),
  list(id = "biv_student", label = "Bivariate Student-t, fixed effects",
       jfam = "biv_student",
       family = function() biv_student(),
       formula = function() bf(mu1 = y1 ~ x, mu2 = y2 ~ x,
                               sigma1 = ~ 1, sigma2 = ~ 1, nu = ~ 1, rho12 = ~ 1),
       jformula = list(mu1 = "y1 ~ x", mu2 = "y2 ~ x", sigma1 = "sigma1 ~ 1",
                       sigma2 = "sigma2 ~ 1", nu = "nu ~ 1", rho12 = "rho12 ~ 1"),
       build = function() {
         set.seed(21); n <- 800; x <- rnorm(n)
         s1 <- 0.7; s2 <- 1.1; rho <- 0.5; nu <- 6
         z1 <- rnorm(n); z2 <- rho * z1 + sqrt(1 - rho^2) * rnorm(n)
         sh <- sqrt(nu / rchisq(n, df = nu))
         data.frame(y1 = 0.5 + 0.8 * x + s1 * z1 * sh,
                    y2 = -0.3 + 0.4 * x + s2 * z2 * sh, x = x)
       })
)

rows <- list()
for (cell in cells) {
  d <- cell$build()
  res <- list(
    capability_id = cell$id, label = cell$label,
    status = NA_character_, max_abs_coef_diff = NA_real_,
    loglik_tmb = NA_real_, loglik_julia = NA_real_, loglik_diff = NA_real_,
    tolerance = tol, note = ""
  )

  ft <- try(drmTMB(cell$formula(), family = cell$family(), data = d, engine = "tmb"),
            silent = TRUE)
  fj <- try(drmTMB(cell$formula(), family = cell$family(), data = d, engine = "julia"),
            silent = TRUE)

  if (inherits(ft, "try-error")) {
    res$status <- "NATIVE_FAILED"; res$note <- conditionMessage(attr(ft, "condition"))
  } else if (inherits(fj, "try-error")) {
    res$status <- "JULIA_FAILED"; res$note <- conditionMessage(attr(fj, "condition"))
  } else {
    ct <- unlist(fixef(ft)); cj <- unlist(fixef(fj))
    common <- intersect(names(ct), names(cj))
    if (length(common) == 0L && length(ct) == length(cj)) common <- seq_along(ct)
    res$max_abs_coef_diff <- max(abs(ct[common] - cj[common]))
    res$loglik_tmb <- as.numeric(logLik(ft))
    res$loglik_julia <- as.numeric(logLik(fj))
    res$loglik_diff <- abs(res$loglik_tmb - res$loglik_julia)
    agree <- res$max_abs_coef_diff < tol && res$loglik_diff < tol
    res$status <- if (agree) "PARITY_PASS" else "PARITY_FAIL"
    res$note <- sprintf("%d coefficient(s) compared", length(common))
  }
  rows[[length(rows) + 1L]] <- as.data.frame(res, stringsAsFactors = FALSE)
  cat(sprintf("%-32s %-14s coef_diff=%.3e  loglik_diff=%.3e\n",
              res$capability_id, res$status,
              res$max_abs_coef_diff, res$loglik_diff))
}

drmTMB:::drm_julia_setup()
for (cell in fe_cells) {
  d <- cell$build()
  res <- list(
    capability_id = cell$id, label = cell$label,
    status = NA_character_, max_abs_coef_diff = NA_real_,
    loglik_tmb = NA_real_, loglik_julia = NA_real_, loglik_diff = NA_real_,
    tolerance = tol, note = "gate REFUSES engine='julia'; compared vs DRM.jl bridge payload"
  )
  ft <- try(drmTMB(bf(y ~ x), family = cell$family(), data = d, engine = "tmb"), silent = TRUE)
  jb <- try(JuliaCall::julia_call("drmTMB_drm_bridge", "y ~ x", cell$jfam,
                                  as.list(d), NULL, NULL), silent = TRUE)
  if (inherits(ft, "try-error")) {
    res$status <- "NATIVE_FAILED"
  } else if (inherits(jb, "try-error")) {
    res$status <- "JULIA_FAILED"
  } else {
    ct <- unlist(fixef(ft)); cj <- jb$coefficients
    k <- min(length(ct), length(cj))
    res$max_abs_coef_diff <- max(abs(ct[seq_len(k)] - cj[seq_len(k)]))
    res$loglik_tmb <- as.numeric(logLik(ft)); res$loglik_julia <- jb$loglik
    res$loglik_diff <- abs(res$loglik_tmb - res$loglik_julia)
    res$status <- if (res$max_abs_coef_diff < tol && res$loglik_diff < tol)
      "PARITY_PASS" else "PARITY_FAIL"
  }
  rows[[length(rows) + 1L]] <- as.data.frame(res, stringsAsFactors = FALSE)
  cat(sprintf("%-32s %-14s coef_diff=%.3e  loglik_diff=%.3e\n",
              res$capability_id, res$status, res$max_abs_coef_diff, res$loglik_diff))
}

for (cell in biv_cells) {
  d <- cell$build()
  res <- list(
    capability_id = cell$id, label = cell$label,
    status = NA_character_, max_abs_coef_diff = NA_real_,
    loglik_tmb = NA_real_, loglik_julia = NA_real_, loglik_diff = NA_real_,
    tolerance = tol, note = "capability parity vs DRM.jl bridge payload; not bridge admission"
  )
  ft <- try(drmTMB(cell$formula(), family = cell$family(), data = d, engine = "tmb"),
            silent = TRUE)
  jb <- try(JuliaCall::julia_call("drmTMB_drm_bridge", cell$jformula, cell$jfam,
                                  as.list(d), NULL, NULL), silent = TRUE)
  if (inherits(ft, "try-error")) {
    res$status <- "NATIVE_FAILED"
  } else if (inherits(jb, "try-error")) {
    res$status <- "JULIA_FAILED"
  } else {
    ct <- unlist(fixef(ft)); cj <- jb$coefficients
    k <- min(length(ct), length(cj))
    res$max_abs_coef_diff <- max(abs(ct[seq_len(k)] - cj[seq_len(k)]))
    res$loglik_tmb <- as.numeric(logLik(ft)); res$loglik_julia <- jb$loglik
    res$loglik_diff <- abs(res$loglik_tmb - res$loglik_julia)
    res$status <- if (res$max_abs_coef_diff < tol && res$loglik_diff < tol)
      "PARITY_PASS" else "PARITY_FAIL"
  }
  rows[[length(rows) + 1L]] <- as.data.frame(res, stringsAsFactors = FALSE)
  cat(sprintf("%-32s %-14s coef_diff=%.3e  loglik_diff=%.3e\n",
              res$capability_id, res$status, res$max_abs_coef_diff, res$loglik_diff))
}

tab <- do.call(rbind, rows)
dir.create(dirname(out_path), showWarnings = FALSE, recursive = TRUE)
write.table(tab, out_path, sep = "\t", row.names = FALSE, quote = FALSE)
cat("\nwrote ", out_path, "\n", sep = "")
cat("OVERALL: ", if (all(tab$status == "PARITY_PASS")) "ALL CELLS PASS" else "SOME CELLS FAILED", "\n", sep = "")
