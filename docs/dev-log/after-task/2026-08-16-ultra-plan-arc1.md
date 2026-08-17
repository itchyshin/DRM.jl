# 2026-08-16 — Ada Phase 0–2: ultra-plan for Arc 1 (inventory only)

**Lane:** plan Arc 1 inventory (read-only through Phase 2).
**Author:** Ada (Shannon speaking). **No nested Task subagents ran.**
**Platform:** Cursor. **Cursor cannot EnterPlanMode** — this session stayed
strictly read-only except this note. **No Phase 3. No `/goal`. No `/arc-loop`.
No merges. No `src/` edits.** Still unexecuted.

---

## 🎯 GOAL

```
🎯 GOAL
Solo platform: Cursor (this planning session) → /goal only after Shinichi
  approves G0 (fresh chat in ~/local-scratch/lanes/DRM.jl-catchup, not this
  Dropbox leftover checkout)
Deliverable: ordered, claim-fenced backlog of the 11 parity-ledger rows
  with claim_status ≠ supported, plus one recommended first *later*
  implement slice — not implementing any of the 11 in this arc
HEADLINE: Arc 1 inventory — ordered backlog of 11 unsupported rows
IN PARALLEL: 4 Grok recon batches (Phase 1.5 admitted trio · remaining
  partials · experimentals minus #428 · owned+fence), then Ada consolidate
DEFER:
  - implementation PRs / src/ edits / flipping TSV to supported
  - Arc 1′ (ordinary-RE REML, :natgrad, VA/#136, AGHQ, #49) — no ledger
    row maps to those chips
  - stealing #428 cross_family_latent
  - inventing twin Δ / “parity complete” / “become GLLVM”
  - Totoro/DRAC recovery unless owner asks
  - full Pkg.test
  - leftover Dropbox docs/a3c-design commits
  - leftover scratch docs/arc0-after-task (ahead 1 / behind 4)
  - #136 OPEN · #49 PARKED · D-111 OFF
  - drmTMB #1049/#1050 STOP GATE · GPL vendoring
  - staging .codex/agents/shannon-coordinator.toml
  - checkout of the shared drmTMB tree
  - feat/a11, feat/a8, feat/a12, fix/a10, #406, #423, #429
DISCIPLINE: verify=each row classified from cited TSV claim_boundary +
  next_action + existing fixture path (or explicit NONE) · compute=n/a
  (easy on this Mac; no recovery) · closure=Shinichi approves G0
```

**Lane claimed:** `PLATFORM: cursor | ON BRANCH: docs/a3c-design (leftover; do not build here) | LANE: plan Arc 1 inventory | OTHER LANES: 9 live — do not steal feat/a11 (#428), feat/a8 (#423), feat/a12 (#429), fix/a10, #406, main-direct`

---

## Plan-mode note (once)

Cursor cannot flip Plan mode from here. Phases 0–2 ran read-only. Execution
waits for explicit G0. After approval, **do not continue in this chat** —
paste the `/goal` prompt below into a **fresh** Cursor chat opened on the
scratch worktree.

---

## Decision LOCK (recommend — he approves at G0)

**Arc 1 = inventory-first capability backlog** under the **2026-08-14
campaign G0** (admit what an R user actually fits). It does **not** replace
that G0. It does **not** implement the 11 rows. It produces an ordered
backlog plus one recommended first implement slice for a *later* G0.

**"11 unsupported" means `claim_status ≠ supported`**, not 11 rows with
status `unsupported`. Split: **6 partial · 4 experimental · 1 unsupported**.
Zero rows are `supported`. The sole literal-`unsupported` row is
`engine_control_surface` (design fence, not a port).

---

## PREFLIGHT (Phase 0.2)

```
bash ~/shinichi-brain/tools/lane_preflight.sh "/Users/z3437171/Dropbox/Github Local/DRM.jl"
```

