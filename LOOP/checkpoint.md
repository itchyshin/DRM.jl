GOAL: see GOAL.md (G0 APPROVED 2026-08-03 for #372).
STATE: Arcs 0–3 landed — PR #373 open (closes #372), stacked on #371 base.
ARCS DONE (verified):
  - Arc 0: smoke both arms; probe md retained
  - Arc 1: six cells both arms measured; evidence md + TOML/JSON retained
  - Arc 2: bridge docs match; check-log.d; after-task; Rose PASS
  - Arc 3: PR https://github.com/itchyshin/DRM.jl/pull/373
ARC IN PROGRESS: none (await CI / #371 merge then retarget base → main).
NEXT: after #371 merges, `gh pr edit 373 --base main`; merge when green.
OPEN GATES (need human): merge of #371 (external); then merge #373.
TRUTH LIVES IN: `feat/372-six-cell-measured-timing` @ 70c456e;
  PR #373; `docs/dev-log/evidence/2026-08-03-372-six-cell-timing.md`.
RESUME: watch #371 merge → retarget #373 to main → merge #373.
Leave `.worktrees/` alone.
