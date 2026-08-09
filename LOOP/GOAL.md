# GOAL — drm-136-va-rung2-3 (IMMUTABLE — re-read at the top of EVERY arc)
Read this first, every cycle. Auto-compact eats messages, not this file. Unsure after a compaction?
Re-read THIS, then checkpoint.md, then continue.

## Mission
One PR from tip `origin/main` @ `fbbb8a56` (PR #400 merged): Rung 2 promote
scaffold `@test_skip` anchors a/b/c where true; finish mixed-marginal AIC/LRT
guard. Rung 3 docs honesty — public VA is **Experimental** for Poisson +
Binomial + NB2 + Gamma + Beta `(1 | g)`. Issue **#136 stays OPEN**. Do **not**
start 136e / Rung 4. Do **not** start drmTMB `engine="julia"`.

## Headline
Promote true anchors; do not fake-pass; banners match tip after #399+#400.

## Invariants
- One lane; branch `feat/136-va-rung2-3` from `origin/main` @ `fbbb8a56`.
- Fence: no q=4 core rewrite; ML default; no close #136; #49 parked; no R-bridge;
  never stage `.worktrees/`; no GPL vendoring; no 136e bias report; no kernel
  rewrite; no ZI/phylo/crossed/corr public VA; no merge.
- Opening PR = OK. **Do not merge.** OPEN GATE = owner + Noether sign-off.
- ELBO ≠ logLik; verify by LOG not exit code.

## Definition of done
- Scaffold a/b/c promoted or honestly still skipped
- Mixed AIC/LRT guard complete (`aicc` VA-first; NB2 public mixed test)
- capabilities.md + marginal-la-vs-va.md Experimental (not Planned-only stub)
- check-log.d + after-task; Rose PASS; PR does **not** `closes #136`