**VERDICT:** `FOREIGN LANE ACTIVE (direct-to-main)`. Concurrency allowed;
bleed-through is not (D-88). This lane writes **only this untracked plan
note** on leftover `docs/a3c-design`. It does not claim `src/`, live PR
files, or `origin/main`.

**9 LANES LIVE** (do not claim their files): `#429` A12 · `#428` A11 ·
`#425` A10 · `#423` A8 · `#421` rosetta · `#420` loop items · `#406`
github-auto-merge · `main-direct` · leftover `docs/a3c-design`.

**COORD BOARD:** committed to `origin/main` (reaches other lanes). This
plan does **not** edit it.

**SESSION OWNERSHIP:** `PLATFORM: Cursor`. Dropbox dirty = prior-session
untracked notes (this file + Arc 0 plan + Hopper remasure + Pólya +
ultra-vs-loop + never-stage `shannon-coordinator.toml`). Not a concurrent
editor.

---

## Phase 0.3b — two-bar

Owner note this invocation: prefer **Cursor Models / Grok 4.6 high-fast**
(Other Models historically ahead, ~66% vs ~51%). On-demand **disabled**.
Grok Bot unused — leave unused.

| Bar | Route this plan |
|---|---|
| Cursor Models | **All recon + consolidate + Rose** — Grok 4.6 high-fast |
| Other Models | Do not burn on recon to even the meters |
| Grok Bot | unused |
| On-demand | disabled |

---

## Evidence already on disk (cite; do not re-derive)

| File | Role | Present? |
|---|---|---|
| scratch `docs/dev-log/evidence/2026-08-16-arc1-eleven-rows.md` | 11 rows + claim_boundary; drmTMB `097bed1e2` | **yes** |
| scratch `docs/dev-log/evidence/2026-08-16-arc1-rose-fence.md` | allowed/forbidden claims; two scoreboards | **yes** |
| Dropbox `docs/dev-log/after-task/2026-08-16-ultra-plan-next-arc.md` | Arc 0 plan; deferred Arc 1 here | **yes** |
| Dropbox `docs/dev-log/evidence/2026-08-16-parity-ledger-remeasure.md` | Hopper remasure (older tip `9e42d2c94`; same 11 IDs) | **yes** |
| scratch `docs/dev-log/evidence/2026-08-16-arc1-lane-collisions.md` | Shannon | **absent** — census from `lane_preflight` above |
| scratch `docs/dev-log/evidence/2026-08-16-arc1-hopper-twin-map.md` | Hopper twin map | **absent** — TSV `next_action` read via `git show` below |

**Arc 0 status (do not redo):** `#430` `@ref` and `#431` after-task are on
`origin/main`. Scratch `docs/arc0-after-task` @ `659e0824` says Arc 0 DONE,
Arc 1 DEFER — **ahead 1 / behind 4**. Do not inventory on that leftover
branch.

---

## The 11 rows (from eleven-rows + live TSV `next_action`)

`claim_boundary` from eleven-rows (drmTMB `origin/main` `097bed1e2`).
`next_action` from this session:

```
git -C "/Users/z3437171/Dropbox/Github Local/drmTMB" show origin/main:inst/extdata/julia-capabilities.tsv
```

No drmTMB checkout. Status unchanged vs remasure (`9e42d2c94` → `097bed1e2`).

