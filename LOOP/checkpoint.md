GOAL: see GOAL.md.   STATE: S2 PR #340 open (ayumi→main); CI pending; OPEN GATE = merge to main.

ARCS DONE (verified):
- S1 Merge #339 — MERGED @ 7cb868d on shannon/ayumi-integration
- S2 merge commit on branch — `4bce123` Merge ayumi into main tip; AGENTS fence commits absent; PR https://github.com/itchyshin/DRM.jl/pull/340

ARC IN PROGRESS: S2 — PR #340 (base main). CI test (1) + test (1.10) pending. mergeable=MERGEABLE, mergeStateStatus=UNSTABLE until checks finish.

NEXT: Wait for CI green on #340; then STOP for Shinichi merge-to-main OK. After merge: S3 scoped hygiene on main tip. Do not Registrator (S4 gate).

OPEN GATES (need human):
- Merge PR #340 into main (after CI green)
- S4 Registrator submit — later

TRUTH LIVES IN:
- LOOP/GOAL.md (Q2 SCOPED)
- .worktrees/ayumi-main-integrate @ shannon/ayumi-main-integrate
- PR #340
- origin/main @ edd9965 until merge

RESUME:
```
You are DRM.jl registry→bridge lane — running LOOP goal. RESUME.
READ FIRST: LOOP/GOAL.md → LOOP/checkpoint.md → LOOP/ultra-plan.md → AGENTS.md.
WORKSPACE: .worktrees/ayumi-main-integrate on shannon/ayumi-main-integrate; PR #340.
CONTINUE FROM: if CI green and Shinichi OK → merge #340; else wait/fix CI. Then S3 scoped hygiene. Q2=SCOPED. DEFER #136 #291 #13. Fence AGENTS commits.
Pause at: merge to main; S4 Registrator; public claims.
```
