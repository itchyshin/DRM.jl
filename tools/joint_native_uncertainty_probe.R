#!/usr/bin/env Rscript
# Independently derived uncertainty oracle; native generated outputs only.
args <- commandArgs(TRUE)
preflight <- '--preflight' %in% args; args <- setdiff(args, '--preflight')
checkout <- NULL
if(length(args)==5L && args[[4]]=='--checkout') { checkout <- normalizePath(args[[5]],mustWork=TRUE); args <- args[1:3] }
if (length(args) != 3L) stop('usage: joint_native_uncertainty_probe.R FROZEN_JSON R_LIB NEW_JSON [--preflight] [--checkout R_CHECKOUT]')
frozen <- normalizePath(args[[1]], mustWork=TRUE)
rlib <- normalizePath(args[[2]], mustWork=TRUE); output <- args[[3]]
if (file.exists(output)) stop('refusing stale output')
.libPaths(c(rlib,.libPaths()))
suppressPackageStartupMessages(library(drmTMB))
ref <- jsonlite::read_json(frozen, simplifyVector=TRUE)
sha <- function(p) digest::digest(file=p, algo='sha256')
loaded <- c(getLoadedDLLs()[['drmTMB']][['path']], file.path(find.package('drmTMB'),'R','drmTMB.rdb'))
stopifnot(identical(unname(tools::md5sum(loaded)), unname(unlist(ref$loaded_files))))
source_manifest <- function() { if(is.null(checkout)) return(NULL); paths <- sort(list.files(file.path(checkout,'R'),full.names=TRUE,pattern='[.]R$')); as.list(setNames(vapply(paths,sha,''),basename(paths))) }
if(!is.null(checkout)) { pkgload::load_all(checkout,quiet=TRUE,recompile=FALSE); loaded <- getLoadedDLLs()[['drmTMB']][['path']] }
source_before <- source_manifest()
decode <- function(v) {
  # jsonlite simplifies the frozen JSON's literal NA strings to R NA.
  bad <- !is.na(v) & !grepl('^(NA|[-+0-9.eE]+)$', as.character(v))
  if (any(bad)) stop('unexpected fixture representation')
  value <- suppressWarnings(as.numeric(v)); stopifnot(all(is.finite(value) | is.na(v) | as.character(v)=='NA'))
  value
}
fixtures <- lapply(c('gaussian','bernoulli'), function(kind) {
  f <- ref$cases[[kind]]$fixture
  d <- data.frame(x=decode(f$x),y=decode(f$y),z=decode(f$z)); X <- cbind(1,d$z)
  p <- ref$cases[[kind]]$parameters; a <- as.numeric(p$a)
  eta <- if(kind=='gaussian') as.numeric(p$m) else qlogis(as.numeric(p$prob))
  beta <- qr.solve(X,a); alpha <- qr.solve(X,eta)
  stopifnot(max(abs(X%*%beta-a))<1e-12,max(abs(X%*%alpha-eta))<1e-12,nrow(d)==160L,
    identical(as.integer(table(factor(paste0(!is.na(d$x),!is.na(d$y)),levels=c('TRUETRUE','TRUEFALSE','FALSETRUE','FALSEFALSE')))),c(147L,3L,9L,1L)))
  theta <- c(beta,p$b,log(p$sigma),alpha,if(kind=='gaussian') log(p$tau) else NULL)
  list(data=d,theta=unname(theta))
}); names(fixtures) <- c('gaussian','bernoulli')
if(preflight) { cat('JOINT_NATIVE_PREFLIGHT_PASS cases=2 rows=320\n'); quit(status=0L) }
common_theta <- function(fit,kind) {
  b <- coef(fit,'mu'); a <- coef(fit,'mi_x'); s <- coef(fit,'sigma')
  stopifnot(identical(names(b),c('(Intercept)','z','mi(x)')),identical(names(a),c('(Intercept)','z')),length(s)==1L)
  unname(c(b,s,a,if(kind=='gaussian') log(coef(fit,'sigma_mi_x')) else NULL))
}
# This fixture-specific permutation is accepted only with a unique exact bijection.
# It is retained with the native parameter labels, never generalized to production.
common_permutation <- function(fit,theta) {
  par <- fit$opt$par
  matches <- lapply(theta,function(v) which(abs(par-v)<1e-12))
  stopifnot(length(par)==length(theta),all(lengths(matches)==1L))
  idx <- unlist(matches,use.names=FALSE); stopifnot(length(unique(idx))==length(theta))
  idx
}
conditional <- function(theta,d,kind) {
  a <- theta[1]+theta[2]*d$z; b <- theta[3]; S <- exp(2*theta[4]); eta <- theta[5]+theta[6]*d$z
  mu <- d$x; v <- rep(0,nrow(d)); missing_x <- is.na(d$x)
  if(kind=='gaussian') {
    T <- exp(2*theta[7]); mu[missing_x] <- eta[missing_x]; v[missing_x] <- T
    j <- which(missing_x & !is.na(d$y)); D <- S+b*b*T
    mu[j] <- (S*eta[j]+b*T*(d$y[j]-a[j]))/D; v[j] <- S*T/D
  } else {
    p <- plogis(eta); j <- which(missing_x & !is.na(d$y))
    log0 <- plogis(eta[j],lower.tail=FALSE,log.p=TRUE)+dnorm(d$y[j],a[j],sqrt(S),log=TRUE)
    log1 <- plogis(eta[j],log.p=TRUE)+dnorm(d$y[j],a[j]+b,sqrt(S),log=TRUE)
    p[j] <- plogis(log1-log0); mu[missing_x] <- p[missing_x]; v[missing_x] <- p[missing_x]*(1-p[missing_x])
  }
  list(mean=mu,variance=v)
}
out <- list(scope='Native uncertainty and stopping diagnostic; frozen defaults preserved',
  frozen_sha256=sha(frozen),runner_sha256=sha('tools/joint_native_uncertainty_probe.R'),
  R_checkout=checkout,R_source_sha256=source_before,
  R_version=R.version.string,TMB_version=as.character(packageVersion('TMB')),
  library=find.package('drmTMB'),loaded_files=as.list(tools::md5sum(loaded)),
  loaded_sha256=as.list(setNames(vapply(loaded,sha,''),loaded)),
  thresholds=list(default_theta=1e-10,conditional_mean=1e-6,standard_error=1e-6,fd_step=1e-5),cases=list())
