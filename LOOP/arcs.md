# Arcs — SCOPED Phase 1.0 remainder (#3 / #13 / JET)

| ID | Arc | Status | Gate? | Notes |
|---|---|---|---|---|
| pre | Merge tip-honesty #358 + drmTMB #887 | parallel | yes (CI) | docs-only; leave `.worktrees/` |
| S0 | #13 natgrad decision gate | **done FAIL** | no | brief → `docs/dev-log/plans/2026-08-01-natgrad-decision-gate.md` |
| S1a | Wire `algorithm = :natgrad` | skipped | — | S0 FAIL |
| S1b | Extract `lc_metric` infra | **done** | soft | `src/lc_metric.jl` + unit test; no public solver |
| S2 | JET Workflow Q gate | **done** | no | `test_qgate_jet.jl`; ROADMAP Q ticks |
| S3 | Park experimental/ + close #338 | **done** | no | tip docs honesty; check-log.d + after-task |
| S4 | Verify `Pkg.test` smoke | **done** | soft | lc_metric 5/5 + JET OK |
| S5 | Rose claim-vs-evidence | **done** | claim | PASS in after-task |
| Mel | Melissa plan-actual | **done** | no | `docs/dev-log/plan-actual/2026-08-01-phase10-remainder.md` |

## Deferred / fenced
JuliaRegistrator/General (D-111) · FULL experimental dump · #136 VA · #291 REML · AGENTS fence commits · Workflow R (parked)
