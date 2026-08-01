GOAL: see GOAL.md. STATE: SCOPED Phase 1.0 — S0 **FAIL** → S1b+S2+S3 landed on `feat/phase10-scoped-13-jet`. NEXT = S4 smoke → push/PR → close #13/#338/#3 as appropriate.

ARCS DONE:
- S0 #13 gate — FAIL (ng −259.795539 vs ref −256.512618); brief `docs/dev-log/plans/2026-08-01-natgrad-decision-gate.md`
- S1b — `src/lc_metric.jl` + `test/test_lc_metric.jl`; no `:natgrad`
- S2 — JET Q gate + ROADMAP Q ticks
- S3 — park docs + capability-status; after-task + check-log.d + Melissa plan-actual drafted

ARC IN PROGRESS: S4 verify + PR open; tip-honesty #358/#887 merge hygiene in parallel when green.

NEXT:
1. `Pkg.test` smoke (lc_metric + JET)
2. Commit + push + `gh pr create` (closes #13, #338; #3 SCOPED)
3. Merge tip-honesty when green (docs-only; rebase if needed)
4. Do NOT Registrator; leave `.worktrees/` alone

OPEN GATES:
- No Registrator / General (D-111)
- Do not dump AGENTS fence commits

RESUME:
```
You are DRM.jl Cursor lane — SCOPED Phase 1.0 remainder. RESUME.
READ FIRST: LOOP/GOAL.md → LOOP/checkpoint.md → docs/dev-log/plans/2026-08-01-natgrad-decision-gate.md.
WORKSPACE: feat/phase10-scoped-13-jet (S0 FAIL → S1b lc_metric + JET + park docs).
CONTINUE FROM: S4 Pkg.test smoke → push/PR → close issues.
FENCE: D-111 no Registrator; no FULL experimental dump; leave .worktrees alone.
```
