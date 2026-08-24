# parity_se.R — native-vs-Julia SAME-TARGET standard-error comparison per cell.
#
# The unmeasured axis. `tools/parity_fixture.R` compares coefficients and
# logLik; this script compares per-coefficient Wald STANDARD ERRORS between
# `engine = "tmb"` and `engine = "julia"` on the same target. SE agreement
# between two engines is NOT interval coverage — no coverage claim is made or
# implied here; `interval_status` stays exactly as the capability registry says.
#
#   DRM_JL_PATH=/path/to/DRM.jl Rscript tools/parity_se.R
#
# Writes a TSV of results to `out_path` below (same append-style contract as
# tools/parity_fixture.R). The final NEGATIVE_CONTROL row deliberately perturbs
# one Julia SE by 10% and must come out SE_FAIL — if it ever reads SE_PASS the
# comparator is broken and the whole file is void.

suppressMessages(library(drmTMB))

out_path <- "docs/dev-log/evidence/parity-se.tsv"

# Tolerance (relative, on each per-coefficient SE): SEs are second-order
# quantities — sqrt(diag(inverse observed information)) — and the two engines
# build that information differently (TMB sdreport AD-Hessian vs DRM.jl's
# central finite-difference Jacobian of its exact gradient, h = 1e-5), so they
# will not agree at the 1e-4 coefficient tolerance. 1e-3 relative is the
# measured-headroom choice; see docs/dev-log/evidence/2026-08-24-se-axis.md.
rtol_se <- 1e-3
atol_se <- 1e-8

# Extract named per-coefficient SEs from a fitted object: sqrt of the diagonal
# of the fixed-effect covariance. The two engines label coefficients with
# different separators (native "mu:(Intercept)" vs bridge "mu_(Intercept)"), so
# normalise both to the fixture's flat "<param>_<name>" convention before
# matching by name.
se_of <- function(f) {
  V <- vcov(f)
  v <- diag(as.matrix(V))
  se <- ifelse(v > 0, sqrt(v), NA_real_)
  labels <- rownames(as.matrix(V))
  names(se) <- sub(":", "_", labels, fixed = TRUE)
  se
}

fmt_vec <- function(x) paste(sprintf("%s=%.6g", names(x), x), collapse = ";")

cells <- list(
  list(
    capability_id = "base_gaussian_location_scale",
    cell_id = "se_gaussian_location_scale",
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
    capability_id = "biv_gaussian",
    cell_id = "se_biv_gaussian_rho12",
    label   = "Bivariate Gaussian, rho12 ~ 1, fixed effects",
    build   = function() {
      set.seed(11); n <- 400; x <- rnorm(n)
      s1 <- 0.5; s2 <- 0.8; rho <- 0.6
      z1 <- rnorm(n); z2 <- rho * z1 + sqrt(1 - rho^2) * rnorm(n)
      data.frame(y1 = 0.4 + 0.9 * x + s1 * z1,
                 y2 = -0.2 + 0.5 * x + s2 * z2, x = x)
    },
    formula = function() bf(mu1 = y1 ~ x, mu2 = y2 ~ x,
                            sigma1 = ~ 1, sigma2 = ~ 1, rho12 = ~ 1),
    family  = function() biv_gaussian()
  ),
  list(
    capability_id = "base_gaussian_ranef",
    cell_id = "se_gaussian_group_ranef",
    label   = "Gaussian location-scale, group random intercept (Laplace)",
    build   = function() {
      set.seed(777)
      ng <- 30; per <- 8; n <- ng * per
      g <- factor(rep(seq_len(ng), each = per))
      u <- rnorm(ng, sd = 0.5)
      x <- rnorm(n)
      data.frame(y = 0.3 + 0.7 * x + u[as.integer(g)] + 0.6 * rnorm(n),
                 x = x, g = g)
    },
    formula = function() bf(y ~ x + (1 | g), sigma ~ 1),
    family  = function() gaussian()
  )
)

