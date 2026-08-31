# Location-scale inner-mode stationarity repair

## Contract

`_ls_inner_mode` keeps its tuple shape, 200-iteration default, `1e-9` scaled
stationarity tolerance, likelihood, and generalized `Zη`/`Zψ` loadings. It may
return `ok=true` only when returned coordinates and a fresh gradient are finite,
the existing scaled stationarity criterion holds, and the undamped Hessian
factorization succeeds. A final Newton update may therefore succeed after a
fresh recheck; exhausted nonstationary states must return `ok=false`.

## Executable acceptance gates

- [x] G0: focused inner-status test with guarded ULP polish
  CWD: .
  CHECK: JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. --startup-file=no test/test_locscale_inner_status.jl && printf 'LOCSCALE_INNER_STATUS_OK\n'
  EXPECT: LOCSCALE_INNER_STATUS_OK
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/integration/DRM.jl; path=92301ffe9a62/34 entries; output=location-scale inner-mode stationarity acceptance |   47     47  0.1s | LOCSCALE_INNER_STATUS_OK
- [ ] G1: inner-status module and existing inner, marginal, gradient, and fit neighbours
  CWD: .
  CHECK: python3 /private/tmp/drm-parity-20260830/integration/run_inner_status_module.py 1 round001
  EXPECT: MODULE_INNER_STATUS_OK
  EVIDENCE: pending
- [ ] G2: profile-status regression
  CWD: .
  CHECK: python3 /private/tmp/drm-parity-20260830/integration/run_profile_status_module.py 1 round001
  EXPECT: MODULE_PROFILE_STATUS_OK
  EVIDENCE: pending
- [ ] G3: four-thread profile-status regression
  CWD: .
  CHECK: python3 /private/tmp/drm-parity-20260830/integration/run_profile_status_module.py 4 round002
  EXPECT: MODULE_PROFILE_STATUS_OK
  EVIDENCE: pending
- [x] G4: independent central-difference perturbation verification
  CWD: .
  CHECK: python3 /private/tmp/drm-parity-20260830/integration/run_inner_perturbations.py 1 round001
  EXPECT: MODULE_INNER_PERTURBATIONS_OK
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/integration/DRM.jl; path=92301ffe9a62/34 entries; output=MODULE_INNER_PERTURBATIONS_OK | {"started_utc": "2026-08-31T13:35:26.317314+00:00", "ended_utc": "2026-08-31T13:35:31.917970+00:00", "elapsed_seconds": 5.599384542088956, "exit_code": 0, "timed_out": false, "deadline_seconds": 120, "julia_t
- [ ] G5: Rose review of guarded ULP polish
  EVIDENCE: pending