save <- function() jsonlite::write_json(out,output,pretty=TRUE,auto_unbox=TRUE,digits=17,na='string',null='null')
started <- proc.time()[['elapsed']]
for(kind in names(fixtures)) {
 out$cases[[kind]] <- tryCatch({
  d <- fixtures[[kind]]$data; dat <- d
  if(kind=='bernoulli') dat$x <- factor(dat$x,levels=c(0,1))
  imp <- if(kind=='gaussian') list(x=x~z) else list(x=impute_model(x~z,family=binomial()))
  fitfun <- function(se) drmTMB(bf(y~z+mi(x),sigma~1),data=dat,impute=imp,
    missing=miss_control(response='include',predictor='model'),control=drm_control(se=se))
  f0 <- fitfun(FALSE); t0 <- common_theta(f0,kind)
  reproduction <- max(abs(t0-fixtures[[kind]]$theta)); stopifnot(reproduction<=1e-10)
  f1 <- fitfun(TRUE); theta <- common_theta(f1,kind); permutation <- common_permutation(f1,theta)
  V <- f1$sdr$cov.fixed[permutation,permutation,drop=FALSE]
  moments <- conditional(theta,d,kind); ids <- which(is.na(d$x)); h <- 1e-5
  J <- vapply(seq_along(theta),function(k) {
    hi <- lo <- theta; step <- h*max(1,abs(theta[k]));hi[k] <- hi[k]+step;lo[k] <- lo[k]-step
    (conditional(hi,d,kind)$mean[ids]-conditional(lo,d,kind)$mean[ids])/(2*step)
  },numeric(length(ids)))
  delta <- if(kind=='gaussian') rowSums((J%*%V)*J) else rep(0,length(ids))
  predicted_se <- sqrt(moments$variance[ids]+delta)
  all <- imputed(f1,rows='all'); miss <- imputed(f1,rows='missing'); no_se <- imputed(f1,rows='all',se=FALSE)
  mean_error <- max(abs(all$estimate-moments$mean)); se_error <- max(abs(miss$std_error-predicted_se))
  row_ok <- identical(all$original_row,seq_len(nrow(d))) && identical(miss$model_row,ids) &&
    all(is.na(all$std_error[!is.na(d$x)])) && all(is.na(no_se$std_error))
  refinement <- NULL
  if(kind=='bernoulli') {
    p0 <- common_permutation(f0,t0)
    tight <- nlminb(f0$opt$par,f0$obj$fn,f0$obj$gr,control=list(rel.tol=1e-12,x.tol=1e-12,iter.max=1000L,eval.max=1000L))
    refinement <- list(scope='diagnostic restart only; not baseline substitution',theta=unname(tight$par[p0]),convergence=tight$convergence,message=tight$message,
      gradient=unname(f0$obj$gr(tight$par)),objective=tight$objective,iterations=tight$iterations)
  }
  list(status=if(row_ok && is.finite(mean_error) && mean_error<=1e-6 && is.finite(se_error) && se_error<=1e-6) 'PASS' else 'FAIL',
    default_theta=t0,frozen_theta=fixtures[[kind]]$theta,default_reproduction_error=reproduction,
    se_theta=theta,default_vs_se_theta_error=max(abs(t0-theta)),
    opt_names=names(f1$opt$par),opt_values=unname(f1$opt$par),common_to_native=permutation,
    cov_fixed_common=V,cov_fixed_native=f1$sdr$cov.fixed,sdr_par_fixed=unname(f1$sdr$par.fixed),
    diag_cov_random=f1$sdr$diag.cov.random,random_parameter_names=names(f1$sdr$par.random),
    random_values=unname(f1$sdr$par.random),imputed_all=all,imputed_missing=miss,imputed_no_se=no_se,
    native_status=drmTMB:::drm_standard_error_status(f1),conditional_mean=moments$mean,
    conditional_variance=moments$variance,jacobian_fd=J,parameter_variance=delta,oracle_se=predicted_se,
    mean_error=mean_error,se_error=se_error,row_contract=row_ok,refinement=refinement)
 },error=function(e) list(status='ERROR',error=conditionMessage(e)))
 save();cat(kind,out$cases[[kind]]$status,'\n')
}
out$seconds <- proc.time()[['elapsed']]-started
out$source_unchanged <- identical(source_before,source_manifest())
out$status <- if(out$source_unchanged && all(vapply(out$cases,function(z) identical(z$status,'PASS'),logical(1)))) 'PASS' else 'FAIL'
save();cat('JOINT_NATIVE_UNCERTAINTY_',out$status,'\n',sep='')
if(out$status!='PASS')quit(status=1L)