compare_cell <- function(cell, perturb = 0) {
  res <- list(
    capability_id = cell$capability_id, cell_id = cell$cell_id,
    label = cell$label, status = NA_character_,
    max_abs_se_diff = NA_real_, max_rel_se_diff = NA_real_,
    se_tmb = "", se_julia = "",
    tolerance = rtol_se, note = ""
  )
  d <- cell$build()
  ft <- try(drmTMB(cell$formula(), family = cell$family(), data = d, engine = "tmb"),
            silent = TRUE)
  fj <- try(drmTMB(cell$formula(), family = cell$family(), data = d, engine = "julia"),
            silent = TRUE)
  if (inherits(ft, "try-error")) {
    res$status <- "NATIVE_FAILED"; res$note <- conditionMessage(attr(ft, "condition"))
    return(res)
  }
  if (inherits(fj, "try-error")) {
    res$status <- "JULIA_FAILED"; res$note <- conditionMessage(attr(fj, "condition"))
    return(res)
  }
  st <- try(se_of(ft), silent = TRUE)
  sj <- try(se_of(fj), silent = TRUE)
  if (inherits(st, "try-error")) {
    res$status <- "NATIVE_SE_UNAVAILABLE"
    res$note <- conditionMessage(attr(st, "condition")); return(res)
  }
  if (inherits(sj, "try-error")) {
    res$status <- "JULIA_SE_UNAVAILABLE"
    res$note <- conditionMessage(attr(sj, "condition")); return(res)
  }
  if (perturb != 0) sj[1] <- sj[1] * (1 + perturb)
  common <- intersect(names(st), names(sj))
  if (length(common) == 0L && length(st) == length(sj)) {
    common <- seq_along(st)
    res$note <- "matched positionally (no shared names); "
  }
  a <- st[common]; b <- sj[common]
  res$se_tmb <- fmt_vec(st)
  res$se_julia <- fmt_vec(sj)
  # Boundary guard: an SE at a constrained boundary optimum (e.g. a variance
  # component pinned at DRM.jl's log(1e-6) floor, which drmTMB does not share)
  # is not comparable to an interior-optimum SE — no PASS/FAIL is meaningful.
  # Heuristic proxy here: a non-finite or degenerate (<= 1e-6) SE on either
  # side. The authoritative detector is theta-level (see compare.jl's
  # `compare_se` boundary contract); cells below are chosen with variance
  # components well away from any floor.
  degenerate <- !is.finite(a) | !is.finite(b) | a <= 1e-6 | b <= 1e-6
  if (any(degenerate)) {
    res$status <- "BOUNDARY_NOT_COMPARABLE"
    res$note <- paste0(res$note, "degenerate/boundary SE(s): ",
                       paste(names(a)[degenerate], collapse = ","),
                       "; comparison declined, not passed")
    a <- a[!degenerate]; b <- b[!degenerate]
    if (length(a)) {
      res$max_abs_se_diff <- max(abs(a - b))
      res$max_rel_se_diff <- max(abs(a - b) / pmax(abs(a), abs(b)))
    }
    return(res)
  }
  res$max_abs_se_diff <- max(abs(a - b))
  res$max_rel_se_diff <- max(abs(a - b) / pmax(abs(a), abs(b)))
  agree <- res$max_abs_se_diff <= atol_se || res$max_rel_se_diff <= rtol_se
  res$status <- if (agree) "SE_PASS" else "SE_FAIL"
  res$note <- paste0(res$note, length(a), " SE(s) compared",
                     if (perturb != 0) sprintf("; NEGATIVE CONTROL: se_julia[1] perturbed by %+.0f%%", 100 * perturb) else "")
  res
}

rows <- list()
for (cell in cells) {
  res <- compare_cell(cell)
  rows[[length(rows) + 1L]] <- as.data.frame(res, stringsAsFactors = FALSE)
  cat(sprintf("%-28s %-22s abs_diff=%.3e  rel_diff=%.3e\n",
              res$cell_id, res$status, res$max_abs_se_diff, res$max_rel_se_diff))
}

# NEGATIVE CONTROL — prove the comparator can fail. Re-run cell 1 with one
# Julia SE inflated by 10%; the comparator MUST report SE_FAIL.
nc <- cells[[1]]
nc$cell_id <- "negative_control_perturbed"
nc$label <- "NEGATIVE CONTROL: cell 1 with se_julia[1] * 1.10"
res <- compare_cell(nc, perturb = 0.10)
res$status <- if (res$status == "SE_FAIL") "NEGATIVE_CONTROL_OK" else "NEGATIVE_CONTROL_BROKEN"
rows[[length(rows) + 1L]] <- as.data.frame(res, stringsAsFactors = FALSE)
cat(sprintf("%-28s %-22s abs_diff=%.3e  rel_diff=%.3e\n",
            res$cell_id, res$status, res$max_abs_se_diff, res$max_rel_se_diff))

tab <- do.call(rbind, rows)
dir.create(dirname(out_path), showWarnings = FALSE, recursive = TRUE)
write.table(tab, out_path, sep = "\t", row.names = FALSE, quote = FALSE)
cat("\nwrote ", out_path, "\n", sep = "")
main_ok <- all(tab$status[tab$cell_id != "negative_control_perturbed"] == "SE_PASS")
nc_ok <- all(tab$status[tab$cell_id == "negative_control_perturbed"] == "NEGATIVE_CONTROL_OK")
cat("OVERALL: ",
    if (main_ok && nc_ok) "ALL CELLS PASS (+ negative control rejects)" else "SOME CELLS FAILED",
    "\n", sep = "")
