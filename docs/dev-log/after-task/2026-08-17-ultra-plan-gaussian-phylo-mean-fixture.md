# 2026-08-17 — Ada Phase 0–2: ultra-plan for `gaussian_phylo_mean` Route A fixture

**Lane:** plan Hopper's late pick — one hermetic Route A same-target
cell (coef + logLik). **Not** a replacement of the 2026-08-14 campaign
G0. **Author:** Ada (Shannon speaking). **No nested Task subagents ran.**
**Platform:** Cursor. **Cursor cannot EnterPlanMode** — this session
stayed strictly read-only except this note. **No Phase 3. No `/goal`.
No `/arc-loop`. No merges. No `src/` edits.** Still unexecuted.

#434 (`biv_q4_phylo_reml`) is **shipped**. This plan is a **new
implement G0** under the same campaign. It does **not** reuse the
docs-only next-after-#434 `/goal` (that plan stays unexecuted and
separate).

---

## 🎯 GOAL

```
🎯 GOAL
Solo platform: Cursor (this planning session) → /goal only after Shinichi
  approves G0 (fresh chat in a NEW scratch lane, not Dropbox leftover
  docs/a3c-design, not DRM.jl-catchup, not leftover #434 worktree, not
  claude/lane-arc1-backlog-after-434)
Deliverable: one hermetic native-vs-Julia same-target fixture for
  gaussian_phylo_mean (Route A: ML, univariate, sigma ~ 1) + standalone
  test + check-log + after-task + Rose claim fence. One issue → one
  branch → one PR.
HEADLINE: bank expected.toml + tree + data so Route A coef+logLik does
  not depend on a live R+drmTMB skip-guard
IN PARALLEL: Grok recon (drmTMB Route A call + Julia drm() path) +
  Boole/Hopper fixture-schema design
DEFER:
  - TSV claim_status flip to supported (drmTMB STOP GATE #1049/#1050)
  - sigma ~ phylo(...) / loc-scale phylo / non-Gaussian phylo / q4
  - #49 PARKED · #136 OPEN · D-111 OFF
  - #428 A11 / cross_family_latent (DIRTY / CONFLICTING / UNARMED)
  - test/runtests.jl include (wait-gate: #423 + #428 still own it)
  - leftover docs-only next-after-#434 /goal
  - Workflow G glob harness (runparity.jl / gen_fixtures.R)
  - leftover Dropbox docs/a3c-design commits
  - leftover scratch DRM.jl-catchup / DRM.jl-biv-q4-phylo-reml /
    claude/lane-arc1-backlog-after-434
  - GPL vendoring · shared drmTMB checkout
  - staging .codex/agents/shannon-coordinator.toml
DISCIPLINE: verify=Julia and drmTMB numbers on the SAME data/tree/formula
  (ML, sigma ~ 1) within declared [tol] ·
  compute=Mac-easy small cell ·
  closure=Shinichi approves G0, then /goal ships the one fixture
```

**Lane claimed:** `PLATFORM: cursor | ON BRANCH: docs/a3c-design (leftover; do not build here) | LANE: plan gaussian_phylo_mean Route A fixture | OTHER LANES: Claude arc1-backlog scratch · #429 A12 · #428 A11 · #423 A8 · #421 · #420 · #406 · leftover #434 worktree`

---

## Plan-mode note (once)

Cursor cannot flip Plan mode from here. Phases 0–2 ran read-only.
Execution waits for explicit G0. After approval, **do not continue in
this chat** — paste the `/goal` prompt below into a **fresh** Cursor
chat opened on a **new** scratch worktree.

---

## Decision LOCK (recommend — he approves at G0)

**This G0 = one DRM.jl hermetic same-target fixture** for
`gaussian_phylo_mean` (Route A). Campaign G0 stays **2026-08-14
admit-what-R-fits**. This does not replace it.

The Gaussian phylo-mean engine is already on Scoreboard B
(`docs/design/capability-status.md`: *Gaussian phylogenetic random
intercept (mean) = implemented*). Phase 1.5 already admitted the row
via marshalling / result-shape + optional live TMB parity. What is
missing is a **committed** `expected.toml` so CI does not depend on
drmTMB's skip-guarded Route A (`test-julia-tmb-parity.R`).

Same *class of work* as #434: fixture, not an engine port, not a TSV
flip. Different *cell*: ML, univariate, `sigma ~ 1`. Do **not** reuse
#434 REML/q4 numbers or any `loconly-gaussian-phylo-reml-v1` artefact.

**Not this slice:** TSV `supported` · `sigma ~ phylo(...)` · `#49` ·
`#136` · `#428` · `runtests.jl` include.

---

## Tension — overnight Ada “no fixture-gap” vs Hopper Route A gap

Both statements are true **in different taxonomies**. This G0 does not
pretend one side was wrong.

