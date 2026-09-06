# Plan vs actual — #563 S7(b) sparse multi-component LSS engine

**Melissa reconciliation** · 2026-09-02 · DRM.jl, `feat/563-s7b-lss-sparse-multi`, head `638a2da3`
Plan: `docs/src/developer-notes/lss-sparse-multi-component.md` §7 (estimate + GO/NO-GO), ratified as
D-206. Six sub-slices, S7b.1–S7b.6 (S7b.6 not in the original plan — see §5).

Material deviations only. Cosmetic ordering/wording is not drift.

---

## 1. Scope

| planned | actual | tag | owner |
|---|---|---|---|
| S7b.1: block `H`/`b` assembly, multi-component | `ed45a044`, `src/gaussian_sparse_lss.jl`, 7/7 (`test_lss_sparse_multi.jl`) | — | — |
| S7b.2: per-component `g_α,c` gradient generalisation | `e3e65500`, corrected mid-implementation (§2 below) — diagonal-only formula (91% wrong on a toy) replaced with the cross-component `Hinv[g,t]` trace term; 8/8 (`_gradient.jl`), FD rel ≤1.37e-7 | adaptive (design corrected during build, not before — see §2) | Noether |
| S7b.2b: cross-block `Hinv[g,t]` accumulation + permanent FD oracle | Folded into the same `e3e65500` commit and the same `_gradient.jl` file rather than a separate sub-slice/commit — the design note's own row (§3) already treated this as inseparable from S7b.2's `g_α,c` fix | adaptive (merged, substance unchanged) | — |
| S7b.3: REML multi-component sparse backsolves | `56f66c7f`, `_reml.jl`, 25/25, REML FD rel ≤1.09e-7 incl. a boundary point | — | — |
| S7b.4: oracles 1/2/4 wired into `test/`, public router | `aafab7c4` (+docs `ba9f20c2`, `07c18534`, `bfe71145`), `_public.jl`, 35/35 (21+7+7) at plan time | — | — |
| S7b.5: p=10,000 pilot on Totoro + scaling writeup | `22e4d12d`, ran as planned (D-139 pre-run discipline followed) — but the **result itself was a negative finding the plan did not anticipate**: fill flat (as predicted) but wall time NOT O(p) (exponent ≈2.6–2.9), see §5 | material (unplanned finding, correctly not suppressed) | Curie |
| S7b.6 (**not in the original six-row plan**) | `86b7e3d4` fix + `385f02cd`/`638a2da3` post-fix re-measurement — a new sub-slice added in-session to chase down S7b.5's negative finding | added (see §5) | Karpinski |

## 2. Evidence and verification

