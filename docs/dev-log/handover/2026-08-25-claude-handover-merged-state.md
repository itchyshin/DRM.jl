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

### #503 — I filed it wrong; the correction is the finding

Filed as "unguarded sparse Cholesky throws PosDefException". **The throw is the SAFE branch.** Fixing
only it would have repaired the 772 cases that already failed safely and left 1654 that silently
return a finite likelihood computed from a wildly non-PD matrix (worst: `min_eig = -1.17e22`
returning `reml_loglik = -131.881`).

Root cause is upstream: `lc_to_cov` is PD by construction in exact arithmetic but numerically
singular at extreme log-Cholesky values — at `lc = [-25, 1, -25]`, `det(Λ) = -2.24e-38` (negative)
while `isposdef` still answers true. `inv(Λ)` is meaningless, `H_uu` inherits it, and LAPACK's `potrf`
notices only sometimes.

**CI's red was the machine behaving correctly.** Totoro's green was the dangerous branch.

Fix in [PR #505](https://github.com/itchyshin/DRM.jl/pull/505): reject inadmissible Λ before `inv(Λ)`
(`det > 0`, `cond < 1e12`), plus `check = false` at the flagged line as defence in depth.
Tree route only — the relmat route keeps a PD `D⁻¹` term on every block, which is why this hid.

| | non-PD H | silent finite | rejected | healthy |
|---|---|---|---|---|
| main | 2426 | **1654** | 772 | 2207 |
| guarded | 2426 | **0** | 2426 | **1407** |

The 2207 → 1407 is the cost: `cond` alone cannot separate ~800 extreme-but-benign Λ from the bad
ones. Real fits sit at `cond` 1.0–2.6 and every failure needs ≥1.6e17, so the threshold has nine
orders of headroom — but it is a behaviour change, and it is the number to push back on.

### Five PRs, all locally verified

| PR | issue | 1.10 CI | 1.12 CI | full suite |
|---|---|---|---|---|
| [#500](https://github.com/itchyshin/DRM.jl/pull/500) | 499 | pass | fail (#503) | 325 / 0 |
| [#501](https://github.com/itchyshin/DRM.jl/pull/501) | 498 | pass | **pass** | — |
| [#502](https://github.com/itchyshin/DRM.jl/pull/502) | 496 | pass | **pass** | — |
| [#504](https://github.com/itchyshin/DRM.jl/pull/504) | 497 | pass | **pass** | 325 / 0 |
| [#505](https://github.com/itchyshin/DRM.jl/pull/505) | 503 | pending | pending | 325 / 0 |

**None merged** — deliberately left for the owner. #505 changes behaviour for ~800 parameter
combinations and deserves a real read.

### Hypotheses tested and REFUTED — do not re-derive these

1. *One shared boundary weakness across #496/#498/#499.* Three unrelated defects; #499 fails at
   variance → ∞, the others → 0.
2. *#498 is a Julia-version-dependent collapse.* No version-dependent behaviour exists; the RNG was
   not stream-stable, so the comparison was never like-for-like.
3. *#497 is a lying convergence flag (#491 class).* The flag is honest.
4. *The `Inf` barrier at `reml_q4.jl:381/383` causes #497's `ls_failed`.* Plumbing verified; the fit
   is **bit-identical** with a 1e6 barrier (`theta[end] = -1.057576`). It is never reached.
5. *#503's unguarded Cholesky is the defect.* It is the safe branch; see above.

Also corrected: the honest #497 baseline is **238/300**, not 249/300 — 11 fits report
`converged = true` with `g_residual` above the requested `g_tol` (Optim stopped on the f-criterion).
That is a correctness bug in its own right and #504 fixes it too.

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

---

# Session 3 (2026-08-25 night) — merges, the cap lift, and an issue-ledger reckoning

## Merged to main

Four PRs, all fully green at merge: **#501** (#498 StableRNG), **#502** (#496 docs),
**#504** (#497 relaunch rescue), **#505** (#503 Λ guard). `main` is now `ca7c95cd`.

**#500** (#499 PSD-safe logdet) is rebased onto that and left unmerged at the owner's instruction —
its only failing check was #503, which #505 fixed, so its CI should now clear.

## The Phase 1.5 cap is lifted — drmTMB PR #1085

Owner decision. Three rows promoted `partial → covered`: `base_gaussian_location_scale`,
`biv_gaussian_residual`, `gaussian_phylo_mean`. **The ledger goes 2 → 5 covered of 10 admissible.**

Done at the SOURCE OF TRUTH (`R/julia-bridge.R`) with both TSV artifacts regenerated — the TSVs are
generated files and hand-editing them is how an earlier pass in this program lost a night's work.

The cap assertion was **inverted, not deleted**, so the decision is locked in and a reversion fails
loudly:

```r
was:  expect_true(all(phase15$claim_status %in% c("partial", "experimental")))
now:  expect_true(all(phase15$claim_status == "covered"))
```

**What it does NOT claim: interval coverage.** Every `interval_status` fence is unchanged. For
`gaussian_phylo_mean` the recorded interval-failure rate (313/1000 on sigma at ntip=16) stands, as
does its own note that *the failure rate, not the calibration, is what would block a coverage claim*.

Verified locally: all 16 julia-facing test files pass, FAIL 0; the gate file is 140 passes (up from 138).

## Issue-ledger reckoning — 11 issues closed, all verified by RUNNING something

The open-issue list was badly stale. Every closure below was checked behaviourally, not by reading code:

| # | what proved it |
|---|---|
| **460** *(the program's headline)* | profile `[0.3853512, 0.5717354]` and bootstrap `[0.4021655, 0.5696364]` through `engine="julia"`, both previously refused outright |
| 466 | Poisson reports `niterations = 5` (was `-1`) |
| 468 | coverage campaign complete — pre-run, certification, results + TSV all banked |
| 470 | `test_reml_q2_structured.jl` 34/34, covering both the feature and the boundary it asked to confirm |
| 477, 492, 493, 494 | code verified present on `main`; should have closed with PR #485 |
| 478 | both claim_boundary rewrites already landed; **no owner decision was needed after all** — nothing was narrowed, the AI-REML term moved from "required" to "explicitly outside" |
| 479 | Poisson-phylo bootstrap **25/25 successes** against a documented "fails every replicate" |
| 480 | formula-based surface likewise 25/25, no `MethodError` |
| 483 | fixture reseeded to 404; the retired seed-111 effect was IID noise, not phylogenetic at all |
| 484 | `test_parity_biv_q4_phylo_reml.jl` 33/33 — the exact cell it was filed against |
| 489 | `runparity.jl` exit 0, bridge-* fixtures all executing |

## Two reclassifications that change the roadmap

**#471 is not a catch-up item.** `biv_student()` in drmTMB *itself* raises *"currently allows
fixed-effect formulas only; random and structured effects are deferred"*. There is no reference
implementation on either side, so building this would put DRM.jl **ahead of** drmTMB, not level.
Relabel as beyond-parity/v1.0, and if built it needs simulation recovery rather than parity, since no
comparator exists.

**#467 is 6 of 6 done**, narrowed to one residual gap. `scale`/`I`/`factor`/`poly`/`(a+b)^k`/`- term`
all verified accepted with the coefficient counts R's expansion implies. `_BRIDGE_REJECT_CALLS` now
holds only `:^`, and only for a power over an expression containing `*`. What remains: materialised
columns are not reconstructed for `newdata` — it fails loudly, which is right, and matters most for
`poly` whose basis is defined relative to the training `x`.

## Where the catch-up actually stands

- **Features: caught up.** 0 export gaps (17/17 accounted), and DRM.jl is **ahead in 19 places**.
- **Evidence grade: 2 → 5 of 10 covered** once #1085 lands.
- The remainder is not "make it do more" — it is proving to `covered` standard what already works,
  and that is campaign work rather than code.

## In flight at write time

- Workflow `wf_237b7034-22c` on **#491** (sparse-Laplace `converged` flag). Two diagnosis agents
  done, fix agent running, branch `fix/491-laplace-converged` exists.
- CI on drmTMB #1085 and DRM.jl #500.

---

# Session 4 — the cap is LIFTED and merged; a fix of mine was incomplete

## Landed: 2 → 5 covered

**drmTMB `fc8ee77a6`** (PR #1085, merged). The parity ledger now reads:

```
0 export gaps (17/17) · 19 ahead-of-drmTMB
11 capability rows [5 covered · 4 partial · 1 experimental · 1 unsupported]
CLOSURE: PASS
```

`base_gaussian_location_scale`, `biv_gaussian_residual`, `gaussian_phylo_mean` promoted on evidence
they already had. Interval fences **unchanged** — `covered` is a capability claim, not a coverage one.

## #491 solved — and it IS the lying flag #497 was not

Two same-shaped questions, opposite answers, both settled by measuring the right gradient:

- `‖gfinal‖∞` is the gradient of the **summed** NLL, so it scales with n (1.085e-4 → 4.414e-4)
- the threshold `1e-4·(1+‖θ‖∞)` is **flat** at ~1.5e-4
- `g_tol·n`, written to compensate, is **8–32× too small to ever win the `max()`** — first binds at n ≈ 15,500
- per-observation gradient is flat (2.1–2.6e-7); restart from θ̂ moves < 1e-7
- **`Optim.converged(res)` is false at EVERY p including 128** — the fallback arithmetic alone decided
  the entire column

Fix (PR #506, branch `fix/491-laplace-converged`): normalise by n, matching the mean-objective
convention the q4 routes already use. Independently re-verified with a token control on both arms —
`beta1` **identical** (0.3131 / 0.2368 / 0.3293), only the boolean moves.

**Not fixed, flagged:** the `Optim.converged(res) && return true` short-circuit remains, and it makes
the flag anti-correlated with care (g_tol=1e-8 → false at 1.39e-07; g_tol=10 → true at 1.18e-03).
Removing it moves the boundary for every family on that path — owner's call, but now decidable
against numbers. Also flagged: a `q ≈ n` edge case (m=1) still reports false, bit-identically.

## My #503 fix was INCOMPLETE — PR #507

I claimed on #500 that #503 was its only blocker and #505 would clear it. **Wrong.** CI on 1.12.7
still threw with #505 merged, and the stacktrace names a **different site**: `coevo_marginal_cov`
(`coevolution_q.jl:233`) has its own unguarded `cholesky(Symmetric(H))` behind a *"PD: P + PSD data
term"* comment — the same by-construction claim #503 disproved elsewhere.

Two call sites in `reml_q2.jl` reach it unprotected: **line 197** (the existing `try` wrapped only
`_q2_profile_and_schur`) and **line 281** (the final evaluation). The Λ-admissibility guard does not
cover them — different matrix, so `cond < 1e12` protects nothing here.

**Verification limit, stated:** this does not reproduce on macOS 1.10 or Linux 1.12.6. Local tests can
only show no regression. **CI on 1.12 is the real test of #507.** If it goes green that is the
evidence; if not, there is a third site.

## Issue ledger: 28 → 17 open, 26 closed today

Every closure verified by running something. Highlights: **#460 (the program's headline)** — profile
`[0.3853512, 0.5717354]` and bootstrap `[0.4021655, 0.5696364]` through `engine="julia"`, both
previously refused; #479/#480 Poisson-phylo bootstrap 25/25 against "fails every replicate"; #484
33/33 on the exact cell it was filed against.

**Reclassified:** #471 is not a catch-up item (drmTMB's own `biv_student()` defers it too, so building
it moves *ahead*); #467 is 6-of-6 done, narrowed to `newdata` reconstruction; #473 narrowed to
coverage (2 of 21 fixtures record `drmtmb_code_hash`).

## Status board

`https://claude.ai/code/artifact/cabc9c81-95fe-4d0a-8b49-6bfd5943f57b` — the eleven rows, the two-axis
reading, and what is deliberately not claimed.

## Open PRs

| PR | what | state |
|---|---|---|
| #500 | #499 PSD-safe logdet | blocked on #507, not on itself; 1.10 green, suite 325/0 |
| #506 | #491 convergence normalisation | CI running |
| #507 | #503 follow-up guard | CI running — this is the one that unblocks #500 |

---

# Session 5 — #503 finally closed, at the source

## The whack-a-mole and what ended it

`coevo_marginal_cov` (`coevolution_q.jl:233`) had ONE unguarded `cholesky(Symmetric(H))` reached
from **three** call sites: `reml_q2.jl:197`, `reml_q2.jl:281`, `coevolution_q.jl:438`. I guarded them
one at a time and it took **two CI rounds** to find the third. Guarding the *source* covers all three
and any future caller. PR #507, merged — `main` is `0b8f561f`.

**The detail worth remembering:** that same function already applies this exact pattern twelve lines
below, to `chP`, with a comment explaining why an incomplete factor poisons the likelihood. That guard
was written and the one on `chH` was missed — which is *precisely* the shape of #503 itself, where
`reml_q2.jl` guarded `ch_S` and missed `chH`. The same slip twice in one subsystem. When you find one
unguarded factorisation here, grep for its siblings before fixing it.

## First local reproduction, with a two-way positive control

Earlier rounds could only be tested through CI, because the failing Λ is one a converging optimiser
rarely visits. Calling `coevo_marginal_cov` directly reaches it deterministically:

| Λ | cond | main | guarded |
|---|---|---|---|
| healthy | 1 | −133.203 | −133.203 |
| singular | 3.24e+26 | **THREW PosDefException** | **−Inf** |
| Λ → ∞ | 1 | −153.965 | −153.965 |

Healthy fits bit-identical; only the failing case moves, to the barrier the callers already expect.
Full suite on that commit: **325 testsets, 0 failures.** CI green on Julia 1.12.7 — the platform that
had been failing.

## Also swept, so this is not a fourth-site risk

Audited every `cholesky(` in `src/` without `check = false`. The rest are benign — simulation code
with known-PD inputs (`fit_ml_q4.jl`, `sparse_em_fit.jl`), or live paths that already handle failure
(`location_only.jl:193/195` ridge-and-retry, `sparse_aug_plsm.jl:158` finite surrogate).

## State

| PR | what | state |
|---|---|---|
| **#506** | #491 convergence normalisation | **fully green, HELD** — changes the criterion for every family on the sparse-Laplace path; wants an owner read |
| #500 | #499 PSD-safe logdet | CI re-running now that it carries #507 |

Issues **28 → 16 open**, 27 closed. #496 closed as documented-not-patched (its docs page shipped in
#502 and is live on `main`).

## In flight

Workflow `wf_7d269f3d-43c` on **#495** — profile-vs-Wald on the same fits, to test whether the
phylocov miscalibration is a Wald-on-nonlinear-reparameterisation artefact. **D-139 gate is built into
the workflow**: its first phase measures seconds/rep and returns GO or NO-GO with a budget, so it will
not launch a long campaign while the owner is asleep. If NO-GO it reports the number that *would*
answer it.