| Voice | What they said | What they meant | Still true? |
|---|---|---|---|
| Overnight Ada / Shannon / Rose next-arc | After #434 there is **no remaining inventory `fixture-gap`** | #432 class `fixture-gap` = unsigned row whose engine exists **and** whose same-target cell was never Phase-1.5-admitted. Ord 1 was `biv_q4_phylo_reml`. That class is empty after `b73d9241`. | **Yes** — inside the #432 inventory class |
| Rose next-arc table | Phase 1.5 admitted trio: “Fixtures exist. Promotion = drmTMB owner.” | Lumped `base_gaussian_location_scale` + `biv_gaussian_residual` + `gaussian_phylo_mean` + `plain_binomial_nonphylo` | **Over-lump** — S1 said fixtures exist for rows 1–2; Route A `expected.toml` is **NONE** |
| Hopper (16 Aug, next-after-biv) | Do **not** implement `gaussian_phylo_mean` as the next G0 | Inventory class is TSV-claim / keep-tests; adding a hermetic copy is inventory-class work, not a missing engine | **Was** the conservative call before an owner-named G0 |
| Hopper **late pick** | Pick `gaussian_phylo_mean` — cheapest remaining YES-twin hole | Committed same-target fixture is still NONE. Live Route A exists but is skip-guarded. Same work-shape as #434 | **Yes** — about the **artefact** |
| Overnight handover | Name a G0; no implement row until named; prefer docs-only `/goal` or “not yet” | Did not itself invent a new implement. Mission Control: “New G0 for the next Arc 1 backlog row (not a TSV flip)” | **Yes** — this morning **is** that named G0 |

**Ada synthesis (this plan):** keep the inventory class as **TSV-claim /
Phase 1.5 admitted**. Do not rewrite #432 to say Route A was a
`fixture-gap` all along. Name the missing artefact honestly: **Route A
hermetic cell is still NONE.** Owner-named G0 = bank that cell. Claim
stays `partial`. `next_action` (“keep first phylo-mean … do not widen
to sigma-phylo”) is what this slice *keeps*, not a promotion.

Rose fence shape used: **Later fixture** (one unsigned `capability_id`
→ one same-target cell). Not the status-honesty include. Not a TSV
flip.

Allowed sentence: *this PR adds a same-target fixture for
`gaussian_phylo_mean` within the row’s declared tolerance.* Forbidden:
“R–Julia parity complete.”

---

## PREFLIGHT (Phase 0.2)

```
bash ~/shinichi-brain/tools/lane_preflight.sh "/Users/z3437171/Dropbox/Github Local/DRM.jl"
```

**VERDICT:** `FOREIGN LANE ACTIVE (claude)`. Concurrency allowed;
bleed-through is not (D-88). This lane writes **only this untracked
plan note** on leftover `docs/a3c-design`. It does not claim `src/`,
live PR files, Claude’s `claude/lane-arc1-backlog-after-434`, leftover
#434 worktree, or `origin/main`.

**8 LANES LIVE** (do not claim their files): `#429` A12 · `#428` A11 ·
`#423` A8 · `#421` rosetta · `#420` loop items · `#406`
github-auto-merge · `claude/lane-arc1-backlog-after-434` (foreign
Claude; ahead 1 / behind 5 vs `origin/main`) · leftover
`docs/a3c-design`.

**COORD BOARD:** committed to `origin/main` (reaches other lanes). This
plan does **not** edit it.

**SESSION OWNERSHIP:** `PLATFORM: Cursor`. Dropbox dirty = prior-session
untracked notes (Arc 0/1 plans + remasure + Pólya + overnight handover
+ never-stage `shannon-coordinator.toml`). Not a concurrent editor.
**Do not `git add -A`.**

**Dropbox leftover:** `docs/a3c-design` is **0 ahead / 72 behind**
`origin/main`. Do not build here.

---

## Phase 0.3 / 0.3b — roster + two-bar

Live session model: **Cursor Grok 4.6** (this chat). Owner instruction
this invocation: **Grok only — no Opus/Sol**. Grok Bot unused.
On-demand **disabled**.

This-morning Settings → Usage glance: **not available from this
session** (UNVERIFIED). Dated prior (`memory/MODEL-ROUTING.md`,
2026-08-16 morning): Cursor Models **51%** · Other Models **66%** ·
Grok Bot **4%**. Other Models still ahead → stay on Cursor Models /
Grok. Do **not** burn Other Models to even the meters.

| Bar | Route this plan |
|---|---|
| Cursor Models | **All recon + design + Rose + verify** — Grok 4.6 high-fast |
| Other Models | Do not burn |
| Hand off | **Codex** only if live Rscript / Julia ML fit needs the toolchain (named `HANDS TO` below). Not a Cursor parent for HPC |
| Grok Bot | unused |
| On-demand | disabled |

---

## Evidence already on disk (cite; do not re-derive)

