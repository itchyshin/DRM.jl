source("tools/parity_numeric.R")
ref <- c("mu:(Intercept)" = 1, "mu:x" = 2, "sigma:(Intercept)" = -1)
same <- c("sigma.(Intercept)" = -1, "mu.x" = 2, "mu.(Intercept)" = 1)
stopifnot(parity_numeric(ref, same, 1e-6)$pass)
bad <- list(same[-1], c(same, "sigma.z" = 0), unname(same),
            setNames(same, rep("mu.x", 3)), replace(same, 1, NA_real_),
            replace(same, 1, Inf), numeric(), same + 0.1)
for (x in bad) stopifnot(!parity_numeric(ref, x, 1e-6)$pass)
stopifnot(!parity_numeric(c("mu:x" = 1, "mu.x" = 1), c("mu:x" = 1), 1e-6)$pass)
stopifnot(!parity_numeric(ref, same, -1)$pass)
stopifnot(!parity_numeric(ref, same, NA_real_)$pass)
# Punctuation inside a term is significant; only the parameter separator maps.
stopifnot(!parity_numeric(c("mu:a.b" = 1), c("mu:a_b" = 1), 1e-6)$pass)
stopifnot(parity_numeric(ref, same + 5e-7, 1e-6)$pass)
cat("NUMERIC_CONTRACT_PASS\n")
