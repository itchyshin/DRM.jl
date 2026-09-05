#!/usr/bin/env Rscript
# Deliberately corrupt every analytic gradient; the same oracle must reject it.
args <- commandArgs(TRUE)
if (length(args) != 3L) stop('usage: parity_stopping_negative.R R_CHECKOUT FROZEN_JSON OUTPUT_JSON')
runner <- 'tools/parity_stopping_diagnostic.R'
code <- readLines(runner, warn = FALSE)
target <- '      c(-crossprod(X, r/v), crossprod(Z, (t/v) * (1-r*r/v)))'
stopifnot(sum(code == target) == 1L)
code[code == target] <- paste0(target, ' + 0.01')
env <- new.env(parent = globalenv())
env$commandArgs <- function(trailingOnly = FALSE) args
env$quit <- function(status = 0L, ...) {
  if (status == 1L) stop('EXPECTED_ORACLE_REJECTION', call. = FALSE)
  stop('unexpected quit status')
}
rejected <- tryCatch({ eval(parse(text = code), envir = env); FALSE }, error = function(e) {
  if (!identical(conditionMessage(e), 'EXPECTED_ORACLE_REJECTION')) stop(e)
  TRUE
})
r <- jsonlite::read_json(args[[3L]], simplifyVector = TRUE)
stopifnot(rejected, identical(r$status, 'FAIL'), length(r$cases) == 4L,
  all(vapply(r$cases, function(z) identical(z$status, 'FAIL') &&
    all(vapply(z$results, function(m) abs(m$TMB_gradient_error - 0.01) < 1e-10 && m$FD_gradient_error > 0.0099, logical(1))), logical(1))))
cat('DAMAGED_GRADIENT_REJECTED=8\n')
