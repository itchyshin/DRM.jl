# Ayumi exact profile target

- [x] G1: Public Julia bridge profiles one coefficient and matches independent Gaussian ML endpoints, serial and threaded.
  CHECK: JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 julia --project=. -e 'include("test/test_bridge_profile_target.jl"); println("EXACT_PROFILE_TARGET_PASS")'
  EXPECT: EXACT_PROFILE_TARGET_PASS
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=bridge profiles only the requested coefficient |   36     36  5.4s | EXACT_PROFILE_TARGET_PASS

- [x] G2: Existing bridge regression suite remains passing.
  CHECK: JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. -e 'include("test/test_bridge.jl"); println("BRIDGE_NEIGHBOUR_PASS")'
  EXPECT: BRIDGE_NEIGHBOUR_PASS
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=│   rcond = 2.6217709657519925e-12 | └ @ DRM /private/tmp/drm-parity-20260830/DRM.jl/src/vcov_guard.jl:87

- [x] G3: Independent Rose review verifies scope and remaining scaling limitations.
  EVIDENCE: Rose final APPROVE owned hunks only: R a57b7aa7, Julia 411d64b6, runner e9031a71 and current public-green-001 source stamps verified. No broad speed/convergence or foreign-work approval.

- [x] G4: R batch/check guard regressions pass without live Julia.
  CHECK: cd /private/tmp/drm-parity-20260830/drmTMB && Rscript --vanilla -e 'pkgload::load_all(quiet=TRUE,recompile=FALSE); testthat::test_file("tests/testthat/test-julia-batch-startup.R",stop_on_failure=TRUE); testthat::test_file("tests/testthat/test-cran-lane-filter.R",stop_on_failure=TRUE); cat("BATCH_GUARDS_PASS\n")'
  EXPECT: BATCH_GUARDS_PASS
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=[ FAIL 0 | WARN 0 | SKIP 0 | PASS 34 ] Done! | BATCH_GUARDS_PASS

- [x] G5: Public ordinary Rscript and actual generated profile wrapper pass without opt-in.
  CHECK: cd /private/tmp/drm-parity-20260830/drmTMB && receipt_dir=$(mktemp -d /private/tmp/drm-ayumi-check.XXXXXX) && Rscript --vanilla tools/run-julia-ayumi-batch.R /private/tmp/drm-parity-20260830/DRM.jl "$receipt_dir/public.json"
  EXPECT: AYUMI_BATCH_PASS
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=Activating project at `/private/tmp/drm-parity-20260830/DRM.jl` | Julia exit.
