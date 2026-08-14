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

tab <- do.call(rbind, rows)
dir.create(dirname(out_path), showWarnings = FALSE, recursive = TRUE)
write.table(tab, out_path, sep = "\t", row.names = FALSE, quote = FALSE)
cat("\nwrote ", out_path, "\n", sep = "")
cat("OVERALL: ", if (all(tab$status == "PARITY_PASS")) "ALL CELLS PASS" else "SOME CELLS FAILED", "\n", sep = "")
