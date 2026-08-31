# Bootstrap covariance-provider forwarding

OWNS: src/inference.jl, test/test_bootstrap_provider_forwarding.jl.
Do not change likelihoods, fit estimators, covariance normalization, seeds,
convergence policy, or public coefficient scales.

- [x] G0: retained public coords failure before implementation
  EVIDENCE: pre-fix standalone test exits nonzero with MethodError: unsupported keyword argument coords at bootstrap_result(fit; ...).
- [x] G1: fit- and formula-based coords bootstrap survive refits
  CHECK: env JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 julia --startup-file=no --project=. test/test_bootstrap_provider_forwarding.jl
  EXPECT: Test Summary:
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/integration/DRM.jl; path=92301ffe9a62/34 entries; output=Test Summary:                                        | Pass  Total   Time | coordinate provider survives every bootstrap surface |   19     19  20.2s
- [x] G2: structured bootstrap neighbours remain green
  CHECK: julia --startup-file=no --project=. -e 'using Test; include("test/test_bootstrap_nongaussian_structured.jl"); include("test/test_bootstrap_formula_structured.jl")'
  EXPECT: Test Summary:
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/integration/DRM.jl; path=92301ffe9a62/34 entries; output=│   rcond = 7.848920889568808e-10 | └ @ DRM /private/tmp/drm-parity-20260830/integration/DRM.jl/src/vcov_guard.jl:87
- [x] G3: independent review and final provenance
  EVIDENCE: Rose bounded PASS on final sources/tests and live receipt; claims correction applied. Melissa bounded PASS after verifying 18 packaged artifacts, final hashes, G0-G2, and preserved global scope.

This slice proves bootstrap provider plumbing, not interval coverage, native-R
parity, R bridge completion or performance. Global programme G0-G8 remain open.
