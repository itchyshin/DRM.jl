# 2026-08-16 — Ada Phase 0–2: ultra-plan for `biv_q4_phylo_reml` same-target fixture

**Lane:** plan the first *implement* G0 under the 2026-08-14 campaign
(admit what an R user actually fits). **Not** a replacement of that campaign G0.
**Author:** Ada (Shannon speaking). **No nested Task subagents ran.**
**Platform:** Cursor. **Cursor cannot EnterPlanMode** — this session stayed
strictly read-only except this note. **No Phase 3. No `/goal`. No `/arc-loop`.
No merges. No `src/` edits.** Still unexecuted.

Arc 1 inventory is **DONE / in #432**. This plan implements the backlog's
recommended later slice only.

---

## 🎯 GOAL

```
🎯 GOAL
Solo platform: Cursor (this planning session) → /goal only after Shinichi
  approves G0 (fresh chat in a NEW scratch lane, not Dropbox leftover
  docs/a3c-design and not the #432 catchup worktree)
Deliverable: measured same-target DRM.jl↔drmTMB fixture for the
  biv_q4_phylo_reml cell + standalone tests + check-log + after-task
  + Rose claim fence. One issue → one branch → one PR.
HEADLINE: one same-target fixture for biv_q4_phylo_reml
  (coef + logLik + fit-specific CI/status)
IN PARALLEL: Grok recon (what drmTMB outputs exist / Julia path) +
  Boole/Hopper fixture-schema design
DEFER:
  - TSV claim_status flip to supported (drmTMB STOP GATE)
  - the other 10 unsigned ledger rows
  - VA / #136 · :natgrad · ordinary-RE REML · AGHQ
  - #428 A11 / cross_family_latent
  - #49 PARKED · D-111 OFF
  - HSquared AI-REML · interval coverage / reliability claims
  - editing Workflow G glob harness (runparity.jl / gen_fixtures.R)
  - editing test/runtests.jl while #425/#428 own it
  - leftover Dropbox docs/a3c-design commits
  - leftover scratch DRM.jl-catchup LOOP/ (#432)
  - drmTMB #1049/#1050 · GPL vendoring · shared drmTMB checkout
  - staging .codex/agents/shannon-coordinator.toml
DISCIPLINE: verify=Julia and drmTMB numbers on the SAME data/tree/formula
  within declared [tol]; CI/status fields recorded, not coverage ·
  compute=Mac-easy small cell (ask Totoro/DRAC at G0 if recovery-grade) ·
  closure=Shinichi approves G0, then /goal ships the one fixture
```

**Lane claimed:** `PLATFORM: cursor | ON BRANCH: docs/a3c-design (leftover; do not build here) | LANE: plan biv_q4_phylo_reml fixture | OTHER LANES: #432 inventory · #429 A12 · #428 A11 · #425 A10 · #423 A8 · #421 · #420 · #406 · main-direct`

---

## Plan-mode note (once)

