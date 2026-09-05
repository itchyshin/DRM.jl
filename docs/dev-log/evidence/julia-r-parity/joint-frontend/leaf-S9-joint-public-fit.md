# S9 public formula fits on two frozen datasets
OWNS: tools/check_joint_frontend_fit.jl and its two Python checkers; builder Terra/high source frozen.
Estimate <30 seconds for2fits based on prepared10seconds+frontend13seconds. Max60seconds; one Julia/BLAS thread, no R fit or remote work.
Required native parity is evaluated separately and must remain red if failing; the command-line flag is not a scope exclusion.

- [x] G1: Execute public fits with complete source and output receipt
  CHECK: JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. tools/check_joint_frontend_fit.jl test/fixtures/joint_missing_predictor/native_reference.toml test/fixtures/joint_missing_predictor/native_uncertainty.toml /private/tmp/drm-parity-20260830/joint-frontend-fit-001.toml
  EXPECT: JOINT_FRONTEND_FITS_EXECUTED cases=2 rows=320
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=public=bernoulli converged=true gradient=2.3506085966573664e-11 native_theta_max_abs=1.0015094105086941e-5 | JOINT_FRONTEND_FITS_EXECUTED cases=2 rows=320
- [x] G2: Independent likelihood, information and imputation checks pass
  CHECK: python3 tools/check_joint_frontend_fit_receipt.py test/fixtures/joint_missing_predictor/native_reference.toml test/fixtures/joint_missing_predictor/native_uncertainty.toml /private/tmp/drm-parity-20260830/joint-frontend-fit-001.toml .
  EXPECT: JOINT_FRONTEND_RECEIPT_PASS cases=2 rows=320
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=JOINT_FRONTEND_RECEIPT_PASS cases=2 rows=320 native_theta_checked=false deltas={'gaussian': 2.7546376548670537e-06, 'bernoulli': 1.0015094105086941e-05}
- [x] G3: Damaged receipts are rejected
  CHECK: python3 tools/test_joint_frontend_fit_receipt.py test/fixtures/joint_missing_predictor/native_reference.toml test/fixtures/joint_missing_predictor/native_uncertainty.toml /private/tmp/drm-parity-20260830/joint-frontend-fit-001.toml .
  EXPECT: JOINT_FRONTEND_RECEIPT_NEGATIVES_PASS=17
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=JOINT_FRONTEND_RECEIPT_NEGATIVES_PASS=17
- [x] G4: Damaged receipts remain rejected under Python -O
  CHECK: python3 -O tools/test_joint_frontend_fit_receipt.py test/fixtures/joint_missing_predictor/native_reference.toml test/fixtures/joint_missing_predictor/native_uncertainty.toml /private/tmp/drm-parity-20260830/joint-frontend-fit-001.toml .
  EXPECT: JOINT_FRONTEND_RECEIPT_NEGATIVES_PASS=17
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=JOINT_FRONTEND_RECEIPT_NEGATIVES_PASS=17
- [ ] G5: Required native fitted-parameter parity remains within4e-6
  CHECK: python3 tools/check_joint_frontend_fit_receipt.py test/fixtures/joint_missing_predictor/native_reference.toml test/fixtures/joint_missing_predictor/native_uncertainty.toml /private/tmp/drm-parity-20260830/joint-frontend-fit-001.toml . --native-theta
  EXPECT: JOINT_FRONTEND_RECEIPT_PASS cases=2 rows=320 native_theta_checked=true
