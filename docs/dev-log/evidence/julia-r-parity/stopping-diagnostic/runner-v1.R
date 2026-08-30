#!/usr/bin/env Rscript
# Independent Gaussian oracle. Tighter controls are diagnostic, never a new baseline.
args <- commandArgs(TRUE)
if (length(args) != 3L) stop('usage: parity_stopping_diagnostic.R R_CHECKOUT FROZEN_JSON OUTPUT_JSON')
pkg <- normalizePath(args[[1L]], mustWork = TRUE)
input <- normalizePath(args[[2L]], mustWork = TRUE)
out <- args[[3L]]
if (file.exists(out)) stop('refusing stale output')
pkgload::load_all(pkg, quiet = TRUE, recompile = FALSE)
sha <- function(p) digest::digest(file = p, algo = 'sha256')
frozen <- jsonlite::read_json(input, simplifyVector = TRUE)
dat <- frozen$data
dat$g <- factor(dat$g, levels = c('a', 'b'))
grid <- frozen$newdata
grid$g <- factor(grid$g, levels = levels(dat$g))
forms <- list(numeric = bf(y ~ x, sigma ~ x), factors = bf(y ~ x + g, sigma ~ x + g), default_scale = bf(y ~ x), known_variance = bf(y ~ x + meta_V(V = v), sigma ~ 1))
tight <- list(rel.tol = 1e-12, x.tol = 1e-12, iter.max = 1000L, eval.max = 1000L)
receipt <- list(scope = 'Gaussian fixed-effect stopping diagnostic only', substitution_allowed = FALSE,
  input = input, input_sha256 = sha(input), native_methods_sha256 = sha(file.path(pkg, 'R/methods.R')),
  native_control_sha256 = sha(file.path(pkg, 'R/control.R')),
  runner_sha256 = sha('tools/parity_stopping_diagnostic.R'), R = R.version.string,
  R_checkout = pkg, package_version = as.character(packageVersion('drmTMB')),
  tight_diagnostic_control = tight, parity_tolerance_unchanged = frozen$tolerance,
  fd_step = 1e-6, oracle_tolerance = 1e-6, default_reproduction_tolerance = 1e-12,
  cases = list())
dll <- getLoadedDLLs()[['drmTMB']][['path']]
receipt$native_DLL <- list(path = dll, sha256 = sha(dll))
if (!identical(receipt$native_DLL$sha256, frozen$native_DLL$sha256) ||
    !identical(receipt$native_methods_sha256, frozen$native_methods_sha256)) stop('native build changed from frozen baseline')
