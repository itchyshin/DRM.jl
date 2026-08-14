| slice | date | change | check | result |
|---|---|---|---|---|
| parity fixtures | 2026-08-14 | `tools/parity_fixture.R` — native-vs-Julia same-target comparison through drmTMB itself (the promotion gate) | `DRM_JL_PATH=... Rscript tools/parity_fixture.R` against installed drmTMB 0.6.0 | **ALL CELLS PASS** — `base_gaussian_location_scale` coef 4.56e-06 / logLik 4.58e-09; `base_gaussian_intercept_only` coef 2.49e-10 / logLik 5.26e-13 (tol 1e-4) |
