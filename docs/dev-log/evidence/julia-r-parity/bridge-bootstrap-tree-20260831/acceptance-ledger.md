# Tree forwarding through non-Gaussian bootstrap APIs

OWNS: root src/bridge.jl, test/test_bridge_bootstrap_tree.jl, test/runtests.jl;
R worker R/julia-bridge.R, tests/testthat/test-julia-bootstrap-tree.R.
Preserve convergence, estimator, seeds, failure counts, and tree scale.

- [x] G0: retained pre-fix failure on an actual tree bootstrap
  EVIDENCE: retained label failure204158Z, label-only patch, missing-tree failure204403Z; both have successful direct2/2 control. Rose reviewed source and both behavioural failures. Cache-permission failure204352Z is environment-only.
- [x] G1: Julia public bridge equals direct bootstrap at one thread
  CHECK: python3 /private/tmp/drm-parity-20260830/bridge-bootstrap-tree/run.py 1
  EXPECT: TREE_BOOTSTRAP_CHECK_PASS
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/integration/DRM.jl; path=92301ffe9a62/34 entries; output={'command': ['julia', '--startup-file=no', '--project=/private/tmp/drm-parity-20260830/integration/DRM.jl', '/private/tmp/drm-parity-20260830/bridge-bootstrap-tree/tree-threads1-20260831T210056Z.jl'], 'code': 0, 'seconds': 24.79307408281602
- [x] G2: Julia bridge serial/threaded consistency at four threads
  CHECK: python3 /private/tmp/drm-parity-20260830/bridge-bootstrap-tree/run.py 4
  EXPECT: TREE_BOOTSTRAP_CHECK_PASS
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/integration/DRM.jl; path=92301ffe9a62/34 entries; output={'command': ['julia', '--startup-file=no', '--project=/private/tmp/drm-parity-20260830/integration/DRM.jl', '/private/tmp/drm-parity-20260830/bridge-bootstrap-tree/tree-threads4-20260831T210121Z.jl'], 'code': 0, 'seconds': 22.08116399985738
- [x] G3: actual R public API and generated wrapper
  CHECK: python3 /private/tmp/drm-parity-20260830/bridge-bootstrap-tree/run_r.py
  EXPECT: R_TREE_BOOTSTRAP_CHECK_PASS
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/integration/DRM.jl; path=92301ffe9a62/34 entries; output=/private/tmp/drm-parity-20260830/bridge-bootstrap-tree/actual-r-threads4-20260831T210213Z {'command': ['Rscript', '--vanilla', '/private/tmp/drm-parity-20260830/bridge-bootstrap-tree/actual-r.R'], 'code': 0, 'seconds': 27.359863250050694, '
- [x] G4: independent review and final-source provenance
  EVIDENCE: manual review, Rose PASS; Melissa bounded PASS after R log-provenance correction verified. Final source hashes, retained red/green, artifact integrity and served two-field Mission Control update verified. See retained review.md and reconciliation.md; all programme gates remain open.

This is integration, not interval calibration. Global G0-G8, providers K/A/coords,
Gamma public scale normalization and the complete parity manifest stay required.
