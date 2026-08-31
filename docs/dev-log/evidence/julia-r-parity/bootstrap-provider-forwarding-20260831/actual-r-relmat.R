root <- normalizePath('/private/tmp/drm-parity-20260830/integration/drmTMB')
jl <- normalizePath('/private/tmp/drm-parity-20260830/integration/DRM.jl')
options(drmTMB.DRM.jl.path = jl)
pkgload::load_all(root, quiet=TRUE, compile=FALSE)
stopifnot(identical(normalizePath(getNamespaceInfo('drmTMB','path')), root))
set.seed(20260831)
G <- 8L; m <- 4L
pos <- matrix(runif(G*2L, 0, 3), G, 2L)
D <- as.matrix(dist(pos)); K <- exp(-D/0.8) + diag(1e-8, G)
id <- rep(sprintf('g%02d', seq_len(G)), each=m)
x <- rnorm(G*m)
u <- 0.45 * drop(t(chol(K)) %*% rnorm(G))
y <- 0.2 + 0.35*x + u[match(id, unique(id))] + 0.3*rnorm(G*m)
dat <- data.frame(y=y, x=x, id=id)
form <- drmTMB::bf(y ~ x + relmat(1 | id, K=K), sigma ~ 1)
fit <- drmTMB::drmTMB(form, family=stats::gaussian(), data=dat, engine='julia')
stopifnot(identical(fit$bridge_payload$kwarg,'K'),
          identical(dim(fit$bridge_payload$matrix),dim(K)),
          isTRUE(all.equal(unname(fit$bridge_payload$matrix),unname(K),tolerance=0)))
ci <- stats::confint(fit, parm='fixef:mu:x', method='bootstrap', level=.95,
                     R=2L, seed=7001L, threads=FALSE)
ci_profile <- stats::confint(fit, parm='fixef:mu:x', method='profile',
                             level=.95, threads=FALSE)
JuliaCall::julia_command(paste(
  'drmTMB_direct_provider_inference(formula,family,data,K,options)=',
  'DRM.drm_bridge_inference(formula=formula,family=family,data=data,K=K,',
  'options=options,method="bootstrap",level=.95,B=2,seed=7001,',
  'threads=false,parm="fixef:mu:x")'))
direct <- JuliaCall::julia_call('drmTMB_direct_provider_inference',
  fit$bridge_payload$formula, fit$model$model_type,
  as.list(fit$bridge_payload$data), K,
  if(length(fit$bridge_payload$options)) fit$bridge_payload$options else NULL)
JuliaCall::julia_command(paste(
  'drmTMB_direct_provider_profile(formula,family,data,K,options)=',
  'DRM.drm_bridge_inference(formula=formula,family=family,data=data,K=K,',
  'options=options,method="profile",level=.95,threads=false,parm="fixef:mu:x")'))
direct_profile <- JuliaCall::julia_call('drmTMB_direct_provider_profile',
  fit$bridge_payload$formula, fit$model$model_type,
  as.list(fit$bridge_payload$data), K,
  if(length(fit$bridge_payload$options)) fit$bridge_payload$options else NULL)
observed <- c(unname(coef(fit,dpar='mu')['x']), ci$lower[[1L]], ci$upper[[1L]])
expected <- c(direct$estimate, direct$lower, direct$upper)
observed_profile <- c(ci_profile$lower[[1L]],ci_profile$upper[[1L]])
expected_profile <- c(direct_profile$lower,direct_profile$upper)
print(list(source=getNamespaceInfo('drmTMB','path'), drm_path=JuliaCall::julia_eval('pathof(DRM)'),
           payload_kwarg=fit$bridge_payload$kwarg, observed=observed, expected=expected,
           difference=observed-expected, ci=ci,
           observed_profile=observed_profile, expected_profile=expected_profile,
           profile_difference=observed_profile-expected_profile, profile_ci=ci_profile))
stopifnot(all(is.finite(observed)), isTRUE(all.equal(observed,expected,tolerance=1e-12)),
          all(is.finite(observed_profile)),
          isTRUE(all.equal(observed_profile,expected_profile,tolerance=1e-12)),
          identical(ci$bootstrap.n[[1L]],2L), identical(ci$bootstrap.failed[[1L]],0L),
          identical(ci$conf.status[[1L]],'bootstrap'),
          identical(ci_profile$conf.status[[1L]],'profile'),
          identical(as.integer(JuliaCall::julia_eval('DRM.LinearAlgebra.BLAS.get_num_threads()')),1L))
cat('ACTUAL_R_RELMAT_BOOTSTRAP_PROFILE_PASS\n')
