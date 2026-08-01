# After-task — SCOPED Phase 1.0 remainder (#3 / #13 / JET)

**Date:** 2026-08-01  
**Branch:** `feat/phase10-scoped-13-jet`  
**Closes:** #13, #338; advances #3 (SCOPED)  
**Voice:** Shannon (coordination) + Ada / Noether / Karpinski / Rose / Melissa  
**Subagents:** none spawned (Composer lane)

## What landed

| Slice | Outcome |
|---|---|
| S0 #13 gate | **FAIL** — ng logLik −259.795539 vs sparse-TMB −256.512618 (Δ=3.28); brief filed |
| S1b | Extracted `src/lc_metric.jl` + `test/test_lc_metric.jl`; **no** `:natgrad` public API |
| S2 | JET Workflow Q gate (`test/test_qgate_jet.jl` + JET in `test/Project.toml`); ROADMAP Q ticks refreshed |
| S3 | Park leftovers in ROADMAP/HANDOVER/README/capability-status/design; close #338 (content on tip) |
| S4–S5 | Local smoke + Rose claim-vs-evidence below |
| Melissa | `docs/dev-log/plan-actual/2026-08-01-phase10-remainder.md` |

## Rose claim-vs-evidence

| Claim | Evidence | Verdict |
|---|---|---|
| Natgrad is not a public faster solver | Measured stall −259.80 vs −256.51; no `:natgrad` in `gaussian_core` algorithm set | **PASS** — honest FAIL |
| `lc_metric` is Fisher infra for #11/#165 | `src/lc_metric.jl` exported; unit test asserts SPD + descent + FD-Hessian agreement | **PASS** |
| Workflow Q JET gap closed | `test_qgate_jet.jl` + runtests guard; FD/Allocs/multi-shape already gated/evidenced | **PASS** (cross-check still open — not oversold) |
| Leftover experimental/ parked | Tip docs list SQUAREM/estep/dense/`fit_em_natgrad` as unwired | **PASS** |
| #338 content on tip | `docs/design/capability-status.md` present; close-only | **PASS** |
| No Registrator / no FULL dump | Fenced; D-111 held | **PASS** |

**Rose verdict:** PASS — no oversell of stalling EM; #13 closed as infra.

## Verify

- Decision-gate numbers read from `/tmp/natgrad_gate_run.log` + `_natgrad_gate_raw.txt` (not exit codes alone).
- `Pkg.test` smoke for `test_lc_metric` + JET gate (see plan-actual / check-log).