| File | Role | Present? |
|---|---|---|
| scratch `docs/dev-log/evidence/2026-08-16-next-arc-hopper-pick.md` | Late pick = this cell; class of work = #434 | **yes** |
| scratch `docs/dev-log/evidence/2026-08-16-arc1-recon-s1.md` | Route A: **NONE** `expected.toml`; live skip-guard exists | **yes** |
| scratch `docs/dev-log/evidence/2026-08-16-next-arc-rose-fence.md` | Later-fixture shape; allowed claim #5 | **yes** |
| Dropbox `docs/dev-log/after-task/2026-08-17-overnight-handover.md` | #425 MERGED; wait-gate now `#423`+`#428`; no implement until named G0 | **yes** |
| Dropbox `docs/dev-log/after-task/2026-08-16-ultra-plan-next-after-biv-q4.md` | Overnight Ada: no remaining *inventory* fixture-gap; docs-only `/goal` still unexecuted | **yes** |
| Dropbox `docs/dev-log/evidence/2026-08-16-next-after-biv-{hopper,rose,shannon}.md` | Conservative “do not implement Route A” before this named G0 | **yes** |
| `origin/main` `test/parity/q4-reml/biv-q4-phylo-reml/` + `gen_biv_q4_phylo_reml.R` + `test/test_parity_biv_q4_phylo_reml.jl` | #434 pattern to copy (paths, not numbers) | **yes** |
| `test/test_bridge.jl` | Julia marshalling: `bf(@formula(y ~ x + phylo(1 \| species)), @formula(sigma ~ 1))` | **yes** |
| drmTMB TSV via `git show origin/main:inst/extdata/julia-capabilities.tsv` | Row quoted below; tip `d9fddfa28` | **yes** |
| drmTMB `tests/testthat/test-julia-tmb-parity.R` `drm_parity_fit_route_a()` | Live Route A: seed 111, n=18, `bf(y ~ x + phylo(1 \| species, tree = tree), sigma ~ 1)`, ML, skip-guarded | **yes** (`git show`; no checkout) |

