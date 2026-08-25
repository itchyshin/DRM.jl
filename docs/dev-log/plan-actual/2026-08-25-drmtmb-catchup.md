# Plan vs actual — drmTMB catch-up (Waves 1–2)

**Melissa reconciliation** · 2026-08-25 · lane `feat/drmtmb-catchup` · Claude Code
Plan: `~/.claude/plans/partitioned-wishing-shell.md` · run state: `~/.claude/plans/OVERNIGHT-RUN-drmtmb-catchup.md`

Material deviations only, on the six axes. Cosmetic wording and ordering changes are not drift.

---

## 1. Scope

| planned | actual | verdict |
|---|---|---|
| Wave 1: #465, #466, #467, #460, #468 | all delivered | — |
| Wave 2: "REML holes ×4, markers ×2" | **re-scoped to 2 slices before dispatch** | **adaptive** |
| — | **+6 unplanned slices** (#479, #482 probe, biv parity, binomial SE, structured families, Route-C, large-p) | **adaptive** |
| — | **+23 issues filed** | **adaptive** |

**Adaptive, not drift.** Group A was cut from four slices to roughly one by *reading the code before
dispatching*: bivariate q=4 REML was already implemented, and the residual-only rejection is correct
statistics (no random effects ⇒ nothing to restrict). Recorded in the plan at the time, not retrofitted.

The six unplanned slices were all downstream of findings — each one closed a gap a measurement had just
exposed. That is the intended shape.

## 2. Evidence and verification

| planned | actual | verdict |
|---|---|---|
| full suite green per wave | Wave 1 **312 testsets, 0 failures**; Wave 2 **two regressions, both mine, both caught** | — |
| adversarial verify per wave | ran on the #460 headline → **3 defects**, all repaired | — |
| — | ran on "0 over-claims" → 6 candidates raised, **all 6 refuted** on the ledger's own bar | — |

**Two regressions, both introduced by me and both caught by the suite rather than by my own checks:**

1. Reworded an error message, "verified" no test matched by grepping a phrase **longer** than the one the
   test asserts. A grep for a longer phrase cannot prove the absence of a shorter one.
2. Left conflict markers in `expected.meta.toml` — resolved and validated `expected.toml`, then staged the
   whole directory.

Same shape both times: **a check narrower than what it was reported to cover.** Recorded in the after-task
and handover; this is the drift class most worth a process fix.

## 3. Model routing

| planned | actual | verdict |
|---|---|---|
| Fable for planning/campaign design | used for #468 coverage design | — |
| Sonnet for build slices | all build slices | — |
| Opus for adversarial verify | #460 review + refutation workflow | — |
| Haiku for recon/mechanical | 3 recon agents, 1 claim audit | — |

No ceiling-tier inflation. The one Opus review found three real defects in the headline, which is where
that budget belongs.

## 4. Safety gates

| gate | held? |
|---|---|
| No `submit_cran` / tag / announcement (D-164) | ✅ |
| drmTMB `main` untouched | ✅ `fb8e6c1a5` throughout |
| DRM.jl `main` untouched | ✅ `8d45b651` |
| Nothing merged needing maintainer approval | ✅ 3 PRs open |
| Coverage grid not run (D-139) | ✅ pre-run only, stops at go/no-go |
| Both `coverage_claimed` fences intact | ✅ |
| `.codex/agents/shannon-coordinator.toml` never staged | ✅ |
| #420/#406 untouched, unrebased | ✅ |

**One gate wobbled and was corrected:** two commits landed on local `main` in a shared checkout when HEAD
moved under me. Nothing was lost; commits were moved to the lane and `main` reset to `origin/main`. That
is exactly the bleed-through D-88 warns about, and the lane pre-flight had warned about the shared
checkout at session start.

## 5. Public claims

| claim | status |
|---|---|
| 7 capability rows moved | **measured**, limb-by-limb against design/168 |
| 1 row NOT moved on purpose (`gaussian_response_mask`) | limbs arguably met; held `partial` because one of its two mask modes still fails |
| REML cuts bias 2.5–2.8× | measured, 60/60 seeds |
| q4 constant-offset prediction holds | measured on a converged fit |
| interval coverage | **NOT claimed** — explicitly, everywhere |
| TMB is O(p³) on the large-p route | **retracted** — measured O(p^1.27) |

**Three of my own readiness assessments were wrong and were corrected by measurement**, not argument:
`biv_gaussian_residual`'s blocker was misdiagnosed; `plain_binomial_nonphylo` was queued for a promotion
it had not earned; `general_covariance_structured` had more evidence than I credited. Each correction is
recorded in the artifact that carried the error.

## 6. Handoff state

| item | state |
|---|---|
| `feat/drmtmb-catchup`, 48 commits | pushed · **DRM.jl#485 DRAFT** |
| drmTMB#1080 (#460 fix) | pushed · **OPEN** |
| drmTMB#1082 (4 rows) | pushed · **OPEN** |
| Handover | committed |
| Board + Mission Control | updated |
| Vault D-164 clarification | `ed5132b` |

Nothing undeclared. Every unlanded item is `CARRIED-OVER` with a branch and a reason.

---

## Drift routed to a decision-owner

| finding | class | owner |
|---|---|---|
| Verification narrower than reported (×2) | **drift** — process | Rose: worth a standing check |
| Two commits to `main` in a shared checkout | **drift** — recovered | Ada: lane discipline |
| Scope expanded by 6 slices + 23 issues | **adaptive** | — |
| Group A cut 4 slices → 1 | **adaptive** | — |
| Coverage campaign unrun | **not drift** — D-139 gate, owner's call | Shinichi |

## The one recurring class worth a process fix

Both regressions, and all three wrong readiness calls, share a root: **checking a proxy for the thing
rather than the thing.** A grep pattern near the assertion instead of the assertion; a sibling file
instead of the file; a plausible blocker instead of the measured one.

The counter-practice that worked, every time, was *running the thing* — the orphan tests, the live
Route-C parity, the SE cell, the nll sweep, the p=3000 fit. Six of tonight's findings exist only because
something that had never been run was run.
