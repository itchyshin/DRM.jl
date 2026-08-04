# Arcs — R-parity +4 FE bridge (status-marked)

| ID | Status | Gate? | Arc |
|---|---|---|---|
| Arc0 | PENDING | no | Issue + 4-cell drm_bridge smoke inventory |
| Rung1 | PENDING | no | gen_fixtures.R + MIT fixtures + meta.toml |
| Rung2 | PENDING | no | `_BRIDGE_PARITY_COHORT` + `_parity_family` + DRM_PARITY_TESTS=1 |
| Docs | PENDING | no | `r-julia-bridge.md` (+ parity README if needed) |
| Closeout | PENDING | OPEN GATE: PR open (merge = owner) | check-log.d + after-task + Rose + PR |
| Under#186 | OPTIONAL | no | Close stale epic #186 checklist only if early |

## Verify (always)
1. `test_parity_harness.jl` green
2. `DRM_PARITY_TESTS=1` native + bridge: old six + new admitted
3. Rose: admitted list = evidence; no speed claim; MIT/GPL boundary