| # | capability_id | status | next_action (abbrev.) | Working classification (Ada prior — inventory confirms) |
|---|---|---|---|---|
| 1 | `base_gaussian_location_scale` | partial | Keep coef/logLik parity on exact bridge payloads (remeasured 2026-08-15) | Phase 1.5 admitted — **drmTMB TSV claim**, not a missing engine |
| 2 | `biv_gaussian_residual` | partial | Keep rho12 result-shape; do not promote beyond experimental | Phase 1.5 admitted — TSV claim |
| 3 | `gaussian_phylo_mean` | partial | Keep first phylo-mean; do not widen to sigma-phylo | Phase 1.5 admitted — TSV claim |
| 4 | `gaussian_response_mask` | partial | Keep mask tests Gaussian-only | Fixture/audit gap; **#49** adjacent — do not unpark |
| 5 | `biv_q4_phylo_reml` | partial | Bank fit-specific CI/status parity before release language | **Same-target bridge-parity gap** on an already-implemented q4 REML path (Scoreboard B). Ada's default first *later* implement look |
| 6 | `plain_binomial_nonphylo` | partial | Keep Workflow G live R gate green; not CRAN-default | Fixture exists (`expected.toml`); promotion is a claim, not a port |
| 7 | `phylo_count_large_p` | experimental | Keep phylo-count smoke + Workflow G FE; do not promote | Smoke-only; large-p evidence, not a new family |
| 8 | `phylo_gamma_beta_binomial` | experimental | **Add comparator or parity evidence** before promoting | Missing comparator — candidate #2 after inventory |
| 9 | `general_covariance_structured` | experimental | Compare accepted families with the R gate (comparison now exists) | Gate-compare exists; widening is a claim |
| 10 | `cross_family_latent` | experimental | Resolve mixed-family API mismatch before any public promotion | **#428 A11 owns this. Inventory only. Do not steal.** |
| 11 | `engine_control_surface` | unsupported | Design `engine_control` before relaxing the gate | Design fence. Leave `unsupported`. |

---

## SWEEP RECEIPT (Phase 0.25 — default-closed)

