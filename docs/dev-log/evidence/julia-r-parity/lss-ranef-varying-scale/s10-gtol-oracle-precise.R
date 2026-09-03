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
fr <- drmTMB(bf(y ~ x + (1 | g), sigma ~ x), data = dat, engine = 'tmb')
cat('mu coef full precision:\n')
cat(sprintf('%.17g', fr$coefficients$mu), '\n')
cat('convergence:', fr$opt$convergence, '\n')
cat('objective:', sprintf('%.17g', fr$opt$objective), '\n')
cat('final gradient (max abs):', max(abs(fr$opt$par - fr$opt$par)), '\n')
# refit with tighter nlminb control to see if TMB's own optimum moves
fr2 <- drmTMB(bf(y ~ x + (1 | g), sigma ~ x), data = dat, engine = 'tmb',
              control = list(rel.tol = 1e-14, x.tol = 1e-14, eval.max=2000, iter.max=2000))
cat('mu coef (tight control) full precision:\n')
cat(sprintf('%.17g', fr2$coefficients$mu), '\n')
cat('convergence (tight):', fr2$opt$convergence, '\n')