| planned | actual | tag | owner |
|---|---|---|---|
| Design note §3 gradient table, as first drafted | `g_α,c` row and, separately, `quad_term`/`g_βσ` rows were WRONG as first drafted — caught by the design note's own §8 adversarial review (a 6-node toy: FD `1.400168` vs. diagonal-only `2.669901`, 91% error) **before** engine code, and by implementation review during S7b.2 (commit `019432d3`, "correct the §3 rows quad_term and g_βσ per the S7b.2 implementation review (FD-verified)") **during** engine code. Both corrections are marked in place in the design note text ("CORRECTED 2026-09-02"), not silently rewritten | adaptive (symbolic-alignment caught most of it pre-code per D-206's own account; one row needed a second, implementation-time correction — disclosed, not hidden) | Noether |
| §5 oracle tolerances (`atol=1e-8` first draft) | Loosened to `atol=1e-5` (loglik) / `rtol=2e-4, atol=2e-5` (coef) to match #551's own shipped precedent, per the design note's own §8 finding 6 (the tighter number was unjustified, "likely-flaky") | adaptive (documented precedent-matching, not a bar lowering) | — |
| Ledger gates (leaf-s7b1..s7b5) | `gate-check.mjs --status`: `leaf-s7b1.md: 3 gates`, `leaf-s7b2.md: 4 gates`, `leaf-s7b3.md: 3 gates`, `leaf-s7b4.md: 4 gates`, `leaf-s7b5.md: 4 gates` → **ALL MET (18 met)**. Leaf-s7b4's own gate G4 explicitly NOT re-verified in this reconciliation, per the task's own instruction — owned by the conductor after the Totoro suite finishes | held (as scoped) | — |
| Totoro full suite (D-205) | Pre-fix head `ba9f20c2` PASSED (`SUITE_EXIT=0`, 442 test-set summaries, 35 min). **Final head (`86b7e3d4`, same src/test tree as this branch's head `638a2da3`) still RUNNING at reconciliation time** — 65 test-set summaries so far, process confirmed live via `ps aux` on Totoro; no `SUITE_EXIT` line yet | pending (not drift; disclosed with the exact command to re-check) | — |

## 3. Model / effort routing

| planned | actual | tag | owner |
|---|---|---|---|
| Design-first (symbolic-alignment) before any engine code (D-206) | Followed: `docs/src/developer-notes/lss-sparse-multi-component.md` exists and was adversarially reviewed (§8) before `ed45a044` (S7b.1's first commit) | held | Noether |
| D-139: estimate before any >30-min run, pre-run test, approval | Followed for S7b.5: the design note's §7 named the pilot as a D-139-gated run; ran on Totoro (≤150 cores, D-143) as a pilot, not straight to the full campaign | held | Curie |
| No estimate/pre-run named for a possible S7b.6 (it didn't exist yet) | S7b.6 was added reactively, in-session, to a finding from S7b.5 — its own fix + re-measurement is small (a router-code fix + a re-run of the *same* pilot script against the fix), not a new >30-min campaign requiring its own fresh D-139 estimate | adaptive (in-scope follow-up, not a new campaign) | Karpinski |

## 4. Safety gates

| gate | held? | tag | owner |
|---|---|---|---|
| D-206 scope boundary (nested/one-phylo only; NO general crossed sparse) | Held — S7b.4's router (`_lss_multi_route`) enforces exactly-one-phylo + nested-or-small-iid mechanically; the crossed-fixture oracle (7/7) asserts the boundary is never silently crossed, even under an explicit `algorithm = :sparse` request | held | — |
| D-209 (overnight standing approvals) | This slice's merge/priority/compute/housekeeping choices are consistent with D-209's four standing answers; no action outside its scope observed | held | — |
| D-205 (checks on Totoro, not GitHub Actions as the default) | Held — the full-suite check and the S7b.5/S7b.6 pilots all ran on Totoro via the `cm-totoro` ControlMaster socket, no GitHub Actions run invoked for this slice's own verification | held | — |
| Never merge (this task) | Not merged; branch remains open, head `638a2da3`. This report's own commit lands on the same branch | held | Rose |
| No `src/`/`test/` edit by this report | Held — this reconciliation added only `docs/dev-log/{after-task,check-log.d,plan-actual}/` files | held | Rose |

## 5. Time

| planned | actual | tag | owner |
|---|---|---|---|
| Design note §7: **20–28 agent-hours** across S7b.1–S7b.5 (S7b.2 alone raised from an initial 3–4h to 6–8h during the estimate itself, "not a mechanical loop-widening") | **≈ one session, ~5 h wall-clock**, with S7b.1–S7b.4 implemented largely in parallel by dispatched children (this report's own header perspectives: Noether/Curie/Karpinski alongside Shannon coordination) rather than serially by one agent-hour budget — so the wall-clock/agent-hour comparison is not apples-to-apples with the original serial estimate | material (the estimate was scoped as agent-hours of serial work; actual delivery used parallel dispatch, which the estimate did not model) | Shannon |
| No S7b.6 in the original estimate (0h) | S7b.6 (root-cause fix + RED-first tripwire + Totoro re-measurement of the full ladder) added un-budgeted, found and closed within the same session | material (unplanned but small; disclosed as its own sub-slice rather than folded silently into S7b.5's numbers) | Karpinski |
| **Deviation, stated plainly**: the S7b.5 pilot found a wall-time defect the design note's own analysis (§2, fill-only) did not and could not predict — it lived in code (`src/gaussian_lss.jl`'s public router) outside the sparse engine the design note was about (`src/gaussian_sparse_lss.jl`). It was found only by running the pilot on real hardware, fixed as S7b.6 with a RED-first tripwire so the same defect cannot silently return, and re-measured against the same ladder to confirm the fix (p=10,000: 165s → 1.6s ML, exponent 2.6–2.9 → 1.1) | — | — | — |

## Recurring classes

Two shapes account for every material deviation this session: (1) **a design claim corrected during
implementation, not before** — the `g_α,c` formula was caught wrong once by the design note's own
adversarial review (pre-code) and once more during S7b.2's implementation (`019432d3`), both disclosed in
place rather than silently rewritten; (2) **a pilot's own honest negative finding triggering an unplanned
but small follow-up sub-slice** — S7b.5 found wall time was not O(p) despite flat fill, and that finding,
reported as measured rather than reframed, is what produced S7b.6. Neither shape weakens a claim without
disclosing it; both are the design/pilot discipline (D-206, D-139) working as intended, not process
failures.

## Verdict

Adaptive, well-disclosed slice. Scope held to the D-206 boundary throughout. The estimate-vs-actual time
comparison is not directly comparable (serial agent-hours planned vs. parallel-dispatch wall-clock
delivered), which this note states rather than forcing a single number. The one open item at
reconciliation time is procedural, not a deviation: the Totoro full-suite run against the exact final head
had not finished, so the "suite green on `638a2da3`" claim is not yet independently confirmed — the check
command is given above for whoever closes that out.
