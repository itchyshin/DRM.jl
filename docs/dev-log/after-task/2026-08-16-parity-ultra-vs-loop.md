# 2026-08-16 — Ada Phase 0–2: ultra-plan vs arc-loop vs /goal for R↔Julia catch-up

**Lane:** Cursor catch-up / docs-@ref + CI watch (read-only through Phase 2).
**Author:** Ada (Shannon speaking). **No nested Task subagents ran.**
**Platform:** Cursor. Plan-first; this session cannot flip Plan mode — stayed
read-only except this note. **No Phase 3. No engine work. No Julia suite.**

---

## 🎯 GOAL

```
🎯 GOAL
Solo platform: Cursor
Deliverable: this note — a Phase 0–2 verdict on how to finish the already-named
  2026-08-14 catch-up G0, plus what Mission Control should say
HEADLINE: do not start a new ultra-plan or /goal until handover OWED 1–6 clear;
  "COUNTDOWN 0" ≠ parity complete
IN PARALLEL: sibling owns OWED mechanical (preflight, red-PR logs, ledger
  re-run, #429 stack watch). This lane watches CI and holds the @ref slice
  PARKED until approval. Do not claim sibling files.
DEFER: the 11 capability rows; #136; drmTMB #1049/#1050; #49; D-111; #406;
  #423's Julia 1.12 test(1) fail (A8, not catch-up); any src/ work; any new
  ship G0; mixing @ref into armed #426
DISCIPLINE: verify=git show / gh / ledger receipt, never a Dropbox checkout ·
  compute=n/a (no Pkg.test, no recovery, no Documenter) ·
  closure=this note + owner answers to ≤3 questions
```

**Lane claimed:** `PLATFORM: cursor | ON BRANCH: docs/a3c-design | LANE: catch-up / docs-@ref + CI watch | OTHER LANES: 10 live (incl. #423 A8, #428 A11, #426 handover, #406 foreign)`

---

## WHAT THE BRAIN ALREADY KNOWS

Cited. Semantic search (`search_notes`, `search_all_projects: true`) plus
deterministic greps. Rung 1 MCP ran; `read_note` on vault permalinks succeeded
for D-111 / project dossier; repo-doc hits often had `permalink: None` (indexed
`docs/`, not vault pages).

