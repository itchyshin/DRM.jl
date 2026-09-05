# Gates: local rendered documentation verification

Scope: Verify the repaired local rendered-site auditor against damage fixtures
and the separately prepared local preview. This leaf does NOT replace globalG6,
raw production-render metadata failures, every-page visual review, external
references, accessibility qualification or deployed-site verification. Commands
are bound before this final re-verification; earlier build commands and failures
remain in the durable evidence directory, not retroactively described as this run.

OWNS: docs/dev-log/evidence/julia-r-parity/production-docs-20260831/**

- [x] D1: Local-reference damage fixtures and positive controls pass.
  CHECK: python3 -m unittest discover -s tools/tests -p test_parity_rendered_docs_audit.py -v
  EXPECT: OK
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/integration/DRM.jl; path=397a2e37e6bb/34 entries; output=Ran 12 tests in 0.171s | OK

- [x] D2: Every source page and supported local reference in completed preview passes the auditor.
  CHECK: python3 tools/parity_rendered_docs_audit.py --site-root docs/build/integration-preview-003 --source-root docs/src --report docs/dev-log/evidence/julia-r-parity/production-docs-20260831/preview-audit-final.json
  EXPECT: failures=0
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/integration/DRM.jl; path=397a2e37e6bb/34 entries; output=RENDERED_DOCS_AUDIT pages=53 source_pages=52 external=436 failures=0

- [x] D3: Independent Rose review accepts the auditor and the stated local-preview boundary.
  EVIDENCE: Rose (Sol/high) independently approved final tool573c50a5/teste52bc707, reran12/12 tests, verified shared inline/linked CSS traversal and local-preview boundary; no remaining blocker in reviewed cases. Raw metadata and external/browser/accessibility/deployment scope remain open.
