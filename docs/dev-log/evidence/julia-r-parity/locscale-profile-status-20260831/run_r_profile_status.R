library(testthat)
pkgload::load_all('/private/tmp/drm-parity-20260830/integration/drmTMB', quiet=TRUE, recompile=FALSE)
source_file <- '/private/tmp/drm-parity-20260830/integration/drmTMB/tests/testthat/test-julia-inference.R'
exprs <- parse(source_file)
chosen <- Filter(function(x) {
  if (!is.call(x)) return(FALSE)
  if (identical(x[[1L]], as.name('<-'))) {
    return(as.character(x[[2L]]) %in% c('drm_julia_inference_synthetic_fit', 'drm_julia_inference_synthetic_fit_with_payload'))
  }
  identical(x[[1L]], as.name('test_that')) && identical(x[[2L]], 'Julia profile failures and no-crossing messages survive public R intervals')
}, as.list(exprs))
stopifnot(length(chosen)==3L)
lines <- unlist(lapply(chosen, deparse, width.cutoff=500L))
test_file <- tempfile(fileext='.R');writeLines(lines,test_file)
cat('RUNTIME',R.version.string,'drmTMB',as.character(packageVersion('drmTMB')),'\n')
r <- testthat::test_file(test_file, reporter='summary',stop_on_failure=TRUE)
tab <- as.data.frame(r)
stopifnot(sum(tab$failed)==0L, !any(tab$error), !any(tab$skipped), sum(tab$nb)>=14L)
print(tab[,intersect(c('test','nb','failed','skipped','error','passed'),names(tab))])
cat('R_PROFILE_STATUS_PASS\n')
