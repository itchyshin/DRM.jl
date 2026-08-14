| slice | date | change | check | result |
|---|---|---|---|---|
| A2a dpar coverage | 2026-08-14 | none — verification of shipped `_bridge_dpars` | `drm_bridge` on lognormal / student / tweedie / zeroonebeta | **NO SILENT DROPS** — student & tweedie emit `mu,nu,sigma`; zeroonebeta emits `mu,sigma,zoi,coi,beta_mu`; all length n. Open: `beta_mu` is not a drmTMB dpar name and needs an explicit map before that cell is admitted |