| Claim | Source | Status |
|---|---|---|
| G0 already named 2026-08-14: catch up so `engine="julia"` admits what an R user actually fits. Anchor drmTMB **0.7.0** `f5ec53634`. | `git show origin/handover/2026-08-16-cursor:docs/dev-log/handover/2026-08-16-cursor-handover.md`; catch-up `LOOP/GOAL.md` | live |
| D-111: DRM.jl stays **off Julia General** until catch-up + both halves working; drmTMB likely R/CRAN first. Do not chase Registrator. | [[DECISIONS#D-111]] · [[DRM.jl General registry OUT OF SCOPE 2026-08-01]] · `shinichi-brain/projects/drm-jl` | accepted |
| D-94: R halves sequenced first for the drmTMB / DRM.jl pair. Julia idleness can be deliberate. | [[DECISIONS#D-94]] | accepted |
| Export-name presence ≠ capability parity. A row promotes only on a native-vs-Julia same-target comparison. Direct DRM.jl evidence is not R-via-Julia support. | A0 ledger `docs/dev-log/evidence/2026-08-14-drmtmb-parity-ledger.md` (`git show origin/main:…`); catch-up `LOOP/GOAL.md` | live |
| **No capability row is `supported` on drmTMB** — all 11 are `partial` / `experimental` / `unsupported` by drmTMB's claim-demotion. Promoting a row is a **drmTMB claim decision**, not a DRM.jl export. | same A0 ledger; Dropbox `LOOP/checkpoint.md` (stale copy, same finding) | live |
| Workflow G fixtures still record **drmTMB 0.6.0** in `expected.meta.toml` (#392). Campaign anchor is 0.7.0. That split is known, not a new G0. | `docs/src/r-julia-bridge.md` on this checkout; `AGENTS.md` parity-anchor paragraph | live |
| 2026-08-14 vault log said *"No owner-named G0"* (PR #407 idle handover). The catch-up G0 was named **later the same day in-repo**, not in the vault. | [[AGENT_LOG-archive]] 2026-08-14 DRM.jl Claude handover | dated prior |
| Live `memory/AGENT_LOG.md` has **almost no catch-up** (board-count line only). The campaign lives in repo `LOOP/` + handover, not the vault. | `grep -in` AGENT_LOG.md | measured |
| Ultra-plan is for ≳2 h **and** multi-slice / fan-out / gates. Most arcs complete **without** it. Cursor hands Phase 3 to `/goal`, not the planning chat. Arc-loop / `/goal` requires an **approved** LOOP kit matching current reality. | `ultra-plan` / `arc-loop` / `goal` skills | doctrine |
| Mission Control `live/status/` has **no `DRM.jl.json`**. `drmTMB.json` still cites DRM.jl tip `94a47e8b` and 0.7 CRAN packaging — stale vs catch-up. Sibling owns the server; this session did not start it. | `ls ~/shinichi-brain/Shinichi/Dashboards/mission-control/live/status/` | measured |

**Brain gap (say so):** the vault does not hold the 2026-08-16 COUNTDOWN-0
handover or the 11-row inventory. Those are repo-truth. Do not re-derive a
ship G0 from D-111's "catch up" sentence — that bar is already the named G0.

---

## SWEEP RECEIPT (Phase 0.25 — default-closed)

| Surface | Evidence (command / query) | Finding | Call |
|---|---|---|---|
| **lane** | `~/shinichi-brain/tools/lane_preflight.sh "/Users/z3437171/Dropbox/Github Local/DRM.jl"` | `VERDICT: no foreign lane (claude codex) and no 2nd cursor lane in last 12h`. **10 LANES LIVE.** Newest handover on disk was the 08-14 idle file; **#426 is the live reassignment.** Silence is weak evidence. | Take **docs-@ref + CI watch** only. Do not claim A8/A11/A12/`#406` files. |
| **repo git** | `git status -sb`; `git log --oneline -15`; `git worktree list`; `git stash list`; `bash ~/shinichi-brain/tools/branch_drift_check.sh` | Dropbox: `docs/a3c-design`, **42 behind** `origin/main`, untracked `.codex/agents/shannon-coordinator.toml` (**never stage**). Scratch: `/Users/z3437171/local-scratch/lanes/DRM.jl-catchup` clean on `#426` @ `d9214fd4`. Local `docs/undocumented-export-gap` **deleted** (no unique commits). Implementation on both trees **stopped**. | Resume the **named G0**, not this stale checkout. Do not `git checkout` over Dropbox. |
| **handover / tip** | `git show origin/handover/2026-08-16-cursor:docs/dev-log/handover/2026-08-16-cursor-handover.md` | Written at `origin/main` = `0a4c2dc9`. Headline: COUNTDOWN 0 · **17 raw / 17 accounted** (superseded below) · 11 capability rows · CLOSURE PASS. OWED 1–6 before the 11 rows. | Reuse G0. Do not invent a replacement. |
| **ledger (Hopper, after this note)** | `docs/dev-log/evidence/2026-08-16-parity-ledger-remeasure.md` (Hopper `d167f1a8`; unstaged on leftover `docs/a3c-design` — **do not git add it there**) | **COUNTDOWN 0 export gaps (18 raw, 18 accounted)** · 11 unsupported (`claim_status != supported`: 6 partial · 4 experimental · 1 unsupported) · 14 closed gates · CLOSURE PASS · **no capability row is `supported`**. `#424` MERGED. `origin/main` **`394b62d9`**. | Cite **18/18**, not the handover’s 17/17. Still not "parity complete." |
| **twin** | `git show origin/main:docs/dev-log/evidence/2026-08-14-drmtmb-parity-ledger.md` (did **not** run the Python ledger here; did **not** checkout drmTMB) | A0: 11 rows, none `supported`; honesty invariant PASS. drmTMB #1049/#1050 remain STOP GATE. | Co-opt the ledger; do not start drmTMB work. |
| **LOOP kit** | Read catch-up `LOOP/{GOAL,checkpoint,arcs,ultra-plan}.md`; Dropbox `LOOP/{GOAL,checkpoint}.md` | Approved G0 **exists**. Catch-up `ultra-plan.md` is the A-fix…A4d export-gap campaign — **exhausted** (A4c–A6 shipped; A4a/#49 and A4b/not-ported resolved). Catch-up `checkpoint.md` still says NEXT=A4c — **stale**. Dropbox LOOP is A3-era — **staler**. The 11 rows are **not** on that arc list. | Reuse G0 + fence. Do **not** `/goal` the stale kit (it would redo A4c). Refresh LOOP only after OWED 1–6, as a **new** arc list under the same G0. |
| **#423 (A8)** | worker diagnosis of `test (1)` | RED on Julia **1.12**: `abs(ρ̂ - residual_rho) = 0.183 ≮ 0.15` at `test_meta_vcov_bivariate.jl:142`. `test (1.10)` + Documenter **green**. Not an `@ref` defect. | **A8's problem. Do not "fix" it on catch-up.** |
| **@ref gap** | worker detector on current main | **24** undocumented `@ref` targets, **16 exported**. Still OWED. PARKED until this plan is approved. | After approval: **new docs branch from current `main` in the scratch worktree**. **Not** onto armed `#426`. |
| **brain** | MCP `search_notes` ×4 (`DRM.jl R-Julia parity engine=julia catch-up`; `ultra-plan vs arc-loop vs /goal DRM.jl LOOP kit`; `D-111 Julia General registry DRM.jl`; `engine=julia catch-up G0 drmTMB 0.7.0`); `read_note` `shinichi-brain/projects/drm-jl`, `DRM.jl General registry OUT OF SCOPE 2026-08-01`; `grep -in "DRM.jl parity\\|engine julia\\|catch-up" memory/AGENT_LOG.md` (almost empty); `grep -in "D-111\\|catch-up" memory/DECISIONS.md`; `grep` AGENT_LOG-archive + journal | D-111/D-94 live. Catch-up G0 is **repo-local**. Vault 08-14 line is pre-G0. | Reuse decisions; do not rebuild the campaign from the vault. |
| **Mission Control** | `ls …/mission-control/live/status/` | No DRM.jl board. `drmTMB.json` stale (`94a47e8b`, 0.7 packaging). Server not started. | Recommend a one-line update; sibling applies. |
| **Verdict** | — | Genuinely new = OWED remainder (`@ref` on a **new** docs branch; #428 owner call; #429 stack; ledger after further merges) then an **inventory** of the 11 rows. Not a new campaign. | **reuse G0 / resume after OWED / do not build-the-gap yet** |

---

## ultra-plan vs arc-loop vs /goal — verdict

**Finish OWED 1–6, then a narrow `/goal` for the 11 rows — do not start
`/ultra-plan` or `/arc-loop` now.**

### WHY NOW

1. **G0 already exists** (2026-08-14). A new ultra-plan would replace it. The
   user forbade inventing a ship G0.
2. **The approved LOOP kit is exhausted and stale.** `LOOP/ultra-plan.md` closed
   the *export-gap* campaign (countdown 0). Its checkpoint still points at A4c.
   `/goal` or `/arc-loop` against that kit would faithfully re-do finished work.
3. **OWED 1–6 are not a campaign.** They are merge-watch, one owner call
   (#428), a stacked PR (#429), a ledger re-run (already done once this
   morning), and a docs-`@ref` slice. Ultra-plan's gate (≳2 h **and**
   multi-slice / fan-out) does not fire. Arc-loop's gate (run an approved plan
   to completion) does not fire either — the remaining work is not on that plan.
4. **The 11 rows are the next frontier, not today's work.** Handover: *"Then,
   and only then."* They are also **not 11 missing engines**: A0 says none is
   `supported` because drmTMB demoted the vocabulary. First act after OWED is
   an **inventory** (claim_boundary vs missing cell vs drmTMB-side claim). That
   inventory decides whether a later ultra-plan is needed. Guessing now is how
   a wrong plan gets executed for hours.
5. **Cursor doctrine:** after a *future* G0 refresh, Phase 3 lives in `/goal`,
   not this planning chat. Claude's `/arc-loop` is the same LOOP kit on another
   platform — not a second philosophy, and not today's launch.

### RECOMMENDATION

| Now (unattended, reversible) | After OWED 1–6 + owner answers | Never from this lane |
|---|---|---|
| Sibling continues OWED mechanical. This lane holds `@ref` **PARKED**. Watch CI. Do not arm anything. | Cut **`docs/undocumented-export-@ref`** (name TBD) from **current `main`** (`394b62d9` or newer) **in** `~/local-scratch/lanes/DRM.jl-catchup`. Then inventory the 11 rows under the **same** 2026-08-14 G0. If that inventory is linear and ≲2 h → `/goal`. If it fans out / needs gates → **then** a *narrow* ultra-plan that **extends** the G0, does not replace it. | New ship G0; `/ultra-plan` of "achieve R↔Julia parity"; `/goal` on the stale A4c kit; `#423` 1.12 fix; post-arm push to `#426`; drmTMB merge; D-111; `#136`; `#49`; `#406` |

### IF YOU DO NOT MIND (safe default)

Treat `#423`'s Julia 1.12 fail as **A8's problem** (do not touch). `#428`
auto-merge is **already ARMED** — catch-up must not unarm or re-arm it; that
choice is yours. After you approve this note, cut the `@ref` docs branch from
current `main` in the scratch worktree (fenced paths below).
Do not start a 11-row `/goal` until that branch is up and the inventory exists.

### WHAT CONTINUES unattended

- Already-armed PRs land themselves on green. **Do not arm new ones.**
- `#429` stays stacked on `#423`; do not rebase.
- Ledger re-run after further merges (sibling).
- CI watch. Easy on this Mac — no `Pkg.test`, no recovery, no Documenter.
- Mission Control server stays with the sibling. Recommended one-liner when
  they next write status:

  > DRM.jl catch-up: COUNTDOWN 0 export gaps (**18 raw, 18 accounted**) @ `394b62d9` (past `#424`); CLOSURE
  > PASS; 11 capability rows remain. OWED: `@ref` (24/16) on a **new** docs
  > branch, not `#426`; `#428` owner call; `#423` `test(1)` is A8's 1.12
  > tolerance, not catch-up. D-111 OFF. `#136` OPEN.

### `@ref` after approval — file fence

**Scratch tree yes, `#426` branch no.** `#426` is an armed handover PR; mixing
docs fixes into it is a post-arm push (the failure the handover already paid
for).

Cut a **new** docs branch from current `main` *in*
`/Users/z3437171/local-scratch/lanes/DRM.jl-catchup`.

**Must NOT include** (worker's draft that would have touched these is
**RETRACTED**):

- `docs/src/cross-family.md`
- `docs/src/reference/structured-effect-markers.md`
- `docs/make.jl`
- `LOOP/checkpoint.md`
- `docs/dev-log/coordination-board.md`
- `src/**`
- `test/runtests.jl`

Two different fixes, not one blanket: exported public API → a reference
`@docs` block; `_`-prefixed internals → drop `@ref`, keep a plain code span.

---

## TEAM RAISED

Siblings may return independently. Lines below are **AGENT-INFERRED** until
they do.

```
TEAM RAISED
  Hopper — noticed: the 11 rows are drmTMB claim vocabulary
    (partial/experimental/unsupported), not 11 missing Julia exports; Workflow G
    fixtures still say 0.6.0 while the campaign anchors 0.7.0.
    why it matters: promoting a row from this tree would be a drmTMB claim.
    recommendation: inventory first; keep DRM_PARITY_TESTS=1 on any bf() touch.
    question: none that the ledger cannot answer after the next re-run.
    default: do not promote any row to `supported` from DRM.jl.

  Rose — noticed: "COUNTDOWN 0" + "CLOSURE PASS" is an honesty scoreboard, not
    a public-parity claim; MC still cites DRM.jl @ 94a47e8b; #423 red is a
    measured 1.12 recovery miss, not a docs @ref.
    why it matters: a catch-up "fix" of A8's test would launder a tolerance
    into the wrong lane and could move a published number.
    recommendation: keep the phrase "export-gap countdown at 0; 11 rows still
    unsigned"; never "R–Julia parity complete."
    question: see owner Q2 (#423) and Q1 (#428).
    default: hold the claim fence; do not touch #428's already-armed auto-merge.

  Shannon — noticed: 10 live lanes; Dropbox 42 behind on docs/a3c-design;
    scratch clean on armed #426; a deleted local @ref branch had no unique
    commits; #406 is foreign DIRTY.
    why it matters: bleed-through is the failure mode, not concurrency.
    recommendation: @ref = new branch from main in the scratch worktree;
    never stage shannon-coordinator.toml; never checkout drmTMB.
    question: none — D-87, owner decides overlap.
    default: this lane stays docs-@ref + CI watch.

  Pat — noticed: an R user still cannot treat engine="julia" as "whatever
    drmTMB fits"; reader docs still say Experimental.
    why it matters: updating "what can I fit today?" before the 11-row
    inventory would over-promise.
    recommendation: leave the reader surface until the inventory exists.
    question: none today.
    default: no Documenter rebuild (CPU + this session's fence).

  Ada — synthesis: the named G0 still holds. The export-gap LOOP is done.
    Today's work is OWED remainder, not a new plan. The 11 rows need an
    inventory before anyone picks ultra-plan vs /goal for them.
```

---

## DEFER fence

Do **not** from this plan:

- Invent a new ship G0 or retitle the campaign "R–Julia parity."
- Start `/ultra-plan` or `/arc-loop` / `/goal` against the stale A4c kit.
- Touch `#423` / `test_meta_vcov_bivariate.jl` (A8; Julia 1.12 `0.183 ≮ 0.15`).
- Touch `#428` auto-merge (already **ARMED**; owner: unarm vs leave armed). Rebase `#429` onto main.
- Merge drmTMB `#1049` / `#1050`. Touch `#406`. Close `#136`. Unpark `#49`.
- Chase D-111 / JuliaRegistrator.
- Vendor drmTMB GPL source.
- Stage `.codex/agents/shannon-coordinator.toml` or `.worktrees/`.
- `git checkout` the shared drmTMB tree.
- Mix `@ref` into armed `#426`.
- Edit the retracted file set: `docs/src/cross-family.md`,
  `docs/src/reference/structured-effect-markers.md`, `docs/make.jl`,
  `LOOP/checkpoint.md`, `docs/dev-log/coordination-board.md`, `src/**`,
  `test/runtests.jl`.
- Run `Pkg.test`, recovery, or a Documenter build on this Mac.

---

## ADA'S RECOMMENDATION

**Finish OWED 1–6 (with `@ref` on a new docs branch after you approve), then a
narrow `/goal` that first inventories the 11 rows under the existing 2026-08-14
G0.** Skip ultra-plan until that inventory shows real fan-out. Skip arc-loop
until LOOP/`checkpoint.md` and `arcs.md` are rewritten to match `394b62d9`+
reality.

---

## QUESTIONS STILL OPEN (max 3)

**Q1 — `#428` (A11, `src/`).** Auto-merge is **already ARMED** (Shannon census).
The handover said leave it unarmed. Live question: **unarm vs leave armed** —
not “leave unarmed or arm.” Catch-up must not touch that.
**WHY NOW:** it is the only `src/`-touching open PR on the catch-up stack;
handover and live state disagree.
**RECOMMENDATION:** **unarm** (restore the handover fence) unless you
explicitly want engine auto-merge. This lane will not flip it either way.
**IF YOU DO NOT MIND:** leave armed (do not touch).
**WHAT CONTINUES:** CI watch; no `src/` edits here.

**Q2 — `#423` `test (1)` on Julia 1.12.** Measured `abs(ρ̂ - residual_rho) =
0.183 ≮ 0.15` in `test_meta_vcov_bivariate.jl:142`. `test (1.10)` and
Documenter are green. This is **A8**, not catch-up, and not `@ref`.
**WHY NOW:** a helpful agent will "just fix the red PR" and contaminate two
lanes.
**RECOMMENDATION:** **ignore it here.** Let A8 own the tolerance / recovery
question (measured spread first; never fit to one 1.12 run).
**IF YOU DO NOT MIND:** ignore as A8's problem.
**WHAT CONTINUES:** `#429` stays stacked; do not rebase.

**Q3 — after OWED, do the 11 rows still sit under the 2026-08-14 G0, or do you
want a short G0 dialogue before `/goal`?**
**WHY NOW:** the approved ultra-plan's arc list is exhausted; the 11 rows were
never on it. Extending the G0 is cheaper than replacing it — but only you can
say the finish line is still "admits what an R user actually fits" rather than
"every drmTMB row reads `supported`" (that second sentence is a drmTMB claim).
**RECOMMENDATION:** keep the 2026-08-14 G0; require an inventory before any
`/goal`; do **not** treat row-status `supported` as the finish line.
**IF YOU DO NOT MIND:** same.
**WHAT CONTINUES:** `@ref` PARKED until you approve this note; then the new
docs branch only.

---

## Mission Control (recommended; sibling applies — server not started)

Paste when the sibling next writes `live/status` (no DRM.jl.json exists today):

- **focus:** DRM.jl `engine="julia"` catch-up — export-gap countdown **0**
  (**18 raw, 18 accounted**) at `394b62d9` (`#424` in); CLOSURE PASS; **11
  capability rows** still unsigned (none `supported`).
- **next_safe_action:** after owner approval of this note, new docs-`@ref`
  branch from `main` in the scratch worktree; do not touch `#423` / `#428` /
  `#426`.
- **do_not:** claim "R–Julia parity complete"; touch `#428` auto-merge;
  merge drmTMB `#1049`/`#1050`; chase D-111; close `#136`.
