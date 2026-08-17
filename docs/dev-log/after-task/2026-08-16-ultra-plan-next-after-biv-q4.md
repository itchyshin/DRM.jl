# 2026-08-16 — Ada Phase 0–2: ultra-plan NEXT after #434 (`biv_q4_phylo_reml`)

**Lane:** plan discussion (read-only through Phase 2).
**Author:** Ada (Shannon speaking). Nested Grok Task: Shannon · Hopper · Rose.
**Platform:** Cursor. **Cursor cannot EnterPlanMode** — this session stayed
strictly read-only except this note + scout evidence. **No Phase 3. No
`/goal` execution. No PRs. No `src/` edits.** Still unexecuted.

Campaign **2026-08-14 admit-what-R-fits** is unchanged. This G0 does **not**
replace it.

---

## 🎯 GOAL

```
🎯 GOAL
Solo platform: Cursor (this planning session) → /goal after G0 in THIS chat,
  after scaffolding a NEW scratch lane (not Dropbox leftover, not catchup,
  not the leftover #434 worktree)
Deliverable: refreshed Arc 1 ordered backlog on origin/main after #434
  (fixture banked; claim still partial) + after-task + check-log + Rose
  fence. One issue → one docs branch → one PR. No src/. No TSV flip.
HEADLINE: docs-only — re-rank the 11 unsigned rows now that #434 shipped
IN PARALLEL: Shannon / Hopper / Rose recon — DONE this plan (do not redo)
DEFER:
  - any implement row (phylo_gamma_beta_binomial, phylo_count_large_p,
    general_covariance_structured, gaussian_response_mask, gaussian_phylo_mean)
  - include test/test_parity_biv_q4_phylo_reml.jl in test/runtests.jl
    (WAIT: #423 + #425 + #428 own that file)
  - TSV claim_status → supported (drmTMB STOP GATE; #1049 OPEN)
  - #428 A11 / cross_family_latent
  - #136 VA · :natgrad · ordinary-RE REML · AGHQ · #49 PARKED
  - D-111 OFF · Registrator · GPL vendoring · shared drmTMB checkout
  - leftover Dropbox docs/a3c-design commits
  - leftover scratch DRM.jl-catchup and DRM.jl-biv-q4-phylo-reml
  - staging .codex/agents/shannon-coordinator.toml
  - flipping capability-status.md chips
  - inventing twin Δ (binomial+phylo, beta+relmat)
DISCIPLINE: verify=stale NONE line gone; 11 IDs once; claim_status still
  partial; no src/ / runtests.jl / TSV · compute=n/a ·
  closure=Shinichi approves G0
```

**Lane claimed:** `PLATFORM: cursor | ON BRANCH: docs/a3c-design (leftover; do not build here) | LANE: plan next-after-434 | OTHER LANES: #429 #428 #425 #423 #421 #420 #406 + leftover claude/lane-biv-q4-phylo-reml + leftover docs/a3c-design + main-direct`

**Execution lane (after G0):** `docs/arc1-backlog-after-434` @
`~/local-scratch/lanes/DRM.jl-arc1-backlog-after-434` from `origin/main`
(`b73d9241`). Unique-path docs only.

---

## Plan-mode note (once)

Cursor cannot flip Plan mode from here. Phases 0–2 ran read-only. Execution
waits for explicit G0. After approval, paste the `/goal` block below **in
this chat** — first action is `lane_launch.sh` to the **new** scratch.

---

## Decision LOCK (recommend — he approves at G0)

**This G0 = docs-only backlog refresh.** Not an implement PR.

#434 (`b73d9241`) banked the **only** same-target fixture-gap on an
already-implemented engine (`biv_q4_phylo_reml`). Claim stays **partial**.
logLik gap is a declared `[tol]` (`atol_loglik=6.0`, `d≈−5.63`) because
TMB REML restricts **mean** FE while Julia `reml_q4` profiles **mean and
scale**. No TSV `supported` flip.

