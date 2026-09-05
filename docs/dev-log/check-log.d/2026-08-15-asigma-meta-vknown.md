| slice | date | change | check | result |
|---|---|---|---|---|
| A-sigma / meta V_known | 2026-08-15 | `_bridge_meta_parts` — recovers heterogeneity `tau` and `V_known` for a `meta_V()` fit; bridge now emits `sigma` dpar = tau (not the total SD) plus `V_known`. **No `sigma()` change, no struct change** | 5 suites (bridge, meta, simulate, postfit, gaussian_core) | **ALL PASS**; `V_known` recovered to **1.1e-16**; dpar `sigma` is tau and strictly below the total; non-meta fits gain no key; `sigma()` still returns a bare vector |