| Surface | Evidence (command / query) | Finding | Call |
|---|---|---|---|
| **lane** | `~/shinichi-brain/tools/lane_preflight.sh` on Dropbox DRM.jl | FOREIGN LANE ACTIVE (direct-to-main); 9 live; board committed | Take **plan Arc 1 inventory** only |
| **repo git** | `git status -sb`; `session_ownership.sh`; `branch_drift_check.sh`; `git worktree list`; `git stash list`; `git log --oneline -12`; `git log origin/main -8` | Dropbox: `docs/a3c-design`, **0 ahead / 57 behind** `origin/main`. Untracked prior notes + this file. `origin/main` has `#430`/`#431` (Arc 0 landed). Scratch: `docs/arc0-after-task` **ahead 1 / behind 4**, untracked eleven-rows + rose-fence | **Do not build on Dropbox or leftover Arc 0 branch.** New docs branch from `origin/main` in scratch |
| **siblings** | `ls …/evidence/2026-08-16-arc1-*` | eleven-rows + rose-fence present; Shannon collisions + Hopper twin-map **absent** | Cite present files; TSV `next_action` substitutes for twin-map |
| **ledger / TSV** | eleven-rows; `git show origin/main:inst/extdata/julia-capabilities.tsv` (drmTMB, no checkout) | COUNTDOWN 0 · 18/18 · 11 rows · CLOSURE PASS · none `supported` · tip `097bed1e2` | Cite 18/18; do not ship "parity complete" |
| **twin drmTMB** | `git -C drmTMB log origin/main -1 --oneline` | `097bed1e2` (#1055 winbuilder). Dirty leftover twin checkout **not** used | Read-only `git show`; never checkout; STOP GATE `#1049`/`#1050` |
| **brain** | MCP `search_notes` `DRM.jl Arc 1 inventory 11 unsigned capability rows 2026-08-14 G0 engine=julia` (`search_all_projects: true`) | No vault page holds this Arc 1 decision. Campaign G0 is **repo-local** | Reuse 2026-08-14 G0; do not invent a ship G0 |
| **deterministic grep** | `grep -in "Arc 1 inventory\\|11 unsigned\\|engine_control_surface" memory/AGENT_LOG.md` → none. `grep -in "D-111\\|D-94\\|D-34" memory/DECISIONS.md` → live. `grep` `OPEN_QUESTIONS.md` → none for this inventory. `grep` `journal/` → no 2026-08-16 Arc 1 line. `grep` `projects/deep-research/README.md` → dr18/dr19 are **biv lognormal/Student** (already accounted exports), not this 11-row inventory | No vault decision says "implement the 11 next" | **reuse** G0 + Rose fence; **resume** after Arc 0; **build-the-gap** = inventory backlog only |
| **PRs** | preflight open-PR list | `#428` A11 `src/` live; `#423` A8; `#429` stacked | Do not steal; inventory `#428` as owned |
| **two-bar** | this invocation | Other Models historically ahead (~66% vs ~51%) | Scout/recon on **Cursor Models · Grok 4.6 high-fast** |
| **Verdict** | — | Genuinely new work this lane can own: **the inventory backlog on a new docs branch**. Implementation of any row is a later G0 | **reuse G0 / resume after Arc 0 / build-the-gap = inventory** |

---

## WHAT THE BRAIN ALREADY KNOWS

| Claim | Source | Status |
|---|---|---|
| Campaign G0 (2026-08-14): catch up so `engine="julia"` admits what an R user actually fits. Anchor drmTMB **0.7.0** | catch-up `LOOP/GOAL.md` · handover | live — **keep; this arc is a slice under it** |
| D-111: stay off Julia General | [[DECISIONS#D-111]] | accepted |
| D-94: DRM.jl behind **drmTMB**, not GLLVM.jl | [[DECISIONS#D-94]] · Pólya 2026-08-16 | accepted |
| Export-name presence ≠ capability parity. No ledger row is `supported` | A0 + Hopper remasure + eleven-rows | live |
| `#136` OPEN · `#49` PARKED · `#13` natgrad FAIL | LOOP + Rose fence + capability-status | **PROTECTED** |
| Arc 0 `@ref` landed (`#430`/`#431`) | `origin/main` | **done — do not redo** |
| Ultra-plan Phases 0–2 on Cursor; Phase 3 = `/goal` in a fresh chat | Cursor ultra-plan / goal adapters | doctrine |

---

## WHAT SHINICHI TOLD US (this invocation)

- Decide on Arc 1, then `/ultra-plan` it for approval.
- Arc 1 = inventory-first backlog under the 2026-08-14 G0.
- Deliverable after G0: ordered claim-fenced backlog + recommended first
  implement slice — **not** implementing all 11.
- Explicitly NOT: “parity complete”; Arc 1′ chips unless a ledger row maps
  (none do); stealing `#428`; inventing twin Δ; flipping TSV to `supported`.
- Stay read-only through Phase 2. Cursor cannot EnterPlanMode — say so once.
- Prefer Cursor Models / Grok (Other Models ahead).

---

## TEAM RAISED

Shannon collisions + Hopper twin-map files were **absent**. Lines use
charters + eleven-rows + Rose fence + live TSV `next_action`.

```
TEAM RAISED
  Hopper — noticed: next_action on the 6 partials is mostly “keep tests,
    do not promote”; only phylo_gamma_beta_binomial says “add comparator”;
    biv_q4_phylo_reml says “bank CI/status parity”; cross_family says
    “resolve mixed-family API” (= #428).
    why it matters: treating all 11 as missing engines would start the
    wrong work.
    recommendation: classify each row as TSV-claim / fixture-gap /
    owned / fence; do not promote a TSV row from DRM.jl.
    question: none the inventory cannot answer.
    default: first later implement look = biv_q4_phylo_reml fixture,
    not a Phase 1.5 TSV flip.

  Rose — noticed: COUNTDOWN 0 + CLOSURE PASS is not a public-parity
    claim; Arc 1′ orange chips are not ledger rows; #428 is live src/.
    why it matters: one PR that “clears the 11” or a TSV flip is a
    claim lie.
    recommendation: inventory prose quotes claim_boundary; one-issue
    PRs later; never “R–Julia parity complete.”
    question: Q1 (separate G0 for implement) and Q2 (fixture vs TSV).
    default: hold the fence in rose-fence.md §2–3.

  Shannon — noticed: 9 live lanes; Dropbox 57 behind; scratch Arc 0
    branch drifted (ahead 1 / behind 4); foreign main-direct.
    why it matters: bleed-through, not concurrency.
    recommendation: new docs branch from origin/main in scratch;
    never stage shannon-coordinator.toml; never checkout drmTMB.
    question: none — D-87, owner decides overlap.
    default: this lane stays plan → then inventory docs only.

  Noether — noticed: q4 REML is already implemented; the ledger gap
    is same-target bridge parity, not a missing Laplace path.
    why it matters: “implement biv_q4_phylo_reml” as an engine port
    would regress the verified core for no reason.
    recommendation: src/ frozen this /goal; later fixture work must
    not touch the verified q=4 path (logLik −256.51 / 2.18×).
    question: none today.
    default: src/ frozen.

  Pat — noticed: reader pages still Experimental; inventory must not
    rewrite “what can I fit today?”
    why it matters: a backlog that sounds like a ship list over-promises.
    recommendation: backlog is an internal ordered list, not a reader
    page rewrite.
    question: none today.
    default: no Documenter rebuild.

  Pólya — noticed: D-94 + transferable three already bind (Rose fence,
    no invented Δ, leftover discipline). VA/natgrad/GLLVM stay DEFER.
    recommendation: constraints, not slices.
    question: none.
    default: do not implement from the scout.

  Ada — synthesis: keep the 2026-08-14 G0. NEXT = Arc 1 inventory
    only. Recommended first *later* implement look:
    biv_q4_phylo_reml (bridge-parity fixture). Confirm in S5.
```

---

## ADA'S RECOMMENDATION

**This `/goal` = inventory only.** Four Grok batches classify the 11 rows;
Ada writes one ordered backlog; Rose checks the claim fence. **No `src/`.
No TSV flip. No implement PR.**

**Recommended first *later* implement slice** (inventory may override with
cited evidence): **`biv_q4_phylo_reml`** — bank same-target CI/status
parity. Why not the others: rows 1–3 are already Phase 1.5 admitted (drmTMB
claim); `#428` owns row 10; row 11 is a design fence; row 8 is the runner-up
(missing comparator).

**IF YOU DO NOT MIND:** approve G0 for inventory only; keep 2026-08-14 G0;
require a **new** G0 before any implement PR; default first-look
`biv_q4_phylo_reml` unless inventory cites a cheaper fixture.

**WHAT CONTINUES unattended:** already-armed PRs; `#429` stays stacked;
no new auto-merge from this lane; no `Pkg.test`; no recovery; no drmTMB
checkout.

---

## DECISIONS LOCKED (pending G0)

1. Mission stays the 2026-08-14 G0.
2. This `/goal` inventories **only**. It does not implement.
3. Workspace = scratch worktree, **new docs branch from `origin/main`**.
4. `src/` frozen. `#136` open. `#49` parked. D-111 off. `#428` not stolen.
5. Verify = every row has a class + cited `claim_boundary` / `next_action`
   / fixture path (or NONE). No full `Pkg.test`. No Totoro/DRAC.
6. D-94: behind drmTMB, not GLLVM. Rose fence binds all prose.

---

## QUESTIONS STILL OPEN (max 3)

**Q1 — After this inventory, does implementation need a new G0?**
**WHY NOW:** a helpful `/goal` will “just start the first slice.”
**TEAM VIEW:** Rose/Ada — inventory and implement are different
irreversibility classes (docs vs `src/` / fixtures / claims).
**RECOMMENDATION:** **yes — new G0 before any implement PR.**
**IF YOU DO NOT MIND:** new G0.
**WHAT CONTINUES:** inventory `/goal` regardless.

**Q2 — May the recommended first implement slice be a drmTMB TSV
promotion of an already-admitted Phase 1.5 cell (rows 1–3)?**
**WHY NOW:** those rows look “closest to `supported`.” Promoting them
is a drmTMB claim (STOP GATE `#1049`/`#1050`), not a DRM.jl cell.
**TEAM VIEW:** Hopper/Rose — first implement = DRM.jl same-target
fixture only.
**RECOMMENDATION:** **fixture only.** TSV flips stay on drmTMB, owner-named.
**IF YOU DO NOT MIND:** fixture only; Ada’s prior = `biv_q4_phylo_reml`.
**WHAT CONTINUES:** inventory classifies rows 1–3 as TSV-claim either way.

**Q3 — `#428` / `cross_family_latent`.** Inventory as **owned — skip**.
Still do not unarm/re-arm from this lane (owner call, already live).
**WHY NOW:** it is the only open `src/` PR whose `next_action` is an
API mismatch.
**TEAM VIEW:** Shannon — classify and walk around.
**RECOMMENDATION:** **owned, skip.** Do not propose a competing slice.
**IF YOU DO NOT MIND:** same.
**WHAT CONTINUES:** inventory writes one “owned by #428” row and stops.

---

## SEARCH

`none` for execution (no novelty claim). NotebookLM **not** required.
dr18/dr19 are already-accounted bivariate exports, not this backlog.

---

## SLICE TABLE (inventory only — colleague-runnable)

`SCOUT SUITABILITY: yes` — TSV + fixture-path grep + PR ownership.

Each recon agent writes **one** evidence file and returns path + 3–6
class lines. Class vocabulary (pick one per row):

`TSV-claim` · `fixture-gap` · `smoke-only` · `owned` · `fence` · `parked-adjacent`

Do **not** invent a 12th row. Do **not** edit `src/`. Do **not** flip
`capability-status.md`.

| ID | Member | model+effort | Bar | time | files / detail | dep |
|---|---|---|---|---|---|---|
| S1 RECON | Hopper | **Grok 4.6 high-fast** · low | **Cursor Models** | 20 min | Rows **1–3** (Phase 1.5 admitted). Cite `claim_boundary` + `next_action` + existing Route A/B/C fixture paths. Output: `docs/dev-log/evidence/2026-08-16-arc1-batch-partials-admitted.md` (scratch, new branch) | — |
| S2 RECON | Hopper | Grok 4.6 high-fast · low | **Cursor Models** | 20 min | Rows **4–6** (`gaussian_response_mask`, `biv_q4_phylo_reml`, `plain_binomial_nonphylo`). Find same-target fixture or write NONE. Fence `#49` on row 4. Output: `…/2026-08-16-arc1-batch-partials-rest.md` | — |
| S3 RECON | Hopper | Grok 4.6 high-fast · low | **Cursor Models** | 20 min | Rows **7–9** (experimentals minus `#428`). Output: `…/2026-08-16-arc1-batch-experimental.md` | — |
| S4 RECON | Shannon/Hopper | Grok 4.6 high-fast · low | **Cursor Models** | 10 min | Rows **10–11** only. Row 10 = owned by `#428` (cite live PR; do not steal). Row 11 = fence. Output: `…/2026-08-16-arc1-batch-owned-fence.md` | — |
| S5 | Ada | Grok 4.6 high-fast · med | **Cursor Models** | 25 min | Merge S1–S4 into **one ordered backlog** (cheapest honest next cell first; owned/fence last). Name **one** recommended first implement slice with a one-sentence why. Output: `docs/dev-log/after-task/2026-08-16-arc1-backlog.md` | S1–S4 |
| S6 Rose | Rose | Grok 4.6 high-fast · med | **Cursor Models** | 15 min | Claim-vs-evidence on the backlog: no “parity complete”; no TSV flip; no `#136`/`#49`; `#428` not stolen; sweep receipt non-vacuous. Output: short section in the backlog (or `…/2026-08-16-arc1-rose-review.md`) | S5 |
| S7 MECHANICAL-VERIFY | Hopper | Grok 4.6 high-fast · low | **Cursor Models** | 10 min | Count = 11; every ID present once; every row has a class + citation; recommended slice is not `#428` / `#136` / `#49` / `engine_control_surface` / a TSV flip. **No** `Pkg.test`. **No** recovery | S5+S6 |
| S8 RECONCILE | Melissa | — | skip | 5 min | `N/A — docs-only inventory; record in after-task if `/goal` stays one session` | S7 |

**PARALLEL:** {S1, S2, S3, S4} in **one** dispatch message.
**SEQUENTIAL:** S1–S4 → S5 → S6 → S7.

**FAN-OUT:** 0 in this planning chat. After G0, `/goal` uses **4** Grok
recon children + conductor consolidate. **FAN-OUT BUDGET:**
checkpoint=`arc1-inventory` · new children≤5/6 · scout=4 · build=0 ·
ceiling=0.

**ULTRA EFFORT:** no.
**CONTEXT BRAKE:** parent input=unknown · fresh-task trigger=**START A
FRESH TASK** after G0.
**COMPACTIONS:** n/a (planning only).
**LANE RECEIPT:** `START A FRESH TASK` · reason=G0 handoff to `/goal` in
scratch · next-task prompt=block below.
**AUTO-REVIEW:** unknown · action=none.
**D-43 PANEL:** not a milestone.
**MODELS:** all slices on **Cursor Models · Grok 4.6 high-fast** until
bars are closer. No Grok Bot. No Claude/Codex parent unless reassigned.
**ESTIMATE:** ~1–2 h wall-clock · 1 `/goal` session · no HPC.
**ARC PROGRAM:** N/A (no Arc Card).
**PREFLIGHT:** pasted above.
**REVIEW:** Rose S6 (plan critique also below).
**VERIFY:** 11-row count + class + citation + fence.
**CONSOLIDATE:** backlog after-task on the **new** docs branch (not this
Dropbox leftover).

### File fence (must not include)

- `src/**`
- `test/runtests.jl`
- `docs/src/cross-family.md` (#428)
- `docs/src/reference/structured-effect-markers.md` (#423)
- `docs/make.jl`
- `docs/design/capability-status.md` (do not flip chips)
- `docs/dev-log/coordination-board.md`
- leftover `LOOP/checkpoint.md` from the export-gap / Arc 0 kits
- `.codex/agents/shannon-coordinator.toml`

### How to cut the branch (execution, after G0)

```bash
cd /Users/z3437171/local-scratch/lanes/DRM.jl-catchup
git fetch origin
git checkout -B docs/arc1-inventory origin/main
# confirm: git rev-parse HEAD == origin/main; git status -sb clean
```

Do **not** stay on `docs/arc0-after-task`. Do **not** `git checkout` the
Dropbox tree. Do **not** start from `handover/2026-08-16-cursor`.

Copy (do not rewrite) eleven-rows + rose-fence onto the new branch if they
are not already in `origin/main`. Then run S1–S7.

---

## ROSE PLAN-REVIEW (critique of this decomposition — not an implementation)

**Sweep receipt:** present and non-vacuous. Each surface cites a command
or query (lane_preflight, git + drift, `ls` siblings, `git show` TSV,
MCP `search_notes` query string, deterministic greps on AGENT_LOG /
DECISIONS / OPEN_QUESTIONS / journal / deep-research README).

**What Rose would block**

- Calling COUNTDOWN 0 “parity complete.”
- Merging inventory + implement into one `/goal`.
- A TSV `supported` flip from this tree.
- Stealing `#428` or closing `#136`.
- Planning ordinary-RE REML / `:natgrad` / VA / AGHQ / `#49` as Arc 1
  (no ledger row maps).
- Inventory on leftover `docs/a3c-design` or drifted `docs/arc0-after-task`.

**What Rose accepts**

- Arc 1 as inventory under the existing 2026-08-14 G0.
- Four Grok batches by row group (admitted / rest-partial / experimental /
  owned+fence).
- Ada prior `biv_q4_phylo_reml` as a *later* fixture look, overridable.
- Phrase: *export-gap countdown at 0; 11 rows still unsigned.*

---

## DEFER (fenced — not in the `/goal`)

- Implementation PRs for any of the 11 rows
- Flipping `claim_status` to `supported`
- Arc 1′: ordinary-RE REML, `:natgrad`, VA/ELBO (`#136`), AGHQ, `#49`
- Stealing `#428` `cross_family_latent`
- Invented twin Δ; “parity complete”; “become GLLVM” (D-94)
- Totoro/DRAC recovery unless owner asks
- Full `Pkg.test`
- `#423` / `#429` / `#425` / `#406` / `#421` / `#420`
- Leftover Dropbox `docs/a3c-design` commits
- Leftover scratch `docs/arc0-after-task`
- D-111 / Registrator; GPL vendoring; drmTMB checkout
- Staging `.codex/agents/shannon-coordinator.toml`

---

## Paste-ready `/goal` prompt (UNEXECUTED)

After Shinichi approves G0, paste this into a **fresh** Cursor chat whose
workspace is `~/local-scratch/lanes/DRM.jl-catchup` (not the Dropbox
checkout):

```
/goal

Ultra-plan G0 approved. Run this plan to completion via LOOP/.

LANE: docs-arc1-inventory
REPO: /Users/z3437171/local-scratch/lanes/DRM.jl-catchup
PLAN: /Users/z3437171/Dropbox/Github Local/DRM.jl/docs/dev-log/after-task/2026-08-16-ultra-plan-arc1.md

READ FIRST: the approved plan → repo AGENTS.md →
  docs/dev-log/evidence/2026-08-16-arc1-eleven-rows.md →
  docs/dev-log/evidence/2026-08-16-arc1-rose-fence.md.
SCAFFOLD: in THIS scratch worktree, `git fetch origin` then
  `git checkout -B docs/arc1-inventory origin/main`.
  Do NOT stay on docs/arc0-after-task. Do NOT use the Dropbox leftover.
  Write a *new* LOOP/ kit for Arc 1 inventory only from the plan;
  do not revive the stale export-gap or Arc 0 checkpoint.
RUN: goal skill — re-read GOAL each arc; verify by LOG not exit code;
  pause at OPEN GATE; overwrite checkpoint each arc.
START ARC: S1–S4 Grok recon in one dispatch (rows 1–3 / 4–6 / 7–9 / 10–11),
  then S5 ordered backlog + recommended first later implement slice,
  then S6 Rose + S7 count check.
NEXT GATE: opening a PR for the backlog (docs only). Auto-merge last
  or leave unarmed. Implementation of any row is a NEW G0 — STOP.
VERIFY: 11 IDs once each; every row has class + citation; recommended
  slice is not #428 / #136 / #49 / engine_control_surface / a TSV flip.
COMPUTE: n/a — no Pkg.test, no recovery, no Totoro/DRAC.
FENCE: no src/; no capability-status flip; no TSV supported; no
  cross-family.md; no coordination-board; no #423/#428/#429/#406;
  #136 stays OPEN; #49 PARKED; D-111 OFF; never stage
  shannon-coordinator.toml; never checkout drmTMB.
CLAIM FENCE: do not write "R–Julia parity complete." Quote claim_boundary.
  Rose fence + no invented twin Δ (D-94 = behind drmTMB not GLLVM).
  Do not become GLLVM; do not implement VA/natgrad/AGHQ.
BARS: Cursor Models / Grok 4.6 high-fast for all recon (Other Models ahead).
```

---

## Routing receipt (planning session)

| Field | Value |
|---|---|
| PLATFORM | Cursor (read from `session_ownership.sh`) |
| Session model | Cursor Grok 4.6 (this chat) |
| bars | prefer Cursor Models / Grok (Other Models historically ahead ~66% vs ~51%); Grok Bot unused; on-demand disabled |
| Nested Task subagents | **none** |
| Phase 3 | **not started** |
| git add / commit | **not done** (untracked on leftover `docs/a3c-design`; owner did not ask) |
