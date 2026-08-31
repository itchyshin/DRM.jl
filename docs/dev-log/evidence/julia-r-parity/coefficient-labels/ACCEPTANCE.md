# Native coefficient-label parity
OWNS: Terra src/bridge.jl and test/test_bridge_formula_labels.jl; root collision test, R helper/wrapper/tools/docs/integration; Rose read-only review.
- [x] G1: Native quadratic/factor/interaction selector failures and relevant recovery refs retained.
  EVIDENCE: R probe001; Julia collision-red001; prior25R/6Julia refs checked; no missing independent repair recovered.
- [x] G2: Explicit label mapping preserves numerical design, order and coefficient identity without heuristic ambiguity.
  CHECK: cd /private/tmp/drm-parity-20260830/label-verification/DRM.jl && python3 tools/check_coefficient_label_receipt.py docs/dev-log/evidence/julia-r-parity/coefficient-labels/combined-005.json --self-test && python3 -O tools/check_coefficient_label_receipt.py docs/dev-log/evidence/julia-r-parity/coefficient-labels/combined-005.json --self-test
  EXPECT: COEFFICIENT_LABEL_COMBINED_SELFTEST_PASS:11 damaged receipts rejected
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=COEFFICIENT_LABEL_COMBINED_RECEIPT_PASS 108 current inputs | COEFFICIENT_LABEL_COMBINED_SELFTEST_PASS:11 damaged receipts rejected
- [x] G3: Public native selectors reach intended profile/bootstrap coordinates and independent oracles pass for every registered case.
  CHECK: cd /private/tmp/drm-parity-20260830/label-verification/drmTMB && Rscript tools/check-julia-coefficient-labels-receipt.R docs/dev-log/evidence/julia-r-parity/coefficient-labels/public-008.rds --self-test
  EXPECT: COEFFICIENT_LABEL_SELFTEST_PASS:13 damaged receipts rejected
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=COEFFICIENT_LABEL_RECEIPT_PASS:17 cases and12 inference operations, current source hashes | COEFFICIENT_LABEL_SELFTEST_PASS:13 damaged receipts rejected
- [x] G4: Existing bridge neighbours and metadata/prediction refusal checks pass.
  CHECK: cd /private/tmp/drm-parity-20260830/label-verification/drmTMB && Rscript -e 'pkgload::load_all(".",quiet=TRUE); testthat::test_file("tests/testthat/test-julia-bridge-coef-labels.R",reporter="summary",stop_on_failure=TRUE); testthat::test_file("tests/testthat/test-julia-prediction-scales.R",reporter="summary",stop_on_failure=TRUE); cat("COEFFICIENT_LABEL_R_NEIGHBOURS_PASS\n")'
  EXPECT: COEFFICIENT_LABEL_R_NEIGHBOURS_PASS
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/DRM.jl; path=397a2e37e6bb/34 entries; output=══ DONE ════════════════════════════════════════════════════════════════════════ | COEFFICIENT_LABEL_R_NEIGHBOURS_PASS
- [x] G5: Examples, source-stamped evidence, Rose review and Melissa reconciliation retained.

Review delta: G2/G3 reopened after Rose found scalar source provenance restricted to I(). Prior successful command receipts above are historical; do not treat them as final source qualification. Next bindings await repaired source and updated public denominator.

Final candidate bindings use owned-only label-verification checkouts. Seventeen point cases plus twelve inference operations;13 damaged receipts. Await final sourcefreeze and public008 before running G2–G4. Historical EVIDENCE lines above are retained, not current certification.

CURRENT CHECKPOINT: all five bounded leaf gates met. G5 evidence: RESULT.md, final after-task report, check-log.d entry, review-log.md final Rose and Melissa receipts. Programme G0–G8 remain OPEN. Earlier review deltas above are historical.
