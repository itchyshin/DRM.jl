| slice | date | change | check | result |
|---|---|---|---|---|
| A3a biv_lognormal | 2026-08-14 | `src/bivariate_lognormal.jl` — drmTMB's `biv_lognormal()`; closed-form, delegates to the verified Gaussian bivariate kernel on `log y` + a parameter-free Jacobian. Bridge tag `biv_lognormal` wired | 8 Julia suites + `tools/parity_fixture.R` vs installed drmTMB 0.6.0 | **ALL 8 SUITES PASSED**; **`biv_lognormal` PARITY_PASS vs native drmTMB — coef 9.149e-07, logLik 7.390e-12** (tol 1e-4); structural identities asserted (θ̂ and vcov identical to Gaussian-on-log; logLik shift == Jacobian) |
