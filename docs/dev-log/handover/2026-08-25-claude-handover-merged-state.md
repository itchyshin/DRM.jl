# Handover — everything merged; boundary investigation in flight

**Date:** 2026-08-25 · **Platform:** Claude Code (Shannon) · **Supersedes the branch handover's status lines.**

## Landed state (verify first, trust second)

| repo | main | note |
|---|---|---|
| DRM.jl | `d3e0acd7` | PR #485 merged (106 commits) |
| drmTMB | `6aa541714` | PRs #1080, #1082, #1084 merged |

`parity_ledger.py` → **CLOSURE: PASS**, `2 covered · 7 partial · 1 experimental · 1 unsupported`.
Local suite was 325/0/0 on the merged tree; CI green on Julia 1.10 **and** 1.12.

## What shipped

- **#460 (the headline)** — profile + bootstrap CIs reachable through `engine = "julia"`; verified live
  end-to-end (`fixef:mu:x` profile `[0.3853512, 0.5717354]`, bootstrap `[0.4021655, 0.5696364]`, both
  previously refused outright).
- **Interval coverage MEASURED** on the complete grid — Cell U 3×1000, Cell B **1000/1000**. Both
  `coverage_claimed` fences deliberately **left up**; the measurement argues for keeping them.
- **#493, #494 fixed** — the two solver bugs the campaign found.
- **#477** REML normalisation unified; q4 parity gate tightened **185×** (atol 5.5436 → 0.03).
- **#492** `poly()` landed, closing the bridge-formula group.
- The capability ledger **moved to its source of truth** (`R/julia-bridge.R`) — it is a *generated*
  artifact and hand-edits get wiped by regeneration.

## Open issues, all pre-existing unless noted

| # | what | status |
|---|---|---|
| 495 | phylocov covariance SEs are *uninformative* (`corr(\|err\|,SE)` 0.03 vs 0.70) | open |
| 496 | scale-axis variance bias 1.85 (~1.5 SD), measured small-sample ≈1/N | open |
| 497 | convergence *degrades* with N: 97.0 → 96.3 → 83.7 % | open |
| 498 | Poisson phylo Laplace collapses on Julia 1.12, not 1.10 (σ̂ 3e-04 vs truth 0.45) | open |
| 499 | intermittent `DomainError(log of -1.0)` on Gaussian `(1\|g)` REML; **confirmed flaky** (pass→fail→pass, unchanged commit) | open |

## IN FLIGHT at handover time

A Workflow (`boundary-weakness-investigation`, run `wf_532cbc5c-409`) is investigating whether **#496,
#498 and #499 share one boundary-handling mechanism** or are three separate bugs. Three parallel
root-cause agents plus an adversarial synthesis instructed to *refute* the shared-cause hypothesis if it
does not hold. Results land as a task notification; the transcript is under
`~/.claude/projects/.../subagents/workflows/wf_532cbc5c-409/journal.jsonl`.

Known before it started: `_LAPLACE_LOG_SD_FLOOR = log(1e-6)` exists **only** in
`sparse_laplace_glmm.jl` — it is *not* shared with `reml_q4.jl` or `gaussian_ranef.jl`, and #498's
collapse (σ̂ ≈ 3e-04) sits two orders **above** it. So a shared floor is already ruled out as the
explanation.

## Owner decisions still outstanding

1. **The Phase 1.5 cap** — `base_gaussian_location_scale`, `biv_gaussian_residual`,
   `gaussian_phylo_mean` carry `covered`-grade evidence but are held by
   `tests/testthat/test-julia-gate-vs-engine.R:205`, a CRAN-facing constraint tied to D-164. Evidence is
   not the blocker; permission is.
2. **#473** — whether to reinstall drmTMB (moves the comparator under every banked parity number).
3. Whether the boundary work above becomes one fix or three.

## Resume

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-25-claude-handover-merged-state.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```
