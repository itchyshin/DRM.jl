# The completion roadmap — from 7 covered to a finished package

**Written 2026-08-27 (Fable, per D-151), at the owner's request.** State at writing: drmTMB PR #1087
merged — the ledger reads **7 covered · 3 partial · 1 unsupported** of 11 rows, CLOSURE: PASS.
DRM.jl PR #515 (Phase 1 evidence rebank) has auto-merge armed behind required checks. This document
supersedes the *sequencing* in `2026-08-26-promotion-arc.md` (whose Phase 1 is now complete) and
reconciles the two standing roadmap issues #8 (v0.1.0) and #9 (v1.0).

## Destination

Written first, per the decision-map rule, so the roadmap has a stopping condition:

> **DRM.jl is a finished twin when: every admitted capability row is `covered` or carries a
> deliberate, owner-signed claim_boundary; the engine gaps that block a row are closed and the ones
> that don't are fenced with a written reason; the interval fences are resolved by decision (earned
> with measured coverage, or kept as permanent documented boundaries — not left as defaults); the
> v0.1.0 gate in #8 is either satisfied and tagged or consciously re-scoped; and drmTMB's ledger
> matches all of it.**

Explicitly **not** in the destination: CRAN submission (D-164 holds the release), Julia General
registration (D-111 is OFF — #8 predates that decision and its "then register" clause is suspended,
not silently deleted), and the fenced backlog (#327, #280, #270, #269, #227, #49).

## What is left — the honest inventory

### A. Ledger completion — the last three rows (the catch-up axis)

| row | blocker | the work | size |
|---|---|---|---|
| `phylo_count_large_p` | (a) SE parity loosens to ~1.2e-03 relative at p ≥ 1000 while coef/logLik stay 1e-6..1e-9 — **unexplained**; the #513 tolerance fix improved it only 1.3× (vs Gamma's 188,216×), so solve noise is ruled out. (b) #491: the convergence flag is anti-correlated with care at large n; the `Optim.converged(res) && return true` short-circuit and a relative-gradient threshold (any value in 1e-06..1e-05 separates with orders-of-magnitude margin) await the owner's call. | (a) a stepwise diagnostic **at p = 1000** — the promotion-arc §2d procedure was run at small p only; candidates now are error accumulation across the p-dimensional inner solve vs an information-convention divergence that only opens at scale. (b) is a decision plus a small PR; the numbers are already banked in the row's boundary text. | (a) ~1 session · (b) minutes after the call |
| `gaussian_response_mask` | a semantics decision, settled by the 10-minute experiment specified in promotion-arc §1.4 and never run: fit native drmTMB Gaussian mean-phylo with missing y under `response="include"` and `"drop"`. | If likelihood-identical → `include` is `drop` + prediction, a wrapper, not a derivation → implement the wrapper, promote. If not → the TSV's "needs a derivation" stands; decide fence vs derive (deriving a masked likelihood drmTMB itself lacks is beyond-parity work — recommend fence). Ties to #482. | ~½ session including the wrapper |
| `cross_family_latent` | governance, not code: unreachable from R by construction (`src/bridge.jl` has no cross-family handling), and drmTMB accepts only `c(gaussian(), gaussian())`, so parity evidence cannot exist. | Recommend the promotion-arc §5.2 route: a **permanent claim_boundary** on the `engine_control_surface` pattern, plus correcting the self-described "generous" `r_bridge_status`. The alternative (bridge wiring) is real work serving no current user. Owner picks. | minutes after the call |

`engine_control_surface` stays `unsupported` by design — it is already at its destination.

### B. Engine gaps (beyond the ledger)

Ordered by how much they block; the first two are the only ones that gate the destination.

1. **#509** — q4 structured reports `converged=true` at a singular Λ (cond 1.3e12) and the smoke
   fixture is saturated so nothing catches it. The q2 admissibility guard (#505 pattern) needs
   porting to q4, the fixture de-saturating, and the other smoke fixtures grepping against the
   `4G ≥ 2n` bound — the third bite of the #483/#509 lesson. **~½ session.**
2. **#470** — bivariate **q=2** structured REML, the one real REML gap (q4 REML exists; residual-only
   correctly refuses). **~1 session** with tests.
3. **#472** — `mstep_Lambda` descends the true marginal at p=100 but is unreachable from public
   `drm()`: **fence + document, never "fix"** (already the plan's verdict — it just needs doing).
4. **#467** — bridge formula constructs: the Wave-1 work landed the main functions; what remains is
   the tail (faithful support vs sharper rejection per construct). Small, user-facing, not gating.
5. **#471** — structured markers for bivariate Student/LogNormal: **reclassified beyond-parity**
   (drmTMB's own `biv_student()` defers structured effects). Do-or-defer is an owner call; deferring
   does not block the destination.
6. **Exact REML gradient via `lc_metric`** (the promotion-arc Wave 3): a quality improvement to an
   already-working route. Optional for completion; keep on the list so it is declined consciously.
7. **`src/experimental/`** — one pass, per file: wire, or document as a recorded negative result and
   leave unwired (several EM/VA variants are exactly that). An undocumented experimental directory
   is the kind of loose end that reads as unfinished. **~½ session, writing not coding.**

### C. Interval trust — the fences (a decision, then optional work)

The two `interval_status != "coverage_claimed"` fences are **not** blockers for any promotion — that
is settled (promotion-arc §0). What remains is choosing their end state:

- **Option 1 — keep them permanently**, documented as "capability parity, not coverage": zero compute,
  honest, and consistent with every promoted row's boundary text. **This is the default if no one
  decides otherwise, and it satisfies the destination.**
- **Option 2 — earn `coverage_claimed`** where the measured campaigns already argue it is reachable:
  the mean blocks are nominal at N ≥ 128; the known failures are solver reliability (#493/#494, both
  fixed) and the q4 phylocov scale-axis miscalibration (#495). The discriminating experiment
  (profile vs Wald on the same fits, now runnable via #514's per-coefficient `parm`) needs its own
  D-139 estimate before any run. Campaign compute: Totoro/DRAC, never CI (D-50).

**#495 itself stays open either way** — it is a finding about Wald-on-log-Cholesky, worth a line in
the docs even under Option 1.

### D. Package chrome — calling it a package

- **#8 (v0.1.0 gate):** "Gaussian uni+bivariate (q=4 PLSM headline) + inference + docs published +
  R-bridge functional." Every limb is arguably met today. What remains is the owner *deciding* it is
  met and tagging — minus the registration clause (D-111 OFF). Recommend: tag `v0.1.0` when Wave A
  closes, update #8 to record the D-111 carve-out.
- **#9 (v1.0):** "every drmTMB capability matched, speed edge documented per family." The ledger
  side is Wave A; the speed side needs the benchmark grid extended from the current evidence (2.18×
  single fit, O(p) to p=10,000) to a per-family table in `report/`. **~1 session on existing
  instruments**, no new campaigns.
- **README / docs sweep**: the front page still describes the pre-promotion state in places; one
  pass after Wave A so public text matches the ledger (the gate test's forbidden-pattern list keeps
  it honest).

## Sequence

| wave | contents | gate to next | est. |
|---|---|---|---|
| **A — close the ledger** | A1 large-p SE diagnostic · A2 #491 decision+PR · A3 mask experiment (+wrapper if it wins) · A4 cross_family boundary · promotions PRs as rows qualify | every row `covered` or owner-signed boundary | 2–3 sessions |
| **B — engine hygiene** | #509 · #470 · #472 fence · #467 tail · experimental/ pass | suite green, no known-false `converged` | 2–3 sessions |
| **C — fences decision** | owner picks Option 1 or 2; if 2, D-139-estimated pilots first | decision recorded in DECISIONS.md | 0 or campaign-sized |
| **D — call it** | benchmark table for #9 · README sweep · tag v0.1.0 (#8, D-111 carve-out) · close #8, re-scope #9 | tag exists; drmTMB ledger matches | 1–2 sessions |

Waves A and B interleave freely (different files); C and D wait on A. Total, at the pace of the last
three days: **roughly 5–8 working sessions**, plus campaign time only if Option 2 is chosen.

## Decisions this roadmap needs from Shinichi

**ANSWERED 2026-08-27, all six** — owner instruction: *"Answer decisions 1-6 with your
recommendations."* Every recommendation below is therefore adopted as decided; recorded as vault
D-179 and on issues #491, #471, and #8. Wave A is unblocked in full.


1. **#491** — adopt a relative-gradient convergence criterion (1e-06..1e-05) and drop the
   short-circuit? (Numbers banked; recommendation: yes, at 1e-06.)
2. **`gaussian_response_mask`** — if the experiment says wrapper: implement it? (Recommendation: yes.)
3. **`cross_family_latent`** — permanent boundary vs bridge wiring? (Recommendation: boundary.)
4. **Fences** — Option 1 (permanent, documented) or Option 2 (earn coverage)? (Recommendation:
   Option 1 now; revisit after v0.1.0.)
5. **#471** biv Student/LogNormal markers — do or defer? (Recommendation: defer past v0.1.0.)
6. **v0.1.0 tag** once Wave A closes, with D-111's registration hold recorded on #8?

Answering 1–6 in one sitting makes the rest almost entirely execution.
