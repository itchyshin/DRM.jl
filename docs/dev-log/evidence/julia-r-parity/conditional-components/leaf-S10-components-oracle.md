# Independent component receipt verification
OWNS: tools/check_component_receipt.py, tools/test_component_receipt.py

- [x] G1: Recompute every adapter and likelihood comparison; reject altered evidence
  CHECK: python3 tools/check_component_receipt.py /private/tmp/drm-parity-20260830/components-green-002.json
  EXPECT: COMPONENT_ORACLES_RECOMPUTED=32; SHIFTED_REJECTED=8; LIKELIHOOD_REJECTED=1; MISSING_ROW_REJECTED=1
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=COMPONENT_ORACLES_RECOMPUTED=32; SHIFTED_REJECTED=8; LIKELIHOOD_REJECTED=1; MISSING_ROW_REJECTED=1 | Independent-fit failures: 0 []

- [x] G2: Checks fail closed with and without Python optimization
  CHECK: python3 tools/test_component_receipt.py /private/tmp/drm-parity-20260830/components-green-002.json
  EXPECT: COMPONENT_CHECKER_NORMAL_AND_OPTIMIZED_PASS=14
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=COMPONENT_CHECKER_NORMAL_AND_OPTIMIZED_PASS=14

These checks use the retained live receipt. Independent native-fit comparison
failures are reported separately and never closed by adapter-only agreement.
