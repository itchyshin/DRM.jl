| slice | date | change | check | result |
|---|---|---|---|---|
| A3b biv_student | 2026-08-14 | `src/bivariate_student.jl` — drmTMB's `biv_student()`: exact bivariate-t density, ONE shared `nu` (`logm2` link). `bf(; nu=…)` grammar keyword added (Student-only, omitted otherwise); bridge tag + `nu` threading | 12 suites with **`DRM_PARITY_TESTS=1`** (grammar rail) + `tools/parity_fixture.R` | **ALL 12 SUITES PASSED**; **`biv_student` PARITY_PASS vs native drmTMB — coef 3.117e-06, logLik 1.026e-09** (tol 1e-4); all 7 fixture cells PASS |
