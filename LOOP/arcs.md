# Arcs — #372 measured wall-clock for six #370 bridge cells
# Status: G0 APPROVED 2026-08-03. Arcs 0–3 done; PR #373 open.

| Arc | Status | Gate | Budget | Deliverable |
|---|---|---|---|---|
| 0 Probe + protocol | **done** | G0 approved | 30–45 min | `docs/dev-log/evidence/2026-08-03-372-arc0-probe.md` |
| 1 Six-cell measure | **done** | Arc 0 | 90–150 min | `docs/dev-log/evidence/2026-08-03-372-six-cell-timing.md` (+ JSON/TOML) |
| 2 Docs + DoD + Rose | **done** | Arc 1 | 45–75 min | bridge docs + check-log.d + after-task + Rose |
| 3 PR close | **done** (open) | Arc 2 | 30–45 min | PR https://github.com/itchyshin/DRM.jl/pull/373 closes #372 |

## Prior lane (#370)

| Arc | Status | Note |
|---|---|---|
| 0–4 | **done** | Coef-scale `drm_bridge` parity |
| PR #371 | open / CI | #373 stacked on this base until merge → retarget to main |
