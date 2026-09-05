# Gates: overlapping inference BLAS scopes

Scope: prevent premature restoration of process-global BLAS threads while a
second DRM inference scope remains active. No estimator or likelihood changes.
The deterministic original test failed before source changes (red.log: 2 != 1).
These gates cover the repaired helper; full programme G4/G5/G7 remain open.

OWNS: src/inference.jl,test/test_inference_blas_pinning.jl

- [x] B1: Coordinated scopes preserve BLAS state with one Julia scheduler thread.
  CHECK: OPENBLAS_NUM_THREADS=2 JULIA_PKG_OFFLINE=true JULIA_PKG_PRECOMPILE_AUTO=0 julia --project=. --startup-file=no --threads=1 -e 'include("test/test_inference_blas_pinning.jl"); println("BLAS_PINNING_CHECK_PASS")'
  EXPECT: BLAS_PINNING_CHECK_PASS
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/integration/DRM.jl; path=92301ffe9a62/34 entries; output=inference BLAS pinning is composable across callers |   17     17  0.3s | BLAS_PINNING_CHECK_PASS

- [x] B2: Coordinated scopes preserve BLAS state with four Julia scheduler threads.
  CHECK: OPENBLAS_NUM_THREADS=2 JULIA_PKG_OFFLINE=true JULIA_PKG_PRECOMPILE_AUTO=0 julia --project=. --startup-file=no --threads=4 -e 'include("test/test_inference_blas_pinning.jl"); println("BLAS_PINNING_CHECK_PASS")'
  EXPECT: BLAS_PINNING_CHECK_PASS
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/integration/DRM.jl; path=92301ffe9a62/34 entries; output=inference BLAS pinning is composable across callers |   17     17  0.2s | BLAS_PINNING_CHECK_PASS

- [x] B3: Independent Rose review accepts source, tests and scope limits.
  EVIDENCE: Rose Sol/high approved frozen helper c0675b16 and deterministic test82a0499a; coordinator verified both local executable gates and the five-file Totoro regression against327unchanged source hashes. Uncoordinated external BLAS changes and whole-programme gates remain outside this leaf.
