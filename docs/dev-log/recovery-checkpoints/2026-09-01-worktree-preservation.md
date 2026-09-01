# Worktree and stash preservation receipt — 2026-09-01

## Scope and source stamp

This is a read-only preservation inventory, run from DRM.jl `origin/main`
`d6519d2144509a57b5c8290cfaec9673ce9b691d` and the current drmTMB checkout.
It authorizes no deletion, reset, stash drop, worktree prune, branch deletion, or
mutation of another lane.

## DRM.jl

`git worktree prune --dry-run` identifies 11 stale *administrative registrations*:
`wt503`, `drm-suite-wt`, `wt-handover`, `mainsrc`, `wt491`, `wt499`, `wt497`,
`wt503b`, `wt495`, `wt-parm`, and `wt-newton`. Each says its gitdir points to a
non-existent location. The corresponding working directories are absent, so these
are candidates for a later `git worktree prune`, not recoverable content.

The registered worktree list also contains active current parity/profile/documentation
lanes and many historical Claude/Cursor lanes. They are preserved. In particular,
no conclusion about a branch follows from its age or its worktree registration.

Nine DRM.jl stashes remain preserved without classification:

1. `Cursor: moved local changes to cloud agent` (two records, 2026-08-03)
2. `phase10 LOOP WIP`
3. `temp-untracked`
4. `wip-before-claim-drift`
5. `temp ultra-plan dirty`
6. `wip .gitignore`
7. `WIP on shannon/s3-robust`
8. `resume-status-ledger-cleanup`

The two Cursor records and all remaining stashes require an item-by-item patch
comparison before a retention or disposal decision. They must not be dropped as a
batch.

## drmTMB

`git worktree prune --dry-run` identifies one stale administrative registration:
`drmtmb-promote`, whose gitdir points to a non-existent location. It is a candidate
for a later narrow administrative prune only.

Nine drmTMB stashes remain preserved. `stash@{2026-08-24 18:30:52 -0600}`
(`wip-460-fixef-routing-stale-base`) is a priority comparison item because it
touches historical Julia inference routing. The remaining eight stashes are also
unclassified and retained: NB2 wave-two work, foreign check-log material, binary
separation work, two provenance/workflow helpers, a phase-18 follow-on patch, and
two bivariate profile/sigma covariance safety stashes.

The dirty `drmTMB-rose-nit` worktree remains explicitly protected. It is not a
cleanup target; broad changes there require a source comparison before any action.

## Required next action

1. Compare each stash and dirty worktree against current `origin/main` in an
   isolated scratch location; record unique files and a disposition.
2. Obtain a focused decision for each non-empty patch.
3. Only then run a dry-run-repeated, administrative-only `git worktree prune` for
   registrations with confirmed absent directories. Never combine it with branch or
   stash deletion.

This receipt is evidence of preservation, not proof that recovery is complete.
