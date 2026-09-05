# Production documentation checkpoint — S13 / #563

## 1. Goal
Execute and render production documentation honestly, preserving all routes and recording failures; not close the full parity programme.

## 2. Implemented
Five top menus, correct homepage frontmatter and scoped claims, 109 docstring registrations, seven reference targets, strict production source runner and a tested static HTML checker. Local screenshots and content archives retained.

## 3a. Decisions and Rejected Alternatives
Keep modules=[DRM] and fatal warnings instead of masking missing coverage. Use the installed 0.3.4 backend, not code from a neighboring version. Preserve URLs and separate source execution from theme rendering. srcset is explicitly unsupported and fails; do not claim its assets were checked. No protected engine edit.

## 4. Files Touched
Changed docs/make.jl; docs/src/index.md; docs/src/reference/model-fitting-and-postfit.md, model-specification.md, structured-effect-markers.md; added engine-internals.md. Changed tools/parity_docs_subset.jl; added tools/parity_docs_navigation.jl, tools/parity_html_audit.py, tools/tests/test_docs_navigation.jl, tools/tests/test_parity_html_audit.py. Refreshed docs/dev-log/evidence/julia-r-parity/docs-inventory.{json,md}; added docs-production-pilot/ receipts, archives, logs and screenshots; this report and matching check-log.d row. LOOP/checkpoint.md and ignored leaf ledgers updated. Existing red S5 tests excluded.

## 5. Checks Run
Production005 source:52 pages122 examples111.082s, fatal warnings/module coverage. Preview004 theme:6.94s;53 HTML pages6378 links476 assets827 fragments0 failures. Navigation16 tests; Python inventory8 and HTML8 tests. Logs, source hashes and archive manifests in ../evidence/julia-r-parity/docs-production-pilot/. Two-page desktop light/dark visual review and homepage action click. No remote compute.

## 6. Tests of the Tests
Retained source002/003 failures prove coverage/ref checking. HTML tests reject missing pages/fragments/assets, empty builds/directories, symlink escapes, stylesheet-to-HTML fallback and srcset. New asset/srcset tests failed before the repair. Literal navigation parser rejects executable expressions and initially failed before its implementation.

## 7a. Issue Ledger
DRM.jl#563 remains open. This is a bounded S13 checkpoint; all programme gates remain open, including mobile/live documentation and numerical/performance parity.

## 8. Consistency Audit
Rose independently approved bounded patch, reran16 navigation and8 HTML tests, and inspected home/article screenshots. All old routes retained. No src diff. Memory receipt: continued the established routed programme; lane preflight and scoped ownership were checked earlier in this slice. Golden Set: not rerun in this bounded continuation; no claim of a fresh global memory regression pass. Version-path verification corrected a wrong neighboring-backend assumption.

## 9. What Did Not Go Smoothly
Literal homepage YAML;109 missing docstrings; seven broken refs; six menus still clipped article icons; checker false passes; first exact gate expectation used an unsupported regex-like literal and was corrected. Local Python HTTP server needs .html on direct deep loads; client navigation worked. All material failures retained.

## 10. Known Residuals
No mobile or live verification, no all-page visual claim, no universal parity/speedup. Source predict_parameters docstring retains inaccurate integration wording; reference page explicitly corrects it. Protected S5 edit approval pending and original red tests unstaged. No push/merge or release.

## 11. Team Learning
Inspect the actually loaded documentation backend. Source success cannot prove homepage rendering or module docstring coverage when disabled. Navigation links can use HTML route fallback, but stylesheet/icon/preload URLs must resolve exactly. Save failed controls and measure Julia BLAS threads explicitly. Lessons retained in this repository; no Codex memory writes.

## 12. Cross-Product Coverage
Covers production Julia source examples, docstring registration, local theme generation, checked static references and two inspected desktop pages. This does NOT cover R bridge parity, all Julia likelihoods/inference, all layouts, mobile, external links, browser JavaScript correctness, deployed pages, recovery/cleanup or benchmark wins.