**Do not redo:** Arc 1 inventory (#432). #434 fixture. Overnight
docs-only `/goal`.

---

## What already exists vs the gap

### Julia path (do not re-port)

- Scoreboard B: Gaussian phylogenetic random intercept (mean) =
  **implemented**. Public `drm()` + `phylo()` marker.
- Result-shape / marshalling: `test/test_bridge.jl` (mu phylo +
  `sigma ~ 1`). Adjacent `sigma ~ phylo(...)` tests exist — **do not
  widen this cell to them**.
- Verified ML core stays frozen: logLik **−256.51** / **2.18×**.
- #434 cell is a **different** estimand (q=4 REML, four-axis phylo).
  Do not copy its `[tol]` or logLik.

### drmTMB outputs (read-only `git show`; no checkout)

TSV row `gaussian_phylo_mean` @ `d9fddfa28`:

- `syntax`: `bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1), family = gaussian(), engine = "julia"`
- `claim_status`: **partial**
- `r_bridge_status`: **experimental**
- `claim_boundary`: *Phase 1.5 Hopper admitted cell (Route A): first
  phylo-mean (sigma ~ 1) marshalling/result-shape + optional live TMB
  parity; not loc-scale phylo or non-Gaussian phylo.*
- `next_action`: *Keep first phylo-mean result-shape and Route A
  parity tests; do not widen to sigma-phylo here.*
- `issue`: drmTMB#544

Live Route A (`drm_parity_fit_route_a`, seed **111**, n=**18**,
`engine = "tmb"` vs `"julia"`, method **ML**) is skip-guarded. That is
the Phase 1.5 admission. It is **not** a committed hermetic cell.

### Why Workflow G cannot swallow this cell

`test/parity/runparity.jl` globs `fixtures/*/expected.toml` and fits
`drm(bundle, fam; data = data)` — **ML, no `tree=`**. A phylo
`expected.toml` in that glob would skip or fail (same reason #434 used
`q4-reml/`). **New path, new generator, new standalone test.**

Workflow G metas stay **0.6.0**. This cell records drmTMB **0.7.0**.
Say the split.

---

## SWEEP RECEIPT (Phase 0.25 — default-closed)

| Surface | Evidence (command / query) | Finding | Call |
|---|---|---|---|
| **lane** | `~/shinichi-brain/tools/lane_preflight.sh` on Dropbox DRM.jl | FOREIGN LANE ACTIVE (claude); 8 live; board committed; Claude owns `claude/lane-arc1-backlog-after-434` | Take **plan gaussian_phylo_mean fixture** only; new scratch lane after G0 |
| **repo git** | `git status -sb`; `session_ownership.sh`; `branch_drift_check.sh`; `git worktree list`; `git stash list`; `git log --oneline -15`; `git log origin/main -3` | Dropbox: `docs/a3c-design`, **0 ahead / 72 behind**. Untracked prior notes + this file. `origin/main` tip `5ddaffa9` (#425). #434 on main as `b73d9241` | **Do not build on Dropbox, catchup, leftover #434, or Claude backlog.** New feat branch from `origin/main` |
| **siblings** | `git ls-tree origin/main:test/parity`; scratch S1 + Hopper late pick; `test/test_bridge.jl` | #434 q4-reml fixture exists. **NONE** `gaussian-phylo*` under `fixtures/` or elsewhere | **reuse** engine + #434 *pattern*; **build-the-gap** = Route A `expected.toml` |
| **ledger / TSV** | `git show origin/main:inst/extdata/julia-capabilities.tsv` (drmTMB, no checkout) | Row `gaussian_phylo_mean` `partial`; next_action keep / do not widen; tip `d9fddfa28` | Cite; do not flip `supported` |
| **twin drmTMB** | `git -C drmTMB log origin/main -1 --oneline`; `git show` Route A test | `d9fddfa28`. Live Route A = seed 111 / n=18 / ML / skip-guarded | Read-only `git show`; never checkout |
| **brain** | MCP `search_notes` `gaussian_phylo_mean Route A fixture expected.toml parity` (`search_all_projects: true`) | No vault page holds an implement decision. Hits are older spatial / profile / q4 notes | Reuse 2026-08-14 G0 + D-94/D-111; do not invent a ship G0 |
| **deterministic grep** | `grep -in "gaussian_phylo_mean" memory/AGENT_LOG.md` → none. `grep` `DECISIONS.md` → D-111 / D-94 / D-34 live; no Route A fixture decision. `OPEN_QUESTIONS.md` → none. `journal/` → none. `projects/deep-research/README.md` → none | No vault decision says “flip TSV” or “port the engine” | **reuse** engine + fence; **build-the-gap** = hermetic cell |
| **PRs / issues** | preflight + `gh issue list --search 'gaussian_phylo_mean OR phylo-mean fixture'` | No existing fixture issue. `#423`+`#428` own `runtests.jl`. `#425` MERGED (cleared) | Open a **new** issue; no `runtests.jl`; no `src/` |
| **two-bar** | MODEL-ROUTING 2026-08-16 morning + owner “Grok only”; this-morning Usage **UNVERIFIED** | Other Models historically ahead (~66% vs ~51%) | All plan slices on **Cursor Models · Grok** |
| **Verdict** | — | Genuinely new: **one Route A hermetic fixture + standalone test** on a new feat branch. Engine exists. Inventory class stays TSV-claim. TSV flip is not this repo | **reuse engine / resume after named G0 / build-the-gap = Route A expected.toml** |

---

## WHAT THE BRAIN ALREADY KNOWS

| Claim | Source | Status |
|---|---|---|
| Campaign G0 (2026-08-14): `engine="julia"` admits what an R user actually fits. Anchor drmTMB **0.7.0** | catch-up LOOP · overnight handover | live — **keep; this is a slice under it** |
| Promote a cell only on native-vs-Julia same-target (coef + logLik). Direct DRM.jl ≠ R-via-Julia bridge. Export-name ≠ parity | LOOP DoD · Rose fence | live |
| D-111 OFF · D-94 behind drmTMB not GLLVM | [[DECISIONS#D-111]] · [[DECISIONS#D-94]] | accepted |
| `#136` OPEN · `#49` PARKED · `#13` natgrad FAIL | LOOP + Rose fence | **PROTECTED** |
| #432 inventory class `fixture-gap` is empty after #434 | overnight Ada + Rose next-arc | **keep the class; do not rewrite history** |
| Route A `expected.toml` is still NONE | S1 recon + Hopper late pick + `git ls-tree` | **the gap this G0 banks** |
| Ultra-plan Phases 0–2 on Cursor; Phase 3 = `/goal` in a fresh chat | Cursor adapters | doctrine |

---

## WHAT SHINICHI TOLD US (this invocation)

- Morning ultra-plan = Hopper late pick **`gaussian_phylo_mean` Route A
  hermetic same-target fixture (coef+logLik)**.
- READ-ONLY through G0. Cursor cannot EnterPlanMode — say once.
  Grok only. Do **not** execute.
- DEFER: TSV flip, `sigma ~ phylo` widen, `#49`, `#136`,
  `runtests.jl` include, `#428`.
- ≤3 owner Qs with defaults (Mac small, standalone test, formula
  spelling). Paste-ready `/goal` for a **NEW** scratch lane.
- Address the overnight-Ada vs Hopper tension honestly.

---

## TEAM RAISED

```
TEAM RAISED
  Hopper — noticed: Route A live test exists (seed 111, n=18, ML,
    bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1)) but is
    skip-guarded; committed expected.toml is NONE; Workflow G is
    ML / no tree so this cell cannot join fixtures/.
    why it matters: DRM_PARITY_TESTS=1 cannot certify Route A without
    a live R+drmTMB install.
    recommendation: new path outside the glob; new generator; record
    0.7.0 and say the 0.6.0 split. Copy #434 pattern, not #434 numbers.
    question: Q3 (formula spelling).
    default: TSV/public spelling in the R generator; Julia @formula +
    tree sidecar.

  Boole — noticed: TSV syntax and test_bridge.jl already agree on
    y ~ x + phylo(1 | species) and sigma ~ 1; tree= is an R-side
    argument, not a Julia formula rewrite. Reserved labels stay
    reserved (no rho12-as-phylo, no tau).
    why it matters: inventing sigma ~ phylo(...) or dropping x would
    silently change the twin.
    recommendation: quote TSV; do not widen.
    question: Q3.
    default: TSV spelling.

  Noether — noticed: Gaussian phylo-mean engine is already public;
    verified ML core is −256.51 / 2.18×.
    why it matters: “implement phylo-mean” as an engine port would
    touch src/.
    recommendation: src/ frozen. Fixture calls public drm() only.
    question: none today.
    default: src/ frozen. HANDS TO Codex if the live fit needs the
    toolchain; HANDS TO Claude only if an unexpected src/ bug appears
    (then STOP — new G0).

  Curie — noticed: live Route A already uses a Mac-small n=18 coal
    tree; #434 needed a reseed when TMB failed to converge.
    why it matters: a non-converged cell is not same-target evidence.
    recommendation: start Mac-small (n_tip≈16–18, one obs/tip or
    small n_each). If either side fails to converge, shrink/reseed
    and record — do not silently jump to Totoro.
    question: Q1.
    default: Mac-only small cell.

  Rose — noticed: inventory said “no fixture-gap”; S1 said Route A
    expected.toml is NONE; overnight table lumped “Fixtures exist.”
    why it matters: a PR titled “closing the last fixture-gap” would
    rewrite #432 taxonomy and invite a TSV flip.
    recommendation: allowed sentence = “this PR adds a same-target
    fixture for gaussian_phylo_mean within the row’s declared
    tolerance.” Leave claim_status untouched. Say the taxonomy split
    in the after-task. Do not call this “the last fixture-gap.”
    question: none the owner did not already fence.
    default: later-fixture shape; no “parity complete.”

  Shannon — noticed: #423 + #428 still own test/runtests.jl (#425
    cleared overnight). Claude owns claude/lane-arc1-backlog-after-434.
    why it matters: a helpful include, or a LOOP refresh on that
    scratch, is bleed.
    recommendation: new scratch lane; standalone test; no src/;
    do not reuse any leftover worktree.
    question: Q2.
    default: standalone. Include is a later follow-up after the
    wait-gate, not this PR.

  Pat — noticed: reader pages stay Experimental; this is not “what
    can I fit today?”
    recommendation: worked example = runnable snippet in after-task /
    test header, not a Documenter rewrite.
    default: no docs/src/ edit.

  Ada — synthesis: one Route A hermetic cell, new paths, src/ frozen,
    new scratch lane. Inventory class stays TSV-claim. HANDS TO Codex
    for live R + Julia fit if Grok cannot run the toolchain.
    Recommended defaults on Q1–Q3 below.
```

---

## ADA'S RECOMMENDATION

**Approve this G0 for one Route A hermetic fixture.** Keep the
2026-08-14 campaign G0. Do not flip TSV. Do not touch `src/`. Do not
rewrite #432’s `fixture-gap` class.

**IF YOU DO NOT MIND:**

1. **Mac-only small cell** (n_tip≈16–18, seed recorded; live Route A
   used seed 111 / n=18 as a *size hint*, not as copied numbers).
2. **Standalone test file** — do not edit `test/runtests.jl` while
   `#423`/`#428` own it.
3. **Formula = TSV spelling** in the R generator:
   `bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1)`,
   `family = gaussian()`, ML. Julia: `@formula(y ~ x + phylo(1 | species))`
   + tree sidecar. Payload = **coef + logLik** (fit-status fields
   recorded if cheap; not coverage).

**WHAT CONTINUES unattended:** already-open PRs; Claude backlog scratch
untouched; `#429` stays stacked; no drmTMB checkout; no `Pkg.test` in
*this* planning chat.

---

## DECISIONS LOCKED (pending G0)

1. Mission stays the 2026-08-14 G0. This is a **new implement G0** under it.
2. One cell: `gaussian_phylo_mean` (Route A). One issue → one branch → one PR.
3. Workspace = **new** scratch lane from `origin/main`.
4. `src/` frozen. `#136` open. `#49` parked. D-111 off. `#428` not stolen.
5. New fixture path **outside** `test/parity/fixtures/` glob.
6. License: generated outputs only. Never vendor drmTMB source.
7. Rose sentence only; no “parity complete”; no TSV `supported`; no
   “last fixture-gap” rewrite of #432.
8. Inventory class remains **TSV-claim / Phase 1.5 admitted**. This PR
   banks the missing hermetic artefact.
9. ML (not REML). Univariate. `sigma ~ 1`. Do not reuse #434 numbers.
10. D-94: behind drmTMB, not GLLVM.
11. DoD: see exception below.

---

## Definition of Done (AGENTS.md) — how this slice hits it

| # | AGENTS.md | This slice |
|---|---|---|
| 1 | Implementation wired into the module | Engine already public. This slice wires **evidence** (generator + committed outputs), not `src/` |
| 2 | Tests wired into `test/runtests.jl` | **Known exception** (same as #434): standalone `test/test_parity_gaussian_phylo_mean.jl` now. Include is DEFER until `#423`+`#428` merge or a new G0 steals that file |
| 3 | Docstrings | Public `drm()` / `phylo()` already documented. No new public symbol. Generator + test header state the cell |
| 4 | Worked example | Runnable snippet in test header + after-task (not a Documenter rewrite) |
| 5 | Check-log | `docs/dev-log/check-log.d/2026-08-17-gaussian-phylo-mean-fixture.md` |
| 6 | After-task | `docs/dev-log/after-task/2026-08-17-gaussian-phylo-mean-fixture.md` |
| 7 | Rose audit | Claim-vs-evidence section; taxonomy split stated; no TSV flip |

PR `closes #NN` (new issue; none exists today).

---

## QUESTIONS STILL OPEN (max 3)

**Q1 — Compute / cell size: Mac-only small same-target?**
**WHY NOW:** skill requires Totoro/DRAC at scope time. Live Route A
already uses n=18. Recovery-grade / large-p is a different row
(`phylo_count_large_p`) and is DEFER.
**TEAM VIEW:** Curie/Ada — Mac smoke first.
**RECOMMENDATION:** **Mac-only small cell** (n_tip≈16–18). If either
engine fails to converge, shrink/reseed and record — do not silently
escalate.
**IF YOU DO NOT MIND:** Mac-only. Say “Totoro” or “DRAC” to override.
**WHAT CONTINUES:** recon + schema design either way.

**Q2 — Wire `test/runtests.jl` in this PR?**
**WHY NOW:** `#423` and `#428` still own that file (`#425` cleared
overnight). A helpful include is bleed. AGENTS.md DoD item 2 wants
the include; #434 accepted the same exception.
**TEAM VIEW:** Shannon — standalone file now; include later.
**RECOMMENDATION:** **standalone**
`test/test_parity_gaussian_phylo_mean.jl`, run via
`julia --project=. -e 'using DRM, Test; include(...)'`.
**IF YOU DO NOT MIND:** standalone.
**WHAT CONTINUES:** fixture + test file either way.

**Q3 — Formula spelling?**
**WHY NOW:** TSV / public drmTMB / live Route A / Julia
`test_bridge.jl` already agree on the *model*; they differ on where
`tree=` lives. Widening to `sigma ~ phylo(...)` is the TSV
`next_action` fence.
**TEAM VIEW:** Boole/Hopper — quote TSV; Julia uses `@formula` +
sidecar.
**RECOMMENDATION:** R generator =
`bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1)`,
`family = gaussian()`, ML. Julia =
`bf(@formula(y ~ x + phylo(1 | species)), @formula(sigma ~ 1))` +
`tree.newick`. Keep the covariate `x`.
**IF YOU DO NOT MIND:** that spelling. Say “drop x” or “widen sigma”
only if you mean to change the twin (widen is **out of scope**).
**WHAT CONTINUES:** schema design can reserve the TSV string either way.

---

## SEARCH

`none` for execution (no novelty / “first to” claim). NotebookLM
**not** required. External prior art is drmTMB’s own Route A test +
TSV, already cited.

---

## SLICE TABLE (colleague-runnable)

`SCOUT SUITABILITY: yes` — S1 is bounded read-only recon.

Do **not** edit `src/`. Do **not** flip TSV. Do **not** glob into
`test/parity/fixtures/`.

| ID | Member | model+effort | Bar | time | files / detail | dep |
|---|---|---|---|---|---|---|
| S1 RECON | Hopper | **Grok 4.6 high-fast** · low | **Cursor Models** | 20 min | Confirm exact drmTMB Route A call (`git show` `drm_parity_fit_route_a`) and the exact Julia `drm()` call (public API + `test_bridge.jl`). Do not copy live seed-111 numbers as the committed cell — regenerate on committed data. Output: `docs/dev-log/evidence/2026-08-17-gaussian-phylo-mean-recon.md` | — |
| S2 DESIGN | Boole + Hopper | Grok 4.6 high-fast · med | **Cursor Models** | 25 min | Fixture schema: `test/parity/phylo-mean/gaussian-phylo-mean/{data.csv,tree.newick,expected.toml,expected.meta.toml}`. Keys: `[fit]` (family=gaussian, formula, method=ML, loglik, n) · `[coef]` · `[tol]` · optional `[status]` (converged only; not coverage). Provenance records **0.7.0**. Output: `docs/dev-log/evidence/2026-08-17-gaussian-phylo-mean-schema.md` | S1 |
| S3 IMPLEMENT | Hopper / Noether-adjacent | Grok 4.6 high-fast · med | **Cursor Models** | 60–90 min | New generator `test/parity/gen_gaussian_phylo_mean.R` (do **not** edit `gen_fixtures.R`). Generate via local R + installed drmTMB **without writing the shared drmTMB tree**. New Julia test `test/test_parity_gaussian_phylo_mean.jl` (self-contained; no `runtests.jl`). **HANDS TO: Codex** if live `Rscript` / Julia fit fails in Cursor. **HANDS TO: Claude** only if an unexpected `src/` bug appears — then STOP, new G0 | S2 |
| S4 SMOKE | Curie | Grok 4.6 high-fast · low | **Cursor Models** | 20 min | One-cell smoke: both sides converge, non-empty expected.toml, name-matched coef + logLik within `[tol]`. Read the log, not the exit code. Output: short section in after-task | S3 |
| S5 Rose | Rose | Grok 4.6 high-fast · med | **Cursor Models** | 15 min | Claim-vs-evidence: no “parity complete”; no “last fixture-gap”; no TSV flip; no sigma-phylo widen; GPL = generated outputs only; taxonomy split stated; sweep receipt non-vacuous. Output: Rose section in after-task | S4 |
| S6 DoD | Ada | Grok 4.6 high-fast · low | **Cursor Models** | 20 min | New issue; check-log; after-task; worked example = test header + after-task snippet (no `docs/src/`). PR `closes #NN` | S5 |
| S7 MECHANICAL-VERIFY | Hopper | Grok 4.6 high-fast · low | **Cursor Models** | 10 min | Fixture dir exists; meta has 0.7.0 + r_call + seed; test file exists and was run; no `src/` diff; no TSV; no `runtests.jl`; no leftover LOOP/; no drmTMB checkout. **No** full `Pkg.test` required | S6 |
| S8 RECONCILE | Melissa | Grok 4.6 high-fast · low | **Cursor Models** | 10 min | Plan vs actual → `docs/dev-log/plan-actual/2026-08-17-gaussian-phylo-mean-fixture.md` | S7 |

**PARALLEL:** {S1} first; S2 after S1. S3–S8 sequential.
**FAN-OUT:** 0 in this planning chat. After G0, `/goal` may use **1**
Grok recon child (S1) then conductor. **FAN-OUT BUDGET:**
checkpoint=`gaussian-phylo-mean-fixture` · new children≤2/6 · scout=1
· build=1 · ceiling=0.

**ULTRA EFFORT:** no.
**CONTEXT BRAKE:** parent input=unknown · fresh-task trigger=**START A
FRESH TASK** after G0.
**COMPACTIONS:** n/a (planning only).
**LANE RECEIPT:** `START A FRESH TASK` · reason=G0 handoff to `/goal`
in a **new** scratch lane · next-task prompt=block below.
**AUTO-REVIEW:** unknown · action=none.
**D-43 PANEL:** not a milestone.
**MODELS:** all slices on **Cursor Models · Grok 4.6 high-fast** unless
S3 `HANDS TO: Codex`. No Opus/Sol. No Grok Bot.
**ESTIMATE:** ~2–3 h wall-clock on Mac · 1 `/goal` session · no HPC
unless Q1 overrides.
**ARC PROGRAM:** N/A (no Arc Card).
**PREFLIGHT:** pasted above.
**REVIEW:** Rose S5 (plan critique also below).
**VERIFY:** S4 smoke + S7 mechanical + S5 claim fence.
**CONSOLIDATE:** after-task + check-log on the **new** feat branch.

### File fence (must not include)

- `src/**` (Noether; verified engine)
- `test/runtests.jl` (`#423` / `#428`)
- `test/parity/runparity.jl` · `test/parity/gen_fixtures.R` ·
  `test/parity/runparity_bridge.jl` (do not glob this cell)
- `tools/parity_ledger.py` · `src/DRM.jl` (`#423`)
- `docs/src/cross-family.md` (`#428`)
- `docs/make.jl` · `docs/design/capability-status.md`
- `docs/dev-log/coordination-board.md` (`#406`)
- Claude `LOOP/**` on `claude/lane-arc1-backlog-after-434`
- leftover `#434` worktree files
- leftover `LOOP/checkpoint.md` from catch-up / Arc 0 / `#420`
- `.codex/agents/shannon-coordinator.toml`

### Allowed new paths

```
test/parity/phylo-mean/gaussian-phylo-mean/data.csv
test/parity/phylo-mean/gaussian-phylo-mean/tree.newick
test/parity/phylo-mean/gaussian-phylo-mean/expected.toml
test/parity/phylo-mean/gaussian-phylo-mean/expected.meta.toml
test/parity/gen_gaussian_phylo_mean.R
test/test_parity_gaussian_phylo_mean.jl
docs/dev-log/evidence/2026-08-17-gaussian-phylo-mean-*.md
docs/dev-log/check-log.d/2026-08-17-gaussian-phylo-mean-fixture.md
docs/dev-log/after-task/2026-08-17-gaussian-phylo-mean-fixture.md
docs/dev-log/plan-actual/2026-08-17-gaussian-phylo-mean-fixture.md
```

### How to cut the branch (execution, after G0)

Prefer `~/shinichi-brain/tools/lane_launch.sh "/Users/z3437171/Dropbox/Github Local/DRM.jl" gaussian-phylo-mean`
(new worktree, new LOOP kit, committed). Do **not** launch inside
`DRM.jl-catchup`, `DRM.jl-biv-q4-phylo-reml`, or
`DRM.jl-arc1-backlog-after-434`.

If launching by hand:

```bash
git fetch origin
git worktree add -b feat/gaussian-phylo-mean-fixture \
  ~/local-scratch/lanes/DRM.jl-gaussian-phylo-mean origin/main
cd ~/local-scratch/lanes/DRM.jl-gaussian-phylo-mean
# confirm: git rev-parse HEAD == origin/main; git status -sb clean
# open a NEW GitHub issue for this fixture; PR closes it
```

R generation (S3) must use the **installed** drmTMB library and write
**only** into the DRM.jl fixture dir. Never `git checkout` / commit on
the shared drmTMB tree.

---

## ROSE PLAN-REVIEW (critique of this decomposition — not an implementation)

**Sweep receipt:** present and non-vacuous. Each surface cites a
command or query (lane_preflight, git + drift, `ls-tree` siblings,
`git show` TSV + Route A test, MCP `search_notes` query string,
deterministic greps on AGENT_LOG / DECISIONS / OPEN_QUESTIONS /
journal / deep-research README, `gh issue list`).

**What Rose would block**

- Calling this “R–Julia parity complete” or flipping TSV `supported`.
- Calling this “the last fixture-gap” / rewriting #432 taxonomy.
- Widening to `sigma ~ phylo(...)`, loc-scale phylo, non-Gaussian
  phylo, or q4.
- Bundling `#428`, VA/`#136`, `:natgrad`, or `#49`.
- Vendoring drmTMB GPL source; editing the shared drmTMB checkout.
- Building on leftover `docs/a3c-design`, `#434` worktree, or Claude
  backlog LOOP/.
- Editing `src/` “to make phylo-mean work.”
- Reusing #434 REML/q4 numbers as this cell.

**What Rose accepts**

- One-issue PR that adds a same-target fixture and leaves
  `claim_status` untouched.
- Phrase: *this PR adds a same-target fixture for
  `gaussian_phylo_mean` within the row’s declared tolerance.*
- *Export-gap countdown at 0; 11 capability rows still unsigned.*
- Recording 0.7.0 on this new cell while Workflow G metas stay 0.6.0
  (say the split).
- After-task that states the taxonomy split (inventory class stays
  TSV-claim; hermetic Route A cell was NONE).

---

## DEFER (fenced — not in the `/goal`)

- TSV `claim_status` → `supported`
- `sigma ~ phylo(...)` / loc-scale phylo / non-Gaussian phylo / q4
- `#49` PARKED · `#136` OPEN · D-111 OFF
- `#428` / `cross_family_latent`
- `test/runtests.jl` include
- Docs-only next-after-#434 `/goal` (separate, still unexecuted)
- Workflow G harness edits
- `#423` / `#429` / `#420` / `#406` / `#421` files
- Leftover Dropbox `docs/a3c-design` commits
- Leftover scratch catchup / #434 / Claude backlog
- GPL vendoring; drmTMB checkout
- Staging `.codex/agents/shannon-coordinator.toml`
- Totoro/DRAC unless Q1 says so

---

## Paste-ready `/goal` prompt (UNEXECUTED)

After Shinichi approves G0 (and answers Q1–Q3 or “use your judgment”),
paste this into a **fresh** Cursor chat whose workspace is the **new**
scratch lane (not Dropbox, not `DRM.jl-catchup`, not leftover #434,
not Claude backlog):

```
/goal

Ultra-plan G0 approved. Run this plan to completion via LOOP/.

LANE: feat-gaussian-phylo-mean-fixture
REPO: /Users/z3437171/local-scratch/lanes/DRM.jl-gaussian-phylo-mean
PLAN: /Users/z3437171/Dropbox/Github Local/DRM.jl/docs/dev-log/after-task/2026-08-17-ultra-plan-gaussian-phylo-mean-fixture.md

READ FIRST: the approved plan → repo AGENTS.md →
  scratch docs/dev-log/evidence/2026-08-16-next-arc-hopper-pick.md →
  scratch docs/dev-log/evidence/2026-08-16-arc1-recon-s1.md →
  scratch docs/dev-log/evidence/2026-08-16-next-arc-rose-fence.md →
  Dropbox docs/dev-log/after-task/2026-08-17-overnight-handover.md.
SCAFFOLD: NEW scratch lane
  (lane_launch.sh "/Users/z3437171/Dropbox/Github Local/DRM.jl" gaussian-phylo-mean
  or worktree at REPO above from origin/main).
  Do NOT use Dropbox leftover docs/a3c-design.
  Do NOT reuse ~/local-scratch/lanes/DRM.jl-catchup.
  Do NOT reuse ~/local-scratch/lanes/DRM.jl-biv-q4-phylo-reml.
  Do NOT reuse ~/local-scratch/lanes/DRM.jl-arc1-backlog-after-434
  (foreign Claude; owns LOOP/).
  Write a *new* LOOP/ kit for this fixture only.
  Open one GitHub issue; PR closes it.
RUN: goal skill — re-read GOAL each arc; verify by LOG not exit code;
  pause at OPEN GATE; overwrite checkpoint each arc.
START ARC: S1 Grok recon (Route A call + Julia path), then S2 schema,
  then S3 generate+test, S4 Curie smoke, S5 Rose, S6 DoD, S7 verify.
NEXT GATE: opening the PR. Auto-merge last or leave unarmed.
  TSV supported flip is NOT this PR — STOP if anyone starts it.
VERIFY: fixture numbers exist; Julia re-fit matches within [tol];
  no src/ diff; no runtests.jl; no TSV flip.
COMPUTE: Mac-only small cell unless G0 answered Totoro/DRAC.
  If either side does not converge, shrink/reseed and record — do not
  silently escalate compute.
HANDS TO: Codex if live Rscript / Julia ML fit needs the toolchain.
  HANDS TO Claude only if an unexpected src/ bug appears — then STOP.
FENCE: no src/; no capability-status flip; no TSV supported; no
  runparity.jl / gen_fixtures.R / runtests.jl; no #423/#428/#429/
  #420/#406 files; #136 stays OPEN; #49 PARKED; D-111 OFF;
  never stage shannon-coordinator.toml; never checkout drmTMB;
  do not widen to sigma ~ phylo(...); do not reuse #434 numbers.
CLAIM FENCE: "this PR adds a same-target fixture for
  gaussian_phylo_mean within the row's declared tolerance."
  Do not write "R–Julia parity complete." Do not write "last
  fixture-gap." Inventory class stays TSV-claim / Phase 1.5 admitted;
  this PR banks the missing hermetic Route A cell.
  Quote claim_boundary. D-94 = behind drmTMB not GLLVM.
  Workflow G metas stay 0.6.0; this cell is 0.7.0 — say the split.
BARS: Cursor Models / Grok 4.6 high-fast (Grok only; no Opus/Sol).
```

---

## Routing receipt (planning session)

| Field | Value |
|---|---|
| PLATFORM | Cursor (read from `session_ownership.sh`) |
| Session model | Cursor Grok 4.6 (this chat) |
| bars | prefer Cursor Models / Grok (Other Models historically ahead ~66% vs ~51%; this-morning Usage UNVERIFIED); owner: Grok only; Grok Bot unused; on-demand disabled |
| Nested Task subagents | **none** |
| Phase 3 | **not started** |
| git add / commit | **not done** (untracked on leftover `docs/a3c-design`; owner did not ask) |