`origin/main:docs/dev-log/evidence/2026-08-16-arc1-ordered-backlog.md`
(#432) still says fixture **NONE** and still recommends that cell as the
first later implement. That sentence is **false after `b73d9241`**. A
colleague who starts from #432 will re-plan a shipped slice or "finish"
it by flipping TSV.

Remaining unsigned rows are TSV-claim, smoke-only with `next_action`
already answered, parked (`#49`), owned (`#428`), or a design fence.
Forcing `phylo_gamma_beta_binomial` (or large-p / relmat) as the next
implement invents work the ledger does not ask for.

The honest #434 follow-up (wire the standalone test into `runtests.jl`)
is **not** this G0: `#423` + `#425` + `#428` own that file. DEFER until
they merge.

---

## PREFLIGHT (Phase 0.2)

```
bash ~/shinichi-brain/tools/lane_preflight.sh "/Users/z3437171/Dropbox/Github Local/DRM.jl"
```

**VERDICT:** `** FOREIGN LANE ACTIVE (claude direct-to-main) **`

```
ME              : cursor   (foreign = claude codex · a 2nd cursor lane counts too)
ON BRANCH       : docs/a3c-design
OPEN PRs        : #429 #428 #425 #423 #421 #420 #406
origin/main     : 21 commit(s) in last 12h
   !! b73d9241 Merge pull request #434 from itchyshin/claude/lane-biv-q4-phylo-re
   ** 11 NON-MERGE commit(s) straight to main in 12h **
   + 7 uncommitted path(s) here => TREAT AS A LIVE LANE
LOCAL BRANCHES  : 1 active in last 12h (not already shown as a PR)
   !! claude/lane-biv-q4-phylo-reml  (foreign: claude)
LANE CENSUS     : ** 10 LANES LIVE **
COORD BOARD     : docs/dev-log/coordination-board.md -- COMMITTED to origin/main ✅
```

Concurrency allowed; bleed-through is not (D-88). This lane writes **only
this untracked plan note** (+ scout evidence already written) on leftover
`docs/a3c-design`. It does not claim `src/`, live PR files, or `origin/main`.

`docs/a3c-design` vs `origin/main` = **0 ahead / 67 behind**. Do not build here.

---

## Phase 0.3 / 0.3b — roster + two-bar

Live roster (this session): **Cursor Grok 4.6 high-fast**. Owner: **Grok
only.** Grok Bot unused. On-demand **disabled**.

Last written dashboard (`memory/MODEL-ROUTING.md`, 2026-08-16 morning):
Cursor Models **51%** · Other Models **66%** (ahead). Same call: do not
burn Other Models to even the meters. This plan did **not** re-open
Settings → Usage.

| Bar | Route this plan + `/goal` |
|---|---|
| Cursor Models | **All slices** — Grok 4.6 high-fast |
| Other Models | Do not burn on this docs refresh |
| Grok Bot | unused |
| On-demand | disabled |

---

## SWEEP RECEIPT (Phase 0.25 — default-closed)

| Surface | Evidence (command / query) | Finding | Call |
|---|---|---|---|
| **lane** | `~/shinichi-brain/tools/lane_preflight.sh` on Dropbox DRM.jl | FOREIGN LANE ACTIVE (claude direct-to-main); 10 live; board committed | Take **plan next-after-434** only; execute later on **new** scratch |
| **repo git** | `git status -sb`; `git log --oneline -20`; `git worktree list`; `git stash list`; `branch_drift_check.sh`; `git log origin/main -12` | Dropbox leftover `docs/a3c-design`, 0/67 behind. `origin/main` tip `b73d9241` (#434). Scratch catchup leftover (`docs/arc1-inventory`); scratch biv-q4 leftover (`claude/lane-biv-q4-phylo-reml`). Stashes are old other-lane WIP | **Do not build on Dropbox, catchup, or leftover #434 worktree.** New docs branch from `origin/main` |
| **siblings / inventory** | scratch + `origin/main` `docs/dev-log/evidence/2026-08-16-arc1-ordered-backlog.md`; eleven-rows; S3 batch | #432 inventory on main; ord 1 still says fixture NONE — **stale after #434** | **resume** inventory as a refresh, not a redo of the 11-row hunt |
| **#434 landing** | `git show b73d9241 --stat`; after-task on origin/main | Fixture `test/parity/q4-reml/biv-q4-phylo-reml/`; standalone test; no `src/`; no `runtests.jl`; no TSV | Cell banked; claim stays partial |
| **twin drmTMB** | `git -C drmTMB log origin/main -1`; `git show origin/main:inst/extdata/julia-capabilities.tsv` | Tip `d9fddfa28` (#1058). TSV unchanged; `biv_q4` still `partial`; `next_action` still “Bank CI/status” (stale vs fixture `[status]`) | Read-only `git show`; never checkout; **do not flip TSV** |
| **STOP GATE** | Rose `gh pr view 1049` / `1050` | **#1049 OPEN**; **#1050 MERGED** (does not authorize a flip) | Hold |
| **brain** | MCP `search_notes` `DRM.jl next arc after biv_q4_phylo_reml #434 fixture 2026-08-16 admit-what-R-fits phylo_gamma_beta_binomial` (`search_all_projects: true`) | No vault page holds a “next implement after #434” decision. Hits were older twin notes | Reuse 2026-08-14 G0 + D-94/D-111; do not invent a ship G0 |
| **deterministic grep** | `grep -in "biv_q4_phylo_reml\\|phylo_gamma_beta_binomial\\|#434" memory/AGENT_LOG.md` → none. `grep -in "D-111\\|D-94\\|D-34" memory/DECISIONS.md` → live. `grep` `OPEN_QUESTIONS.md` → none. `grep` `journal/` → none for these strings. `grep` `projects/deep-research/README.md` → none | No vault decision says “implement phylo_gamma next” | **reuse** G0 + Rose fence; **resume** stale #432 backlog; **build-the-gap** = docs refresh only |
| **PRs** | preflight + Shannon `gh pr list` | `#428` DIRTY; `#425` ARMED; `#423` DIRTY + `test(1)` FAIL; all three own `runtests.jl` | Do not steal; do not include-in-runtests this G0 |
| **two-bar** | MODEL-ROUTING 2026-08-16 morning + owner “Grok only” | Other Models ahead (66% vs 51%) | Scout/build on **Cursor Models · Grok 4.6 high-fast** |
| **Verdict** | — | Genuinely new work this lane can own: **refresh the stale #432 backlog**. No remaining honest fixture-gap implement | **reuse G0 / resume inventory / build-the-gap = docs-only** |

---

## WHAT THE BRAIN ALREADY KNOWS

| Claim | Source | Status |
|---|---|---|
| Campaign G0 (2026-08-14): admit what an R user actually fits. Anchor drmTMB **0.7.0** | catch-up LOOP · HANDOVER | live — **keep** |
| D-111: stay off Julia General | [[DECISIONS#D-111]] | accepted · OFF |
| D-94: DRM.jl behind **drmTMB**, not GLLVM.jl | [[DECISIONS#D-94]] | accepted |
| Export-name countdown 0 ≠ capability parity. Zero rows `supported` | Hopper remasure + #432 inventory | live; COUNTDOWN **UNVERIFIED** as a fresh `parity_ledger.py` after `b73d9241` (TSV text verified via `git show`) |
| `#136` OPEN · `#49` PARKED · `#13` natgrad FAIL | LOOP + Rose fence | **PROTECTED** |
| Arc 0 `@ref` landed (`#430`/`#431`); Arc 1 inventory landed (`#432`); #434 fixture landed | `origin/main` | **done — do not redo** |
| Ultra-plan Phases 0–2 on Cursor; Phase 3 = `/goal` | Cursor adapters | doctrine |

---

## WHAT SHINICHI TOLD US (this invocation)

- `/ultra-plan` the NEXT arc after #434 merged (`b73d9241`).
- Campaign locked: 2026-08-14 admit-what-R-fits.
- Just shipped: same-target fixture; claim stays partial; NO TSV flip;
  logLik gap banked as tol (TMB mean-only vs Julia mean+scale).
- Skip `#428`. `#49` PARKED. `#136` OPEN. D-111 OFF. No GPL. Never
  checkout shared drmTMB for writes.
- Prefer fixture-only / new paths when open PRs own `runtests.jl` / LOOP / `src`.
- Pick ONE next implement row **or inventory/docs-only if wiser**.
- STOP at G0. He will run `/goal` in **this** chat after G0.
- LANE = new scratch; not catchup; not Dropbox leftover.
- DEFER defaults: TSV flip, `#428`, VA/natgrad, remaining 9+ rows beyond
  the one picked.
- Grok only.

---

## TEAM RAISED

Nested Grok Task this pass: [Shannon](5d2e9802-994a-4fe2-a2a6-f9737fb281c2) ·
[Hopper](c352a93c-35d4-4976-8a7f-d43bead488fe) ·
[Rose](5a866d34-7c39-46af-9229-01e6089b5c6b).
Evidence: `docs/dev-log/evidence/2026-08-16-next-after-biv-{shannon,hopper,rose}.md`.

```
TEAM RAISED
  Hopper — noticed: the only same-target fixture-gap on an already-
    implemented engine was biv_q4_phylo_reml; #434 closed it. Remaining
    NONE paths are parked, owned, keep-tests, smoke/do-not-promote, or
    next_action-already-done. TSV tip d9fddfa28 unchanged; biv_q4
    next_action stale vs fixture [status].
    why it matters: picking phylo_gamma / large-p / relmat invents a
    cell the ledger does not ask for; #425 owns the nongaussian TSV.
    recommendation: NONE — inventory refresh.
    question: Q1 (docs-only vs force implement).
    default: docs-only.

  Rose — noticed: origin/main backlog still says fixture NONE and still
    recommends biv_q4 as first later implement — a claim hazard.
    why it matters: a colleague will re-plan a shipped slice or flip TSV.
    recommendation: docs-only refresh; do not mint a new “recommended
    implement” in a docs PR.
    question: Q1 + Q3 (stop after this /goal).
    default: docs-only; no new recommended implement.

  Shannon — noticed: 10 live lanes; runtests.jl owned by #423+#425+#428;
    catchup and biv-q4 worktrees leftover; Dropbox 67 behind.
    why it matters: include-in-runtests is the honest #434 follow-up but
    is a collision wait, not a ledger-row implement.
    recommendation: NEW scratch; this G0 = unique-path docs; DEFER
    include until those three merge.
    question: Q2 (wait on include).
    default: wait; do not /goal the include now.

  Noether — noticed: #434 did not touch src/; atol_loglik=6.0 is a
    declared restriction, not a defect to “fix” in reml_q4.
    why it matters: a helpful agent will try to close the logLik gap
    in the verified engine.
    recommendation: src/ frozen. Do not treat the tol as a bug.
    question: none today.
    default: src/ frozen.

  Pat — noticed: reader pages must not say “parity complete” or
    “Julia q4 REML converged” (fixture records julia_converged=false).
    recommendation: docs refresh is internal backlog, not a reader rewrite.
    question: none.
    default: no Documenter rebuild.

  Ada — synthesis: NEXT = docs-only backlog refresh on a new scratch
    branch from origin/main. No implement row. Include-in-runtests
    waits. Campaign G0 stays 2026-08-14.
```

---

## ADA'S RECOMMENDATION

**Approve G0 for docs-only.** Refresh
`docs/dev-log/evidence/2026-08-16-arc1-ordered-backlog.md` so ord 1 reads:
fixture **banked** at `test/parity/q4-reml/biv-q4-phylo-reml/`; `[tol]` =
measured mean-vs-mean+scale gap; `claim_status` still **`partial`**. Drop
“recommended first later implement = `biv_q4_phylo_reml`.” Keep
*export-gap countdown at 0; 11 rows still unsigned.* Quote, do not
rewrite, the eleven `claim_boundary` sentences.

**Do not** name a new recommended implement in this PR (Rose). After
#434 there is no remaining fixture-gap implement in the #432 list.

**IF YOU DO NOT MIND:** docs-only; defer include-in-runtests; stop after
this `/goal` and re-plan before any implement.

**WHAT CONTINUES unattended:** already-armed PRs; `#429` stays stacked on
`#423`; no new auto-merge from this lane; no `Pkg.test`; no recovery; no
drmTMB checkout.

---

## DECISIONS LOCKED (pending G0)

1. Mission stays the 2026-08-14 G0.
2. This `/goal` is **docs-only**. It does not implement a ledger row.
3. Workspace = **new** scratch worktree from `origin/main` (`b73d9241`).
4. `src/` frozen. `#136` open. `#49` parked. D-111 off. `#428` not stolen.
5. No TSV flip. No `runtests.jl`. No LOOP reuse from #434 / #432 / catchup.
6. Verify = stale NONE line gone; 11 IDs once; claim still partial.
7. D-94: behind drmTMB, not GLLVM. Rose fence binds all prose.

---

## QUESTIONS STILL OPEN (max 3)

**Q1 — Docs-only backlog refresh, or force the next implement row
(`phylo_gamma_beta_binomial` / large-p / relmat)?**
**WHY NOW:** the #432 backlog ranked `phylo_gamma_beta_binomial` ord 2,
but classified it **not an implement** (comparator exists; binomial+phylo
is NO twin). Hopper/Rose: forcing it invents work.
**TEAM VIEW:** Hopper/Rose/Ada — docs-only. Shannon — only now-safe work
is unique-path docs.
**RECOMMENDATION:** **docs-only.**
**IF YOU DO NOT MIND:** docs-only.
**WHAT CONTINUES:** this plan either way; implement stays DEFER.

**Q2 — Defer wiring `test/test_parity_biv_q4_phylo_reml.jl` into
`test/runtests.jl` until `#423`+`#425`+`#428` merge?**
**WHY NOW:** that include is the honest #434 follow-up, but three live
PRs own `runtests.jl` (`#428` DIRTY, `#425` ARMED, `#423` DIRTY +
`test(1)` FAIL).
**TEAM VIEW:** Shannon — WAIT. Rose — not a docs title. Ada — not this G0.
**RECOMMENDATION:** **yes — defer.** Fresh G0 later, after the wait
clears; that G0 is an include, not a new ledger-row.
**IF YOU DO NOT MIND:** defer.
**WHAT CONTINUES:** docs refresh does not touch `runtests.jl`.

**Q3 — After this docs `/goal`, stop — or auto-start another implement?**
**WHY NOW:** a helpful `/goal` will “just start the next row.”
**TEAM VIEW:** Rose — do not mint a recommended implement in a docs PR.
Ada — no honest Mac-easy fixture-gap remains.
**RECOMMENDATION:** **stop and re-plan.** Next implement G0 only when
(a) the runtests wait clears, or (b) owner names a new same-target gap.
**IF YOU DO NOT MIND:** stop after this `/goal`.
**WHAT CONTINUES:** docs PR regardless.

---

## SEARCH

`none` for execution (no novelty claim). NotebookLM **not** required.

---

## SLICE TABLE (docs-only — colleague-runnable)

`SCOUT SUITABILITY: yes` — recon already ran this planning pass; `/goal`
does not re-scout the 11 rows.

| ID | Member | model+effort | Bar | time | files / detail | dep |
|---|---|---|---|---|---|---|
| S0 SCAFFOLD | Shannon | **Grok 4.6 high-fast** · low | **Cursor Models** | 10 min | `lane_launch.sh DRM.jl arc1-backlog-after-434` → `~/local-scratch/lanes/DRM.jl-arc1-backlog-after-434` from `origin/main`. New LOOP kit. Open one GitHub issue | — |
| S1 | Ada | Grok 4.6 high-fast · med | **Cursor Models** | 40 min | Rewrite `docs/dev-log/evidence/2026-08-16-arc1-ordered-backlog.md`: ord 1 = fixture **banked** + still `partial`; drop recommended-implement = biv_q4; keep 11 unsigned; quote claim_boundary. Cite #434 after-task + this plan’s Rose fence | S0 |
| S2 | Ada | Grok 4.6 high-fast · low | **Cursor Models** | 20 min | New after-task `docs/dev-log/after-task/2026-08-16-arc1-backlog-after-434.md` + check-log `docs/dev-log/check-log.d/2026-08-16-arc1-backlog-after-434.md`. Do **not** edit the #432 after-task in place | S1 |
| S3 Rose | Rose | Grok 4.6 high-fast · med | **Cursor Models** | 15 min | Claim-vs-evidence on the refreshed backlog. Copy fence from `docs/dev-log/evidence/2026-08-16-next-after-biv-rose.md`. Block “parity complete” / TSV flip / new recommended implement | S1+S2 |
| S4 MECHANICAL-VERIFY | Hopper | Grok 4.6 high-fast · low | **Cursor Models** | 10 min | Count = 11; each ID once; stale NONE gone; no `src/` / `runtests.jl` / TSV / LOOP reuse / capability-status flip. **No** `Pkg.test`. **No** recovery | S3 |
| S5 PR | Ada | Grok 4.6 high-fast · low | **Cursor Models** | 15 min | One issue → one branch → one unarmed PR (`closes #NN`). Phrase: *refresh the Arc 1 backlog after #434; fixture banked; 11 rows still unsigned.* | S4 |
| S6 RECONCILE | Melissa | Grok 4.6 high-fast · low | **Cursor Models** | 5 min | `docs/dev-log/plan-actual/2026-08-16-arc1-backlog-after-434.md` if the `/goal` stays one session; else N/A in after-task | S5 |

**PARALLEL:** none after G0 (docs rewrite is sequential).
**SEQUENTIAL:** S0 → S1 → S2 → S3 → S4 → S5.

**FAN-OUT:** 0 new children required (recon already done). Conductor may
ask Rose S3 as one Grok child. **FAN-OUT BUDGET:**
checkpoint=`arc1-backlog-after-434` · new children≤2/6 · scout=0 ·
build=1 · ceiling=0.

**ULTRA EFFORT:** no.
**CONTEXT BRAKE:** parent input=unknown · after G0 **CONTINUE HERE** in
this chat once the new scratch is the workspace.
**COMPACTIONS:** n/a (planning only).
**LANE RECEIPT:** `CONTINUE HERE` after G0 **if** this chat’s workspace
is switched to the new scratch; else `START A FRESH TASK` opened on that
worktree. Reason=Dropbox leftover must not be the build tree.
**AUTO-REVIEW:** unknown · action=none.
**D-43 PANEL:** not a milestone.
**MODELS:** all slices on **Cursor Models · Grok 4.6 high-fast**. No
Grok Bot. No Claude/Codex parent unless reassigned.
**ESTIMATE:** ~1–1.5 h wall-clock · 1 `/goal` session · no HPC.
**ARC PROGRAM:** N/A (no Arc Card).
**PREFLIGHT:** pasted above.
**REVIEW:** Rose S3 (plan critique also below).
**VERIFY:** S4 mechanical + Rose fence.
**CONSOLIDATE:** refreshed backlog + after-task + check-log on the **new**
docs branch.

### File fence (must not include)

- `src/**`
- `test/runtests.jl` (`#428` `#425` `#423`)
- `LOOP/**` on `origin/main` (leftover #434 kit) — write a **new** kit in
  the new scratch only
- `docs/make.jl` (`#423`)
- `docs/src/cross-family.md` (`#428`)
- `docs/src/model-guides/meta-analysis.md` (`#429` `#423`)
- `docs/src/rosetta.md` (`#423` `#421`)
- `docs/src/reference/structured-effect-markers.md` (`#423`)
- `docs/dev-log/coordination-board.md` (`#406`)
- `docs/dev-log/evidence/parity-phylo-nongaussian.tsv` (`#425`)
- `docs/dev-log/evidence/parity-biv-meta.tsv` (`#423`)
- `tools/parity_ledger.py` (`#423`)
- `test/parity/runparity.jl` · `gen_fixtures.R` · `runparity_bridge.jl`
- `docs/design/capability-status.md`
- leftover worktrees / `docs/a3c-design` commits
- `.codex/agents/shannon-coordinator.toml`

### Allowed paths (this `/goal` only)

```
docs/dev-log/evidence/2026-08-16-arc1-ordered-backlog.md
docs/dev-log/after-task/2026-08-16-arc1-backlog-after-434.md
docs/dev-log/check-log.d/2026-08-16-arc1-backlog-after-434.md
docs/dev-log/plan-actual/2026-08-16-arc1-backlog-after-434.md
LOOP/{GOAL,arcs,checkpoint,ultra-plan}.md   # new kit in NEW scratch only
```

Optional cite-only (do not rewrite): #434 after-task / check-log /
`2026-08-16-next-after-biv-rose.md`.

### How to cut the branch (execution, after G0)

```bash
~/shinichi-brain/tools/lane_launch.sh DRM.jl arc1-backlog-after-434
# expect: ~/local-scratch/lanes/DRM.jl-arc1-backlog-after-434
# branch: docs/arc1-backlog-after-434 (or claude/lane-arc1-backlog-after-434)
# from origin/main @ b73d9241 (or newer main if it moved — rebase onto tip)
```

Do **not** launch inside `DRM.jl-catchup` or `DRM.jl-biv-q4-phylo-reml`.
Do **not** commit on Dropbox `docs/a3c-design`.

---

## ROSE PLAN-REVIEW (critique of this decomposition — not an implementation)

**Sweep receipt:** present and non-vacuous. Each surface cites a command
or query (lane_preflight, git + drift + worktrees, `git show` TSV @
`d9fddfa28`, MCP `search_notes` query, deterministic greps on AGENT_LOG /
DECISIONS / OPEN_QUESTIONS / journal / deep-research README, `gh pr`
locks, #434 `git show --stat`).

**What Rose would block**

- Calling this “R–Julia parity complete” / “caught up” / “D-111 ready”.
- Flipping TSV `supported` or Scoreboard B chips.
- Naming a new recommended implement (`phylo_gamma_beta_binomial`, etc.).
- Wiring the #434 test into `runtests.jl` under a docs title.
- Treating `atol_loglik=6.0` as a defect to fix in `src/`.
- Invented twin Δ; unparking `#49`; closing `#136`; stealing `#428`.
- Building on leftover `docs/a3c-design` / catchup / leftover #434 LOOP/.

**What Rose accepts**

- One-issue docs PR that fixes the stale NONE line and leaves
  `claim_status` untouched.
- Phrase: *refresh the Arc 1 backlog after #434; fixture banked; 11 rows
  still unsigned.*
- *The logLik gap is a declared `[tol]` (TMB mean-only REML vs Julia
  mean+scale), not a 1e-3 Workflow G twin.*

---

## DEFER (fenced — not in the `/goal`)

- TSV `claim_status` → `supported` (`#1049` OPEN; `#1050` merged ≠ flip)
- Remaining 10 unsigned rows as implement cells
- `#428` / `cross_family_latent`
- `#136` VA · `:natgrad` · ordinary-RE REML · AGHQ · `#49`
- include-in-`runtests.jl` (wait `#423` `#425` `#428`)
- HSquared AI-REML · interval coverage
- Workflow G harness edits
- `#423` / `#429` / `#425` / `#420` / `#406` / `#421` files
- Leftover Dropbox `docs/a3c-design` commits
- D-111 / Registrator; GPL vendoring; drmTMB checkout
- Staging `.codex/agents/shannon-coordinator.toml`
- Totoro/DRAC

---

## Paste-ready `/goal` prompt (UNEXECUTED)

After Shinichi approves G0 (and answers Q1–Q3 or “use your judgment”),
paste this **in this chat**:

```
/goal

Ultra-plan G0 approved. Run this plan to completion via LOOP/.

LANE: docs-arc1-backlog-after-434
REPO: /Users/z3437171/local-scratch/lanes/DRM.jl-arc1-backlog-after-434
PLAN: /Users/z3437171/Dropbox/Github Local/DRM.jl/docs/dev-log/after-task/2026-08-16-ultra-plan-next-after-biv-q4.md

READ FIRST: the approved plan → repo AGENTS.md →
  origin/main docs/dev-log/evidence/2026-08-16-arc1-ordered-backlog.md →
  docs/dev-log/evidence/2026-08-16-next-after-biv-rose.md →
  origin/main docs/dev-log/after-task/2026-08-16-biv-q4-phylo-reml-fixture.md.
SCAFFOLD: NEW scratch via `~/shinichi-brain/tools/lane_launch.sh DRM.jl arc1-backlog-after-434`.
  Do NOT use Dropbox leftover docs/a3c-design.
  Do NOT reuse ~/local-scratch/lanes/DRM.jl-catchup.
  Do NOT reuse ~/local-scratch/lanes/DRM.jl-biv-q4-phylo-reml.
  Write a *new* LOOP/ kit for this docs refresh only.
  Open one GitHub issue; PR closes it.
RUN: goal skill — re-read GOAL each arc; verify by LOG not exit code;
  pause at OPEN GATE; overwrite checkpoint each arc.
START ARC: S0 scaffold, then S1 rewrite ordered backlog, S2 after-task +
  check-log, S3 Rose, S4 mechanical verify, S5 unarmed PR.
NEXT GATE: opening the PR. Leave unarmed. STOP after the docs PR —
  do not auto-start an implement row or a runtests.jl include.
VERIFY: stale NONE line gone; 11 IDs once; claim_status still partial;
  no src/ diff; no runtests.jl; no TSV flip; no capability-status flip.
COMPUTE: n/a (docs only).
FENCE: no src/; no runtests.jl; no TSV supported; no #423/#428/#429/#425/
  #420/#406/#421 files; #136 stays OPEN; #49 PARKED; D-111 OFF;
  never stage shannon-coordinator.toml; never checkout drmTMB.
CLAIM FENCE: "refresh the Arc 1 backlog after #434; fixture banked;
  11 rows still unsigned." Do not write "R–Julia parity complete."
  Do not name a new recommended implement. Do not claim interval
  reliability, coverage, AI-REML, or R-via-Julia bridge admission.
  Quote claim_boundary. D-94 = behind drmTMB not GLLVM.
BARS: Cursor Models / Grok 4.6 high-fast (Grok only; no Opus/Sol).
```

---

## Routing receipt (planning session)

| Field | Value |
|---|---|
| PLATFORM | Cursor (lane_preflight `ME: cursor`) |
| Session model | Cursor Grok 4.6 (this chat) |
| bars | Other Models ahead (MODEL-ROUTING 2026-08-16 morning 66% vs 51%); owner: Grok only; Grok Bot unused; on-demand disabled |
| Nested Task subagents | Shannon · Hopper · Rose (Grok 4.6 high-fast) |
| Phase 3 | **not started** |
| git add / commit | **not done** (untracked on leftover `docs/a3c-design`; owner did not ask) |
