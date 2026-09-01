# S9 positive-fit prototype checks

OWNS: tools/check_joint_predictor_fit.jl, tools/check_joint_predictor_fit_receipt.py, tools/test_joint_predictor_fit_receipt.py

Estimate: under two minutes for two bounded default-start local fits, Julia and BLAS one thread. Timeout120s. Native frozen fits are not replaced.
Predeclared correctness: finite converged ML, gradient infinity norm <=1e-6, positive-definite symmetric Hessian, H*V identity error <=1e-6, independent log-likelihood error <=1e-6, correct rows/masks/status and snapshot isolation. Native parameter parity separately requires maximum absolute difference <=4e-6; a native discrepancy remains a failure.

- [x] G1: Execute both frozen nondegenerate datasets from default initial parameters
  CHECK: JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. tools/check_joint_predictor_fit.jl test/fixtures/joint_missing_predictor/native_reference.toml /private/tmp/drm-parity-20260830/joint-fit-002.toml > /private/tmp/drm-parity-20260830/joint-fit-002.raw.log 2>&1; run_status=$?; cat /private/tmp/drm-parity-20260830/joint-fit-002.raw.log; exit "$run_status"
  EXPECT: JOINT_FITS_EXECUTED cases=2
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=bernoulli optimizer=converged gradient=2.3506085966573664e-11 | JOINT_FITS_EXECUTED cases=2

- [x] G2: Recompute likelihood and verify optimizer, covariance, masks and source provenance
  CHECK: /opt/homebrew/bin/python3 tools/check_joint_predictor_fit_receipt.py test/fixtures/joint_missing_predictor/native_reference.toml /private/tmp/drm-parity-20260830/joint-fit-002.toml .
  EXPECT: JOINT_FIT_RECEIPT_PASS cases=2 rows=320 native_parity=false
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=JOINT_FIT_RECEIPT_PASS cases=2 rows=320 native_parity=false

- [x] G3: Damaged receipts fail for their intended reason
  CHECK: /opt/homebrew/bin/python3 tools/test_joint_predictor_fit_receipt.py test/fixtures/joint_missing_predictor/native_reference.toml /private/tmp/drm-parity-20260830/joint-fit-002.toml .
  EXPECT: JOINT_FIT_RECEIPT_NEGATIVES_PASS=13
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=JOINT_FIT_RECEIPT_NEGATIVES_PASS=13

- [x] G4: Negative controls remain active under optimized Python
  CHECK: /opt/homebrew/bin/python3 -O tools/test_joint_predictor_fit_receipt.py test/fixtures/joint_missing_predictor/native_reference.toml /private/tmp/drm-parity-20260830/joint-fit-002.toml .
  EXPECT: JOINT_FIT_RECEIPT_NEGATIVES_PASS=13
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=JOINT_FIT_RECEIPT_NEGATIVES_PASS=13
