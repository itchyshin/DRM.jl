# parity_intervals.R — the interval TRIO at parity: Wald, profile, bootstrap.
#
# Point estimates and logLik agreeing is not the same as INFERENCE agreeing. Both
# engines advertise the same three interval methods:
#
#   confint(object, method = c("wald", "profile", "bootstrap"))
#
# so the capability SURFACE matches on both sides. This script asks the question
# the surface cannot answer: for the same fit, does each method actually run on
# each engine, and do the intervals agree?
#
# Capability parity first. A method that errors on one side is a capability gap;
# a method that runs on both but returns materially different intervals is a
# correctness gap. Both are recorded, and they are NOT the same finding.
#
#   DRM_JL_PATH=/path/to/DRM.jl Rscript tools/parity_intervals.R
#
# Deliberately uses the INSTALLED drmTMB, like every other parity script here --
# never devtools::load_all() on the source tree, which on 2026-08-24 silently
# measured a dirty 0.6.0.9000 checkout while another lane was editing it.

suppressMessages(library(drmTMB))

out_path <- "docs/dev-log/evidence/parity-intervals.tsv"
R_boot   <- as.integer(Sys.getenv("DRM_INT_R", "99"))
boot_seed <- 20260824L
tol_rel  <- 1e-3   # relative agreement bar for an interval endpoint

message(sprintf("parity_intervals.R: INSTALLED drmTMB %s | R_boot=%d | seed=%d",
                as.character(utils::packageVersion("drmTMB")), R_boot, boot_seed))

## ---- cells ---------------------------------------------------------------

cells <- list(
  list(
    id    = "gauss_locscale_fe",
    label = "Gaussian location-scale, fixed effects",
    build = function() {
      set.seed(20260824); n <- 200; x <- rnorm(n); z <- rnorm(n)
      data.frame(y = 0.4 + 0.9 * x + exp(-0.3 + 0.25 * z) * rnorm(n), x = x, z = z)
    },
    formula = function() bf(y ~ x, sigma ~ z),
    family  = function() gaussian()
  ),
  list(
    id    = "gauss_mean_only",
    label = "Gaussian, mean-only (sigma ~ 1)",
    build = function() {
      set.seed(20260824); n <- 200; x <- rnorm(n)
      data.frame(y = 0.4 + 0.9 * x + rnorm(n), x = x)
    },
    formula = function() bf(y ~ x, sigma ~ 1),
    family  = function() gaussian()
  ),
  list(
    id    = "poisson_fe",
    label = "Poisson, fixed effects",
    build = function() {
      set.seed(20260824); n <- 200; x <- rnorm(n)
      data.frame(y = rpois(n, exp(0.6 + 0.4 * x)), x = x)
    },
    formula = function() bf(y ~ x),
    family  = function() poisson()
  )
)

methods <- c("wald", "profile", "bootstrap")

## ---- helpers -------------------------------------------------------------

one_line <- function(x) gsub("[\r\n]+", " ", paste(as.character(x), collapse = " "))

# Return a named list(lower=, upper=, ok=, note=) for one engine x method.
# `parm` matters: profile intervals REQUIRE an explicit target on both engines
# ("Profile confidence intervals currently require explicit target names"), so
# calling confint(method="profile") with no parm reports UNSUPPORTED on both
# sides and hides the real asymmetry underneath.
get_ci <- function(fit, method, parm = NULL) {
  res <- tryCatch({
    ci <- if (method == "bootstrap") {
      if (is.null(parm)) confint(fit, method = method, R = R_boot, seed = boot_seed)
      else confint(fit, parm = parm, method = method, R = R_boot, seed = boot_seed)
    } else if (!is.null(parm)) {
      confint(fit, parm = parm, method = method)
    } else {
      confint(fit, method = method)
    }
    ci <- as.data.frame(ci)
    list(ok = TRUE, ci = ci, note = "")
  }, error = function(e) list(ok = FALSE, ci = NULL, note = one_line(conditionMessage(e))))
  res
}

# Align two CI tables on their common rows, comparing endpoints by row name where
# possible and positionally otherwise (the two engines spell coefficient names
# differently -- `mu:x` native vs `mu_x` julia -- so name matching must normalise).
norm_names <- function(x) gsub(":", "_", x, fixed = TRUE)

