# Rooted multifurcating tree parity
OWNS: Terra/high src/sparse_phy.jl,test/test_phylo_polytomy.jl. Root tests/docs/receipts; R serializer ownership pending. No denied Gaussian file edits.
Contract: positive finite branch lengths; rooted connected directed tree, tips1:p; internal>=2children; no binary resolution or branch normalization in direct Julia. Q=B' diag(1/b) B; condition the unique root. Tip covariance equals summed shared root-path branch lengths. R bridge retains its documented correlation-scale SD mapping. Native zero-length/unary/general-label support remains required distinct parity work, not an exclusion.
Estimate: each local focused Julia correctness check <=120seconds,oneJulia/oneBLASthread; bridge pilot <=120seconds after safeownership.

- [x] G1: Star/mixed trees and malformed topology tests pass after a retained RED
  CHECK: JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. -e 'using DRM, Test; include("test/test_phylo_polytomy.jl"); println("POLYTOMY_CONSTRUCTOR_PASS")'
  EXPECT: POLYTOMY_CONSTRUCTOR_PASS
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=PHYLO_POLYTOMY_TEST_READY | POLYTOMY_CONSTRUCTOR_PASS

- [x] G2: Root conditioning, branch scales and existing binary tree tests remain correct
  CHECK: JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. -e 'using DRM, Test; include("test/test_phylo_tree_height.jl"); println("POLYTOMY_BINARY_NEIGHBOUR_PASS")'
  EXPECT: POLYTOMY_BINARY_NEIGHBOUR_PASS
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=┌ Warning: drm: this tree's maximum tip height is 0.3, not 1, so `sd_phylo` is on the RAW branch-length scale. For an ultrametric tree it is a factor 0.547723 = sqrt(0.3) away from the correlation scale R's drmTMB reports (via `ape::vcv(tre

- [x] G3: Independent covariance and downstream likelihood review, no root/scale change
  EVIDENCE: Rose approved source18c72189 with required runner integration; both new tests are now included alongside existing tree-height test. Independent path covariance, logdet, q2exactGaussian and q4fixed-state normalization reviewed. No q4fit/inference/fullparity claim.

- [x] G4: Public R bridge accepts preserved multifurcations with native covariance and row mapping evidence
  CHECK: python3 tools/check_polytomy_public_receipt.py docs/dev-log/evidence/julia-r-parity/polytomy/public-003.json /private/tmp/drm-parity-20260830/drmTMB --damage
  EXPECT: POLYTOMY_PUBLIC_DAMAGES_REJECTED 16
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=POLYTOMY_PUBLIC_ORACLE_PASS cases=2 rows=120 native_and_direct_and_bridge=true | POLYTOMY_PUBLIC_DAMAGES_REJECTED 16

- [x] G5: q2/q4 dimensions and fixed-parameter normalization match independent dense oracles
  CHECK: JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. -e 'using DRM, Test; include("test/test_phylo_polytomy_kernels.jl"); println("POLYTOMY_KERNEL_PASS")'
  EXPECT: POLYTOMY_KERNEL_PASS
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=polytomy downstream dimensions and likelihood normalization |   22     22  13.1s | POLYTOMY_KERNEL_PASS

Full G0-G8 remain OPEN; no speed/inference/coverage completion claim.
