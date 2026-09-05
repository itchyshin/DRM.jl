#!/usr/bin/env Rscript
# Diagnose native stored random-effect state without mutating fit environments.
args <- commandArgs(TRUE)
if (length(args) != 3L) stop('usage: parity_conditional_native_state.R R_CHECKOUT FROZEN_JSON OUTPUT_JSON')
pkg <- normalizePath(args[[1L]], mustWork = TRUE)
input <- normalizePath(args[[2L]], mustWork = TRUE)
out <- args[[3L]]
if (file.exists(out)) stop('refusing stale output')
pkgload::load_all(pkg, quiet = TRUE, recompile = FALSE)
sha <- function(p) digest::digest(file = p, algo = 'sha256')
frozen <- jsonlite::read_json(input, simplifyVector = TRUE)
dat <- frozen$data; dat$g <- factor(dat$g, levels = frozen$factor_levels)
forms <- list(constant_scale = bf(y ~ x + (1 | g), sigma ~ 1), varying_scale = bf(y ~ x + (1 | g), sigma ~ x))
receipt <- list(scope = 'Native conditional-state diagnostic; no baseline replacement or SE omission from parity',
  input_sha256 = sha(input), runner_sha256 = sha('tools/parity_conditional_native_state.R'),
  native_fit_source_sha256 = sha(file.path(pkg, 'R/drmTMB.R')),
  native_methods_sha256 = sha(file.path(pkg, 'R/methods.R')), cases = list())
dll <- getLoadedDLLs()[['drmTMB']][['path']]
receipt$native_DLL <- list(path = dll, sha256 = sha(dll))
stopifnot(identical(receipt$native_DLL$sha256, frozen$native_DLL$sha256))
start <- proc.time()[['elapsed']]
for (nm in names(forms)) {
  receipt$cases[[nm]] <- tryCatch({
    with_se <- drmTMB(forms[[nm]], data = dat, engine = 'tmb')
    without_se <- drmTMB(forms[[nm]], data = dat, engine = 'tmb', control = drm_control(se = FALSE))
    before <- list(last = with_se$obj$env$last.par, best = with_se$obj$env$last.par.best)
    # parList's explicit full-vector 'par' argument avoids its mutable default.
    stopifnot('par' %in% names(formals(with_se$obj$env$parList)))
    clean_par <- with_se$obj$env$parList(x = with_se$opt$par, par = with_se$tmb_state$last.par.best)
    rebuilt <- with_se
    rebuilt$random_effects <- drmTMB:::split_tmb_random_effects(clean_par, with_se$model)
    a <- predict(with_se, dpar = 'mu', type = 'link')
    b <- predict(without_se, dpar = 'mu', type = 'link')
    clean <- predict(rebuilt, dpar = 'mu', type = 'link')
    old <- frozen$cases[[nm]]$observations[['stored/mu/link']]
    unchanged <- identical(before$last, with_se$obj$env$last.par) && identical(before$best, with_se$obj$env$last.par.best)
    list(status = if (unchanged && max(abs(a-old$native)) < 1e-12) 'PASS' else 'FAIL',
      original_environment_unchanged = unchanged, native_default_reproduction_error = max(abs(a-old$native)),
      fixed_coefficients_with_se = with_se$coefficients, fixed_coefficients_without_se = without_se$coefficients,
      opt_parameter_difference = max(abs(with_se$opt$par-without_se$opt$par)),
      convergence = c(with_se = with_se$opt$convergence, without_se = without_se$opt$convergence),
      stored_random_effects = with_se$random_effects$mu, clean_random_effects = rebuilt$random_effects$mu,
      stored_mu = a, se_false_mu = b, clean_snapshot_mu = clean,
      max_stored_vs_clean = max(abs(a-clean)), max_clean_vs_se_false = max(abs(clean-b)),
      max_clean_vs_Julia = max(abs(clean-old$bridge)))
  }, error = function(e) list(status = 'ERROR', error = conditionMessage(e)))
  cat(nm, receipt$cases[[nm]]$status, '\n')
}
receipt$seconds <- proc.time()[['elapsed']] - start
receipt$status <- if (length(receipt$cases) == 2L && all(vapply(receipt$cases, function(z) identical(z$status, 'PASS'), logical(1)))) 'PASS' else 'FAIL'
jsonlite::write_json(receipt, out, pretty = TRUE, auto_unbox = TRUE, digits = 17, null = 'null')
cat('NATIVE_STATE_DIAGNOSTIC_', receipt$status, '\n', sep = '')
if (receipt$status != 'PASS') quit(status = 1L)
