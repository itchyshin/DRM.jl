# Prepared joint prototype at frozen native parameters
OWNS: tools/check_joint_predictor_reference.jl, tools/check_joint_predictor_receipt.py, tools/test_joint_predictor_receipt.py

- [x] G1: Evaluate both frozen fixtures through the included Julia implementation
  CHECK: JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. tools/check_joint_predictor_reference.jl test/fixtures/joint_missing_predictor/native_reference.toml /private/tmp/drm-parity-20260830/joint-native-002.toml > /private/tmp/drm-parity-20260830/joint-native-002.raw.log 2>&1; run_status=$?; cat /private/tmp/drm-parity-20260830/joint-native-002.raw.log; exit "$run_status"
  EXPECT: JOINT_REFERENCE_EXECUTED cases=2 rows=320
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=JOINT_REFERENCE_EXECUTED cases=2 rows=320

- [x] G2: Recompute comparisons against numerical integration/state summation and verify source bytes
  CHECK: /opt/homebrew/bin/python3 tools/check_joint_predictor_receipt.py test/fixtures/joint_missing_predictor/native_reference.toml /private/tmp/drm-parity-20260830/joint-native-002.toml .
  EXPECT: JOINT_RECEIPT_PASS cases=2 rows=320 likelihoods=2 conditional_moments=640
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=JOINT_RECEIPT_PASS cases=2 rows=320 likelihoods=2 conditional_moments=640

- [x] G3: Reject deliberately damaged likelihoods, moments, metadata and provenance
  CHECK: /opt/homebrew/bin/python3 tools/test_joint_predictor_receipt.py test/fixtures/joint_missing_predictor/native_reference.toml /private/tmp/drm-parity-20260830/joint-native-002.toml .
  EXPECT: JOINT_RECEIPT_NEGATIVES_PASS=11
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=JOINT_RECEIPT_NEGATIVES_PASS=11

- [x] G4: Rejection controls remain active under optimized Python
  CHECK: /opt/homebrew/bin/python3 -O tools/test_joint_predictor_receipt.py test/fixtures/joint_missing_predictor/native_reference.toml /private/tmp/drm-parity-20260830/joint-native-002.toml .
  EXPECT: JOINT_RECEIPT_NEGATIVES_PASS=11
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=JOINT_RECEIPT_NEGATIVES_PASS=11

Estimated under two minutes including package compilation; no optimizer run.
The 1e-6 native log-likelihood and 1e-8 row/moment tolerances are predeclared.
