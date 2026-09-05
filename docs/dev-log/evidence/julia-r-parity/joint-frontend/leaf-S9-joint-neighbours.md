# S9 integration neighbours
Estimate <=90 seconds. Existing Gaussian location-scale and formula tests plus prepared joint63 assertions (bounded fits), Julia/BLAS1. No full-suite claim.

- [x] G1: Existing fixed Gaussian and formula grammar plus prepared tests stay green
  CHECK: JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. -e 'using DRM, Test, LinearAlgebra, Random; BLAS.set_num_threads(1); @assert Threads.nthreads()==1 && BLAS.get_num_threads()==1; include("test/test_gaussian_core.jl"); include("test/test_bf_grammar.jl"); include("test/test_joint_missing_predictor.jl"); println("JOINT_NEIGHBOURS_PASS")'
  EXPECT: JOINT_NEIGHBOURS_PASS
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=S9_JOINT_PURE_PASS | JOINT_NEIGHBOURS_PASS
