GOAL: see GOAL.md.   STATE: verify green; DoD artifacts written; awaiting PR open.
ARCS DONE (verified):
  Arc0 — issue #383; drm_bridge smoke 4/4 PASS (no scale-risk)
  Rung1 — generators + fixtures (drmTMB 0.6.0 meta); DRM_PARITY_ONLY used
  Rung2 — cohort+family wire; native 10+xfam skip, bridge 10/10 (log read)
  Docs — r-julia-bridge.md + parity README/GENERATING
  Under#186 — epic CLOSED (ledger; #187–#189 already CLOSED)
  Closeout DoD — check-log.d + after-task + Rose table written
ARC IN PROGRESS: Closeout PR (OPEN GATE: open PR; merge = owner)
NEXT: commit implementation + open PR closes #383
OPEN GATES (need human): merge to main (owner may merge after review)
TRUTH LIVES IN: branch feat/r-parity-plus4-fe-bridge; fixtures test/parity/fixtures/{count-poisson,positive-gamma,binomial-trials,positive-lognormal}/; /tmp/drm-parity-full.log
RESUME: You are DRM.jl +4 FE R-parity lane — RESUME. READ FIRST: LOOP/GOAL.md -> LOOP/checkpoint.md -> LOOP/ultra-plan.md. WORKSPACE: feat/r-parity-plus4-fe-bridge. CONTINUE FROM: commit + gh pr create closes #383. Pause at merge (owner).
