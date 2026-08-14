| slice | date | change | check | result |
|---|---|---|---|---|
| A2a dpar semantics | 2026-08-14 | `_bridge_dpars` maps `mu ← beta_mu` for ZeroOneBeta (drmTMB's `mu` is the interior beta mean, not `fitted`); `trials` moved out of `dpars` into its own payload key via `_bridge_trials` | 6 suites: bridge, binomial, betabinomial, zeroonebeta, meta, gaussian_core | **ALL 6 SUITES PASSED**; binomial `dpars` now exactly `["mu"]`; zeroonebeta `dpars` = `{mu,sigma,zoi,coi}` with `mu != fitted` asserted |
