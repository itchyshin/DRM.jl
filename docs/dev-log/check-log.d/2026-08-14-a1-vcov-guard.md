| slice | date | change | check | result |
|---|---|---|---|---|
| A1 vcov guard | 2026-08-14 | `src/vcov_guard.jl` `_vcov_from_hessian`; applied at 45 fitter sites across 17 files + the 2 `try inv/catch pinv` blocks in `gaussian_bivariate.jl` | 18 targeted suites (16 families + `test_vcov_guard.jl` + `test_variational.jl`) | **ALL 18 SUITES PASSED**; `VA marginal scaffold (#136)` now 15/15 (was 14 pass / 1 error — `SingularException(3)`) |
