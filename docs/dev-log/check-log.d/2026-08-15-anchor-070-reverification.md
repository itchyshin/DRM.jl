| slice | date | change | check | result |
|---|---|---|---|---|
| anchor 0.7.0 re-verify | 2026-08-15 | drmTMB 0.7.0 installed from a temp worktree (owner-approved); `tools/parity_fixture.R` FE cells switched from bridge-payload comparison to true `engine="julia"` vs `engine="tmb"` | full fixture re-run + direct engine routing test | **ALL 7 CELLS PASS** against 0.7.0, identical to 0.6.0; FE non-Gaussian **ADMITTED via engine=julia** and measured (poisson 1.03e-12, nbinom2 6.89e-08, gamma 5.32e-06) — evidence class upgraded from direct-Julia to R-via-Julia bridge parity |