start <- proc.time()[['elapsed']]
save_receipt <- function() jsonlite::write_json(receipt, out, pretty = TRUE, auto_unbox = TRUE, digits = 17, null = 'null')
for (nm in names(forms)) {
  receipt$cases[[nm]] <- tryCatch({
    X <- model.matrix(if (nm == 'factors') ~ x + g else ~ x, dat)
    Z <- model.matrix(if (nm == 'factors') ~ x + g else if (nm == 'numeric') ~ x else ~ 1, dat)
    a <- if (nm == 'known_variance') dat$v else rep(0, nrow(dat))
    n_beta <- ncol(X)
    objective <- function(theta) {
      r <- dat$y - drop(X %*% theta[seq_len(n_beta)])
      t <- exp(2 * drop(Z %*% theta[n_beta + seq_len(ncol(Z))]))
      v <- t + a
      sum((log(2*pi) + log(v) + r*r/v)/2)
    }
    gradient <- function(theta) {
      r <- dat$y - drop(X %*% theta[seq_len(n_beta)])
      t <- exp(2 * drop(Z %*% theta[n_beta + seq_len(ncol(Z))]))
      v <- t + a
      c(-crossprod(X, r/v), crossprod(Z, (t/v) * (1-r*r/v)))
    }
    coeff <- function(fit) {
      stopifnot(identical(names(fit$coefficients$mu), colnames(X)),
                identical(names(fit$coefficients$sigma), colnames(Z)))
      c(fit$coefficients$mu, fit$coefficients$sigma)
    }
    # The old JSON omitted coefficient names. Recover them independently from
    # its full stored link predictions and the now-explicit design matrices.
    obs <- frozen$cases[[nm]]$observations
    recovered <- c(qr.solve(X, obs[['stored/mu/link']]$bridge),
                   qr.solve(Z, obs[['stored/sigma/link']]$bridge))
    recorded <- unlist(frozen$cases[[nm]]$bridge_coefficients, use.names = FALSE)
    projection_error <- max(abs(c(drop(X %*% recovered[seq_len(n_beta)]) - obs[['stored/mu/link']]$bridge,
      drop(Z %*% recovered[n_beta + seq_len(ncol(Z))]) - obs[['stored/sigma/link']]$bridge)))
    stopifnot(projection_error < 1e-12, max(abs(recovered - recorded)) < 1e-12)
    results <- list()
    for (mode in c('default', 'tight_diagnostic')) {
      fit <- if (mode == 'default') drmTMB(forms[[nm]], data = dat, engine = 'tmb') else
        drmTMB(forms[[nm]], data = dat, engine = 'tmb', control = drm_control(optimizer = tight))
      theta <- coeff(fit)
      stopifnot(length(theta) == length(fit$opt$par), max(abs(theta - fit$opt$par)) < 1e-12)
      fd <- vapply(seq_along(theta), function(j) {
        hi <- lo <- theta; hi[j] <- hi[j] + receipt$fd_step; lo[j] <- lo[j] - receipt$fd_step
        (objective(hi) - objective(lo))/(2*receipt$fd_step)
      }, numeric(1))
      comparisons <- list()
      for (where in c('stored', 'newdata')) for (dpar in c('mu', 'sigma')) for (type in c('link', 'response')) {
        key <- paste(where, dpar, type, sep = '/')
        p <- predict(fit, newdata = if (where == 'stored') NULL else grid, dpar = dpar, type = type)
        delta <- max(abs(p - obs[[key]]$bridge))
        comparisons[[key]] <- list(max_abs_diff_from_frozen_Julia = delta,
          within_original_tolerance = is.finite(delta) && delta < frozen$tolerance,
          default_reproduction_error = if (mode == 'default') max(abs(p - obs[[key]]$native)) else NULL)
      }
      g <- gradient(theta)
      results[[mode]] <- list(coefficient_names = list(mu = colnames(X), sigma = colnames(Z)), coefficients = unname(theta),
        convergence = fit$opt$convergence, message = fit$opt$message,
        objective = objective(theta), TMB_objective_error = abs(objective(theta) - fit$obj$fn(fit$opt$par)),
        gradient = g, max_abs_gradient = max(abs(g)),
        TMB_gradient_error = max(abs(g - fit$obj$gr(fit$opt$par))), FD_gradient_error = max(abs(g - fd)),
        default_coefficient_reproduction_error = if (mode == 'default') max(abs(theta - unlist(frozen$cases[[nm]]$native_coefficients, use.names = FALSE))) else NULL,
        comparisons = comparisons)
    }
    check <- function(z) z$TMB_objective_error < receipt$oracle_tolerance && z$TMB_gradient_error < receipt$oracle_tolerance && z$FD_gradient_error < receipt$oracle_tolerance
    defaults <- results$default
    reproduction <- defaults$default_coefficient_reproduction_error < 1e-12 && all(vapply(defaults$comparisons, function(z) z$default_reproduction_error < 1e-12, logical(1)))
    list(status = if (reproduction && all(vapply(results, check, logical(1)))) 'PASS' else 'FAIL',
      default_reproduced = reproduction, results = results,
      Julia_recorded = list(coefficients_recovered_from_link_predictions = unname(recovered), projection_error = projection_error,
        objective = objective(recovered), gradient = gradient(recovered), max_abs_gradient = max(abs(gradient(recovered)))))
  }, error = function(e) list(status = 'ERROR', error = conditionMessage(e)))
  save_receipt()
  cat(nm, receipt$cases[[nm]]$status, '\n')
}
receipt$seconds <- proc.time()[['elapsed']] - start
receipt$status <- if (length(receipt$cases) == 4L && all(vapply(receipt$cases, function(z) identical(z$status, 'PASS'), logical(1)))) 'PASS' else 'FAIL'
save_receipt()
cat('STOPPING_ORACLE_', receipt$status, '\n', sep = '')
if (!identical(receipt$status, 'PASS')) quit(status = 1L)
