# Existing random-intercept cells against the components adapter
OWNS: tools/parity_conditional_prediction.R

- [ ] G1: Original three-cell independent-fit comparison remains required
  CHECK: Rscript tools/parity_conditional_prediction.R /private/tmp/drm-parity-20260830/s10-components-candidate /private/tmp/drm-parity-20260830/DRM.jl /private/tmp/drm-parity-20260830/conditional-components-regression-001.json > /private/tmp/drm-parity-20260830/conditional-components-regression-001.raw.log 2>&1; run_status=$?; cat /private/tmp/drm-parity-20260830/conditional-components-regression-001.raw.log; exit "$run_status"
  EXPECT: CONDITIONAL_FIT_PARITY_PASS

- [x] G2: Original 24 adapter comparisons pass with damaged controls rejected
  CHECK: python3 tools/check_conditional_receipt.py /private/tmp/drm-parity-20260830/conditional-components-regression-001.json
  EXPECT: CONDITIONAL_ADAPTER_RECOMPUTED=24; DAMAGED_REJECTED=6; MISSING_ROW_REJECTED=1
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=CONDITIONAL_ADAPTER_RECOMPUTED=24; DAMAGED_REJECTED=6; MISSING_ROW_REJECTED=1 | Independent-fit parity is a separate gate; this checker does not close it.

Estimate at most two minutes for the live check, seconds for receipt verification.
The previously retained varying-scale independent-fit failure remains a failure;
G2 does not close G1. The exact previous runner is reused without changes.
