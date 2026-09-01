# Gates: S10 ordinary Gaussian conditional components

OWNS: docs/dev-log/evidence/julia-r-parity/conditional-components/contract.md, .unlazy/julia-r-parity/gates/leaf-S10-components-pure.md

Scope: Evidence and executable acceptance gate for the parent-assigned R-side stored conditional Gaussian mean adapter. The parent assignment owns the sibling drmTMB files, which cannot appear in this DRM.jl-rooted ledger because OWNS forbids path traversal.

- [x] G1: Component payload and stored prediction tests pass with an explicit testthat failure aggregate.
  CHECK: Rscript -e 'pkgload::load_all(".", quiet=TRUE, recompile=FALSE); r <- testthat::test_file("/private/tmp/drm-parity-20260830/drmTMB/tests/testthat/test-julia-conditional-components.R", reporter="summary"); bad <- any(unlist(lapply(r, function(test) vapply(test$results, function(result) inherits(result, "expectation_failure") || inherits(result, "expectation_error"), logical(1))), use.names=FALSE)); if (bad) quit(status=1L); cat("S10_COMPONENTS_PURE_PASS\\n")'
  EXPECT: S10_COMPONENTS_PURE_PASS
  CWD: /private/tmp/drm-parity-20260830/s10-components-candidate
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/s10-components-candidate; path=397a2e37e6bb/34 entries; output=══ DONE ════════════════════════════════════════════════════════════════════════ | S10_COMPONENTS_PURE_PASS

- [x] G2: Existing conditional random-intercept and prediction-scale pure suites remain green.
  CHECK: Rscript -e 'pkgload::load_all(".", quiet=TRUE, recompile=FALSE); fs <- c("/private/tmp/drm-parity-20260830/drmTMB/tests/testthat/test-julia-conditional-prediction.R", "/private/tmp/drm-parity-20260830/drmTMB/tests/testthat/test-julia-prediction-scales.R"); r <- lapply(fs, testthat::test_file, reporter="summary"); bad <- any(unlist(lapply(r, function(file) unlist(lapply(file, function(test) vapply(test$results, function(result) inherits(result, "expectation_failure") || inherits(result, "expectation_error"), logical(1))), use.names=FALSE)), use.names=FALSE)); if (bad) quit(status=1L); cat("S10_COMPONENTS_REGRESSION_PASS\\n")'
  EXPECT: S10_COMPONENTS_REGRESSION_PASS
  CWD: /private/tmp/drm-parity-20260830/s10-components-candidate
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/s10-components-candidate; path=397a2e37e6bb/34 entries; output=══ DONE ════════════════════════════════════════════════════════════════════════ | S10_COMPONENTS_REGRESSION_PASS

- [x] G3: Isolated bridge source parses.
  CHECK: Rscript -e 'invisible(parse("R/julia-bridge.R")); cat("S10_COMPONENTS_PARSE_PASS\\n")'
  EXPECT: S10_COMPONENTS_PARSE_PASS
  CWD: /private/tmp/drm-parity-20260830/s10-components-candidate
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/s10-components-candidate; path=397a2e37e6bb/34 entries; output=S10_COMPONENTS_PARSE_PASS
