# DRM.jl R-parity +4 FE bridge parity (Workflow G)

**Status:** G0 — awaiting owner approval. Plan-only; **STOP at G0** (no Phase 3).  
**Tip truth:** `origin/main` @ **`b538768`** (#382 tip-idle after #381 MERGED).  
**Human review link:** [`docs/dev-log/plans/2026-08-03-r-parity-plus4-fe-bridge-ultra-plan.md`](2026-08-03-r-parity-plus4-fe-bridge-ultra-plan.md)

**Fences (hard):** D-111 OFF · leave `.worktrees/` · no GPL vendoring · no q4 `src/` · no Lovelace / drmTMB R edits · do not reopen #5 / #17 / #370 / #376 (nor #349 / #372).

---

## ARC CARD — Workflow G +4 FE bridge parity

**Mode:** size  
**Requested outcome:** advance R↔Julia coefficient-scale parity beyond the closed six-cell #370 cohort (not quantified by count; owner direction: “anything which can get to the R parity”)  
**Mechanism authority:** DRM.jl only — open one issue → generate MIT-clean fixtures from local drmTMB → admit via existing `compare_bridge` / `runparity_bridge.jl` / `runparity.jl` → docs honesty + DoD PR. **Excluded:** Registrator/D-111; `.worktrees/`; GPL vendoring; q4 `src/` core; R-side Lovelace/`engine="julia"` edits in drmTMB; reopening #5/#349/#17/#370/#372/#376; tip-idle SHA-churn; #202/#49/#136  
**Recommended arc:** **2–3 hours** (range 2–4 h if a family needs scale-transform / tol work)  
**Time contract:** ceiling ~3 h for Arc 0+primary; optional under-run rung  
**Estimate confidence:** **measured** (analogue = #370 plan 4–7 h *with* harness build; harness already landed today — this arc reuses it)  
**Arc 0 outcome:** new GitHub issue + per-family `drm_bridge` smoke log for `{poisson, gamma, binomial, lognormal}` (pass / fail / scale-risk)  
**State transition:** tip idle / 6 admitted bridge-parity cells → **+4 FE families** with committed fixtures + native+bridge `DRM_PARITY_TESTS=1` green + `r-julia-bridge.md` claim list updated  
**Executable rung and evidence:** `gen_fixtures.R` generators + committed `test/parity/fixtures/<slug>/` + cohort set edit in `runparity_bridge.jl` + verify receipt; evidence in check-log.d / after-task / Rose audit

### Capacity ladder (size mode; arc >2 h)

| Order | Budget | Outcome | Trigger / definition of done |
| --- | ---: | --- | --- |
| Arc 0 | 25–40 min | Issue opened; 4-cell smoke inventory | Start now after G0 |
| Rung 1 | 60–90 min | Generators + fixtures committed; cohort wired | Arc 0 clear enough |
| Rung 2 | 30–45 min | `DRM_PARITY_TESTS=1` native+bridge green | Fixtures present |
| Rung 3 (under-run) | 20–30 min | Optional: close stale epic **#186** checklist (subtasks #187–#189 already CLOSED) — ledger only | Only if Rung 2 early |
| Integrate/close | 25–40 min | Docs + check-log.d + after-task + Rose + PR | Always |
| **Total** | **~2.5–3.5 h** | | |

### Budget (Arc 0 + primary)

| Segment | Minutes | Output / stop point |
| --- | ---: | --- |
| Orient | 15 | Tip `b538768`; #370 harness paths; family scale notes |
| Core | 90 | Generators, fixtures, cohort wire, docs claim list |
| Verify | 30 | `DRM_PARITY_TESTS=1` native+bridge receipt |
| Repair reserve | 30 | Soft-diff tols / spelling (student-style from #370) |
| Closeout | 25 | DoD + PR `closes #NN` |
| **Total** | **~190** | |

**In scope:** four FE families already mapped in `_bridge_family` (`poisson`, `gamma`, `binomial`, `lognormal`) but **absent** from `_BRIDGE_PARITY_COHORT` / fixtures.  
**Not in this arc:** Phase 1.5/#5/#349 (CLOSED/MERGED); Workflow G/#17 (CLOSED); #370/#372/#376 (CLOSED today); xfam; non-Gaussian phylo (#202); missing-data FIML (#49); VA (#136); Lovelace R glue; D-111; `.worktrees/`; inventing from ROADMAP alone; more tip-idle hygiene.

**Evidence used:**
- Repo today: `origin/main` @ **`b538768`** (#382 MERGED); ship #376/#377; tip-idle #378–#382; handover after-381; LOOP GOAL #376 DONE; after-task #370 “Families / formula shapes beyond the six fixtures” **Not covered**
- Brain: AGENT_LOG tip IDLE / owner G0 only (2026-08-03); D-111 OFF; D-94 R-first; D-111 text still names “Phase 1.5 closeout (#349/#5)” as *historical Next* — **already closed** (`#5` CLOSED, `#349` MERGED) — do not reopen
- Closed bar: after-task `2026-08-01-bridge-finish-matrix-phase15-5.md`; ROADMAP Phase 1.5/#5 + #17 closed
- Vault MC `drmTMB.json`: `next_safe_action` = owner G0 (lane tip string lags at `08bc4dc`; git truth = `b538768`)
- Deterministic greps: AGENT_LOG / journal / DECISIONS / OPEN_QUESTIONS / deep-research README (no open DRM.jl parity *issue* waiting; OQs are drmTMB-side)

**Risk branch:** If Arc 0 finds a family with parameter-scale mismatch that needs a non-trivial transform (beyond `[tol]`), **admit the green subset** and open a follow-up issue for the hard cell — do not expand into engine redesign.

**Done when:** PR merges with +4 fixtures (or honest subset ≥1 with written failures), native+bridge gates green for admitted cells, docs list them, Rose claim-vs-evidence PASS, `closes #NN`.  
**First action:** from tip `b538768`, `gh issue create` for the +4 FE bridge-parity cohort (template mirrors #370).

### Actuals (complete at close)

*(empty until `/goal` closes)*

**HAND TO ULTRA PLAN:** Cursor · 2–3 h · expand Workflow G/`drm_bridge` coef parity to poisson+gamma+binomial+lognormal · reuse #370 harness · fences D-111 / `.worktrees/` / no GPL / no q4 src / no Lovelace / do not rebuild closed #5/#17/#370/#376.

---

## 🎯 GOAL (paste-ready — copy verbatim into a fresh session)

```
SOLO PLATFORM: Cursor (this session). After G0 approval, hand to /goal —
do not continue Phase 3 in the planning chat.

DELIVERABLE: Open and close one DRM.jl issue — expand Workflow G coefficient-
scale R↔Julia parity (native drm() + drm_bridge) to four fixed-effect families
already bridge-mapped but not fixture-gated: poisson, gamma, binomial,
lognormal. Commit MIT-clean generated drmTMB numbers only; wire into
_BRIDGE_PARITY_COHORT + runners; update docs/src/r-julia-bridge.md; PR closes
the new issue.

HEADLINE: Retire the #370 after-task gap “families beyond the six fixtures”
for the next FE cohort without rebuilding Phase 1.5 / #370 harness.

IN PARALLEL (cheap): Arc-0 smoke of four cells via drm_bridge; optional under-
run = close stale epic #186 checklist only (subtasks already CLOSED).

DEFER (fenced): D-111 / Registrator; .worktrees/; GPL vendoring; q4 engine
src/; Lovelace/drmTMB R edits; #202/#49/#136; xfam-external-gllvm; rebuild
#376; tip-idle SHA-churn; reopening #5/#349/#17/#370/#372.

DISCIPLINE: DRM_PARITY_TESTS=1 local first; fixtures = generated numbers only
(drmTMB v0.1.3 or current installed twin — record version in *.meta.toml);
Rose: no speed claim without measurement (default honest no-claim); ML default;
closure = DoD (tests + docs + check-log.d + after-task + Rose).
```

---

## Phase 0.25 — Sweep receipt (condensed; gate before decompose)

| Surface | Evidence run | Finding | Call |
|---|---|---|---|
| **Repo git** | `git status -sb`; `git log --oneline` today; tip `origin/main` | `main` @ **`b538768`**, dirty only `?? .worktrees/`; today: #376→#382 | **build-the-gap** from idle tip; leave `.worktrees/` |
| **Twin drmTMB** | NEWS + `R/julia-bridge.R` + family.R | R has families + experimental `engine=julia`; Lovelace OUT of this arc | **co-opt** fixture numbers only |
| **Brain (semantic)** | MCP hybrid: Phase 1.5 / tip idle / next twin | Tip IDLE; owner G0; no invented ship | **reuse** idle + owner direction |
| **Brain (deterministic)** | greps AGENT_LOG / journal / DECISIONS / OQ / deep-research README | D-111 OFF; D-94 R-first; AGENT_LOG 2026-08-03 IDLE rehydration; Phase 1.5 named as done/idle; no DRM.jl open parity OQ | **do not reopen** #5/#349 |
| **Code** | `runparity_bridge.jl` cohort set; `gen_fixtures.R`; `_bridge_family`; after-task #370 | Harness exists; 6-cell cohort frozen; 4 target families mapped in bridge; generators missing for them; `nbinom2-dispersion` generator exists but fixture **not** committed | **reuse harness / build +4 FE fixtures** |
| **Verdict** | — | Genuine gap = cohort expansion only | **reuse / build-the-gap** |

---

## WHAT THE BRAIN ALREADY KNOWS

- Phase 1.5 / **#5 CLOSED**, **#349 MERGED**, finish-matrix experimental bar landed 2026-08-01 — not this arc.
- Workflow G / **#17 CLOSED**; **#370/#371** bridge fixture coef parity DONE today; **#372/#374** six-cell timing DONE; **#376/#377** q4 H2H DONE; tip-idle **#378–#382** DONE @ `b538768`.
- D-111 OFF; D-94 R-first (fixtures from R numbers → Julia match).
- AGENT_LOG: tip IDLE until owner G0; inventing ship / rebuilding #376 **RETRACTED**.
- Owner this turn: R-parity direction (satisfies “owner G0” for *topic*; G0 still needs explicit plan approval).

## WHAT SHINICHI TOLD US

- Ultra-plan the new arc; then: “anything which can get to the R parity.”
- Corrections: `/arc-creation` first; ground in today’s tip; ask-brain + deterministic greps before finishing.
- Show this plan “on the right” (Cursor side panel / editor).

## WHAT THE TEAM RAISED

- **Hopper** — Smallest real parity advance is **+FE fixtures through existing `drm_bridge` gate**, not another finish-matrix.
- **Rose** — Do not claim Phase 1.5 reopened or speed wins; default timing **no-claim**; never vendor GPL source.
- **Ada** — Prefer this over #186 docs-close (ledger under-run only) and over #202/#49 (too large).

## ADA'S RECOMMENDATION

Approve this +4 FE cohort expansion as the G0 ship arc.

## DECISIONS LOCKED (pending G0)

| Decision | Lock |
|---|---|
| Cohort | **poisson / gamma / binomial / lognormal** |
| Harness | Reuse #370 (`compare_bridge` / `runparity_bridge.jl` / runners) — no rebuild |
| R repo | No Lovelace / `engine="julia"` edits in drmTMB |
| Timing | Honest **no-claim** unless owner later asks to measure |
| Tip | `origin/main` @ **b538768** — do not tip-idle-churn |
| Registry | **D-111 OFF** |
| Worktrees | Leave **`.worktrees/`** alone / never stage |
| Engine | **No q4 `src/`** edits |
| License | **No GPL** vendoring — generated fixture numbers only |
| Closed issues | Do **not** reopen #5 / #17 / #370 / #376 (nor #349 / #372) |

## QUESTIONS STILL OPEN

None load-bearing after homework. Reply **approve G0** (or name a different cohort).

---

## Slice table

| Slice | Member | Model+effort | Bar | Time | Detail | Dep |
|---|---|---|---|---|---|---|
| RECON Arc0 | Hopper | Composer low–med | Cursor Models | 25–40m | Issue + 4-cell smoke note | — |
| S1 generators+fixtures | Hopper | Composer med | Cursor Models | 45–75m | `gen_fixtures.R` + commit numbers+meta | Arc0 |
| S2 cohort wire | Hopper | Composer med | Cursor Models | 20–40m | `_BRIDGE_PARITY_COHORT` + runners | S1 |
| S3 docs honesty | Pat/Hopper | Composer med | Cursor Models | 20–30m | `r-julia-bridge.md` + parity README | S2 |
| MECH-VERIFY | Hopper/Grace | Composer low | Cursor Models | 20–30m | `DRM_PARITY_TESTS=1` receipt | S2 |
| Rose close | Rose | Auto Cost med–high | Other Models | 15–25m | claim-vs-evidence | S3+verify |
| RECONCILE | Melissa | Auto med | Other Models | 10–15m | plan-actual | close |

**LUNA SUITABILITY:** yes (Arc0 + mech-verify). **ULTRA EFFORT:** no.  
**FAN-OUT BUDGET:** ≤4 children / checkpoint after G0.  
**SEARCH:** none (no novelty claim). NotebookLM: not offered as required.

### VERIFY

1. Always-on `test_parity_harness.jl` still green.
2. `DRM_PARITY_TESTS=1` native + bridge pass for old six **and** new admitted cells.
3. Rose: admitted list matches evidence; no speed inflation; MIT/GPL boundary.

---

## STOP at G0

Do **not** start Phase 3 / do not implement this arc from the planning chat.

`CreatePlan` tool is not available in this Cursor MCP surface — this markdown file is the durable plan artifact for side-panel / editor review.

**Approve?** Reply `G0 APPROVED` (or adjust cohort). Then paste into a **fresh** `/goal` chat:

```text
/goal

Read LOOP/ after G0 approval for DRM.jl R-parity +4 FE cohort
(poisson/gamma/binomial/lognormal) via Workflow G + drm_bridge, reusing #370
harness. Tip origin/main @ b538768. Fences: D-111 OFF; leave .worktrees/;
no GPL vendoring; no q4 src; no Lovelace; do not reopen #5/#17/#370/#376.
First action: gh issue create, then Arc 0 smoke. Platform: Cursor.
Plan summary: docs/dev-log/plans/2026-08-03-r-parity-plus4-fe-bridge-ultra-plan.md
```

No Phase 3 executed.
