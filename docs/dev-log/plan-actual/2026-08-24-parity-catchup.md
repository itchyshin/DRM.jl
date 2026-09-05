# Plan vs actual — R↔Julia parity catch-up (2026-08-24)

**Reconciler:** Melissa · **Plan:** `~/.claude/plans/deep-inventing-bubble.md`
**Branch:** `parity/se-axis` · **Issue:** #457 · **PR:** #458

Material deviations only, across the six axes. Each tagged **adaptive** (justified
and recorded — not a defect), **drift** (unjustified), or **unclear**. Cosmetic
differences are not drift.

## 1. Scope

| planned | actual | tag |
|---|---|---|
| Measure every capability whose only blocker is measurement | Done, plus **three engine defects fixed** (#459, #461, #462) | **adaptive** |
| Waves 1–4, ~7–8h, 9 sub-agents | Waves 1–4 as planned; Waves 5–6 added for the defects | **adaptive** |
| "Evidence, not repair" | Repairs made | **adaptive** |

The plan said explicitly *"no engine work"*. That was breached, and it was right to
breach it: the measurement surfaced defects that made the measured quantity
meaningless. You cannot report a bootstrap interval and also decline to notice the
bootstrap is broken. Owner directed each repair (#459 "fix it", #461 "clearly
broken", then "keep going"). **Adaptive, not drift** — but it is the single largest
departure from the approved plan and is recorded as such.

## 2. Evidence and verification

| planned | actual | tag |
|---|---|---|
| Every new checker made to fail before trusted | Held throughout — SE comparator, cross-check, `[tol]` preservation, #459/#461/#462 tests, dep checker | ✅ |
| Full local suite | 304 testsets, zero failures at HEAD | ✅ |
| Adversarial refutation pass | Done — 38 SE/vcov pairs at exactly 0.0 | ✅ |
| Benchmarks on a quiet machine | Run on a **not-quite-idle** machine (1 core busy, 19 free), conditions recorded | **adaptive** |

One process failure worth recording: **the local suite passed while CI failed.**
A new test file imported `StatsModels`, undeclared in `test/Project.toml`. Local
runs resolve from the Manifest; `Pkg.test()` builds a fresh env from Project.toml.
`tools/check_test_deps.py` now closes that gap, verified both ways. **drift → fixed**,
and the fix is a tool rather than a note, so it cannot recur silently.

## 3. Model routing

| planned | actual | tag |
|---|---|---|
| W2-A on Fable (design slice) | Fable | ✅ |
| Builds on Sonnet | Sonnet | ✅ |
| W4-A adversarial on Opus | **Not dispatched** — refutation run inline by the orchestrator | **adaptive** |
| ≤6 children, ≤1 ceiling per checkpoint | 6 in wave 2 (1 ceiling), 2 in wave 3 | ✅ |

The Opus verifier was folded into inline work. Defensible — the refutation was a
single targeted numerical test, not a review needing fresh context — but it means
**no fully independent agent reviewed the final state**. Recorded as a known
weakness rather than claimed as equivalent.

## 4. Safety gates

| gate | outcome |
|---|---|
| drmTMB untouched (CRAN quiesce) | ✅ dirty-set hash identical to baseline throughout |
| No coverage claim | ✅ both `interval_status != "coverage_claimed"` fences intact |
| No capability row promoted to `supported` | ✅ |
| #49 / #136 / D-111 / #420 / #406 untouched | ✅ |
| `.codex/agents/shannon-coordinator.toml` PROTECTED | ✅ never staged |
| Acceptance ledger | 25 gates, all met, none abandoned |

No safety-gate drift.

## 5. Public claims

| claim | status |
|---|---|
| Single-fit 2.2–12.5× faster | Measured, scoped to 10 cells at n≤1000/p≤40, caveats stated |
| "Better optimizers" | **Explicitly not claimed** — ~8 vs 5–15 iterations says per-iteration cost |
| Bootstrap speed | **Not claimed** — correctness took precedence |
| Interval coverage | **Not claimed anywhere** |
| AGHQ chip flip | Scope *narrowed* in prose, not oversold |

Two documents (`benchmarks-authoritative`, `interval-trio-parity`) recorded claims
later superseded by the fixes. Corrected by **dated UPDATE sections plus a supersede
banner in the after-task**, rather than rewriting history. **adaptive.**

## 6. Handoff state

| item | state |
|---|---|
| PR #458 | OPEN, 19 commits, CI re-running after the dep fix |
| #457 | Work ledger, open |
| #459, #461, #462 | Fixed, commented with evidence |
| #460 | **Open and blocked** — drmTMB-side bridge routing, CRAN quiesce |
| Coordination board | Updated; prior STOP entry superseded and banner-ed |
| After-task | Written + 2 addenda |

**Outstanding:** PR #458 is not merged and its CI has not yet gone green since the
dependency fix. Mission Control's `drmTMB` status still carries
*"Do not start the 11 capability rows"* and a `40/1/1/4` julia-surface tally, both
now stale — a future session reading it would stand down wrongly.

## Recurring drift class for the ledger

**Three of the orchestrator's own changes were wrong in ways that read as correct**
— an inert `loadfixture.jl` edit, a √height scale error, and a fix covering one
route of four that fell *silently back to the bug it fixed*. None was caught by
reading; all by round-trip or positive control. The generalisable rule, already
earning its keep: *verified by round-trip → trust; reasoned about → treat as
unverified*. Candidate for `WHAT-WORKS` rather than a failure ledger, because the
technique (round-trip the fix, not just the feature) is what caught all three.
