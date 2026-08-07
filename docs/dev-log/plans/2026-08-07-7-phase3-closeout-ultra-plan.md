---
name: "Phase 3 #7 closeout"
overview: "Size mode found #7 has no remaining article-fill work (all 26 drmTMB target slugs exist). Arc 0 is a ~75-minute Rose honesty closeout of Phase 3 / issue #7 from tip `f3d8ce7d`, then STOP for G0. #336 Makie is the next ship G0 after this ledger closes — not in this arc."
todos:
  - id: g0-signoff
    content: "Owner G0: approve Phase 3 (#7) closeout (default: close #7 with carve-outs) or reject/pivot"
    status: pending
  - id: goal-execute
    content: "After G0: /goal from updated main — inventory receipt, ROADMAP, DoD, PR closes #7"
    status: pending
  - id: next-g0-336
    content: "After #7 merges: separate arc-creation for #336 Makie (not this PR)"
    status: pending
isProject: false
---

# Phase 3 (#7) honesty closeout — Arc Card + Ultra Plan (G0)

**Speak as Shannon.** Active perspectives: Ada (orchestrate), Pat (docs honesty), Rose (claim-vs-evidence), Grace (ledger). No nested subagents for this plan-only turn.

**Plan mode:** Cursor Plan mode is active (read-only through Phase 2). Do **not** implement, commit, push, or open a PR until owner G0 sign-off. After approval, run via `/goal` in a fresh Agent chat (Cursor Ultra pace).

**Platform:** Cursor (this session).

---

## ARC CARD — Phase 3 (#7) honesty closeout

