# 2026-08-16 — Ada Phase 0–2: ultra-plan for the NEXT DRM.jl arc

**Lane:** Cursor plan discussion (read-only through Phase 2).
**Author:** Ada (Shannon speaking). **No nested Task subagents ran.**
**Platform:** Cursor. **Cursor cannot EnterPlanMode** — this session stayed
strictly read-only except this note. **No Phase 3. No `/goal`. No `/arc-loop`.
No merges. No `src/` edits.**
**Patched 2026-08-16 (this file only):** Phase 0.3b bars from the spending
dashboard; Pólya transferable three folded into *this-arc constraints*
(`docs/dev-log/after-task/2026-08-16-polya-gllvm-lessons.md`). NEXT ARC and
the three owner questions are unchanged. Still unexecuted.

---

## 🎯 GOAL

```
🎯 GOAL
Solo platform: Cursor (this planning session) → /goal after G0 (fresh chat
  in ~/local-scratch/lanes/DRM.jl-catchup, not this Dropbox checkout)
Deliverable: a colleague-runnable ultra-plan for the NEXT arc only
HEADLINE: Arc 0 — close the undocumented @ref / missing @docs gap
  (24 undocumented targets; handover: 16 exported) on a NEW docs branch
  from current origin/main in the scratch worktree
IN PARALLEL: cheap recon of two scoreboards (parity ledger vs Julia
  capability-status) — DONE in this plan; do not re-merge them
DEFER:
  - Arc 1: the 11 non-supported parity-ledger rows (inventory after Arc 0)
  - Arc 1′: Julia-surface REML-RE / natgrad / VA / AGHQ / #49 missing-data
  - #428 A11 src/ (owner: unarm vs leave armed)
  - #423 Julia 1.12 test(1) (A8)
  - #429 stacked on #423
  - #426 armed handover (do not mix @ref into it)
  - leftover Dropbox branch docs/a3c-design
  - #136 VA Experimental (stays OPEN)
  - #49 PARKED
  - D-111 OFF
  - drmTMB #1049/#1050 STOP GATE
  - GPL vendoring
  - staging .codex/agents/shannon-coordinator.toml
  - checkout of the shared drmTMB tree
  - feat/a11, feat/a8, feat/a12, fix/a10, #406
  - GLLVM-specific / VA / natgrad / “become GLLVM” (D-94: behind drmTMB)
DISCIPLINE: verify=ledger re-run + claim_boundary (after merges; not this
  plan's execution) · compute=n/a this plan (easy on this Mac; Totoro/DRAC
  only if a later slice names recovery at scope time) ·
  closure=Shinichi approves G0
```

**Lane claimed:** `PLATFORM: cursor | ON BRANCH: docs/a3c-design (leftover; do not build here) | LANE: plan discussion | OTHER LANES: 10 live — do not steal feat/a11, feat/a8, feat/a12, fix/a10, #406`

---

## Plan-mode note (once)

Cursor cannot flip Plan mode from here. Phases 0–2 ran read-only. Execution
waits for explicit G0. After approval, **do not continue in this chat** —
paste the `/goal` prompt below into a **fresh** Cursor chat opened on the
scratch worktree.

---

## PREFLIGHT (Phase 0.2)

```
bash ~/shinichi-brain/tools/lane_preflight.sh "/Users/z3437171/Dropbox/Github Local/DRM.jl"
```

**VERDICT:** no foreign lane (claude codex) and no 2nd cursor lane in the last
12h. Silence is weak evidence, not proof (D-87).

**10 LANES LIVE** (do not claim their files): `#429` A12 · `#428` A11 · `#427`
overnight close-out · `#426` handover · `#425` A10 · `#423` A8 · `#421`
rosetta · `#420` loop items · `#406` github-auto-merge · leftover
`docs/a3c-design`.

**COORD BOARD:** committed to `origin/main` (reaches other lanes). This plan
does **not** edit it.

**SESSION OWNERSHIP:** `PLATFORM: Cursor`. Dropbox dirty = prior-session
untracked notes (this file + Hopper remasure + prior ultra-vs-loop note +
never-stage `shannon-coordinator.toml`). Not a concurrent editor.

---

## Phase 0.3b — two-bar (spending dashboard 2026-08-16)

Live reading (owner dashboard; on-demand stays **disabled**):

| Bar | Live |
|---|---|
| Cursor Models | **50%** |
| Other Models | **63%** (ahead) |
| Grok Bot | **1% unused** — leave unused |
| On-demand | **disabled** |

**Route until the bars are closer:** scout / recon on **Cursor Models ·
Grok 4.6 high-fast** (not Auto Cost / Claude / GPT / Grok Bot). Judgment
slices (Rose prose) may still use Other Models when that bar has a real
need; do not burn it to even the meters. 2026-08-15 34% / 24% is stale.

---

## Two scoreboards (do not conflate)

### A — Parity ledger (Hopper 2026-08-16 remasure)

Evidence: `docs/dev-log/evidence/2026-08-16-parity-ledger-remeasure.md`
(Hopper; untracked on leftover `docs/a3c-design` — **do not `git add` it
there**). Prior: `docs/dev-log/after-task/2026-08-16-parity-ultra-vs-loop.md`.

