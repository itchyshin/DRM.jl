GOAL: see GOAL.md (G0 APPROVED 2026-08-03 for #372).
STATE: Arcs 0–2 verified; Arc 3 PR close next (rebase onto main if #371 merged).
ARCS DONE (verified):
  - Arc 0: smoke both arms gaussian-locscale; probe md retained
  - Arc 1: six cells both arms measured; evidence md + TOML/JSON retained
  - Arc 2: r-julia-bridge.md matches artifact; check-log.d; after-task; Rose PASS
ARC IN PROGRESS: Arc 3 — push + `gh pr create` closes #372
NEXT: rebase onto origin/main if #371 merged; else open PR from current tip
  (includes #370 commits until #371 lands) or wait briefly for merge watcher.
OPEN GATES (need human): none for reversible work; #371 merge still external.
TRUTH LIVES IN: branch `feat/372-six-cell-measured-timing`;
  `docs/dev-log/evidence/2026-08-03-372-six-cell-timing.md`;
  after-task `docs/dev-log/after-task/2026-08-03-372-six-cell-measured-timing.md`.
RESUME: `/goal` Arc 3 PR close #372; leave `.worktrees/` alone.
Leave `.worktrees/` alone.
