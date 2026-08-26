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

## The boundary investigation — DONE, hypothesis REFUTED

A 4-agent workflow investigated whether #496/#498/#499 shared one boundary-handling mechanism.
**They do not.** Three unrelated defects that share a symptom vocabulary but not a mechanism, a code
path, a parameter direction, or a fix. The decisive point: **#499 fails at variance → ∞**
(σb² ≈ 8×10¹³) while the other two fail at variance → 0 — opposite tails, so no single
"boundary weakness" can describe both.

| # | what it actually is | outcome |
|---|---|---|
| 496 | O(1/N) small-sample bias; tracks **Cholesky depth**, not mean-vs-scale (L22 is a *mean* axis and already jumps 3×) | documented — [PR #502](https://github.com/itchyshin/DRM.jl/pull/502) |
| 498 | **not a `src/` defect** — `MersenneTwister` is not stream-stable 1.10→1.12, so "seed 450" meant different data | fixed — [PR #501](https://github.com/itchyshin/DRM.jl/pull/501) |
| 499 | real crash: `Xμ′V⁻¹Xμ` formed by Woodbury **subtraction** rounds to a negative determinant | fixed — [PR #500](https://github.com/itchyshin/DRM.jl/pull/500) |

Two findings worth carrying forward:

- **#499 is deterministic, not flaky.** It reproduces every time when a mean covariate is collinear
  with the grouping factor. The "intermittent CI failure / runner ULP noise" reading was wrong.
- **#498 is proven closed by cross-version measurement** (Totoro, same checkout, only Julia differs):
  StableRNG draws hash identically on 1.10.10 and 1.12.6, and the fits agree to **10 significant
  figures**. There is no version-dependent numerical behaviour in `src/`.

Also learned, and worth not repeating: the first #499 fix returned `+Inf` on the non-PD case, which
merely traded `DomainError` for `AssertionError` — LBFGS's HagerZhang line search asserts
`isfinite(phi_c)`. It needed a large *finite* barrier. **The reproducer caught that; reasoning did
not.** Likewise the synthesis's second recommendation (a ±30 clamp on `lσb`) was dropped after
checking: the excursion is at `lσb ≈ 16`, inside that range, so it cannot be what fixes it.

## Superseded — was in flight at the previous checkpoint

A Workflow (`boundary-weakness-investigation`, run `wf_532cbc5c-409`) is investigating whether **#496,
#498 and #499 share one boundary-handling mechanism** or are three separate bugs. Three parallel
root-cause agents plus an adversarial synthesis instructed to *refute* the shared-cause hypothesis if it
does not hold. Results land as a task notification; the transcript is under
`~/.claude/projects/.../subagents/workflows/wf_532cbc5c-409/journal.jsonl`.

Known before it started: `_LAPLACE_LOG_SD_FLOOR = log(1e-6)` exists **only** in
`sparse_laplace_glmm.jl` — it is *not* shared with `reml_q4.jl` or `gaussian_ranef.jl`, and #498's
collapse (σ̂ ≈ 3e-04) sits two orders **above** it. So a shared floor is already ruled out as the
explanation.

## Session 2 (2026-08-25 evening) — four PRs open, all Julia 1.10 green

| PR | issue | what | verification |
|---|---|---|---|
| [#500](https://github.com/itchyshin/DRM.jl/pull/500) | 499 | PSD-safe REML restriction determinant | **full suite 325 testsets, 0 failures**; original throws on the new test |
| [#501](https://github.com/itchyshin/DRM.jl/pull/501) | 498 | StableRNG in the Cox–Reid generators | cross-version on Totoro: draws hash identically, fits agree to 10 s.f. |
| [#502](https://github.com/itchyshin/DRM.jl/pull/502) | 496 | documented as measured small-sample behaviour | docs job passes |
| [#504](https://github.com/itchyshin/DRM.jl/pull/504) | 497 | widened stall-restart trigger | **0/51 → 51/51**, both arms one ENV-switched build |

**New issue [#503](https://github.com/itchyshin/DRM.jl/issues/503)** — unguarded sparse Cholesky at
`reml_q2.jl:96` throws `PosDefException` at the definiteness boundary. Line 133 of the same file
already guards; one site was missed. Platform-sensitive: passes Julia 1.12.6 (Totoro), fails 1.12.7
(CI). **Deliberately NOT fixed** — there is no deterministic reproducer, and the failure path is
exactly what cannot be verified without one. Filing beats a plausible unverifiable guard.

**#503 is the only thing keeping #500's 1.12 job red.** Proven disjoint: `nll_reml` is a local
closure in `gaussian_ranef.jl` and nothing in `reml_q2.jl` references it.

### What #497 turned out to be (the most useful result)

Not a lying flag. `g_residual` (`g_tol = 1e-3`): converged median 0.00073, non-converged median
0.00338 — **all 51 above tolerance**, genuinely non-stationary. 51/51 terminate via `ls_failed`,
median 3 iterations, none hitting the 200-iteration cap.

The defect is that **the stall-restart cannot see them**. Its trigger is the exact equality
`minimizer(res) == phi0`; 180/249 (72%) of the *successes* depend on that restart, and 0/51 of the
failures ever match it because they move a few steps first. Widening it rescues all 51, and their
estimates shift only 0.04–0.21 SD — they were already at the answer.

Same signature at ntip=16/32/64, so N changes the **frequency**, not the mechanism.

### Hypotheses tested and REFUTED — do not re-derive these

1. *One shared boundary weakness across #496/#498/#499.* Three unrelated defects; #499 fails at
   variance → ∞, the others → 0.
2. *#498 is a Julia-version-dependent collapse.* No version-dependent behaviour exists; the RNG was
   not stream-stable, so the comparison was never like-for-like.
3. *#497 is a lying convergence flag (#491 class).* The flag is honest.
4. *The `Inf` barrier at `reml_q4.jl:381/383` causes #497's `ls_failed`.* Plumbing verified; the fit
   is **bit-identical** with a 1e6 barrier (`theta[end] = -1.057576`). It is never reached.

Still open on #497: what *does* make BackTracking fail on a finite objective. The finite-difference
gradient producing a non-descent direction is the obvious next hypothesis. **Untested.**

### Process notes worth not repeating

- Long jobs were twice run in a working tree something else was editing (once locally, once on
  Totoro). Use an isolated worktree / directory and a **unique log path** — two suites redirecting to
  one log truncated each other and produced misleading line counts.
- `pgrep -fc` is not valid on macOS; the flag error made a fallback print "finished" for a suite that
  was still running.
- 34 agent worktrees have accumulated under `.claude/worktrees/`.

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