Measured on catch-up / `origin/main` export set (154), drmTMB 0.7.0
`origin/main` `9e42d2c94`:

| Scoreboard | Live |
|---|---|
| Export-name countdown | **0** owed (18 raw, 18 accounted) |
| Capability rows with `claim_status != supported` | **11** |
| Split | 6 partial · 4 experimental · 1 unsupported |
| Rows with `claim_status = supported` | **0** |
| Closed gates | 14 |
| CLOSURE | PASS |

**"11 unsupported" means `!= supported`, not 11 rows with status
`unsupported`.** The sole literal-`unsupported` row is
`engine_control_surface` (design fence, not a port).

The 11 rows and their `claim_boundary` (from
`git show origin/main:inst/extdata/julia-capabilities.tsv` via Hopper):

| capability_id | claim_status | claim_boundary (abbrev.) |
|---|---|---|
| `base_gaussian_location_scale` | partial | Phase 1.5 Hopper admitted cell; CRAN readers still TMB |
| `biv_gaussian_residual` | partial | residual rho12 result-shape; not phylo / cross-family |
| `gaussian_phylo_mean` | partial | first phylo-mean; not loc-scale or non-Gaussian phylo |
| `gaussian_response_mask` | partial | Gaussian-only response masks |
| `biv_q4_phylo_reml` | partial | four-axis phylo loc-scale; no same-target bridge parity |
| `plain_binomial_nonphylo` | partial | Workflow G binomial-trials; still experimental |
| `phylo_count_large_p` | experimental | large-p phylo RI; FE count cells via `expected.toml` |
| `phylo_gamma_beta_binomial` | experimental | finite-and-sane smoke only |
| `general_covariance_structured` | experimental | `K` + `sigma ~ 1`; beta / `Q` / sigma predictors gated |
| `cross_family_latent` | experimental | latent-rho; do not present as release-ready |
| `engine_control_surface` | unsupported | no user-selectable Julia optimizer API yet |

**COUNTDOWN 0 ≠ R↔Julia parity complete.** It is an export-name countdown.
Promoting a row to `supported` is a **drmTMB TSV / claim decision** (STOP
GATE — do not merge drmTMB `#1049`/`#1050` unattended), not a DRM.jl export
gap.

### B — Julia capability surface (`docs/design/capability-status.md` @ `origin/main`)

Read: `git show origin/main:docs/design/capability-status.md`.
Mission Control `http://127.0.0.1:8823/p/drmTMB/julia-surface` parses **only
the `Capability | Status` tables** (`serve_multi.parse_julia_capability_tables`).
This session could not fetch localhost (isolated fetch); counts below are
from the file.

**Table census (what MC shows): 39 implemented · 2 rejected · 1 planned · 4
missing.** The file's own snapshot line ("37 / 1 / 1 / 4") is **stale** —
trust the tables.

MC chip colours (from `serve_multi.py`): **green = implemented · orange =
rejected · blue = planned · grey = missing.** If the on-screen "orange"
list includes REML (Gaussian FE location-scale), that contradicts the file
(that row is `implemented`). Treat UI-vs-file as UNVERIFIED until someone
reloads the board; **do not plan a REML-FE port**.

#### Rejected (orange) — not missing ports

| Capability | Notes / claim_boundary |
|---|---|
| REML with ordinary random effects (Gaussian mean) | Explicit `ArgumentError` in `src/gaussian_core.jl` (~L407): `method = :REML` only for the gated FE / q4 paths. **Rejected by guard.** |
| Natural-gradient EM (`algorithm = :natgrad`) | #13 decision gate **FAIL** (2026-08-01): `fit_em_natgrad` stalls at logLik ≈ −259.80 vs sparse-TMB −256.51. Brief: `docs/dev-log/plans/2026-08-01-natgrad-decision-gate.md`. `lc_metric` extracted; **not** a public solver. Mission Control `drmTMB.json` already fences inventing `:natgrad` on the bridge. |

#### Planned (blue)

| Capability | Notes / claim_boundary |
|---|---|
| Variational (VA/ELBO) marginal estimator | `src/variational.jl` exists; `_fit_va` `error`s and points at **#136**. Tests cover method-selection plumbing only. **#136 stays OPEN** — do not close/fix/resolve. |

#### Missing (grey)

| Capability | Notes / claim_boundary |
|---|---|
| AGHQ adaptive-quadrature marginal estimator | No AGHQ symbol in exports / ROADMAP / HANDOVER / README. Docs list only `:LA` (implemented) and `:VA` (stub). |
| Cross-family bivariate (different families for y1 y2) | File still says `missing` (Gaussian-only bivariate source). **Live work is #428 A11** (`feat/a11-cross-family-formula`, `src/mixed_family.jl`) — **do not steal.** Ledger row `cross_family_latent` is `experimental`. |
| Missing-response handling (native, per fitted route) | Listwise deletion exists; drmTMB's named capability is per-route masked likelihood. **#49 PARKED.** |
| Missing-predictor imputation (`mi()`) | Explicitly out of scope in `src/missing_data.jl`. **#49 PARKED.** |

