# S10 bridge prediction scales
OWNS: tools/parity_prediction.R

- [ ] G1: Four fixed-effect Gaussian cases agree for 32 stored/newdata link/response outputs
  CHECK: Rscript tools/parity_prediction.R /private/tmp/drm-parity-20260830/s10-candidate /private/tmp/drm-parity-20260830/DRM.jl /private/tmp/drm-parity-20260830/prediction-green-003.json
  EXPECT: PREDICTION_CONTRACT_PASS cases=4 predictions=32

- [x] G2: Adapter-only diagnostic agrees with native prediction at identical coefficients for all 32 outputs
  CHECK: python3 -c "import json; r=json.load(open('/private/tmp/drm-parity-20260830/prediction-green-003.json')); assert r['completed_predictions']==32 and r['adapter_status']=='PASS' and r['bridge_unchanged_during_run']; print('ADAPTER_ONLY_PASS; independently fitted native baseline remains separately gated')"
  EXPECT: ADAPTER_ONLY_PASS
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=ADAPTER_ONLY_PASS; independently fitted native baseline remains separately gated

Full programme G2/G3 remain open; this leaf is one prediction contract, not the complete model denominator.
