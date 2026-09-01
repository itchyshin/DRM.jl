# S9 prepared prototype documentation integration
OWNS: docs/src/reference/engine-internals.md

Estimate under three minutes (previous full run111seconds); single Julia/BLAS thread, no deployment.

- [x] G1: Strict full documentation source build includes the new prepared example and every docstring
  CHECK: env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=docs tools/parity_docs_subset.jl --build-dir docs/build/joint-production-001 --pages-file .unlazy/julia-r-parity/docs-pages.txt --navigation production > /private/tmp/drm-parity-20260830/joint-production-001.log 2>&1; run_status=$?; tail -n 20 /private/tmp/drm-parity-20260830/joint-production-001.log; exit "$run_status"
  EXPECT: DOCS_SUBSET_PASS pages=52 examples=123
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=DOCS_SUBSET_PASS pages=52 examples=123 seconds=120.471 | DOCS_SUBSET_BUILD=/private/tmp/drm-parity-20260830/DRM.jl/docs/build/joint-production-001