Cursor cannot flip Plan mode from here. Phases 0–2 ran read-only. Execution
waits for explicit G0. After approval, **do not continue in this chat** —
paste the `/goal` prompt below into a **fresh** Cursor chat opened on a
**new** scratch worktree (not `#432`'s `DRM.jl-catchup`).

---

## Decision LOCK (recommend — he approves at G0)

**This G0 = one DRM.jl same-target fixture** for `biv_q4_phylo_reml`.
Campaign G0 stays **2026-08-14 admit-what-R-fits**. This does not replace it.

The q4 REML engine is already public (`src/reml_q4.jl`, `drm(method = :REML)`;
Scoreboard B; `test/test_reml_q4_allaxes.jl`). The ledger row is `partial`
because there is **no native-vs-Julia same-target cell** (coef + logLik +
fit-specific CI/status). `test/test_bridge_q4_direct_export.jl` still asserts
`"no R-via-Julia q4 bridge parity"`. That is a DRM.jl cell, not a drmTMB TSV
flip.

**Not this slice:** TSV `supported` · other 10 rows · `#428` · `#136` · `#49`
· VA/natgrad · AI-REML · interval *coverage*.

---

## PREFLIGHT (Phase 0.2)

```
bash ~/shinichi-brain/tools/lane_preflight.sh "/Users/z3437171/Dropbox/Github Local/DRM.jl"
```

**VERDICT:** `FOREIGN LANE ACTIVE (direct-to-main)`. Concurrency allowed;
bleed-through is not (D-88). This lane writes **only this untracked plan
note** on leftover `docs/a3c-design`. It does not claim `src/`, live PR
files, `#432` LOOP/, or `origin/main`.

**10 LANES LIVE** (do not claim their files): `#432` Arc 1 inventory ·
`#429` A12 · `#428` A11 · `#425` A10 · `#423` A8 · `#421` rosetta ·
`#420` loop items · `#406` github-auto-merge · `main-direct` · leftover
`docs/a3c-design`.

**COORD BOARD:** committed to `origin/main` (reaches other lanes). This
plan does **not** edit it.

**SESSION OWNERSHIP:** `PLATFORM: Cursor`. Dropbox dirty = prior-session
untracked notes (Arc 0/1 plans + remasure + Pólya + ultra-vs-loop +
never-stage `shannon-coordinator.toml`). Not a concurrent editor.

**#432 collision (new vs Arc 1 plan):** inventory PR owns
`LOOP/{GOAL,arcs,checkpoint,ultra-plan}.md` and
`docs/dev-log/evidence/2026-08-16-arc1-*.md` on scratch
`~/local-scratch/lanes/DRM.jl-catchup` (`docs/arc1-inventory`).
**Do not reuse that worktree or refresh that LOOP kit.**

---

## Phase 0.3 / 0.3b — roster + two-bar

Live session model: **Cursor Grok 4.6** (this chat). Owner instruction this
invocation: **Grok only — no Opus/Sol**. Grok Bot unused. On-demand
**disabled**.

Dated bar prior (`memory/MODEL-ROUTING.md`, 2026-08-16 morning): Cursor
Models **51%** · Other Models **66%** · Grok Bot **4%**. Other Models still
ahead → stay on Cursor Models / Grok. This plan does **not** burn Other
Models to even the meters.

| Bar | Route this plan |
|---|---|
| Cursor Models | **All recon + design + Rose + verify** — Grok 4.6 high-fast |
| Other Models | Do not burn |
| Hand off | **Codex** only if live Rscript / Julia REML fit needs the toolchain (named `HANDS TO` below). Not a Cursor parent for HPC. |
| Grok Bot | unused |
| On-demand | disabled |

---

## Evidence already on disk (cite; do not re-derive)

| File | Role | Present? |
|---|---|---|
| scratch `docs/dev-log/evidence/2026-08-16-arc1-ordered-backlog.md` | Recommended first implement = this cell; class `fixture-gap` | **yes** |
| scratch `docs/dev-log/evidence/2026-08-16-arc1-recon-s2.md` | Row 5: NONE same-target; engine on Scoreboard B | **yes** |
| scratch `docs/dev-log/evidence/2026-08-16-arc1-hopper-twin-map.md` | Twin **YES**: `drmTMB(..., REML = TRUE)` + four-axis `phylo()` + `biv_gaussian()` | **yes** |
| scratch `docs/dev-log/evidence/2026-08-16-arc1-rose-fence.md` | Cell evidence ≠ TSV flip; allowed claim #4 | **yes** |
| Dropbox `docs/dev-log/after-task/2026-08-16-ultra-plan-arc1.md` | Inventory G0; this implement = later G0 | **yes** |
| Dropbox `test/test_reml_q4_allaxes.jl` | Julia REML property test (p=16, no R numbers) | **yes** |
| Dropbox `test/test_bridge_q4_direct_export.jl` | Still: "no R-via-Julia q4 bridge parity" | **yes** |
| Dropbox `test/parity/README.md` + `GENERATING.md` | Workflow G format; runner fits **ML**, **no tree** | **yes** |
| drmTMB TSV via `git show origin/main:inst/extdata/julia-capabilities.tsv` | `partial`; next_action = bank CI/status parity; issue drmTMB#544 | **yes** (tip `d9fddfa28`) |

**Arc 1 status (do not redo):** inventory in **#432**
(https://github.com/itchyshin/DRM.jl/pull/432). Cite it; do not edit its
files until landed.

---

## What already exists vs the gap

### Julia path (do not re-port)

- Public REML: `src/reml_q4.jl` included from `src/DRM.jl`
  (`drm(method = :REML)`). Four-axis bordered correction. HANDOVER: no
  `experimental/reml_q4.jl` on tip.
- Property test: `test/test_reml_q4_allaxes.jl` — synthetic p=16, m=5,
  `bf(mu1/mu2/sigma1/sigma2 + phylo, rho12 ~ 1)`, ML vs REML
  `diag(Σ_a)_REML ≥ diag(Σ_a)_ML`. **No drmTMB numbers.**
- Bridge export: `src/bridge.jl` `_bridge_q4_*` +
  `test/test_bridge_q4_direct_export.jl` — ML point targets;
  `claim_boundary` still says no R-via-Julia q4 bridge parity.
- Verified ML core stays frozen: logLik **−256.51** / **2.18×**.

### drmTMB outputs (read-only `git show`; no checkout)

- Public twin: `drmTMB(..., REML = TRUE)` + four-axis `phylo()` +
  `biv_gaussian()`. TSV `r_bridge_status=experimental`,
  `claim_status=partial`, `issue=drmTMB#544`.
- Native TMB has **separate** q4 recovery evidence (NEWS: dense q4 REML
  recovery wants roughly `n_tip >= 200`, `n_each >= 10`). That is
  **not** this cell. Do not invent AI-REML or coverage as the twin.
- Hopper: NEWS 0.7.0 records Julia `REML=TRUE` forwarding for one q4
  cell. Confirm the exact R call in S1; do not vendor `.R`/`.cpp`.

### Why Workflow G cannot swallow this cell

`test/parity/runparity.jl` globs `fixtures/*/expected.toml` and fits
`drm(bundle, fam; data = data)` — **ML, no `tree=`**. Dropping this
fixture into that glob would skip or fail. **New path, new runner.**

---

## SWEEP RECEIPT (Phase 0.25 — default-closed)

| Surface | Evidence (command / query) | Finding | Call |
|---|---|---|---|
| **lane** | `~/shinichi-brain/tools/lane_preflight.sh` on Dropbox DRM.jl | FOREIGN LANE ACTIVE (direct-to-main); 10 live; board committed; `#432` now open | Take **plan biv_q4_phylo_reml fixture** only; new scratch lane after G0 |
| **repo git** | `git status -sb`; `session_ownership.sh`; `branch_drift_check.sh`; `git worktree list`; `git stash list`; `git log --oneline -20` | Dropbox: `docs/a3c-design`, **0 ahead / 57 behind** `origin/main`. Untracked prior notes + this file. Scratch catchup = `#432` | **Do not build on Dropbox or `#432` worktree.** New feat branch from `origin/main` in a **new** scratch lane |
| **siblings** | `ls` scratch `2026-08-16-arc1-*`; Dropbox reml/q4 tests; `test/parity/fixtures/` | Inventory + Rose fence + twin-map present. Julia REML tests exist. **NONE** `*q4*` / `*reml*` under Workflow G fixtures | **reuse** engine + inventory; **build-the-gap** = same-target fixture |
| **ledger / TSV** | `git show origin/main:inst/extdata/julia-capabilities.tsv` (drmTMB, no checkout) | Row `biv_q4_phylo_reml` `partial`; next_action CI/status; tip `d9fddfa28` | Cite; do not flip `supported` |
| **twin drmTMB** | `git -C drmTMB log origin/main -1 --oneline`; NEWS via `git show` | `d9fddfa28`. Dirty leftover twin checkout **not** used | Read-only `git show`; never checkout; STOP GATE `#1049`/`#1050` |
| **brain** | MCP `search_notes` `biv_q4_phylo_reml same-target fixture DRM.jl drmTMB` + `biv_q4_phylo_reml` (`search_all_projects: true`) | No vault page holds an implement decision. Hits are older q4 export / bridge notes, not this G0 | Reuse 2026-08-14 G0 + Arc 1 backlog; do not invent a ship G0 |
| **deterministic grep** | `grep -in "biv_q4_phylo_reml" memory/AGENT_LOG.md` → none. `AGENT_LOG-archive.md` has one 2026-06 "defended partial" line. `grep` `DECISIONS.md` → D-111 / D-94 / D-34 live; no fixture decision. `OPEN_QUESTIONS.md` → none. `journal/` → none. `projects/deep-research/README.md` → no q4-REML fixture note | No vault decision says "flip TSV" or "port the engine" | **reuse** engine + fence; **build-the-gap** = fixture |
| **PRs** | preflight + `gh pr view 432 --json files` | `#432` owns LOOP/ + arc1 evidence. `#425`/`#428` own `test/runtests.jl`. `#423` owns `tools/parity_ledger.py` / `src/DRM.jl` | New fixture paths; no `runtests.jl`; no `src/`; no ledger.py |
| **two-bar** | MODEL-ROUTING 2026-08-16 morning + owner "Grok only" | Other Models ahead (~66% vs ~51%) | All plan slices on **Cursor Models · Grok**. Codex only for live toolchain |
| **Verdict** | — | Genuinely new: **one same-target fixture + standalone test** on a new feat branch. Engine exists. TSV flip is not this repo | **reuse engine / resume after Arc 1 inventory / build-the-gap = fixture** |

---

## WHAT THE BRAIN ALREADY KNOWS

| Claim | Source | Status |
|---|---|---|
| Campaign G0 (2026-08-14): `engine="julia"` admits what an R user actually fits. Anchor drmTMB **0.7.0** | catch-up `LOOP/GOAL.md` | live — **keep; this is a slice under it** |
| Promote a cell only on native-vs-Julia same-target (coef + logLik). Direct DRM.jl ≠ R-via-Julia bridge. Export-name ≠ parity | LOOP DoD · Rose fence | live |
| D-111 OFF · D-94 behind drmTMB not GLLVM | [[DECISIONS#D-111]] · [[DECISIONS#D-94]] | accepted |
| `#136` OPEN · `#49` PARKED · `#13` natgrad FAIL | LOOP + Rose fence | **PROTECTED** |
| Arc 1 inventory recommended this cell; implement = **new G0** | ordered-backlog · #432 | **done inventory — do not redo** |
| Ultra-plan Phases 0–2 on Cursor; Phase 3 = `/goal` in a fresh chat | Cursor adapters | doctrine |

---

## WHAT SHINICHI TOLD US (this invocation)

- Next arc ultra-plan = **`biv_q4_phylo_reml` same-target fixture** (Arc 1 backlog).
- Campaign G0 still 2026-08-14; this is a **new implement G0** under it.
- Skip `#428`. `#49` PARKED. `#136` OPEN. D-111 OFF. No GPL. Never checkout
  shared drmTMB for writes.
- Avoid `#423/#429/#425/#420/#406` files until landed; prefer new
  test/parity fixture paths.
- Read-only through Phase 2. Cursor cannot EnterPlanMode — say once.
- Grok only — no Opus/Sol. Easy on Mac; Totoro/DRAC if recovery needed,
  ask at G0.
- Do not execute. Owner questions ≤3 + paste-ready `/goal`.

---

## TEAM RAISED

```
TEAM RAISED
  Hopper — noticed: twin YES (REML=TRUE + four-axis phylo + biv_gaussian);
    Workflow G runner is ML / no tree; existing expected.toml cells record
    0.6.0 while campaign anchor is 0.7.0.
    why it matters: globbing this cell into fixtures/ would break or skip
    under DRM_PARITY_TESTS=1.
    recommendation: new path outside the glob; new generator; record 0.7.0
    and say the split.
    question: Q3 (payload: coef+logLik vs also CI/status).
    default: new path + 0.7.0 meta + CI/status fields without coverage claim.

  Boole — noticed: formula is already the four-axis bf() + phylo() grammar
    used in test_reml_q4_allaxes.jl; reserved labels must stay reserved.
    why it matters: a new fixture that invents rho12-as-phylo or tau
    spelling is a grammar regression.
    recommendation: paste the same bf() keys; tree as Newick sidecar, not
    a formula rewrite.
    question: none the design cannot answer.
    default: mirror test_reml_q4_allaxes.jl grammar.

  Noether — noticed: reml_q4.jl is public and additive; verified ML core
    is −256.51 / 2.18×.
    why it matters: "implement REML" as an engine port would touch src/.
    recommendation: src/ frozen. Fixture calls drm(method=:REML) only.
    question: none today.
    default: src/ frozen. HANDS TO Codex if the live fit needs the
    toolchain; HANDS TO Claude only if an unexpected src/ bug appears
    (then STOP — new G0).

  Curie — noticed: #291 reml ladder at p=16 can be diagnostic_only
    (nonconvergence); drmTMB NEWS recovery-grade q4 REML wants p≳200.
    why it matters: a non-converged cell is not same-target evidence.
    recommendation: Mac smoke first (p≈16, nrep≈5). If either side fails
    to converge, shrink or reseed — do not silently jump to Totoro
    recovery-grade (that is a different estimand).
    question: Q1 (Mac vs Totoro).
    default: Mac-only small cell. Ask before Totoro/DRAC.

  Rose — noticed: next_action says bank CI/status; claim_boundary says
    this row does not establish interval reliability or AI-REML;
    COUNTDOWN 0 ≠ parity complete.
    why it matters: a PR titled "q4 REML parity complete" is a claim lie.
    recommendation: allowed sentence = "this PR adds a native-vs-Julia
    same-target fixture for biv_q4_phylo_reml within the row's declared
    tolerance." Leave claim_status untouched. Do not rewrite
    test_bridge_q4_direct_export.jl's "no R-via-Julia q4 bridge parity"
    unless the *bridge* path is also measured (it is not this slice).
    question: Q3.
    default: record CI/status; forbid coverage / supported / bridge-admitted.

  Shannon — noticed: #432 owns scratch LOOP/; #425/#428 own runtests.jl;
    #423 owns parity_ledger.py + src/DRM.jl.
    why it matters: reusing DRM.jl-catchup or editing runtests.jl is bleed.
    recommendation: new scratch lane; standalone test file; no src/;
    no LOOP refresh on #432.
    question: Q2.
    default: standalone test; wire runtests.jl only after those PRs land
    (follow-up, not this PR).

  Pat — noticed: reader pages stay Experimental; this is not "what can
    I fit today?"
    recommendation: worked example = runnable snippet in after-task / test
    header, not a Documenter rewrite.
    default: no docs/src/ edit.

  Ada — synthesis: one fixture, new paths, src/ frozen, new scratch lane.
    HANDS TO Codex for live R + Julia fit if Grok cannot run the toolchain.
    Recommended defaults on Q1–Q3 below.
```

---

## ADA'S RECOMMENDATION

**Approve this G0 for one same-target fixture.** Keep the 2026-08-14
campaign G0. Do not flip TSV. Do not touch `src/`.

**IF YOU DO NOT MIND:**

1. **Mac-only small cell** (p≈16, nrep≈5, seed recorded). Totoro/DRAC
   only if you answer Q1 that way.
2. **Standalone test file** — do not edit `test/runtests.jl` while
   `#425`/`#428` own it.
3. **Payload = coef + logLik + fit-specific CI/status** (finite /
   `pdHess` / interval_status). Not coverage. Not AI-REML. Record
   drmTMB **0.7.0** in `expected.meta.toml` and say the 0.6.0 split.

**WHAT CONTINUES unattended:** already-armed PRs; `#432` inventory;
`#429` stays stacked; no drmTMB checkout; no `Pkg.test` in *this*
planning chat.

---

## DECISIONS LOCKED (pending G0)

1. Mission stays the 2026-08-14 G0. This is a **new implement G0** under it.
2. One cell: `biv_q4_phylo_reml`. One issue → one branch → one PR.
3. Workspace = **new** scratch lane from `origin/main` (not Dropbox
   `docs/a3c-design`, not `#432` catchup).
4. `src/` frozen. `#136` open. `#49` parked. D-111 off. `#428` not stolen.
5. New fixture path **outside** `test/parity/fixtures/` glob.
6. License: generated outputs only. Never vendor drmTMB source.
7. Rose sentence only; no "parity complete"; no TSV `supported`.
8. Verify = measured same-target numbers + Curie smoke + Rose section.
   Full `Pkg.test` only if it does not require editing `runtests.jl`.
9. D-94: behind drmTMB, not GLLVM.

---

## QUESTIONS STILL OPEN (max 3)

**Q1 — Compute / cell size: Mac-only small same-target, or Totoro
recovery-grade (p≳200)?**
**WHY NOW:** skill requires Totoro/DRAC at scope time. drmTMB NEWS
recovery-grade q4 REML is a different estimand than same-target
coef/logLik. `#291` p=16 can be `diagnostic_only`.
**TEAM VIEW:** Curie/Ada — Mac smoke first; recovery-grade is DEFER.
**RECOMMENDATION:** **Mac-only small cell.** If either engine fails to
converge, shrink/reseed and record it — do not silently escalate.
**IF YOU DO NOT MIND:** Mac-only. Say "Totoro" or "DRAC" to override.
**WHAT CONTINUES:** recon + schema design either way.

**Q2 — Wire `test/runtests.jl` in this PR?**
**WHY NOW:** `#425` and `#428` own that file. A helpful include is bleed.
**TEAM VIEW:** Shannon — standalone file now; include later.
**RECOMMENDATION:** **standalone** `test/test_parity_biv_q4_phylo_reml.jl`,
run via `julia --project=. -e 'using DRM, Test; include(...)'`. After
`#425`/`#428` land, a tiny follow-up include (not this G0).
**IF YOU DO NOT MIND:** standalone.
**WHAT CONTINUES:** fixture + test file either way.

**Q3 — Same-target payload: coef+logLik only, or also fit-specific
CI/status?**
**WHY NOW:** Rose allowed claim #4 is coef+logLik. TSV `next_action` is
"Bank fit-specific CI/status parity." `claim_boundary` forbids interval
*reliability* and AI-REML.
**TEAM VIEW:** Hopper/Rose — record CI/status fields; do not claim
coverage or reliability.
**RECOMMENDATION:** **both** — coef + logLik + CI/status
(`converged`, `pdHess` / Julia equivalent, `interval_status`). Forbid
coverage numbers and `supported`.
**IF YOU DO NOT MIND:** both, no coverage.
**WHAT CONTINUES:** schema design can reserve `[status]` either way.

---

## SEARCH

`none` for execution (no novelty / "first to" claim). NotebookLM **not**
required. External prior art is drmTMB's own NEWS + TSV, already cited.

---

## SLICE TABLE (colleague-runnable)

`SCOUT SUITABILITY: yes` — S1 is bounded read-only recon.

Do **not** edit `src/`. Do **not** flip TSV. Do **not** glob into
`test/parity/fixtures/`.

| ID | Member | model+effort | Bar | time | files / detail | dep |
|---|---|---|---|---|---|---|
| S1 RECON | Hopper | **Grok 4.6 high-fast** · low | **Cursor Models** | 25 min | What drmTMB outputs exist (`git show` NEWS / man / tests mentioning q4 REML + Julia `REML=TRUE` forwarding) and the exact Julia call (`drm(..., method=:REML, tree=)`). Output: `docs/dev-log/evidence/2026-08-16-biv-q4-phylo-reml-recon.md` | — |
| S2 DESIGN | Boole + Hopper | Grok 4.6 high-fast · med | **Cursor Models** | 30 min | Fixture schema: `test/parity/q4-reml/biv-q4-phylo-reml/{data.csv,tree.newick,expected.toml,expected.meta.toml}`. Keys: `[fit]` (family, formula, method=REML, loglik, n) · `[coef]` · optional `[vcov]` · `[status]` (converged, pdHess/Julia equiv, interval_status) · `[tol]`. Provenance records **0.7.0**. Output: `docs/dev-log/evidence/2026-08-16-biv-q4-phylo-reml-schema.md` | S1 |
| S3 IMPLEMENT | Hopper / Noether-adjacent | Grok 4.6 high-fast · med | **Cursor Models** | 60–90 min | New generator `test/parity/gen_biv_q4_phylo_reml.R` (do **not** edit `gen_fixtures.R`). Generate numbers via local R + installed drmTMB **without writing the shared drmTMB tree**. New Julia test `test/test_parity_biv_q4_phylo_reml.jl` (self-contained; no `runtests.jl`). **HANDS TO: Codex** if live `Rscript` / Julia REML fit fails in Cursor (toolchain). **HANDS TO: Claude** only if an unexpected `src/` bug appears — then STOP, new G0. | S2 |
| S4 SMOKE | Curie | Grok 4.6 high-fast · low | **Cursor Models** | 20 min | One-cell smoke: both sides converge, non-empty expected.toml, name-matched coef + logLik within `[tol]`, status fields finite. Read the log, not the exit code. Output: short section in after-task | S3 |
| S5 Rose | Rose | Grok 4.6 high-fast · med | **Cursor Models** | 15 min | Claim-vs-evidence: no "parity complete"; no TSV flip; no coverage; no AI-REML; no bridge-admitted rewrite of `test_bridge_q4_direct_export.jl`; GPL = generated outputs only; sweep receipt non-vacuous. Output: Rose section in after-task | S4 |
| S6 DoD | Ada | Grok 4.6 high-fast · low | **Cursor Models** | 20 min | New issue; check-log `docs/dev-log/check-log.d/2026-08-16-biv-q4-phylo-reml-fixture.md`; after-task `docs/dev-log/after-task/2026-08-16-biv-q4-phylo-reml-fixture.md`; worked example = test header + after-task snippet (no `docs/src/`). PR `closes #NN` | S5 |
| S7 MECHANICAL-VERIFY | Hopper | Grok 4.6 high-fast · low | **Cursor Models** | 10 min | Fixture dir exists; meta has 0.7.0 + r_call + seed; test file exists and was run; no `src/` diff; no TSV; no `runtests.jl`; no `#432` LOOP/; no drmTMB checkout. **No** full `Pkg.test` required | S6 |
| S8 RECONCILE | Melissa | Grok 4.6 high-fast · low | **Cursor Models** | 10 min | Plan vs actual → `docs/dev-log/plan-actual/2026-08-16-biv-q4-phylo-reml-fixture.md` | S7 |

**PARALLEL:** {S1} first; S2 after S1. S3–S8 sequential.
**FAN-OUT:** 0 in this planning chat. After G0, `/goal` may use **1** Grok
recon child (S1) then conductor. **FAN-OUT BUDGET:**
checkpoint=`biv-q4-phylo-reml-fixture` · new children≤2/6 · scout=1 ·
build=1 · ceiling=0.

**ULTRA EFFORT:** no.
**CONTEXT BRAKE:** parent input=unknown · fresh-task trigger=**START A
FRESH TASK** after G0.
**COMPACTIONS:** n/a (planning only).
**LANE RECEIPT:** `START A FRESH TASK` · reason=G0 handoff to `/goal` in
a **new** scratch lane · next-task prompt=block below.
**AUTO-REVIEW:** unknown · action=none.
**D-43 PANEL:** not a milestone.
**MODELS:** all slices on **Cursor Models · Grok 4.6 high-fast** unless
S3 `HANDS TO: Codex`. No Opus/Sol. No Grok Bot.
**ESTIMATE:** ~2–4 h wall-clock on Mac · 1 `/goal` session · no HPC
unless Q1 overrides.
**ARC PROGRAM:** N/A (no Arc Card).
**PREFLIGHT:** pasted above.
**REVIEW:** Rose S5 (plan critique also below).
**VERIFY:** S4 smoke + S7 mechanical + S5 claim fence.
**CONSOLIDATE:** after-task + check-log on the **new** feat branch.

### File fence (must not include)

- `src/**` (Noether; verified engine)
- `test/runtests.jl` (`#425` / `#428`)
- `test/parity/runparity.jl` · `test/parity/gen_fixtures.R` ·
  `test/parity/runparity_bridge.jl` (do not glob this cell)
- `tools/parity_ledger.py` · `src/DRM.jl` (`#423`)
- `docs/src/cross-family.md` (`#428`)
- `docs/src/reference/structured-effect-markers.md` (`#423`)
- `docs/make.jl` · `docs/design/capability-status.md`
- `docs/dev-log/coordination-board.md` (`#406`)
- `#432` `LOOP/**` and `docs/dev-log/evidence/2026-08-16-arc1-*.md`
- leftover `LOOP/checkpoint.md` from catch-up / Arc 0 / `#420`
- `.codex/agents/shannon-coordinator.toml`

### Allowed new paths

```
test/parity/q4-reml/biv-q4-phylo-reml/data.csv
test/parity/q4-reml/biv-q4-phylo-reml/tree.newick
test/parity/q4-reml/biv-q4-phylo-reml/expected.toml
test/parity/q4-reml/biv-q4-phylo-reml/expected.meta.toml
test/parity/gen_biv_q4_phylo_reml.R
test/test_parity_biv_q4_phylo_reml.jl
docs/dev-log/evidence/2026-08-16-biv-q4-phylo-reml-*.md
docs/dev-log/check-log.d/2026-08-16-biv-q4-phylo-reml-fixture.md
docs/dev-log/after-task/2026-08-16-biv-q4-phylo-reml-fixture.md
docs/dev-log/plan-actual/2026-08-16-biv-q4-phylo-reml-fixture.md
```

### How to cut the branch (execution, after G0)

Prefer `~/shinichi-brain/tools/lane_launch.sh DRM.jl biv-q4-phylo-reml`
(new worktree, new LOOP kit, committed). Do **not** launch inside
`DRM.jl-catchup`.

If launching by hand:

```bash
git fetch origin
# new worktree, not the Dropbox leftover, not DRM.jl-catchup
git worktree add -b feat/biv-q4-phylo-reml-fixture \
  ~/local-scratch/lanes/DRM.jl-biv-q4-phylo-reml origin/main
cd ~/local-scratch/lanes/DRM.jl-biv-q4-phylo-reml
# confirm: git rev-parse HEAD == origin/main; git status -sb clean
# open a NEW GitHub issue for this fixture; PR closes it
```

R generation (S3) must use the **installed** drmTMB library and write
**only** into the DRM.jl fixture dir. Never `git checkout` / commit on
the shared drmTMB tree.

---

## ROSE PLAN-REVIEW (critique of this decomposition — not an implementation)

**Sweep receipt:** present and non-vacuous. Each surface cites a command
or query (lane_preflight, git + drift, `ls` siblings, `git show` TSV,
MCP `search_notes` query strings, deterministic greps on AGENT_LOG /
DECISIONS / OPEN_QUESTIONS / journal / deep-research README, `gh pr view 432`).

**What Rose would block**

- Calling this "R–Julia parity complete" or flipping TSV `supported`.
- Bundling the other 10 rows, `#428`, VA/`#136`, `:natgrad`, or `#49`.
- Claiming interval *coverage* / *reliability* or HSquared AI-REML.
- Rewriting `test_bridge_q4_direct_export.jl` to drop "no R-via-Julia
  q4 bridge parity" (this slice is native `drm()`, not the bridge).
- Vendoring drmTMB GPL source; editing the shared drmTMB checkout.
- Building on leftover `docs/a3c-design` or `#432` LOOP/.
- Editing `src/` "to make REML work."

**What Rose accepts**

- One-issue PR that adds a same-target fixture and leaves
  `claim_status` untouched.
- Phrase: *this PR adds a native-vs-Julia same-target fixture for
  `biv_q4_phylo_reml` within the row's declared tolerance.*
- *Export-gap countdown at 0; 11 rows still unsigned.*
- Recording 0.7.0 on this new cell while Workflow G metas stay 0.6.0
  (say the split).

---

## DEFER (fenced — not in the `/goal`)

- TSV `claim_status` → `supported`
- The other 10 unsigned ledger rows
- `#428` / `cross_family_latent`
- `#136` VA · `:natgrad` · ordinary-RE REML · AGHQ · `#49`
- HSquared AI-REML · interval coverage
- Workflow G harness edits / `runtests.jl` include
- `#423` / `#429` / `#425` / `#420` / `#406` / `#421` / `#432` files
- Leftover Dropbox `docs/a3c-design` commits
- D-111 / Registrator; GPL vendoring; drmTMB checkout
- Staging `.codex/agents/shannon-coordinator.toml`
- Totoro/DRAC unless Q1 says so

---

## Paste-ready `/goal` prompt (UNEXECUTED)

After Shinichi approves G0 (and answers Q1–Q3 or "use your judgment"),
paste this into a **fresh** Cursor chat whose workspace is the **new**
scratch lane (not Dropbox, not `DRM.jl-catchup`):

```
/goal

Ultra-plan G0 approved. Run this plan to completion via LOOP/.

LANE: feat-biv-q4-phylo-reml-fixture
REPO: /Users/z3437171/local-scratch/lanes/DRM.jl-biv-q4-phylo-reml
PLAN: /Users/z3437171/Dropbox/Github Local/DRM.jl/docs/dev-log/after-task/2026-08-16-ultra-plan-biv-q4-phylo-reml-fixture.md

READ FIRST: the approved plan → repo AGENTS.md →
  scratch docs/dev-log/evidence/2026-08-16-arc1-ordered-backlog.md →
  scratch docs/dev-log/evidence/2026-08-16-arc1-recon-s2.md →
  scratch docs/dev-log/evidence/2026-08-16-arc1-hopper-twin-map.md →
  scratch docs/dev-log/evidence/2026-08-16-arc1-rose-fence.md.
SCAFFOLD: NEW scratch lane (lane_launch.sh DRM.jl biv-q4-phylo-reml
  or worktree at REPO above from origin/main).
  Do NOT use Dropbox leftover docs/a3c-design.
  Do NOT reuse ~/local-scratch/lanes/DRM.jl-catchup (#432 owns LOOP/).
  Write a *new* LOOP/ kit for this fixture only.
  Open one GitHub issue; PR closes it.
RUN: goal skill — re-read GOAL each arc; verify by LOG not exit code;
  pause at OPEN GATE; overwrite checkpoint each arc.
START ARC: S1 Grok recon (drmTMB outputs + Julia path), then S2 schema,
  then S3 generate+test, S4 Curie smoke, S5 Rose, S6 DoD, S7 verify.
NEXT GATE: opening the PR. Auto-merge last or leave unarmed.
  TSV supported flip is NOT this PR — STOP if anyone starts it.
VERIFY: fixture numbers exist; Julia re-fit matches within [tol];
  status fields recorded; no src/ diff; no runtests.jl; no TSV flip.
COMPUTE: Mac-only small cell unless G0 answered Totoro/DRAC.
  If either side does not converge, shrink/reseed and record — do not
  silently escalate compute.
HANDS TO: Codex if live Rscript / Julia REML fit needs the toolchain.
  HANDS TO Claude only if an unexpected src/ bug appears — then STOP.
FENCE: no src/; no capability-status flip; no TSV supported; no
  runparity.jl / gen_fixtures.R / runtests.jl; no #423/#428/#429/#425/
  #420/#406/#432 files; #136 stays OPEN; #49 PARKED; D-111 OFF;
  never stage shannon-coordinator.toml; never checkout drmTMB.
CLAIM FENCE: "this PR adds a native-vs-Julia same-target fixture for
  biv_q4_phylo_reml within the row's declared tolerance."
  Do not write "R–Julia parity complete." Do not claim interval
  reliability, coverage, AI-REML, or R-via-Julia bridge admission.
  Quote claim_boundary. D-94 = behind drmTMB not GLLVM.
BARS: Cursor Models / Grok 4.6 high-fast (Grok only; no Opus/Sol).
```

---

## Routing receipt (planning session)

| Field | Value |
|---|---|
| PLATFORM | Cursor (read from `session_ownership.sh`) |
| Session model | Cursor Grok 4.6 (this chat) |
| bars | prefer Cursor Models / Grok (Other Models historically ahead ~66% vs ~51%); owner: Grok only; Grok Bot unused; on-demand disabled |
| Nested Task subagents | **none** |
| Phase 3 | **not started** |
| git add / commit | **not done** (untracked on leftover `docs/a3c-design`; owner did not ask) |
