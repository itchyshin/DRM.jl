# Independent joint-model numerical references
OWNS: tools/export_joint_predictor_reference.R

- [x] G1: Frozen native fixtures yield normalized conditional moments and unchanged likelihoods
  CHECK: Rscript tools/export_joint_predictor_reference.R docs/dev-log/evidence/julia-r-parity/missing-predictor-oracle/native-mi-oracle-003.json /private/tmp/drm-parity-20260830/joint-reference-001.json
  EXPECT: JOINT_REFERENCE_PASS rows=320 missing_predictors=20
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=JOINT_REFERENCE_PASS rows=320 missing_predictors=20

Export only: no fitting, compilation, remote compute or optimizer changes.
