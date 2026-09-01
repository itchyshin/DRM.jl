# Worktree preservation receipt

## 1. Goal
Create a source-stamped, preservation-first recovery receipt for DRM.jl and drmTMB without discarding unfinished work.

## 2. Implemented
Recorded stale administrative worktree registrations, active-lane protection, preserved stash sets, the protected `drmTMB-rose-nit` worktree, and the next item-by-item comparison sequence.

## 3. Decisions and rejected alternatives
No `git worktree prune`, stash drop, reset, branch deletion, or mass cleanup ran. A dry-run result is not treated as authorization to remove content.

## 4. Files touched
Only the recovery receipt and its check-log/after-task evidence files.

## 5. Checks run
Ran `git worktree list --porcelain`, `git worktree prune --dry-run`, and `git stash list --date=iso` for both repositories. `git diff --check` passed.

## 6. Tests of the checks
The inventory combines registered worktrees, prunable markers, and stash metadata; a missing filesystem path alone was not used to classify a branch or stash as disposable.

## 7. Issue ledger
Programme recovery gate remains open. No user-visible issue was closed and no collaborator communication was sent.

## 8. Consistency audit
The receipt distinguishes stale Git administrative registrations from working trees, stashes, and dirty prototype work. It preserves all three categories until a patch-level comparison supplies stronger evidence.

## 9. What did not go smoothly
The repositories contain many historical worktrees from several agent systems. That is why this slice records a safe denominator rather than attempting a broad cleanup.

## 10. Known residuals
Every stash and dirty worktree still needs an individual comparison/disposition. The administrative prune is deferred pending those receipts.

## 11. Team learning
Worktree counts measure accumulated activity, not unfinished feature count. Cleanup must start with preservation evidence and remain narrower than the inventory.
