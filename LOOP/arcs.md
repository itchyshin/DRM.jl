# Arcs — #370 bridge fixture coefficient-scale parity
# G0 APPROVED 2026-08-03 (Shinichi). Defaults: timing no-claim OK; hold until all six pass.

| Arc | Status | Gate | Budget | Deliverable |
|---|---|---|---|---|
| 0 Smoke + inventory | **done** | G0 approved | 20–40 min | Smoke log in `docs/dev-log/evidence/2026-08-03-370-arc0-smoke.md`; student scale drift found |
| 1 Bridge parity harness | **done** | Arc 0 | 1–2 h | `compare_bridge` + `runparity_bridge.jl` under `DRM_PARITY_TESTS=1` |
| 2 Admit six cells | **done** | harness | 1–2 h | 6/6 bridge + 6/6 native; student fixture scale fixed; xfam skip |
| 3 Timing cells | **done** | Arc 2 | 30–60 min | Honest no-claim artifact `docs/dev-log/evidence/2026-08-03-370-timing-no-claim.md` |
| 4 Docs + DoD + close | **done** | Arc 2+3 | 45–90 min | `r-julia-bridge.md`; check-log.d; after-task; Rose; [PR #371](https://github.com/itchyshin/DRM.jl/pull/371) `closes #370` |
