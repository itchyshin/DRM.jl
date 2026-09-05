# Complete documentation source execution
OWNS: tools/parity_docs_subset.jl, docs/src/
Scope: All51 source pages through strict example execution; production navigation/theme/links/deployment are separate.

- [x] G1: Every source page emits and every executable example succeeds
  CHECK: env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=docs tools/parity_docs_subset.jl --build-dir docs/build/full-source-003 --pages-file .unlazy/julia-r-parity/docs-pages.txt > /private/tmp/drm-parity-20260830/full-docs-source-003.log 2>&1 && cat /private/tmp/drm-parity-20260830/full-docs-source-003.log
  EXPECT: DOCS_SUBSET_PASS pages=51 examples=122
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=DOCS_SUBSET_PASS pages=51 examples=122 seconds=111.795 | DOCS_SUBSET_BUILD=/private/tmp/drm-parity-20260830/DRM.jl/docs/build/full-source-003

Denominator correction: 119 column-zero example fences plus three indented examples
in tutorials/bivariate-nongaussian.md (lines73,121,189) = 122; no cases removed.
Run002 emitted all51 pages with exit0; its gate stayed unmet because the original
EXPECT undercounted those three nested examples. Retain002 and rerun003.
