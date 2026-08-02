GOAL: see GOAL.md. STATE: SCOPED Phase 1.0 **PR open** — #359. S0 **FAIL** → S1b lc_metric + JET + park docs @ `e7de946` (+ tip checkpoint). Tip-honesty **merged** (#358 DRM.jl, #887 drmTMB).

ARCS DONE:
- S0 #13 gate — FAIL (ng −259.795539 vs ref −256.512618)
- S1b — `src/lc_metric.jl` + tests; no `:natgrad`
- S2 — JET Q gate; ROADMAP Q ticks
- S3 — park docs; #338 close via PR
- S4 — local smoke lc_metric 5/5 + JET OK
- S5 Rose PASS; Melissa plan-actual filed
- Tip-honesty — #358 + drmTMB #887 merged onto main

ARC IN PROGRESS: CI on PR #359 (rebased/merged with tip-honesty main).

NEXT:
1. Watch CI on https://github.com/itchyshin/DRM.jl/pull/359
2. Merge #359 when green → issues #13/#338/#3 close via PR
3. Do NOT Registrator; leave `.worktrees/` alone
4. Do not dump AGENTS fence commits; Melissa stays hub-only

OPEN GATES (need human):
- None for Registrator (cancelled — do **not** ask for app install)
- Public claims stay experimental for bridge

RESUME:
```
You are DRM.jl Cursor lane after SCOPED Phase 1.0 remainder PR. RESUME.
READ FIRST: LOOP/GOAL.md → LOOP/checkpoint.md → docs/dev-log/plans/2026-08-01-natgrad-decision-gate.md.
WORKSPACE: feat/phase10-scoped-13-jet; PR https://github.com/itchyshin/DRM.jl/pull/359 (#13 FAIL → lc_metric + JET; closes #13 #338 #3).
CONTINUE FROM: watch CI on #359 after tip-honesty merge; merge #359 when green.
FENCE: D-111 no Registrator; leave .worktrees alone; no AGENTS fence dumps.
#13 VERDICT: FAIL — wired lc_metric infra only (not :natgrad).
```
