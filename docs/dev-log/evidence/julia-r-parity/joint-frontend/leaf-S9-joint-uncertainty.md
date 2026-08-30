# Julia native-shaped imputation uncertainty
OWNS: src/joint_missing_uncertainty.jl, test/test_joint_missing_uncertainty.jl

Mathematical contract approved by Rose before implementation; API tests failed before source was written. This leaf records the executable checks after the initial TDD cycle; it is not backdated. Native common-parameter evidence has separate gates. Kernel checks involve no optimizer; estimated <15seconds.

- [x] G1: Analytic Gaussian Jacobian and native status/mask neighbours pass
  CHECK: JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. test/test_joint_missing_uncertainty.jl
  EXPECT: JOINT_UNCERTAINTY_KERNEL_PASS
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=Bernoulli uncertainty is conditional, with native fit-status gate |    6      6  0.0s | JOINT_UNCERTAINTY_KERNEL_PASS
