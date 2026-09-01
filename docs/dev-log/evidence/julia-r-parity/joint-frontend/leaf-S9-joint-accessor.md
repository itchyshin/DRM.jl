# S9 two-family public frontend and imputation oracle
OWNS: root module/core integration, new checker/runner and public frontend tests; builder source frozen.
No remote compute. Estimated local 45 seconds for two small frontend fits and supplied-parameter checks. Common-theta accessor does NOT estimate covariance or prove fit parity.

- [x] G1: Public frontend admits two predictor families and rejects unsupported controls
  CHECK: JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. test/test_joint_missing_frontend.jl
  EXPECT: JOINT_EXOGENOUS_REFUSALS_PASS
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=joint model requires exogenous complete covariates |    9      9  0.6s | JOINT_EXOGENOUS_REFUSALS_PASS
- [x] G2: Execute 320 row accessor references without optimization
  CHECK: JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. tools/check_joint_imputation_reference.jl test/fixtures/joint_missing_predictor/native_reference.toml test/fixtures/joint_missing_predictor/native_uncertainty.toml /private/tmp/drm-parity-20260830/joint-imputation-reference-002.toml
  EXPECT: JOINT_IMPUTATION_REFERENCE_EXECUTED cases=2 rows=320
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=JOINT_IMPUTATION_REFERENCE_EXECUTED cases=2 rows=320
- [x] G3: Native fields and independent analytic covariance correction pass
  CHECK: python3 tools/check_joint_imputation_receipt.py test/fixtures/joint_missing_predictor/native_reference.toml test/fixtures/joint_missing_predictor/native_uncertainty.toml /private/tmp/drm-parity-20260830/joint-imputation-reference-002.toml .
  EXPECT: JOINT_IMPUTATION_RECEIPT_PASS cases=2 rows=320
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=JOINT_IMPUTATION_RECEIPT_PASS cases=2 rows=320
- [x] G4: Damaged receipts fail normally
  CHECK: python3 tools/test_joint_imputation_receipt.py test/fixtures/joint_missing_predictor/native_reference.toml test/fixtures/joint_missing_predictor/native_uncertainty.toml /private/tmp/drm-parity-20260830/joint-imputation-reference-002.toml .
  EXPECT: JOINT_IMPUTATION_NEGATIVES_PASS=14
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=JOINT_IMPUTATION_NEGATIVES_PASS=14
- [x] G5: Damaged receipts fail with Python assertions disabled
  CHECK: python3 -O tools/test_joint_imputation_receipt.py test/fixtures/joint_missing_predictor/native_reference.toml test/fixtures/joint_missing_predictor/native_uncertainty.toml /private/tmp/drm-parity-20260830/joint-imputation-reference-002.toml .
  EXPECT: JOINT_IMPUTATION_NEGATIVES_PASS=14
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=JOINT_IMPUTATION_NEGATIVES_PASS=14
