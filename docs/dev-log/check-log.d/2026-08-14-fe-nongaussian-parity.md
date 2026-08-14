| slice | date | change | check | result |
|---|---|---|---|---|
| FE non-Gaussian parity | 2026-08-14 | `tools/parity_fixture.R` extended with fixed-effect Poisson / NB2 / Gamma(log) cells, compared native TMB vs DRM.jl bridge payload | `DRM_JL_PATH=... Rscript tools/parity_fixture.R` | **ALL 5 CELLS PASS** — fe_poisson 1.03e-12, fe_nbinom2 2.79e-08, fe_gamma 3.91e-06 (tol 1e-4); tighter than the already-admitted Gaussian location-scale cell |
