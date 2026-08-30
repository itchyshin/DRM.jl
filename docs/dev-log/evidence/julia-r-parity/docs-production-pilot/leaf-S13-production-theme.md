# Actual production theme and local references
OWNS: tools/parity_html_audit.py, tools/tests/test_parity_html_audit.py
Scope: Local preview of production005, with two explicit preview-only version metadata files. No deployed-site claim.

- [x] G1: Static HTML checker rejects damaged fixtures
  CHECK: python3 -m unittest tools.tests.test_parity_html_audit
  EXPECT: OK
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=Ran 8 tests in 0.043s | OK

- [x] G2: Full production theme builds without ignoring dead links
  CHECK: test ! -e /private/tmp/drm-parity-20260830/docs-production-preview-004/1 && node '/Users/z3437171/Dropbox/Github Local/DRM.jl/docs/node_modules/vitepress/bin/vitepress.js' build /private/tmp/drm-parity-20260830/docs-production-preview-004/source > /private/tmp/drm-parity-20260830/production-theme-004.log 2>&1 && cat /private/tmp/drm-parity-20260830/production-theme-004.log
  EXPECT: build complete in
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=[32m✓[0m rendering pages... | build complete in 6.94s.

- [x] G3: All checked HTML links, fragments and href/src assets resolve; srcset is rejected
  CHECK: python3 tools/parity_html_audit.py /private/tmp/drm-parity-20260830/docs-production-preview-004/1 > /private/tmp/drm-parity-20260830/production-html-004.log 2>&1 && cat /private/tmp/drm-parity-20260830/production-html-004.log
  EXPECT: HTML_AUDIT pages=53 local_links=6378 local_assets=476 fragments=827 failures=0
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=HTML_AUDIT pages=53 local_links=6378 local_assets=476 fragments=827 failures=0