**Mode:** size  
**Requested outcome:** not quantified — retire or honestly re-scope open roadmap issue [#7](https://github.com/itchyshin/DRM.jl/issues/7) after tip-idle  
**Mechanism authority:** docs + ROADMAP + GitHub issue/PR ledger edits only; **no** `src/` engine changes; **no** inventing tip-idle SHA churn; **no** claiming simultaneous phylo×spatial or VA as shipped  
**Recommended arc:** **75 minutes** (range 60–90)  
**Time contract:** ceiling ~90 min  
**Estimate confidence:** **measured** (slug inventory 26/26 OK on tip; analogous docs honesty PRs)  
**Arc 0 outcome:** PR that updates Phase 3 status + Rose receipt + closes or checklist-dispositions #7 without fake article fills  
**State transition:** `#7 OPEN / Phase 3 "nearly complete"` → `#7 CLOSED (or explicitly parked with only engine blockers) / Phase 3 complete-with-carveouts`  
**Executable rung and evidence:** inventory receipt + ROADMAP/#7 text + Rose PASS in check-log.d + after-task; PR `closes #7`

### Capacity ladder (short; optional)

| Order | Budget | Outcome | Trigger / definition of done |
| --- | ---: | --- | --- |
| Arc 0 | 75 min | Phase 3 honesty closeout PR | Start now after G0 |
| Rung 1 | — | **Deferred:** open separate G0 for [#336](https://github.com/itchyshin/DRM.jl/issues/336) Makie | Only after #7 close merges; not this arc |
| Integrate/close | in Arc 0 | DoD artifacts | Always |

### Budget (Arc 0)

| Segment | Minutes | Output / stop point |
| --- | ---: | --- |
| Orient | 10 | Checkout `origin/main` @ `f3d8ce7d`; confirm 26/26 slugs + two honesty banners |
| Core | 35 | ROADMAP Phase 3 complete-with-carveouts; #7 body/comment disposition; light coordination-board tip refresh |
| Verify | 15 | Diff review vs claim rules; no capability-status overclaim |
| Repair reserve | 10 | Wording if Rose flags drift |
| Closeout | 15 | check-log.d + after-task + PR `closes #7` |
| **Total** | **75** | |

**In scope:** ledger/docs honesty for Phase 3 / #7 only.  
**Not in this arc:** filling new articles; implementing phylo×spatial joint fit; #136 VA; #49 FIML; #336 MakieExt; R `engine="julia"` live round-trip; tip-idle padding commits.  
**Evidence used:** tip `origin/main` = `f3d8ce7d` (Merge #396); all #7 slugs present under `docs/src/`; remaining banners = Theory+roadmap (`phylogenetic-spatial.md`) + Planned (#136) (`marginal-la-vs-va.md`); AGENT_LOG tip-IDLE notes; HSquared Makie exists but is **next** G0.  
**Risk branch:** If Rose finds a **missing** slug or a Stable page that overclaims simultaneous phylo×spatial / VA fit, stop closeout and open a real fill/fix issue instead of closing #7.

**Done when:** PR merges (or is open+CI green awaiting merge) with Rose PASS; #7 closed or explicitly parked with only non-article blockers named; ROADMAP Phase 3 matches evidence.  
**First action (post-G0):** `git fetch && git checkout main && git pull && git checkout -b docs/7-phase3-closeout`

**HAND TO ULTRA PLAN:** Arc 0 = Phase 3 (#7) honesty closeout, ~75 min, docs/ledger only, from tip `f3d8ce7d`; fence #136/#336/#49/engine; PR `closes #7`.

### Actuals (complete at close)
*(empty until `/goal` execution)*

---

## Ultra Plan — Phases 0–2 (STOP at G0)

### GOAL (paste-ready)

```
PLATFORM: Cursor (workbench)
DELIVERABLE: Close DRM.jl #7 via a Rose-honest Phase 3 closeout PR from tip
  origin/main @ f3d8ce7d — no new article fills unless inventory finds a real gap.
HEADLINE: All 26 target Documenter slugs already exist; remaining honesty is
  Theory+roadmap (phylogenetic-spatial) + Planned VA (#136). Update ROADMAP +
  issue ledger; do not invent tip-idle SHA churn or ship claims.
IN PARALLEL: none required (single docs/ledger slice).
DEFER / FENCE: #136 VA implementation; #336 MakieExt; #49 FIML; R-repo
  engine="julia" live round-trip; simultaneous phylo×spatial engine; q=4 core;
  D-111/Registrator; GPL vendoring.
DISCIPLINE: verify before claiming · one issue → one branch → one PR ·
  never stage .worktrees/ · local docs check before CI · Rose claim-vs-evidence.
```

### ARC PROGRAM

Size mode · Arc 0 = 75 min Phase 3 closeout · Rung 1 = #336 (separate owner G0 after merge) · no padding.

### PHASE 0.25 — SWEEP RECEIPT

| Surface | Evidence ran | Finding | Call |
|---|---|---|---|
| **repo git** | `git status -sb`; `origin/main` = `f3d8ce7d`; local checkout still on merged `feat/388-ci-rng-exposure` (**1 behind** main); PR #396 **MERGED**; `branch_drift_check` on that branch 0 ahead / 1 behind; no open ship PR; many stale worktrees (do not touch) | Tip **IDLE** for new ship; resume nothing for #7 | **build-the-gap** on fresh `docs/7-phase3-closeout` from **updated main** |
| **twin / sister** | drmTMB article target in #7 body; HSquared `ext/HSquaredMakieExt.jl` (~346 lines) for #336 later | Article mirror target already met in DRM docs tree; Makie pattern ready to co-opt **after** this closeout | **reuse** article map; **defer** Makie co-opt |
| **brain** | `search_notes` Phase 3/#7/#336; `grep` AGENT_LOG (`tip IDLE — no Phase 3 ship`), journal (2026-07-06 #336 posted, no code), DECISIONS/OPEN_QUESTIONS/deep-research | No decision locking #7 open forever; prior tip-IDLE said wait for owner G0; #336 is posted idea | **close ledger gap**; do not invent Phase 3 fill |
| **repo docs** | Python slug check **26/26 OK**; Status banners left: Theory+roadmap (`docs/src/tutorials/phylogenetic-spatial.md`), Planned (`docs/src/model-guides/marginal-la-vs-va.md`), Experimental bridge/cross-family | Fill work **exhausted**; honesty closeout is the real #7 slice | **build closeout, not articles** |
| **Verdict** | | Genuinely new: Phase 3 / #7 **disposition**. Not new: article content | **reuse filled docs → close or re-scope #7 honestly** |

### WHAT THE BRAIN / REPO ALREADY KNOWS

- Tip idle after #388/#396; owner asked for next G0 and accepted the #7 recommendation.
- Inventory falsified “fill remaining tutorials” as Arc 0 — pages exist; two are intentionally non-Stable.
- AGENT_LOG: do not invent Phase 3 ship / tip-idle churn.

### WHAT SHINICHI TOLD US

- Accepted recommendation of #7 as next G0; asked `/arc-creation` then `/ultra-plan`.
- Campaign desire for #7 → #336 → R-bridge → #136 → #49 exists, but **serial one-issue G0s**.

### WHAT THE TEAM RAISED

```
TEAM RAISED
  Pat   — All Workflow D target slugs present; phylo-spatial + VA pages are honest
          status banners, not empty stubs. · Rec: closeout prose, not rewrite.
  Rose  — Closing #7 must not imply simultaneous phylo×spatial or VA fits.
          Carve-outs must name #136 + engine follow-up. · Rec: Rose PASS gate on PR.
  Ada   — Shortest credible arc is ledger closeout; #336 is next ship G0.
          · Rec: lock closeout; fence Makie.
  Grace — Branch from main after pull; local feat/388 is stale-merged.
```

### ADA'S RECOMMENDATION

**Execute Arc 0 as Phase 3 honesty closeout of #7.** Do not pivot this G0 to #336 unless owner rejects closeout. Default if silent: close #7 with carve-outs.

### DECISIONS LOCKED

1. Arc 0 = **#7 closeout**, not article invention.  
2. From tip `f3d8ce7d` / updated `main`; new branch `docs/7-phase3-closeout`.  
3. Fence #136 / #336 / #49 / R-bridge / engine core.  
4. Plan-only until G0; then `/goal` (not continue Phase 3 in this chat).  
5. Durable plan copy path on execution: [`docs/dev-log/plans/2026-08-07-7-phase3-closeout-ultra-plan.md`](docs/dev-log/plans/2026-08-07-7-phase3-closeout-ultra-plan.md) (write after G0, not before).

### QUESTIONS STILL OPEN (max 1 for owner)

**Q1.** On closeout, should #7 be **closed** with carve-outs (#136 + phylo×spatial engine tracked elsewhere), or kept **open** with a reduced checklist of only those two blockers?  
**Recommendation / IF YOU DO NOT MIND:** **Close #7** — articles milestone done; carve-outs named in ROADMAP + issue comment.  
**WHAT CONTINUES:** reversible plan only until you answer or say “use your judgment.”

---

## Slice table (post-G0 `/goal` execution)

| Slice | Member | Bar | Model | Time | Detail | Dep |
|---|---|---|---|---|---|---|
| Orient + inventory receipt | Ada/Pat | Cursor Models | Composer | 10m | Confirm tip; re-run 26/26; list carve-outs | — |
| ROADMAP + #7 disposition | Pat | Cursor Models | Composer | 25m | [`ROADMAP.md`](ROADMAP.md) Phase 3; issue comment; optional light [`docs/dev-log/coordination-board.md`](docs/dev-log/coordination-board.md) tip note | orient |
| Rose audit + DoD | Rose | Other Models / judgment | Auto Cost or Claude | 20m | claim-vs-evidence; check-log.d + after-task | docs |
| PR `closes #7` | Grace/Shannon | Cursor Models | Composer | 15m | branch, PR, CI docs workflow | Rose |
| MECHANICAL-VERIFY | Grace | Cursor Models | Composer | 5m | links/status strings; no capability overclaim | PR |
| RECONCILE | Melissa | Other Models | light | 5m | plan-actual note if material close | PR |

**LUNA SUITABILITY:** yes for inventory/mechanical verify (Composer scout).  
**FAN-OUT BUDGET:** 0 parallel children needed (single lane).  
**ESTIMATE:** ~75–90 min wall-clock; one session; one PR.  
**VERIFY:** Rose PASS; PR body cites inventory + carve-outs.  
**CONSOLIDATE:** after-task + check-log.d; ROADMAP matches tip.

---

## Execution sketch (only after G0)

1. `git checkout main && git pull` → branch `docs/7-phase3-closeout`.  
2. Write inventory receipt under `docs/dev-log/evidence/` (26/26 + two banners).  
3. Edit ROADMAP Phase 3 → complete-with-carveouts (#136; phylo×spatial joint fit).  
4. Comment/close #7 per locked disposition.  
5. DoD: check-log.d + after-task + Rose; open PR `closes #7`.  
6. Stop; next owner G0 = **#336 Makie** (separate arc-creation).

---

## Paste-ready `/goal` prompt (after you approve G0)

```
/goal DRM.jl Phase 3 (#7) honesty closeout

PLATFORM: Cursor Agent from tip origin/main @ f3d8ce7d (pull main first;
local feat/388 is merged/stale).

DELIVERABLE: One docs/ledger PR that Rose-honestly closes or dispositions #7.
HEADLINE: 26/26 Documenter target slugs already exist; do not invent article fills.
Carve-outs only: phylogenetic-spatial Theory+roadmap (engine later) +
marginal-la-vs-va Planned (#136).

IN SCOPE: ROADMAP Phase 3, #7 issue disposition, evidence receipt,
check-log.d + after-task, light coordination-board tip refresh if needed,
PR closes #7.

FENCE: no src/ engine; no #136/#336/#49/R-bridge implementation;
no tip-idle SHA padding; never stage .worktrees/; no GPL vendoring.

FIRST ACTION: git fetch && git checkout main && git pull &&
git checkout -b docs/7-phase3-closeout

PLAN REF: Cursor plan "Phase 3 #7 closeout"; on start write durable copy to
docs/dev-log/plans/2026-08-07-7-phase3-closeout-ultra-plan.md

DONE WHEN: PR open (closes #7), Rose PASS, inventory receipt retained.
STOP: do not start #336 in the same PR.
```

---

**Await G0 sign-off; do not execute.**


## G0 lock (execution)

- Owner disposition: **CLOSE #7** with carve-outs (not keep open).
- Execution start: 2026-08-07; tip base `f3d8ce7d`; branch `docs/7-phase3-closeout`.
