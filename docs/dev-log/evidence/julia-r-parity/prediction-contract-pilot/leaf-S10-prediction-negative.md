# Deliberately damaged prediction control
OWNS: tools/parity_prediction.R

- [x] G1: The executed +0.1 prediction fault is rejected for every registered output
  CHECK: python3 -c "import json; r=json.load(open('/private/tmp/drm-parity-20260830/prediction-negative-001.json')); a=[p for c in r['cases'].values() for p in c['observations'].values()]; assert r['status']=='FAIL' and r['adapter_status']=='FAIL' and len(a)==32 and all(p['adapter_status']=='FAIL' and abs(p['adapter_max_abs_diff']-0.1)<1e-12 for p in a); print('DAMAGED_PREDICTIONS_REJECTED=32')"
  EXPECT: DAMAGED_PREDICTIONS_REJECTED=32
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=DAMAGED_PREDICTIONS_REJECTED=32

This checks the retained output from the executed negative-control wrapper; it does not rerun fits.
