# Direct finite new-data prediction
OWNS: Terra/high src/joint_missing_frontend.jl,test/test_joint_missing_finite_prediction.jl; root wiring, docs, receipts. Likelihood unchanged; no GPL implementation copied.
Contract: fitted mean/sigma schemas retained including native state permutation/ordinal coding; known finite levels give native plug-in predictions without new-response conditioning; missing/unknown new finite x refused like native/bridge. Sigma requires only its own design columns. Both link/response, covariance-based SEs, factor singleton/subset batches, immutable training data, explicit invalid-control refusals. Broader missing-newdata integration and typed factors remain programme obligations if native admits them.
Estimate: root local focused test <=120seconds,1Julia/1BLASthread.

- [x] G1: Prediction/SE/schema/refusal test passes after recorded RED
  CHECK: JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. -e 'using DRM, Test; include("test/test_joint_missing_finite_prediction.jl"); println("FINITE_PREDICTION_PASS")'
  EXPECT: FINITE_PREDICTION_PASS
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=FINITE_JOINT_PREDICTION_TEST_READY | FINITE_PREDICTION_PASS

- [x] G2: Existing finite frontend/factor designs remain correct
  CHECK: JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. -e 'using DRM, Test; include("test/test_joint_missing_finite_frontend.jl"); include("test/test_joint_missing_finite_factor_coding.jl"); println("FINITE_PREDICTION_NEIGHBOURS_PASS")'
  EXPECT: FINITE_PREDICTION_NEIGHBOURS_PASS
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=FINITE_JOINT_FACTOR_CODING_TEST_READY | FINITE_PREDICTION_NEIGHBOURS_PASS

- [x] G3: Independent Rose source and native prediction contract review

  EVIDENCE: Rose independent review approved final source 34e715491f4b967ed119a22bd2abce5a76095d69ebfaeca99910d0585fcd4964 and test 478fba446c10bb8c2d1ec52f080174c3c2be950a16bf72615f02b5fe6b1a6bf9; 51 prediction +86 frontend +109 factor assertions pass in finite-prediction-green-003.log. Tiny negative covariance rejection and positive tiny covariance acceptance included. Known-state scope only.
