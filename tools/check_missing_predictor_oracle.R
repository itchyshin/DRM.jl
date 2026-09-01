# Native-contract probe using an independently derived observed-data likelihood.
# Does not implement or claim a Julia missing-predictor engine.
suppressPackageStartupMessages(library(drmTMB))
source("tools/missing_predictor_oracle.R")
args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 1L, !file.exists(args[[1]]))
set.seed(20260830)
n <- 160L
z <- rnorm(n)
out <- list()
for (kind in c("gaussian", "bernoulli")) {
  complete_x <- if (kind == "gaussian") 0.2 + 0.6*z + 0.7*rnorm(n) else
    rbinom(n,1,plogis(-0.2 + 0.5*z))
  dat <- data.frame(y = 0.4 + 0.3*z + 1.2*complete_x + 0.8*rnorm(n), z=z,
                    x=complete_x)
  if (kind == "bernoulli") dat$x <- factor(dat$x, levels=c(0,1))
  dat$x[c(2,5,8,11,14,17,20,23,26,29)] <- NA
  dat$y[c(2,6,12,18)] <- NA
  imputation <- if (kind == "gaussian") list(x = x ~ z) else
    list(x = impute_model(x ~ z, family=binomial()))
  fit <- drmTMB(bf(y ~ z + mi(x), sigma ~ 1), data=dat, impute=imputation,
                missing=miss_control(response="include", predictor="model"),
                control=drm_control(se=FALSE))
  beta <- coef(fit,"mu"); gamma <- coef(fit,"mi_x")
  stopifnot(setequal(names(beta),c("(Intercept)","z","mi(x)")),
            setequal(names(gamma),c("(Intercept)","z")))
  parameters <- list(a=unname(beta['(Intercept)']+beta['z']*z),
                     b=unname(beta['mi(x)']), sigma=exp(unname(coef(fit,"sigma"))))
  predictor_eta <- unname(gamma['(Intercept)']+gamma['z']*z)
  if (kind == "gaussian") {
    parameters$m <- predictor_eta
    # Unlike the response's log-sigma coefficient, this public predictor block
    # already reports the standard deviation. Do not exponentiate it twice.
    parameters$tau <- unname(coef(fit,"sigma_mi_x"))
  } else parameters$prob <- plogis(predictor_eta)
  observed_x <- if (kind == "bernoulli") as.numeric(dat$x)-1 else dat$x
  value <- joint_mi_loglik(observed_x,dat$y,parameters,kind)
  native <- as.numeric(logLik(fit))
  masks <- table(factor(paste0(!is.na(dat$x),!is.na(dat$y)),
                        levels=c("TRUETRUE","TRUEFALSE","FALSETRUE","FALSEFALSE")))
  row_contract <- identical(fit$missing_data$original_row,seq_len(n)) &&
    identical(fit$missing_data$predictors$x$model_row,which(is.na(dat$x))) &&
    nobs(fit)==sum(!is.na(dat$y))
  out[[kind]] <- list(native_loglik=native,oracle_loglik=value,
    abs_diff=abs(native-value),tolerance=1e-6,row_contract=row_contract,
    masks=as.list(masks),parameters=parameters,fixture=list(x=observed_x,y=dat$y,z=z),
    native_convergence=fit$opt$convergence,
    native_gradient_max=max(abs(fit$obj$gr(fit$opt$par))),
    pass=is.finite(value) && abs(native-value)<=1e-6 && row_contract && all(masks>0))
}
loaded_files <- c(getLoadedDLLs()[["drmTMB"]][["path"]],
                  file.path(find.package("drmTMB"),"R","drmTMB.rdb"))
receipt <- list(scope="Two native fixed-effect ML joint likelihoods at identical fitted parameters; SE disabled; not Julia parity",
                package_version=as.character(packageVersion("drmTMB")),
                loaded_package=find.package("drmTMB"),r_version=R.version.string,
                loaded_files=as.list(tools::md5sum(loaded_files)),
                fixture_seed=20260830L,cases=out)
jsonlite::write_json(receipt,args[[1]],pretty=TRUE,auto_unbox=TRUE,digits=17)
stopifnot(all(vapply(out,function(x)x$pass,logical(1))))
cat("NATIVE_MISSING_PREDICTOR_ORACLE_PASS\n")
