# Deliberately damage every Julia prediction, leaving native/oracle predictions intact.
# This is a test of the comparison harness, never a parity fixture or production code.
wrapper <- new.env(parent = globalenv())
wrapper$predict <- function(object, ...) {
  value <- stats::predict(object, ...)
  if (inherits(object, 'drmTMB_julia')) value <- value + 0.1
  value
}
cat('NEGATIVE_CONTROL: injected +0.1 into every Julia prediction\n')
sys.source('tools/parity_prediction.R', envir = wrapper)
