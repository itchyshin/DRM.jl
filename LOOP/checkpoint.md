GOAL: see GOAL.md (#202 locscale closeout). STATE: MID-FLIGHT — S1 code landed; VERIFY not run.
ARCS DONE (verified):
  SCAFFOLD — LOOP + ultra-plan @ 3addf4aa
  RECON — A errors; B parses :phylo but needed tree= forward; B-iid fits
  S1 (code) — tree=/K=/A=/coords= forward in nb2+gamma; stale #209 comment fixed;
    public test file added — NOT yet verified by Julia log
ARCS DONE (unverified / do not claim): S2 recovery/FD green
ARC IN PROGRESS: none (handover)
NEXT: checkout feat/202-locscale-closeout; run test/test_public_phylo_locscale.jl;
  then S3–S4 docs + PR (L2 merge gate)
OPEN GATES (need human): merge of DoD PR after green verify
TRUTH LIVES IN: branch feat/202-locscale-closeout (push required);
  docs/dev-log/handover/2026-08-05-cursor-handover-202-locscale-closeout.md
RESUME: Read LOOP/GOAL.md → LOOP/checkpoint.md → handover. Continue NEXT.
  Never stage .worktrees/. Grammar B locked. No q=4 core.
