# Current R selected-state regression for missing-predictor summaries
OWNS: tools/joint_native_uncertainty_probe.R

Estimate <60seconds; four small fits and one diagnosticrestart. The old installed-build failure is retained separately and not replaced. Same frozen data/parameters; current R source and DLL fingerprinted before/after; no compilation or Julia fit.

- [x] G1: Current R source fixes imputation metadata while preserving native uncertainty/row contracts
  CHECK: OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript tools/joint_native_uncertainty_probe.R docs/dev-log/evidence/julia-r-parity/missing-predictor-oracle/native-mi-oracle-003.json /private/tmp/drm-parity-20260830/R-lib /private/tmp/drm-parity-20260830/joint-native-uncertainty-current-001.json --checkout /private/tmp/drm-parity-20260830/drmTMB > /private/tmp/drm-parity-20260830/joint-native-uncertainty-current-001.log 2>&1; run_status=$?; cat /private/tmp/drm-parity-20260830/joint-native-uncertainty-current-001.log; exit "$run_status"
  EXPECT: JOINT_NATIVE_UNCERTAINTY_PASS
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=bernoulli PASS | JOINT_NATIVE_UNCERTAINTY_PASS