#### Implemented but easy to misread

| Capability | Why it is not Arc 1′ |
|---|---|
| REML (Gaussian fixed-effect location-scale) | **implemented** (`method = :REML`). Not a gap. |
| REML bivariate phylogenetic location-scale (q4, all axes) | **implemented** (`src/reml_q4.jl`, `test/test_reml_q4_allaxes.jl`). |

**Scoreboard rule:** A is drmTMB's *bridge claim vocabulary*. B is DRM.jl's
*code+test census*. Orange/blue/grey on B are mostly **rejected / parked /
owned-by-another-PR**, not a "port these four" campaign.

---

## SWEEP RECEIPT (Phase 0.25 — default-closed; Phase 1 may not begin without this)

| Surface | Evidence (command / query) | Finding | Call |
|---|---|---|---|
| **lane** | `~/shinichi-brain/tools/lane_preflight.sh` on Dropbox DRM.jl | Verdict above; 10 live lanes; board committed | Take **plan discussion** only |
| **repo git** | `git status -sb`; `session_ownership.sh`; `branch_drift_check.sh`; `git worktree list`; `git stash list`; `git log --oneline -12`; `git log origin/main -12` | Dropbox: `docs/a3c-design`, **0 ahead / 42 behind** `origin/main`. Untracked: this note, Hopper remasure, prior ultra-vs-loop, `shannon-coordinator.toml` (**never stage**). `origin/main` = `394b62d9` (#424 in). Scratch catch-up: `handover/2026-08-16-cursor` @ `d9214fd4` (5 commits ahead of main, all handover docs). Many stale `.worktrees/` / `.claude/worktrees/` | **Do not build on Dropbox.** Resume scratch; cut a **new** docs branch from `origin/main`, not from `#426` |
| **@ref detector** | Handover Python snippet run in catch-up tree | **24** undocumented `@ref` targets still. Handover inventory: **16 exported**. Crude `export` harvest undercounted (multi-line `export`) — do not trust a 3-exported recount. Re-run on **fresh main** at execution | **This is the NEXT arc** |
| **handover OWED** | `git show` / read catch-up `docs/dev-log/handover/2026-08-16-cursor-handover.md` | G0 2026-08-14: *admit what an R user actually fits*. OWED 1–6 before the 11 rows. `#428` later "armed at owner's explicit instruction"; live `gh` still **ARMED + BEHIND**. `#423` `test(1)` **FAILURE** (1.12). `#426` ARMED + BLOCKED | Unarm `#428` is the recommended default; this lane will not flip it |
| **ledger** | Hopper remasure (cited) | COUNTDOWN 0 · 18/18 · 11 rows · CLOSURE PASS · none `supported` | Cite 18/18; do not ship "parity complete" |
| **twin drmTMB** | `git -C "…/drmTMB" status -sb`; `git log origin/main -5`; `git show origin/main:docs/design/capability-status.md` | Twin checkout is **dirty leftover** `claude/handover-freshness-0718` (do **not** checkout). `origin/main` `9e42d2c94` (#1050 merged on R side). **No** `docs/design/capability-status.md` on drmTMB `origin/main` — Julia file is the MC julia-surface source | Read-only; never checkout the shared tree; STOP GATE `#1049`/`#1050` |
| **brain** | MCP `search_notes` ×3, `search_all_projects: true` (never `project:`): `DRM.jl REML natgrad VA capability-status parity 11 unsupported rows`; `DRM.jl undocumented @ref export gap catch-up G0 engine=julia 2026-08-14`; `D-111 Julia General DRM.jl #136 VA Experimental natgrad rejected REML ordinary RE`. `read_note` `shinichi-brain/projects/drm-jl` (D-94 / D-111). `read_note` on the D-111 title failed (permalink miss) — D-111 body read from `memory/DECISIONS.md` | D-111 live (stay off General). D-94 R-first. Catch-up G0 is **repo-local**, not in the vault. Vault `AGENT_LOG` has almost no DRM.jl catch-up (board-count line only) | Reuse G0 + decisions; do not rebuild a ship G0 from the vault |
| **deterministic grep** | `grep -in "capability-status\\|natgrad\\|REML\\|VA" memory/AGENT_LOG.md` (DRM.jl hit: board-count only; rest is gllvmTMB/drmTMB). `grep -in` same strings in `memory/DECISIONS.md` → D-111, D-94, D-34 (capability-status as *volatile* — do not put current state in always-loaded files). `grep` `journal/` (no 2026-08-16 DRM.jl @ref/ledger line). `grep` `OPEN_QUESTIONS.md` (REML sample-size lesson; not this arc). `rg` `projects/deep-research/README.md` → dr20 REML-vs-AGHQ and dr21 VA/EVA are **gllvmTMB/drmTMB**, not a DRM.jl VA/natgrad implementation brief | No vault decision says "implement natgrad / ordinary-RE REML / VA next" | **reuse** rejected/parked fences; **resume** the named G0; **build-the-gap** = `@ref` docs only |
| **PRs (live `gh`)** | `gh pr view` 423/426/428/429 | `#423` ARMED, `test(1)` FAIL, `test(1.10)`+docs green. `#426` ARMED, BLOCKED. `#428` ARMED (itchyshin 13:00Z), BEHIND, touches `src/`. `#429` stacked on `#423`, no automerge | Do not steal; do not rebase `#429` |
| **Mission Control** | `live/status/drmTMB.json` (no `DRM.jl.json`); parser in `serve_multi.py` | `drmTMB.json` still cites DRM.jl tip `94a47e8b` (stale). Julia-surface counts are server-derived from origin/main tables | Sibling may refresh; this plan does not start the server |
| **two-bar** | Spending dashboard **2026-08-16** (Phase 0.3b; live) | Cursor Models **50%** · Other Models **63%** (ahead) · Grok Bot **1% unused** · on-demand **disabled**. Prior 2026-08-15 34%/24% is stale. | Scout/recon on **Cursor Models · Grok 4.6 high-fast** until bars are closer; do not burn Other Models on recon. `/goal` after G0 |
| **Verdict** | — | Genuinely new work this lane can own without stealing: **the `@ref` docs gap on a new branch from main**. The 11 rows and Julia-surface orange/blue/grey are not one blob and are not next | **reuse G0 / resume after OWED / build-the-gap = Arc 0 `@ref`** |

---

## WHAT THE BRAIN ALREADY KNOWS

| Claim | Source | Status |
|---|---|---|
| G0 already named 2026-08-14: catch up so `engine="julia"` admits what an R user actually fits. Anchor drmTMB **0.7.0**. | catch-up handover + `LOOP/GOAL.md` | live — **keep as mission; this arc is a slice under it** |
| D-111: stay off Julia General until catch-up + both halves working; drmTMB likely R/CRAN first | [[DECISIONS#D-111]] · `projects/drm-jl` | accepted |
| D-94: each Julia repo is sequenced behind **its own R half**. DRM.jl is behind **drmTMB**, not GLLVM.jl. Do not open a “catch up to GLLVM” G0. | [[DECISIONS#D-94]] · Pólya 2026-08-16 gllvm-lessons | accepted |
| Export-name presence ≠ capability parity. No ledger row is `supported` | A0 + Hopper remasure | live |
| `#13` natgrad FAIL; not a public solver | ROADMAP / HANDOVER / capability-status notes | accepted |
| `#136` VA Experimental stays open | LOOP fence + this invocation | **PROTECTED** |
| `#49` missing-data PARKED | LOOP fence | **PARKED** |
| Ultra-plan Phases 0–2 on Cursor; Phase 3 = `/goal` in a fresh chat | Cursor ultra-plan / goal adapters | doctrine |
| Catch-up LOOP kit's *export-gap* arc list is exhausted (A4c–A6 shipped). Stale `checkpoint.md` still saying NEXT=A4c must **not** be `/goal`'d | prior 2026-08-16 ultra-vs-loop note | live |

---

## WHAT SHINICHI TOLD US (this invocation)

- Plan a bit more; stay read-only through Phase 2.
- Solo platform Cursor for the **plan**; execution after G0 is a fresh `/goal`
  in the scratch worktree, not this Dropbox checkout.
- Name **one** next arc (not "achieve R–Julia parity").
- Recommend defaults: **unarm `#428`**; **leave `#423` to A8**; **keep the
  2026-08-14 G0** as mission; this arc is a named slice under it.
- `@ref` must be a **new docs branch from main** in
  `~/local-scratch/lanes/DRM.jl-catchup`, not mixed into `#426`.

---

## TEAM RAISED

Siblings did not return independently in this session. Lines below are
**AGENT-INFERRED** from their charters + the measured scoreboards.

```
TEAM RAISED
  Hopper — noticed: COUNTDOWN 0 is export-name honesty; 11 rows are
    claim_status != supported (6 partial / 4 experimental / 1 unsupported);
    zero rows are supported; Workflow G fixtures still record drmTMB 0.6.0
    while the campaign anchors 0.7.0.
    why it matters: treating the 11 as "missing Julia ports" would start
    drmTMB claim work from the wrong tree.
    recommendation: inventory after Arc 0; keep DRM_PARITY_TESTS=1 on any
    later bf() touch; do not promote a TSV row from DRM.jl.
    question: none the ledger cannot answer after the next post-merge re-run.
    default: do not start Arc 1 in the same /goal as Arc 0.

  Rose — noticed: two scoreboards (ledger vs capability-status) use different
    vocabularies; MC snapshot line in the markdown is stale (37 vs 39);
    "COUNTDOWN 0" + "CLOSURE PASS" is not a public-parity claim; #423 red is
    a measured 1.12 recovery miss, not an @ref defect.
    why it matters: a "fix the orange chips" arc would re-open rejected
    estimators and #136.
    recommendation: Arc 0 docs-only; phrase "export-gap countdown at 0; 11
    rows still unsigned"; never "R–Julia parity complete."
    question: Q1 (#428 unarm) and Q2 (#423).
    default: hold the claim fence; do not touch #428's auto-merge from this lane.

  Shannon — noticed: 10 live lanes; Dropbox 42 behind on docs/a3c-design;
    scratch is parked on armed #426; @ref mixed into #426 would be a post-arm
    push (already paid for once).
    why it matters: bleed-through, not concurrency, is the failure mode.
    recommendation: new docs branch from origin/main in the scratch worktree;
    never stage shannon-coordinator.toml; never checkout drmTMB.
    question: none — D-87, owner decides overlap.
    default: this lane stays plan → then docs-@ref only.

  Noether — noticed: Arc 1′ orange/blue rows are rejected guards (#13 natgrad,
    ordinary-RE REML) or the #136 VA stub; REML FE and q4 REML are already
    implemented; verified engine logLik −256.51 / 2.18× is not in scope.
    why it matters: "implement the orange chips" would regress the #13 gate
    and touch src/ without maintainer sign-off.
    recommendation: do not open an estimator arc; do not edit src/.
    question: none today.
    default: src/ frozen for this /goal.

  Pat — noticed: an R user still cannot treat engine="julia" as "whatever
    drmTMB fits"; reader docs still say Experimental; a broken @ref becomes
    a VitePress npm failure (warnonly=true on Documenter).
    why it matters: Arc 0 prevents the next docs PR from dying the same way
    #423/#428 did; it does not change "what can I fit today?"
    recommendation: add @docs for exported names; demote _-prefixed @ref to
    code spans; do not rewrite reader pages.
    question: none today.
    default: no full Documenter rebuild on this Mac unless the detector is
    clean and a preview is cheap.

  Ada — synthesis: keep the 2026-08-14 G0. NEXT = Arc 0 @ref hygiene.
    Defer the 11-row inventory and Julia-surface orange/blue/grey until
    after that PR is up. Do not replace G0 with "parity complete."

  Pólya — noticed (2026-08-16 gllvm-lessons; propose only): GLLVM.jl looks
    greener because it is a different twin (gllvmTMB) and a different
    dashboard (VA-GH on the R pair). D-94 sequences DRM.jl behind drmTMB,
    not GLLVM. Transferable now: Rose fence, no invented twin Δ,
    leftover / @ref discipline. VA / natgrad / “become GLLVM” stay DEFER.
    why it matters: a “catch up to GLLVM” G0 would change the product.
    recommendation: fold the three as *this-arc constraints*; do not add
    slices. NEXT ARC stays Arc 0 @ref hygiene.
    question: none — owner questions stay Q1–Q3.
    default: do not implement from the scout.
```

---

## ADA'S RECOMMENDATION

**NEXT ARC = Arc 0 — undocumented `@ref` / missing `@docs` hygiene.**

One sentence: *Cut a new docs-only branch from current `origin/main` in
`~/local-scratch/lanes/DRM.jl-catchup`, close the 24 undocumented `@ref`
targets (exported names → `@docs`; `_`-prefixed internals → plain code
spans), and open a PR that does not touch `src/`, `#426`, or anyone else's
files.*

**Why this, not the others**

| Candidate | Why not NEXT |
|---|---|
| **Arc 1 — 11 ledger rows** | Handover: *"Then, and only then."* None is `supported`; six are already admitted Phase 1.5 cells; promoting any row is a drmTMB claim. Needs an **inventory** after Arc 0, then one-issue PRs — not this `/goal`. |
| **Arc 1′ — Julia-surface orange/blue/grey** | REML FE is already implemented. Ordinary-RE REML and `:natgrad` are **rejected**. VA is **#136 OPEN**. AGHQ is a real missing estimator but not the catch-up OWED. Cross-family is **#428's lane**. Missing-data is **#49 PARKED**. These are not "missing ports." |
| **Stay on `#426` / Dropbox `docs/a3c-design`** | `#426` is an armed handover PR; Dropbox is 42 behind. Mixing `@ref` into either repeats the post-arm-push failure. |

**IF YOU DO NOT MIND:** approve G0 for Arc 0 only; unarm `#428` yourself (this
lane will not); leave `#423` to A8; keep the 2026-08-14 G0 as the campaign
mission.

**WHAT CONTINUES unattended:** already-armed PRs (except the `#428` call);
`#429` stays stacked; no new auto-merge from this lane; no `Pkg.test`; no
recovery; no drmTMB checkout.

---

## THIS ARC CONSTRAINTS (Pólya 2026-08-16 — transferable three)

Cite: `docs/dev-log/after-task/2026-08-16-polya-gllvm-lessons.md`.
**D-94:** DRM.jl is sequenced behind **drmTMB**, not GLLVM.jl. These are
fences on Arc 0, not new slices. GLLVM-specific / VA / natgrad /
“become GLLVM” stay in DEFER.

1. **Rose fence** — intended API similarity ≠ full parity claim. Export
   present ≠ `supported`. Do not write “R–Julia parity complete.” Do not
   promote a ledger row or flip `capability-status.md` because a name
   exists. (The 11-row inventory is still *after* Arc 0; the fence applies
   to any prose this `/goal` writes.)
2. **No invented twin Δ** — if drmTMB did not ship the cell, a Julia-only
   “Δ” is forbidden, not owed. Do not invent drmTMB support. Promoting a
   TSV row is a drmTMB claim decision (STOP GATE `#1049`/`#1050`).
3. **Leftover / `@ref` discipline** — do not code on leftover
   `docs/a3c-design` or mix `@ref` into armed `#426`. New docs branch from
   current `origin/main` in the scratch worktree. Convention-change
   cascade: `@ref` / `@docs` / docstrings / status tables move together
   (copy the *rule*, not GLLVM pages). VitePress dies on literal `./@ref`.

---

## DECISIONS LOCKED (pending G0)

1. Mission stays the 2026-08-14 G0 (admit what an R user actually fits).
2. This `/goal` implements **Arc 0 only**.
3. Workspace = scratch worktree, **new branch from `origin/main`**.
4. `src/` frozen. `#136` open. `#49` parked. D-111 off.
5. Verify = detector re-run (0 undocumented *exported* `@ref`s) + Rose
   claim fence. No full `Pkg.test`. No Totoro/DRAC.
6. D-94: behind drmTMB, not GLLVM. Pólya transferable three (above) bind
   this arc. Do not start a “become GLLVM” or VA/natgrad slice.

---

## QUESTIONS STILL OPEN (max 3)

**Q1 — `#428` (A11, `src/`).** Live `gh`: auto-merge **ARMED** by itchyshin
(2026-08-16 13:00Z) and **BEHIND**. Handover first said leave unarmed, then
recorded that you armed it. **Unarm vs leave armed?**
**WHY NOW:** only open `src/` PR on the catch-up stack; this lane must not
touch it either way.
**TEAM VIEW:** Rose/Shannon — unarm (restore the engine auto-merge pause)
unless you want engine auto-merge.
**RECOMMENDATION:** **unarm.**
**IF YOU DO NOT MIND:** unarm (you flip it; we do not).
**WHAT CONTINUES:** Arc 0 docs branch regardless.

**Q2 — `#423` `test(1)` on Julia 1.12.** Measured
`abs(ρ̂ - residual_rho) = 0.183 ≮ 0.15` at
`test_meta_vcov_bivariate.jl:142`. `test(1.10)` + Documenter green. Auto-merge
still armed.
**WHY NOW:** a helpful agent will "just fix the red PR."
**TEAM VIEW:** Rose/Hopper — A8 owns the tolerance; never fit to one 1.12 run.
**RECOMMENDATION:** **ignore here.**
**IF YOU DO NOT MIND:** ignore as A8's problem.
**WHAT CONTINUES:** `#429` stays stacked; do not rebase.

**Q3 — after Arc 0, do the 11 rows still sit under the 2026-08-14 G0?**
**WHY NOW:** the export-gap LOOP is exhausted; the 11 rows were never on it.
**TEAM VIEW:** Ada — keep the G0; require an inventory before any later
`/goal`; do not treat TSV `supported` as the finish line.
**RECOMMENDATION:** **keep the 2026-08-14 G0.** This arc does not replace it.
**IF YOU DO NOT MIND:** same.
**WHAT CONTINUES:** Arc 0 only after you approve.

---

## SEARCH

`none` for execution (no novelty claim). **NotebookLM offered, not run:**
want a grounded NotebookLM pass on Documenter `@ref`/`@docs` vs VitePress
dead-link behaviour, or on REML/VA/natgrad prior art? Not required for Arc 0
(the defect class is already diagnosed in the handover). Say yes if you want
it before a later Arc 1 inventory.

---

## SLICE TABLE (Arc 0 only — colleague-runnable)

`SCOUT SUITABILITY: yes` — detector + grep + export-list parse.

| ID | Member | model+effort | Bar | time | files / detail | dep |
|---|---|---|---|---|---|---|
| S0 RECON | Hopper/Pat (scout) | **Grok 4.6 high-fast** · low | **Cursor Models** | 15 min | Re-run handover detector on **fresh `origin/main`** in scratch; parse `src/DRM.jl` exports properly (multi-line); split list into exported-public vs `_`-internal vs `#136` `Laplace`/`Variational` (do **not** `@docs` those). Write the list into the PR body. Route here until Cursor Models / Other Models bars are closer (0.3b: 50% / 63%). | — |
| S1 | Pat | Grok/Composer · med | **Cursor Models** | 30–45 min | Add `@docs` blocks for exported public names. Prefer `docs/src/reference/model-fitting-and-postfit.md` (heritability / icc / bias_correct / chibar / phylo_penalty*) and/or a **new** `docs/src/reference/engine-accessors.md` if the fitting page would collide. **Do not edit** `docs/src/cross-family.md`, `docs/src/reference/structured-effect-markers.md`, `docs/make.jl`, `LOOP/checkpoint.md`, `docs/dev-log/coordination-board.md`, `src/**`, `test/runtests.jl`. | S0 |
| S2 | Pat | Grok/Composer · low | **Cursor Models** | 15–20 min | Demote `_`-prefixed `@ref` (and other internals) to plain `` `name` `` code spans. Same file fence as S1. | S0 |
| S3 MECHANICAL-VERIFY | Hopper | Grok/Composer · low | **Cursor Models** | 10 min | Re-run detector: **0 undocumented exported `@ref`s**. Spot-check one `@docs` name exists in the page. **No** `Pkg.test`. **No** recovery. Documenter/VitePress preview only if cheap and not racing `#423`/`#428` previews. | S1+S2 |
| S4 | Ada/Pat | Auto Cost · low | **Other Models** | 15 min | PR from the new docs branch; `closes` a new issue if one is filed, else say "hygiene / handover OWED 6". Auto-merge is the **last** action after the final commit — or leave unarmed if docs CI is racing. | S3 |
| S5 Rose | Rose | Auto Cost / pinned Claude · med | **Other Models** | 15 min | Claim-vs-evidence: no "parity complete"; no capability-status edit; no `#136` close; sweep receipt non-vacuous (this file). | S4 |
| S6 RECONCILE | Melissa | — | **hand off** or skip | 5 min | `N/A — small docs-only hygiene; record in after-task if `/goal` stays one session.` | S5 |

**PARALLEL:** S1 and S2 after S0 (disjoint files if S0 splits the list).
**SEQUENTIAL:** S0 → {S1,S2} → S3 → S4 → S5.

**FAN-OUT:** 0 in this planning chat. After G0, `/goal` may use 1 scout + 1
build child. **FAN-OUT BUDGET:** checkpoint=`arc0-ref` · new children≤2/6 ·
scout=1 · build=1 · ceiling=0.

**ULTRA EFFORT:** no.
**CONTEXT BRAKE:** parent input=unknown · fresh-task trigger=**START A FRESH
TASK** after G0 (this planning chat must not execute).
**COMPACTIONS:** n/a (planning only).
**LANE RECEIPT:** `START A FRESH TASK` · reason=G0 handoff to `/goal` in
scratch · next-task prompt=block below.
**AUTO-REVIEW:** unknown · action=none.
**D-43 PANEL:** not a milestone.
**MODELS:** scout/recon on **Cursor Models · Grok 4.6 high-fast** until
bars are closer (0.3b: Cursor Models 50% / Other Models 63% / Grok Bot 1%
unused / on-demand disabled). Cursor Grok/Composer for S1–S3 edits. Other
Models only for Rose prose when needed — do not burn it on recon. No
Claude/Codex parent unless you reassign. No Grok Bot.
**ESTIMATE:** ~1–2 h wall-clock · 1 session · fits one `/goal` · no HPC.
**ARC PROGRAM:** N/A (no Arc Card).
**PREFLIGHT:** pasted above.
**REVIEW:** Rose section below (plan critique, not implementation).
**VERIFY:** detector + claim fence.
**CONSOLIDATE:** after-task + check-log.d entry on the docs branch (not this
Dropbox leftover).

### File fence (must not include)

- `docs/src/cross-family.md` (#428)
- `docs/src/reference/structured-effect-markers.md` (#423 already touched)
- `docs/make.jl`
- `LOOP/checkpoint.md` (stale catch-up kit — do not refresh as a side effect)
- `docs/dev-log/coordination-board.md`
- `src/**`
- `test/runtests.jl`
- `.codex/agents/shannon-coordinator.toml`

### How to cut the branch (execution, after G0)

```bash
cd /Users/z3437171/local-scratch/lanes/DRM.jl-catchup
git fetch origin
# #426 stays on origin; this worktree moves to a new docs branch
git checkout -B docs/undocumented-export-ref origin/main
# confirm: git rev-parse HEAD == origin/main; git status -sb clean
```

Do **not** `git checkout` the Dropbox tree. Do **not** start from
`handover/2026-08-16-cursor`.

### Two different fixes (do not apply one blanket)

1. **Exported public API** → a reference `@docs` block (docstring already
   exists; rendering is what makes `@ref` resolve).
2. **`_`-prefixed internals** → drop `@ref`, keep a plain code span.
   Documenting them would publish internals.

`Laplace` / `Variational` `@ref`s in `src/variational.jl` are **#136
plumbing** — demote to code spans; do **not** add `@docs` that look like a
working VA estimator.

Handover's 16 exported names (reconfirm on fresh main in S0):
`drm_phylo_penalty`, `drm_phylo_penalty_sweep`, `associate_pairs`,
`association`, `latent_normal`, `heritability`, `icc`, `bias_correct`,
`chibar_pvalue`, `fit_q4_sparse_tmb`, `make_problem`, `marginal_nll`,
`lc_to_cov`, `AugProblem`, `CoevoProblem`, `PhyloCorPenaltyNeedsTwoSD`.

---

## ROSE PLAN-REVIEW (critique of this decomposition — not an implementation)

**Sweep receipt:** present and non-vacuous. Each surface cites a command or
query (lane_preflight, `git status -sb` + `branch_drift_check`, Hopper
remasure path, `git show origin/main:docs/design/capability-status.md`,
MCP `search_notes` query strings, deterministic greps on AGENT_LOG /
DECISIONS / journal / OPEN_QUESTIONS / deep-research README, `gh pr view`).
Not a bare "none found."

**What Rose would block**

- Calling COUNTDOWN 0 "parity complete."
- Merging Arc 0 + Arc 1 + Arc 1′ into one `/goal`.
- Editing `capability-status.md` to flip rejected → implemented without a
  new guard/test (that would be a claim lie).
- Closing `#136` because VA is "planned."
- Mixing `@ref` into `#426` or `#428`.
- A Documenter CI race used as a reason to push onto an armed PR.

**What Rose accepts**

- Arc 0 as the single next slice under the existing G0.
- Pólya transferable three as *constraints* (Rose fence, no invented twin
  Δ, leftover/@ref discipline) — not as extra slices. D-94: behind drmTMB,
  not GLLVM. VA / natgrad / “become GLLVM” stay DEFER.
- Detector-as-verifier (log + printed list, not exit code theatre).
- Stale snapshot line in capability-status left alone (out of scope; do not
  "fix the census comment" in this arc unless it is a one-line honesty
  patch on the *new* docs branch and Rose agrees it is not claim drift).

---

## DEFER (fenced — not in the `/goal`)

- Arc 1: inventory + one-issue PRs for the 11 ledger rows
- Arc 1′: ordinary-RE REML, `:natgrad`, VA/ELBO, AGHQ
- `#428` unarm/leave (owner flips)
- `#423` / `test_meta_vcov_bivariate.jl` (A8)
- `#429` rebase
- `#426` post-arm docs
- Dropbox `docs/a3c-design` commits
- `#136`, `#49`, D-111, drmTMB `#1049`/`#1050`
- GPL vendoring; shared drmTMB checkout
- Staging `.codex/agents/shannon-coordinator.toml`
- `feat/a11`, `feat/a8`, `feat/a12`, `fix/a10`, `#406`
- Full `Pkg.test`, recovery campaigns, Totoro/DRAC
- Refreshing the stale catch-up `LOOP/` kit as a side effect of Arc 0
- A new ship G0 titled "R–Julia parity"
- **GLLVM-specific / “become GLLVM”** (ordination, fourth-corner, LV
  modes, family-count race, Identity→ADMIT conveyor, SPDE-as-LV). D-94:
  DRM is behind drmTMB, not GLLVM
- VA / ELBO implementation or promotion (`#136`); `:natgrad` / AI-REML
  public solver (already rejected); copying GLLVM VA-GH as a DRM G0

---

## Paste-ready `/goal` prompt (UNEXECUTED)

After Shinichi approves G0, paste this into a **fresh** Cursor chat whose
workspace is `~/local-scratch/lanes/DRM.jl-catchup` (not the Dropbox
checkout):

```
/goal

Ultra-plan G0 approved. Run this plan to completion via LOOP/.

LANE: docs-undocumented-ref
REPO: /Users/z3437171/local-scratch/lanes/DRM.jl-catchup
PLAN: /Users/z3437171/Dropbox/Github Local/DRM.jl/docs/dev-log/after-task/2026-08-16-ultra-plan-next-arc.md

READ FIRST: the approved plan → repo AGENTS.md → HANDOVER.md.
SCAFFOLD: in THIS scratch worktree, `git fetch origin` then
  `git checkout -B docs/undocumented-export-ref origin/main`.
  Do NOT stay on handover/2026-08-16-cursor. Do NOT mix into #426.
  Write a *new* LOOP/ kit for Arc 0 only (or a lane folder) from the plan;
  do not revive the stale A4c checkpoint.
RUN: goal skill — re-read GOAL each arc; verify by LOG not exit code;
  pause at OPEN GATE; overwrite checkpoint each arc.
START ARC: S0 detector on fresh main, then S1 @docs + S2 demote internals.
NEXT GATE: opening/arming the PR (auto-merge last, or leave unarmed).
VERIFY: detector prints 0 undocumented exported @refs.
COMPUTE: n/a — no Pkg.test, no recovery, no Totoro/DRAC.
FENCE: no src/; no cross-family.md; no structured-effect-markers.md;
  no make.jl; no coordination-board; no LOOP/checkpoint.md refresh of the
  catch-up kit; no #423/#428/#429/#406; #136 stays OPEN; #49 PARKED;
  D-111 OFF; never stage shannon-coordinator.toml; never checkout drmTMB.
CLAIM FENCE: do not write "R–Julia parity complete." Rose fence + no
  invented twin Δ (Pólya transferable; D-94 = behind drmTMB not GLLVM).
  Do not become GLLVM; do not implement VA/natgrad.
```

---

## Routing receipt (planning session)

| Field | Value |
|---|---|
| PLATFORM | Cursor (read from `session_ownership.sh`) |
| Session model | Cursor Grok 4.6 (this chat) |
| bars | **2026-08-16 dashboard:** Cursor Models **50%** · Other Models **63%** · Grok Bot **1% unused** · on-demand **disabled**. Scout/recon → Cursor Models · Grok 4.6 high-fast until closer |
| Nested Task subagents | **none** |
| Phase 3 | **not started** |
| git add / commit | **not done** (owner did not ask) |
