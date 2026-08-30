# Production navigation and strict documentation build
OWNS: tools/parity_docs_subset.jl, tools/parity_docs_navigation.jl, tools/tests/test_docs_navigation.jl

- [x] G1: Production navigation matches the source manifest and rejects executable impostors
  CHECK: julia --startup-file=no tools/tests/test_docs_navigation.jl
  EXPECT: PRODUCTION_NAVIGATION_CONTRACT_PASS
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=Production navigation is data, never executed |   16     16  0.5s | PRODUCTION_NAVIGATION_CONTRACT_PASS

- [x] G2: Every source page executes with production navigation and fatal link/example errors
  CHECK: env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=docs tools/parity_docs_subset.jl --build-dir docs/build/production-005 --pages-file .unlazy/julia-r-parity/docs-pages.txt --navigation production > /private/tmp/drm-parity-20260830/production-source-005.log 2>&1 && cat /private/tmp/drm-parity-20260830/production-source-005.log
  EXPECT: DOCS_SUBSET_PASS pages=52 examples=122
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=DOCS_SUBSET_PASS pages=52 examples=122 seconds=111.082 | DOCS_SUBSET_BUILD=/private/tmp/drm-parity-20260830/DRM.jl/docs/build/production-005

Scope addition: reference/engine-internals.md adds one source/visible page;
all original51 sources and50 visible routes remain. Module coverage is enabled.
