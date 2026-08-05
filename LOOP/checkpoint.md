GOAL: see GOAL.md (#202 locscale closeout). STATE: READY FOR PR — S2 green; S3–S4 docs landed.
ARCS DONE (verified):
  SCAFFOLD — LOOP + ultra-plan @ 3addf4aa
  RECON — A errors; B parses :phylo; tree= forward was the gap
  S1 — tree=/K=/A=/coords= forward; stale #209 comment fixed; public test added
  S2 — test_public_phylo_locscale.jl 13/13 (54.2s); NB2 draw uses ψ=logσ
  S3 — Gamma public smoke in same test
  S4 — capability-status row + tutorial + NEWS; DoD artifacts
ARCS DONE (unverified / do not claim): owner merge; R nbinom2-locscale fixture
ARC IN PROGRESS: none — open PR closes #202; pause for L2 merge
NEXT: gh pr create; wait owner merge; tip-idle refresh only if owner asks
OPEN GATES (need human): merge of DoD PR (L2)
TRUTH LIVES IN: branch feat/202-locscale-closeout;
  docs/dev-log/after-task/2026-08-05-202-locscale-closeout.md
RESUME: if PR open, watch CI + owner merge. Never stage .worktrees/. Grammar B locked.
