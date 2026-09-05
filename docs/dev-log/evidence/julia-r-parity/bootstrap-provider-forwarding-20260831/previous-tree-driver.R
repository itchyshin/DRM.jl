root <- normalizePath('/private/tmp/drm-parity-20260830/integration/drmTMB')
jl <- normalizePath('/private/tmp/drm-parity-20260830/integration/DRM.jl')
fixture <- '/private/tmp/drm-parity-20260830/bridge-bootstrap-tree/fixture'
nt <- as.integer(Sys.getenv('JULIA_NUM_THREADS'))
stopifnot(nt %in% c(1L, 4L))
options(drmTMB.DRM.jl.path = jl)
pkgload::load_all(root, quiet = TRUE, compile = FALSE)
stopifnot(identical(normalizePath(getNamespaceInfo('drmTMB','path')), root))
print(list(source_loaded_R=root, DRM_JL_PATH=jl, R_version=R.version.string,
           dll_paths=vapply(getLoadedDLLs(), function(x) x[['path']], character(1))))
dat <- read.csv(file.path(fixture,'data.csv'))
dat$y <- readBin(file.path(fixture,'y.f64le'), 'double', n=nrow(dat), size=8L, endian='little')
dat$x <- readBin(file.path(fixture,'x.f64le'), 'double', n=nrow(dat), size=8L, endian='little')
tree <- ape::read.tree(file.path(fixture,'tree.newick'))
form <- drmTMB::bf(y ~ x + phylo(1 | tree_boot | species, tree=tree),
                  sigma ~ 1 + phylo(1 | tree_boot | species, tree=tree))
fit <- drmTMB::drmTMB(form, family=stats::Gamma(link='log'), data=dat, engine='julia')
stopifnot(identical(as.integer(JuliaCall::julia_eval('Threads.nthreads()')), nt),
          identical(as.integer(JuliaCall::julia_eval('DRM.LinearAlgebra.BLAS.get_num_threads()')), 1L))
print(JuliaCall::julia_eval('pathof(DRM)'))
ci <- stats::confint(fit, parm='fixef:mu:x', method='bootstrap', level=.95,
                     R=2L, seed=4001L, threads=nt > 1L)
print(list(formula=fit$bridge_payload$formula, options=fit$bridge_payload$options,
           coefficients=coef(fit), ci=ci))
expected <- readBin(file.path(fixture,'reference.f64le'), 'double', n=3L, size=8L, endian='little')
observed <- c(unname(coef(fit,dpar='mu')['x']), ci$lower[[1L]], ci$upper[[1L]])
dput(list(observed=observed, expected=expected, difference=observed-expected))
stopifnot(length(observed)==3L, all(is.finite(observed)),
          isTRUE(all.equal(observed, expected, tolerance=1e-12)),
          identical(ci$bootstrap.n[[1L]],2L), identical(ci$bootstrap.failed[[1L]],0L),
          identical(ci$conf.status[[1L]],'bootstrap'),
          identical(ci$julia.threaded[[1L]],nt>1L),
          identical(ci$julia.threads[[1L]],nt), identical(ci$julia.blas_threads[[1L]],1L))
cat('ACTUAL_R_TREE_BOOTSTRAP_PASS\n')
