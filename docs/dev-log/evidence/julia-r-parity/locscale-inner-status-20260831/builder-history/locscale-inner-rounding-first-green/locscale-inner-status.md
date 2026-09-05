# Location-scale inner-mode stationarity repair

## Contract

`_ls_inner_mode` keeps its tuple shape, 200-iteration default, `1e-9` scaled
stationarity tolerance, likelihood, and generalized `Zη`/`Zψ` loadings. It may
return `ok=true` only when returned coordinates and a fresh gradient are finite,
the existing scaled stationarity criterion holds, and the undamped Hessian
factorization succeeds. A final Newton update may therefore succeed after a
fresh recheck; exhausted nonstationary states must return `ok=false`.

## Executable acceptance gates

- [x] G0: focused inner-status test
  CWD: .
  CHECK: JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. --startup-file=no test/test_locscale_inner_status.jl && printf 'LOCSCALE_INNER_STATUS_OK\n'
  EXPECT: LOCSCALE_INNER_STATUS_OK
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/integration/DRM.jl; path=92301ffe9a62/34 entries; output=location-scale inner-mode stationarity acceptance |   33     33  1.7s | LOCSCALE_INNER_STATUS_OK
- [ ] G1: inner-status module and existing inner, marginal, gradient, and fit neighbours
  CWD: .
  CHECK: python3 /private/tmp/drm-parity-20260830/integration/run_inner_status_module.py 1 final001
  EXPECT: MODULE_INNER_STATUS_OK
  EVIDENCE: pending
- [ ] G2: profile-status regression
  CWD: .
  CHECK: python3 /private/tmp/drm-parity-20260830/integration/run_profile_status_module.py 1 inner001
  EXPECT: MODULE_PROFILE_STATUS_OK
  EVIDENCE: pending
- [ ] G3: four-thread profile-status regression
  CWD: .
  CHECK: python3 /private/tmp/drm-parity-20260830/integration/run_profile_status_module.py 4 inner002
  EXPECT: MODULE_PROFILE_STATUS_OK
  EVIDENCE: pending
- [ ] G4: Rose review
  EVIDENCE: pending
