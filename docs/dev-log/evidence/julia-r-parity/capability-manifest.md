# Native R capability manifest

This is a structural denominator, not functional Julia parity evidence.

- Pinned drmTMB Git SHA: `b35642b4560072cadba7e595e66e00209ebdeb40`
- Native ledger rows: 751
- Exported functions: 59
- S3 operations: 90
- Supplemental source-audited admissions: 3

| Native capability status | Rows |
| --- | ---: |
| implemented | 393 |
| not_implemented | 10 |
| rejected_by_design | 348 |

| Implemented axis | Rows |
| --- | ---: |
| association | 6 |
| missing_predictor | 24 |
| missing_response | 18 |
| model_surface | 345 |

All direct-reference fixtures, bridge fixtures, and required outputs are initialized as `MISSING`.
`MANIFEST_STRUCTURE_PASS` validates source pins, exact rows, namespace coverage, contract shape, and any declared receipt bytes.
A `PASS` receipt must be a pinned JSON artifact with matching source IDs, cell, route, output,
SHA-256, and declared passed assertions. The current checker does **not** recompute numerical
comparisons or prove loaded binary build identity. Those are required harness work, not completed
evidence. No command in this scaffold can return an overall parity PASS, even with all fields filled.
`verify-parity` remains fail-closed while observations are missing, skipped, stale, or pending; its present scaffold also requires an evidence review before reporting parity.

The LSS, bivariate Student-t, and bivariate lognormal supplemental entries are source admissions only; normalization and estimand contracts remain unresolved.
