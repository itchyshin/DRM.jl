# Nested documentation execution and integration claims
OWNS: tools/parity_docs_subset.jl, tools/tests/test_documenter_nested.jl, docs/src/tutorials/location-scale.md, docs/src/model-guides/cross-family-methods.md, docs/src/model-guides/marginal-la-vs-va.md
Scope: nested directory/example regression and specific integration-claim corrections; full-site G6 remains open.

- [x] G1: A fresh nested example executes in its build directory and the deliberately broken example fails
  CHECK: env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=docs tools/tests/test_documenter_nested.jl > /private/tmp/drm-parity-20260830/nested-contract-final.log 2>&1 && cat /private/tmp/drm-parity-20260830/nested-contract-final.log
  EXPECT: NESTED_DOCUMENTATION_CONTRACT_PASS
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=Nested Documenter execution contract |    4      4  3.7s | NESTED_DOCUMENTATION_CONTRACT_PASS

- [x] G2: The three corrected pages render and the nested location-scale tutorial executes all four examples
  CHECK: env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=docs tools/parity_docs_subset.jl --build-dir docs/build/nested-three-pages-001 --page tutorials/location-scale.md --page model-guides/cross-family-methods.md --page model-guides/marginal-la-vs-va.md > /private/tmp/drm-parity-20260830/nested-three-pages-final.log 2>&1 && cat /private/tmp/drm-parity-20260830/nested-three-pages-final.log
  EXPECT: DOCS_SUBSET_PASS pages=3 examples=4
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=DOCS_SUBSET_PASS pages=3 examples=4 seconds=14.283 | DOCS_SUBSET_BUILD=/private/tmp/drm-parity-20260830/DRM.jl/docs/build/nested-three-pages-001
