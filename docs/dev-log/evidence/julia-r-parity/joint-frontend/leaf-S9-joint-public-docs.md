# S9 public joint frontend source documentation
OWNS: two reference pages and strict source build receipt.
Estimate <=3 minutes based on previous120seconds. One new32rowGaussian example fit. No deployment or visual verdict.

- [x] G1: All pages and runnable examples pass strict source generation
  CHECK: env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=docs tools/parity_docs_subset.jl --build-dir docs/build/joint-public-002 --pages-file .unlazy/julia-r-parity/docs-pages.txt --navigation production > /private/tmp/drm-parity-20260830/joint-public-docs-002.log 2>&1; run_status=$?; tail -n 20 /private/tmp/drm-parity-20260830/joint-public-docs-002.log; exit "$run_status"
  EXPECT: DOCS_SUBSET_PASS pages=52 examples=124
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=DOCS_SUBSET_PASS pages=52 examples=124 seconds=116.529 | DOCS_SUBSET_BUILD=/private/tmp/drm-parity-20260830/DRM.jl/docs/build/joint-public-002
