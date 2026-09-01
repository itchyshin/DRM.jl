# Native imputation uncertainty and stopping diagnostic
OWNS: tools/joint_native_uncertainty_probe.R

Estimate <60seconds: four native small fits plus one diagnostic restart. Mac, one BLAS thread. Frozen defaults are immutable. Gaussian standard error oracle sqrt(v+J Vtheta J') uses finite-difference conditional-mean Jacobian and reordered native marginal covariance; Bernoulli uses sqrt(p*(1-p)). Fixedparameter posteriorSD alone is not the Gaussian native contract. Observed-x SEs must be missing.

- [x] G1: Frozen data, coefficient reconstruction and exact native build verified before fitting
  CHECK: OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript tools/joint_native_uncertainty_probe.R docs/dev-log/evidence/julia-r-parity/missing-predictor-oracle/native-mi-oracle-003.json /private/tmp/drm-parity-20260830/R-lib /private/tmp/drm-parity-20260830/joint-native-uncertainty-001.json --preflight
  EXPECT: JOINT_NATIVE_PREFLIGHT_PASS cases=2 rows=320
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=JOINT_NATIVE_PREFLIGHT_PASS cases=2 rows=320

- [ ] G2: Native imputation errors agree with independently derived uncertainty and original rows
  CHECK: OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript tools/joint_native_uncertainty_probe.R docs/dev-log/evidence/julia-r-parity/missing-predictor-oracle/native-mi-oracle-003.json /private/tmp/drm-parity-20260830/R-lib /private/tmp/drm-parity-20260830/joint-native-uncertainty-001.json > /private/tmp/drm-parity-20260830/joint-native-uncertainty-001.log 2>&1; run_status=$?; cat /private/tmp/drm-parity-20260830/joint-native-uncertainty-001.log; exit "$run_status"
  EXPECT: JOINT_NATIVE_UNCERTAINTY_PASS
