#!/usr/bin/env Rscript
# Reproduces the exact data-generation and varying_scale cell of
# tools/parity_conditional_prediction.R (DRM.jl repo), TMB-only, to obtain a
# hard R oracle for test/test_lss_ranef_varying_scale_parity.jl.
library(drmTMB)
set.seed(202608302L)
labels <- c('z', 'a', 'm', 'b', 'x', 'c', 'w', 'd', 'v', 'e', 'u', 'f')
g <- factor(rep(labels, each = 12L), levels = c('unused', rev(sort(labels))))
n <- length(g)
x <- runif(n, -1, 1)
b <- setNames(rnorm(length(labels), sd = 0.8), labels)
y <- 0.3 + 0.6*x + b[as.character(g)] + rnorm(n, sd = exp(-0.5 + 0.15*x))
dat <- data.frame(y, x, g)[sample.int(n), , drop = FALSE]
rownames(dat) <- NULL
grid <- data.frame(x = c(-0.7, 0, 0.8))

fr <- drmTMB(bf(y ~ x + (1 | g), sigma ~ x), data = dat, engine = 'tmb')
cat('convergence:', fr$opt$convergence, '\n')
cat('mu coef:\n'); print(fr$coefficients$mu)
cat('sigma coef:\n'); print(fr$coefficients$sigma)

mu_link <- predict(fr, newdata = grid, dpar = 'mu', type = 'link')
mu_resp <- predict(fr, newdata = grid, dpar = 'mu', type = 'response')
cat('newdata mu link: ', paste(sprintf('%.17g', mu_link), collapse=', '), '\n')
cat('newdata mu response: ', paste(sprintf('%.17g', mu_resp), collapse=', '), '\n')

write.csv(dat, '/private/tmp/claude-503/-Users-z3437171-Dropbox-Github-Local-DRM-jl/2b420b3d-cf11-4ac2-ab94-c3306978df50/scratchpad/wt-563-s10-gtol/test/parity/lss-ranef-varying-scale/data.csv', row.names = FALSE)
