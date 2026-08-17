# Plan vs actual — gaussian_phylo_mean Route A fixture (2026-08-17)

## Shipped vs plan

| Plan | Actual |
|---|---|
| New scratch lane from origin/main | `claude/lane-gaussian-phylo-mean` @ `~/local-scratch/lanes/DRM.jl-gaussian-phylo-mean`. `lane_launch.sh` failed twice (sandbox, then leftover branch from the failed add). Worktree attached to that leftover branch at `origin/main` `5ddaffa9`. Did not reuse catchup / biv-q4 / arc1-backlog / Dropbox leftover. |
| One issue → one PR | #437 |
| Mac-small; prefer Route A clone n_tip=18 seed 111 | **Held.** First TMB attempt conv=0, logLik −13.268. No reseed. |
| Standalone test; no `runtests.jl` | held |
| Tight ML tols, not `atol_loglik=6` | held: 1e-6 / 1e-5. Measured d_loglik ≈ −2.7e-9; max \|d_coef\| ≈ 8.5e-9 |
| Sibling S1 / S2 / S5 | S1 + S5 + morning fence consumed from catchup and copied into this worktree. S2 schema written here (sibling S2 file never appeared). |
| HANDS TO Codex if toolchain stalls | **not used** — local R + drmTMB 0.7.0 + Julia 1.10 ran |
| New LOOP kit committed | **Local only.** `LOOP/` is already on `origin/main` (leftover campaign). This PR does **not** overwrite it (fixture-only merge condition). |

## Drift / honesty

No numeric surprise. Unlike #434, this ML Route A cell is a tight twin.
The Julia tree-height / `sd_phylo` scale warning is recorded; FE+logLik
comparison does not use that scale.

## Not done (fence held)

TSV `supported`. `runtests.jl`. `src/`. `sigma ~ phylo`. `#136` close.
`#49` unpark. D-111. drmTMB checkout. "parity complete." "last fixture-gap."
`#432` taxonomy rewrite.

## Fence correction

First commit accidentally included catchup `2026-08-17-morning-rose-fence.md`. Removed in a follow-up commit so the PR stays on the allowed path list.
