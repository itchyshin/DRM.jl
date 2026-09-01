# Independent comparison contract for generated numerical outputs only.
# Normalize only the documented distributional-parameter separator. Term names
# remain significant: unknown or ambiguous names must fail, never match by index.
parity_numeric <- function(reference, observed, atol) {
  fail <- function(reason) list(pass = FALSE, max_abs_diff = NA_real_, reason = reason)
  if (!is.numeric(atol) || length(atol) != 1L || !is.finite(atol) || atol < 0) {
    return(fail("invalid tolerance"))
  }
  valid <- function(x) {
    is.numeric(x) && length(x) > 0L && all(is.finite(x)) &&
      !is.null(names(x)) && !anyNA(names(x)) && all(nzchar(names(x)))
  }
  if (!valid(reference) || !valid(observed)) return(fail("invalid numeric observation"))
  canonical <- function(x) sub(
    "^(mu1|mu2|sigma1|sigma2|rho12|mu|sigma|nu|phi|zi|hu|zoi|coi)[_.:]",
    "\\1:", names(x)
  )
  a <- canonical(reference)
  b <- canonical(observed)
  if (anyDuplicated(a) || anyDuplicated(b)) return(fail("duplicate coefficient keys"))
  if (length(a) != length(b) || !setequal(a, b)) return(fail("coefficient key sets differ"))
  delta <- max(abs(reference - observed[match(a, b)]))
  list(pass = is.finite(delta) && delta <= atol, max_abs_diff = delta,
       reason = if (delta <= atol) "all named coefficients compared" else "numeric tolerance exceeded")
}