compare_ci <- function(a, b) {
  # confint.drmTMB returns NAMED columns (parm, level, lower, upper, tmb_parameter,
  # ...), not positional endpoints. Reading columns 1:2 as lower/upper silently
  # coerced the `parm` STRINGS to NA and produced width_ratio = -Inf -- a
  # comparison that looked like it ran and compared nothing.
  # Key on `parm`, NOT `tmb_parameter`. `parm` is the shared, human-meaningful id
  # and matches across engines ("fixef:mu:x"). `tmb_parameter` does not: native
  # TMB reports internal block names (beta_mu, beta_sigma) which are NOT UNIQUE
  # across rows, while the Julia bridge reports flat coefficient names
  # (mu_(Intercept)). Keying on it matched nothing and every cell came back
  # INDETERMINATE while the endpoints in fact agreed exactly.
  key <- function(x) norm_names(as.character(x$parm))
  need <- c("lower", "upper")
  if (!all(need %in% names(a)) || !all(need %in% names(b))) {
    return(list(n = 0L, max_abs = NA_real_, max_rel = NA_real_,
                width_ratio = NA_real_, how = "no lower/upper columns",
                only_tmb = NA_integer_, only_julia = NA_integer_))
  }
  ka <- key(a); kb <- key(b)
  common <- intersect(ka, kb)
  only_a <- setdiff(ka, kb); only_b <- setdiff(kb, ka)
  if (length(common) == 0L) {
    return(list(n = 0L, max_abs = NA_real_, max_rel = NA_real_,
                width_ratio = NA_real_, how = "no shared parameters",
                only_tmb = length(only_a), only_julia = length(only_b)))
  }
  ia <- match(common, ka); ib <- match(common, kb)
  la <- as.numeric(a$lower[ia]); ua <- as.numeric(a$upper[ia])
  lb <- as.numeric(b$lower[ib]); ub <- as.numeric(b$upper[ib])
  d  <- c(abs(la - lb), abs(ua - ub))
  sc <- c(pmax(abs(la), abs(lb)), pmax(abs(ua), abs(ub)))
  wa <- ua - la; wb <- ub - lb
  ok <- is.finite(wa) & is.finite(wb) & wa > 0 & wb > 0
  wr <- if (any(ok)) max(pmax(wa[ok] / wb[ok], wb[ok] / wa[ok])) else NA_real_
  list(n = length(common),
       max_abs = suppressWarnings(max(d, na.rm = TRUE)),
       max_rel = suppressWarnings(max(d / pmax(sc, 1e-12), na.rm = TRUE)),
       # Width ratio is its own gate: two intervals can share endpoints on the
       # parameters they both report and still disagree on SPREAD elsewhere.
       width_ratio = wr,
       how = sprintf("by name (%d shared)", length(common)),
       only_tmb = length(only_a), only_julia = length(only_b))
}

## ---- run -----------------------------------------------------------------

rows <- list()
for (cell in cells) {
  d <- cell$build()
  ft <- tryCatch(drmTMB(cell$formula(), family = cell$family(), data = d, engine = "tmb"),
                 error = function(e) e)
  fj <- tryCatch(drmTMB(cell$formula(), family = cell$family(), data = d, engine = "julia"),
                 error = function(e) e)
  cat(sprintf("\n-- %s (%s)\n", cell$id, cell$label))

  for (m in methods) {
    rec <- list(cell_id = cell$id, label = cell$label, method = m,
                status = NA_character_, n_params = NA_integer_,
                max_abs_diff = NA_real_, max_rel_diff = NA_real_,
                width_ratio = NA_real_, matched = NA_character_,
                only_tmb = NA_integer_, only_julia = NA_integer_,
                tolerance = tol_rel, note = "")

    if (inherits(ft, "error") || inherits(fj, "error")) {
      rec$status <- "FIT_FAILED"
      rec$note <- one_line(if (inherits(ft, "error")) conditionMessage(ft) else conditionMessage(fj))
    } else {
      # Profile needs an explicit target; use a fixed effect present in every cell.
      parm_m <- if (m == "profile") "fixef:mu:x" else NULL
      a <- get_ci(ft, m, parm_m); b <- get_ci(fj, m, parm_m)
      if (!a$ok && !b$ok) {
        rec$status <- "UNSUPPORTED_BOTH"; rec$note <- one_line(a$note)
      } else if (!a$ok) {
        rec$status <- "UNSUPPORTED_TMB"; rec$note <- one_line(a$note)
      } else if (!b$ok) {
        rec$status <- "UNSUPPORTED_JULIA"; rec$note <- one_line(b$note)
      } else {
        cmp <- compare_ci(a$ci, b$ci)
        rec$n_params <- cmp$n; rec$max_abs_diff <- cmp$max_abs
        rec$max_rel_diff <- cmp$max_rel; rec$width_ratio <- cmp$width_ratio
        rec$matched <- cmp$how
        # A parameter reported by one engine and not the other is a CAPABILITY
        # difference, not an agreement one, and must not be hidden by comparing
        # only the intersection.
        rec$only_tmb <- cmp$only_tmb
        rec$only_julia <- cmp$only_julia
        # An interval can match at its endpoints and still be the wrong SHAPE, so
        # the width ratio is a gate in its own right, not decoration.
        rec$status <- if (!is.finite(cmp$max_rel)) {
          "INTERVAL_INDETERMINATE"
        } else if (cmp$only_tmb > 0L || cmp$only_julia > 0L) {
          "PARAM_COVERAGE_DIFF"
        } else if (cmp$max_rel <= tol_rel &&
                   (is.na(cmp$width_ratio) || cmp$width_ratio <= 1.05)) {
          "INTERVAL_PASS"
        } else {
          "INTERVAL_MISMATCH"
        }
      }
    }
    cat(sprintf("   %-10s %-18s rel=%-10.3g width_ratio=%-10.3g %s\n", m, rec$status,
                ifelse(is.na(rec$max_rel_diff), NA_real_, rec$max_rel_diff),
                ifelse(is.na(rec$width_ratio), NA_real_, rec$width_ratio),
                substr(rec$note, 1, 60)))
    rows[[length(rows) + 1L]] <- rec
  }
}

df <- do.call(rbind, lapply(rows, function(r) as.data.frame(r, stringsAsFactors = FALSE)))
df$drmtmb_version <- as.character(utils::packageVersion("drmTMB"))
df$R_boot <- R_boot
df$seed <- boot_seed
write.table(df, out_path, sep = "\t", row.names = FALSE, quote = FALSE)
cat(sprintf("\nwrote %s\n", out_path))

tally <- table(df$status)
cat("STATUS TALLY: ", paste(sprintf("%s=%d", names(tally), as.integer(tally)), collapse = "  "), "\n")
