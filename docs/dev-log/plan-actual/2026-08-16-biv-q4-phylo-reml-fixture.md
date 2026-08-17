# Plan vs actual — biv_q4_phylo_reml fixture (2026-08-16)

## Shipped vs plan

| Plan | Actual |
|---|---|
| New scratch lane from origin/main | `claude/lane-biv-q4-phylo-reml` @ worktree `DRM.jl-biv-q4-phylo-reml` (lane_launch failed in sandbox; worktree added by hand to the same path/branch) |
| One issue → one PR | #433 |
| Mac-only p≈16, nrep≈5 | p=16; first five n_each=5 seeds were TMB `conv=1`; **n_each=8 seed 20260822** converged. Recorded. No Totoro. |
| Standalone test; no `runtests.jl` | held |
| coef + logLik + CI/status | held. Wald on TMB was non-finite → `interval_status=wald_unavailable` |
| `[tol]` start 1e-3 | **widened to measured gap** after Julia re-fit (d_loglik ≈ −5.63; max \|d_coef\| ≈ 0.032) |
| HANDS TO Codex if toolchain stalls | **not used** — local R 4.6.0 + drmTMB 0.7.0 + Julia 1.10 ran |

## Drift / honesty

The plan implied a tight same-target numeric twin. Measured reality: native TMB
REML restricts **mean** FE; Julia `reml_q4` profiles **mean and scale**. That is
why logLik is not a 1e-3 match. The PR declares that tolerance instead of
claiming a Workflow G-style twin.

Julia `is_converged` is **false** on this cell at a stable point (same numbers
at 300 and 800 iterations). Recorded as `julia_converged = false`. Not treated
as a `src/` bug (no HANDS TO Claude / new G0).

## Not done (fence held)

TSV `supported`. `runtests.jl`. `src/`. Coverage. AI-REML. Bridge rewrite.
`#136` close. D-111. drmTMB checkout.
