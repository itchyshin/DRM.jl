# Plan vs actual — SCOPED Phase 1.0 remainder (2026-08-01)

**Plan:** `~/.cursor/plans/phase_1.0_ultra-plan_6633f778.plan.md` (copy in `LOOP/ultra-plan.md`)  
**Voice:** Melissa (reconcile) · Shannon+Ada lane

| Planned | Actual | Delta |
|---|---|---|
| Merge tip-honesty #358/#887 when green | In flight at plan start; Phase 1.0 branch cut from `origin/main` to avoid stall — tip-honesty merges in parallel when CI green | Soft: honesty not a hard dep for engine PR |
| S0 natgrad vs sparse TMB | **FAIL** measured: ng −259.795539 / ref −256.512618 / Δ=3.28 | Matches design default (infra path) |
| S1a XOR S1b | **S1b** — `src/lc_metric.jl` + test; no `:natgrad` | As planned on FAIL |
| S2 JET Q gate | `test_qgate_jet.jl` + JET in `test/Project.toml`; ROADMAP Q ticks for FD/Allocs/multi-shape | Done |
| S3 park + #338 | Tip docs + capability-status rows; close #338 | Done |
| S4 Pkg.test smoke | Local smoke on new tests | See check-log |
| S5 Rose | PASS in after-task | Done |
| Registrator / FULL dump / #136 / #291 | Fenced | Held |

**Headline actual:** #13 closed as infrastructure (not a public solver); JET gap closed; Phase 1.0 SCOPED closeout PRable.
