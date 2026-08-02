GOAL: see GOAL.md (SCOPED Phase 1.0 — **CLOSED**). STATE: tip **IDLE** on `origin/main` @ `e6c3eef` (#359 merged). #13 FAIL → lc_metric + JET; #13/#338/#3 CLOSED. Tip-honesty #358 + drmTMB #887 merged. D-111 General OUT.

START HERE: `docs/dev-log/handover/2026-08-02-cursor-handover.md`
(supersedes 2026-08-01-cursor-handover.md pointer).

ARCS DONE:
- Phase 1.5 / registry→bridge (#5, #349, drmTMB #878; D-111; Melissa S8)
- Tip-honesty #358 + drmTMB #887
- S0 #13 gate — FAIL (ng −259.795539 vs ref −256.512618)
- S1b — `src/lc_metric.jl` + tests; no `:natgrad`
- S2 — JET Q gate; ROADMAP Q ticks
- S3 — park docs; #338 close via PR
- S4 — local smoke lc_metric + JET OK
- S5 Rose PASS; Melissa plan-actual
- #359 merge — closes #13 / #338 / #3

ARC IN PROGRESS: **none** on DRM.jl (idle tip).

NEXT:
1. Prefer idle on DRM.jl — do not invent ship work
2. New goal/arc only if Shinichi opens it — owner said **different lane**
3. Do NOT Registrator; leave `.worktrees/` alone
4. Do not dump AGENTS fence commits; Melissa stays hub-only

OPEN GATES (need human):
- None for Registrator (cancelled — do **not** ask for app install)
- Public claims stay experimental for bridge

RESUME:
```
You are DRM.jl Cursor lane after Phase 1.0 SCOPED closeout. Tip IDLE.
READ FIRST: AGENTS.md → docs/dev-log/handover/2026-08-02-cursor-handover.md → LOOP/checkpoint.md.
WORKSPACE: origin/main @ e6c3eef (+ handover PR if open).
CONTINUE FROM: idle; new arc only if Shinichi opens a different lane.
FENCE: D-111 no Registrator; leave .worktrees alone; no AGENTS fence dumps; no :natgrad.
#13 VERDICT: FAIL — lc_metric infra only (not public solver).
```
