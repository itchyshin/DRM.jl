# Plan vs actual — Arc 1 backlog refresh after #434 (2026-08-16)

## Shipped vs plan

| Plan | Actual |
|---|---|
| New scratch via `lane_launch.sh DRM.jl arc1-backlog-after-434` | `claude/lane-arc1-backlog-after-434` @ `~/local-scratch/lanes/DRM.jl-arc1-backlog-after-434` from `origin/main` |
| Do not use catchup / leftover #434 / Dropbox `docs/a3c-design` | held |
| New LOOP kit | held (`LOOP/{GOAL,arcs,checkpoint,ultra-plan}.md`) |
| One issue → one PR | #435 |
| Rewrite ordered backlog: fixture banked; still `partial`; drop recommended implement | held |
| New after-task + check-log; do not edit #432 after-task in place | held |
| Rose fence copied; no new recommended implement | held |
| Mechanical: 11 IDs once; stale NONE gone; no src/ / runtests / TSV | held |
| Defer `runtests.jl` include | held |
| Stop after this PR | held — no implement row started |

## Drift / honesty

Morning restart (2026-08-17): leftover scratch was dirty/behind; used
the already-opened PR #436 rather than a second `lane_launch.sh`.
Wait-gate prose still listed `#425` as a live `runtests.jl` owner;
corrected to `#423`+`#428` (`#425` merged). No new recommended
implement named (`gaussian_phylo_mean` stays an unsigned TSV-claim
row only). Overnight/morning authority: `gh pr merge --merge` if CI
green and docs-only.

## Not done (fence held)

TSV `supported`. `runtests.jl`. `src/`. New recommended implement.
`#136` close. `#49` unpark. `#428` steal. D-111. drmTMB checkout.
`capability-status.md`. `Pkg.test`.
