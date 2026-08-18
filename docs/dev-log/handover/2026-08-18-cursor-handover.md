# Session Handoff: DRM.jl 3h-queue closeout → next Cursor G0

Meta: 2026-08-18 13:12 MDT · from Cursor (Shannon; AUTHOR=cursor) · TARGET=cursor ·
context n/a (this is a durable closeout, not a mid-compact)

You are Cursor, picking up DRM.jl after the 2026-08-18 three-hour queue.
You inherit **no chat context**. This document plus `AGENTS.md` and the
**current** git/gh state are the record. Rehydrate, classify, then execute
**only `OWED`**. Do not implement a G0 until Shinichi names it.

---

## Critical Context

1. **The 3h queue is DRAINED.** Six DRM merges and two GLLVM merges are on
   `origin/main`. There is no in-flight MUST-finish. Next G0 is **Shinichi's
   call, not started**: AGHQ port (lever 2) **or** Poisson phylo Laplace
   `:555` punch — **not both this slice**.
2. **Dropbox `DRM.jl` on `docs/a3c-design` is leftover** (~114 commits behind
   `origin/main` at writing). Do not resume there. Do not build `src/` on it.
   Preferred fresh tree: `origin/main` @ `d04ba994` (merge of #446), or this
   handover branch `handover/2026-08-18-cursor`.

---

## Goals / mission

DRM.jl is the MIT Julia twin of GPL drmTMB (univariate & bivariate
distributional regression). Mission: the fastest correct engine for that
model class, with paste-and-run `bf()` parity. **ML is the default.** Twin
numbers are vs **drmTMB**, never GLLVM loading-matrix numbers. Never vendor
drmTMB source.

This session's "why": close the 3h queue (REML / Cox–Reid / A8 / A11 /
Option A / GLLVM A4(3) honesty) and hand a **named-or-STOP** G0 to the next
Cursor lane.

---

## Plans / roadmap (beyond the next G0)

Probe order after #444 (`docs/dev-log/evidence/2026-08-18-cox-reid-scoping-probe.md`
§ Next G0s) — **direction only; do not start un-named items**:

1. Poisson phylo Laplace Cox–Reid wiring (`_fit_poisson_general_laplace`;
   probe labeled `_withnll` at `:555` — on `origin/main` the function starts
   at `src/sparse_laplace_glmm.jl:470`; use the **function name**, not a
   frozen line). Hook proven (Cell C). Cell D underpowered for a bias-sign
   claim — ADEMP with a larger tree before `:REML` is admitted there.
2. Other scalar-per-cluster families, one at a time.
3. **AGHQ port (lever 2)** — after Cox–Reid, not instead of it; after GLLVM
   honesty (#255/#256 already landed).

Vault had “wiring then AGHQ.” Wiring (#444) shipped. Owner picks **one**.

---

## What Was Accomplished

Verified with `gh` on 2026-08-18 (do not re-merge; do not rewrite helpers).

| Item | Classification | PR / issue | Merge SHA | Notes |
|---|---|---|---|---|
| DRM REML mean `(1\|g)` | **DONE** | #440 / #439 | `5e392c6e` | Woodbury spine |
| Cox–Reid scoping probe | **DONE** | #442 / #441 | `e161c165` | not a ship |
| Cox–Reid wiring Poisson `(1\|g)` GHQ | **DONE** | #444 / #443 | `2dcc5508` | opt-in `:REML`; ML default |
| A8 bivariate meta known-V | **DONE** | #423 | `7dcaa41e` | |
| A11 cross-family bivariate formula | **DONE** | #428 | `d40552ae` | |
| Option A standalones in `runtests.jl` | **DONE** | #446 / #445 | `d04ba994` | `origin/main` tip at writing |
| GLLVM A4(3) honesty | **DONE** | GLLVM #255 | `81866b1a` | |
| GLLVM A4(3) `_aghq_kd_bound` | **DONE** | GLLVM #256 | `70c2e95f` | CI + Documenter **success** on that SHA (was still `in_progress` in the 13:04 three-hour note) |

Wiring cell is **only** Poisson `(1|g)` GHQ. Phylo Laplace `:555`
(`_fit_poisson_general_laplace`) is **not** this cell.

Source after-task (working copy, not on `origin/main`):
`docs/dev-log/after-task/2026-08-18-three-hour-handover.md`
in `~/local-scratch/lanes/DRM.jl-catchup`.

---

## Classification (rehydrate, then re-check)

A handoff is a dated prior. Re-classify against **today's** `git`/`gh`
before acting.

### DONE — do not redo

The eight merges above. Issues #439, #441, #443, #445 are CLOSED.

### OWED — next lane, after Shinichi names one

| Item | State | Resume |
|---|---|---|
| **AGHQ port (lever 2)** | **OWED**, not started | Only if Shinichi names it. DRM G0, not a GLLVM copy. |
| **Poisson phylo Laplace `:555` punch** | **OWED**, not started | Only if Shinichi names it. Hook: `_fit_poisson_general_laplace` after `_withnll`. |

Until one is named: **STOP**. Do not start both. Do not start a second
Cox–Reid family cell, a second Option A PR, a probe redo, or GLLVM A4(4)/A4(5).

### RETRACTED — do not propagate

| Item | Why |
|---|---|
| Dual-start AGHQ **and** `:555` in one slice | Owner: pick one. |
| Spare wiring writer `0d8a4ca3` | Never started; #444 already opened (`2aad10a7`) before `resource_exhausted`. |
| Cell D as a Laplace bias-sign / recovery headline | Underpowered (16 tips, 12 seeds). Hook-runs-only. |
| “#420/#406 would revert `src/poisson.jl` `_vcov_from_hessian`” | **Corrected 13:12 MDT.** `gh` now shows #420 = `LOOP/checkpoint.md` only; #406 = docs-only. Both `CONFLICTING`. Rebase-before-merge still holds; the poisson-revert claim does not. |

### PROTECTED — do not touch

| Fence | Hold |
|---|---|
| No AGHQ as a DRM G0 until **named** | Lever 2 is OWED, not armed. |
| No q4 / `reml_q4.jl` | Verified engine. |
| D-111 Julia General | **OFF** |
| #49 missing-data | **PARKED** (GitHub state is OPEN + `enhancement`/`idea`; process status is PARKED) |
| ML default | `:REML` stays opt-in |
| Twin = drmTMB | Never headline GLLVM Λ / loading-matrix numbers as DRM recovery |
| No steal dirty PRs | #420, #406, foreign unpushed branches |
| GLLVM honesty worktree | `~/local-scratch/lanes/GLLVM.jl-a43-honesty-20260818` — **never mutate** overnight `LOOP/GOAL.md` (file exists at `LOOP/GOAL.md`) |
| GPL→MIT | Never vendor drmTMB source |
| Cursor Ultra | Ask → Manual → Agent; Composer only for bounded slices |

---

## Current Working State

- **Working:** `origin/main` @ `d04ba994` (#446). GLLVM `origin/main` @
  `70c2e95f` (#256); CI conclusion `success`.
- **In progress:** none that MUST finish.
- **Not working / blocked:** next G0 unnamed. Dropbox leftover
  `docs/a3c-design`. Catchup worktree `docs/arc1-inventory` is **54 behind**
  `origin/main` with ~38 uncommitted evidence files — a **different** lane
  (Arc 1 inventory), not this G0.

---

## Key Decisions & Rationale

- **ML default / REML opt-in** — REML likelihoods are not comparable across
  FE structures (model selection). #444 admits `:REML` only on Poisson
  `(1|g)` GHQ.
- **Cox–Reid is a wiring job, not a derivation** — reuse
  `_glsp_reml_penalty` + `_glsp_reml_refit_clean` + `_withreml`. See probe.
- **#256 `gh pr merge --auto` landed while four-cell CI was still
  `in_progress`** because `main` is unprotected. Helper was not rewritten.
  Comment on GLLVM #256 records this. **Do not re-merge.**
- **#444 docs-first red** was a `gh-pages` preview-deploy race with #446, not
  a wiring defect. Documenter rerun went green; then merge `2dcc5508`.
- **D-87 / D-88** — overlap is Shinichi's call. This handover names lanes; it
  does not claim them.

---

## Landing State

`handoff_gate.sh` on Dropbox `docs/a3c-design` and on catchup
`docs/arc1-inventory` both **FAIL** (uncommitted + many unpushed other
branches). Declared below. Gate does not merge and does not push.

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| DRM.jl `main` `5e392c6e` REML `(1\|g)` | y | y | #440 merged | **LANDED** |
| DRM.jl `main` `e161c165` Cox–Reid probe | y | y | #442 merged | **LANDED** |
| DRM.jl `main` `2dcc5508` Poisson GHQ REML | y | y | #444 merged | **LANDED** |
| DRM.jl `main` `7dcaa41e` A8 | y | y | #423 merged | **LANDED** |
| DRM.jl `main` `d40552ae` A11 | y | y | #428 merged | **LANDED** |
| DRM.jl `main` `d04ba994` Option A | y | y | #446 merged | **LANDED** |
| GLLVM.jl `main` `81866b1a` A4(3) honesty | y | y | #255 merged | **LANDED** |
| GLLVM.jl `main` `70c2e95f` `_aghq_kd_bound` | y | y | #256 merged | **LANDED** (CI success) |
| This doc `handover/2026-08-18-cursor` | y (this branch) | see PR | handover PR | **LANDED** with the handover |
| Dropbox leftover `docs/a3c-design` @ `9203ee0a` | y (old) | y | none | **CARRIED-OVER** leftover. ~114 behind `origin/main`. Do not resume. `?? .codex/agents/shannon-coordinator.toml` — **never stage**. |
| Catchup `docs/arc1-inventory` @ `c36ff3b9` | y (that PR) | y | Arc 1 inventory | **CARRIED-OVER** other lane. 54 behind `origin/main`. ~38 uncommitted `docs/dev-log/evidence/2026-08-16*` / `2026-08-17*` + `2026-08-18-three-hour-handover.md`. Resume only for Arc 1 inventory: `cd ~/local-scratch/lanes/DRM.jl-catchup && git status`. Do not mix this G0 onto that branch. |
| DRM #420 `docs/loop-items-1-4` | y | y | #420 open, **CONFLICTING** | **CARRIED-OVER**. Rebase before merge. File: `LOOP/checkpoint.md` only. Not this G0. Resume: `gh pr view 420 --repo itchyshin/DRM.jl`. |
| DRM #406 `docs/github-auto-merge` | y | y | #406 open, **CONFLICTING** | **CARRIED-OVER**. Docs-only auto-merge policy. Rebase before merge. Not this G0. Resume: `gh pr view 406 --repo itchyshin/DRM.jl`. |
| Unpushed local branches (36+) listed by `handoff_gate.sh` | mixed | n | none / stale | **CARRIED-OVER**. Deliberate WIP / abandoned agent worktrees. Do not steal. Do not `git add -A`. |

**Why catchup uncommitted evidence is not landed:** overnight / morning recon
notes from 2026-08-16–17 sitting on a 54-behind inventory branch. Landing them
here would mix ledgers. Resume command if Shinichi wants them: explicit-path
commit on a **new** docs branch off current `origin/main`, never onto leftover
`docs/a3c-design`.

---

## Files Created / Modified — every PATH

Already on `origin/main` (session diffs; do not re-apply):

**#440 `5e392c6e`:** `src/gaussian_core.jl`, `src/gaussian_ranef.jl`,
`test/test_reml.jl`, `test/test_reml_ordinary_ranef.jl`,
`docs/design/capability-status.md`, `docs/src/capabilities.md`,
`docs/dev-log/after-task/2026-08-17-mean-re-reml.md`,
`docs/dev-log/check-log.d/2026-08-17-mean-re-reml.md`

**#442 `e161c165`:** `LOOP/GOAL.md`, `LOOP/arcs.md`, `LOOP/checkpoint.md`,
`LOOP/ultra-plan.md`, `bench/cox_reid_probe.jl`, `bench/out/cox_reid_probe.txt`,
`docs/dev-log/after-task/2026-08-18-cox-reid-scoping-probe.md`,
`docs/dev-log/check-log.d/2026-08-18-cox-reid-scoping-probe.md`,
`docs/dev-log/evidence/2026-08-18-cox-reid-scoping-probe.md`,
`docs/dev-log/evidence/2026-08-18-hopper-cox-reid-gllvm-fence.md`,
`test/test_cox_reid_characterization.jl`

**#444 `2dcc5508`:** `LOOP/GOAL.md`, `LOOP/arcs.md`, `LOOP/checkpoint.md`,
`docs/dev-log/after-task/2026-08-18-cox-reid-poisson-ranef-wiring.md`,
`docs/dev-log/check-log.d/2026-08-18-cox-reid-poisson-ranef-wiring.md`,
`src/poisson.jl`, `src/variational.jl`,
`test/test_cox_reid_characterization.jl`, `test/test_cox_reid_poisson_ranef.jl`

**#423 `7dcaa41e`:** `src/DRM.jl`, `src/gaussian_bivariate.jl`,
`src/meta_vcov_bivariate.jl`, `test/runtests.jl`,
`test/test_meta_vcov_bivariate.jl`, `docs/make.jl`,
`docs/src/model-guides/meta-analysis.md`,
`docs/src/reference/structured-effect-markers.md`, `docs/src/rosetta.md`,
`docs/dev-log/check-log.d/2026-08-16-a8-biv-meta-vknown.md`,
`docs/dev-log/check-log.d/2026-08-16-a12-biv-meta-recovery.md`,
`docs/dev-log/evidence/2026-08-16-a12-biv-meta-recovery.md`,
`docs/dev-log/evidence/parity-biv-meta.tsv`, `tools/parity_biv_meta.R`,
`tools/parity_ledger.py`, `tools/recovery_biv_meta.jl`,
`tools/sensitivity_biv_meta_cor12.jl`

**#428 `d40552ae`:** `src/mixed_family.jl`, `src/mixed_family_postfit.jl`,
`test/runtests.jl`, `test/test_cross_family_formula.jl`,
`docs/src/cross-family.md`,
`docs/dev-log/check-log.d/2026-08-16-a11-cross-family-formula.md`

**#446 `d04ba994`:** `test/runtests.jl`,
`test/test_parity_biv_q4_phylo_reml.jl`,
`test/test_parity_gaussian_phylo_mean.jl`, `test/test_reml_ordinary_ranef.jl`,
`docs/dev-log/after-task/2026-08-18-option-a-runtests-include.md`,
`docs/dev-log/check-log.d/2026-08-18-option-a-runtests-include.md`

**GLLVM #255 `81866b1a`:** `LOOP/arcs.md`, `LOOP/checkpoint.md`,
`docs/dev-log/after-task/2026-08-18-aghq-a43-honesty.md`,
`docs/dev-log/check-log.md`, `docs/dev-log/decisions/2026-08-18-aghq-a43-gate.md`,
`test/test_aghq_gate.jl`

**GLLVM #256 `70c2e95f`:** `src/families/aghq_grid.jl`, `test/runtests.jl`,
`test/test_aghq_gate.jl`, `test/test_aghq_kd_bound.jl`, `LOOP/*`,
`docs/dev-log/after-task/2026-08-18-aghq-a43-afford.md`,
`docs/dev-log/after-task/2026-08-18-aghq-a43-afford-close.md`,
`docs/dev-log/decisions/2026-08-18-aghq-a43-afford.md`,
`docs/dev-log/decisions/2026-08-18-aghq-a43-gate.md`,
`docs/dev-log/check-log.md`

**This handover:** `docs/dev-log/handover/2026-08-18-cursor-handover.md`
(AGENTS.md has **no** Live Phase Snapshot block — pointer refresh skipped.
Coordination board Active-Lane-Split is stale 2026-08-16; this doc is the
3h-queue closeout pointer. Do not overwrite the board from leftover.)

---

## Next Immediate Steps

Ordered. Execute **only** after rehydrate + classify. Items 2–3 are OWED
and **blocked on Shinichi**.

1. Run `~/shinichi-brain/tools/lane_preflight.sh` on the **fresh** tree
   (not Dropbox leftover). Read `AGENTS.md`, this file, `HANDOVER.md`,
   `docs/dev-log/coordination-board.md` (stale split — do not treat as
   today's G0). Reconcile SHAs with `gh` / `git log origin/main`.
2. **Ask Shinichi to name exactly one G0:**
   - **A.** AGHQ port (lever 2), or
   - **B.** Poisson phylo Laplace Cox–Reid punch
     (`_fit_poisson_general_laplace` / probe `:555`).
3. After a name: one issue → one branch → one PR. Work in a **new**
   scratch worktree off `origin/main`. Cursor Ultra: Ask → Manual → Agent;
   Composer only for a bounded slice.
4. Until named: **STOP**. Do not start AGHQ, `:555`, A4(4), A4(5), a
   second family cell, or a probe redo.

---

## Blockers / Open Questions

- **Which G0?** Shinichi. Not this document's to resolve (D-87).
- **#420 / #406** are `CONFLICTING` — rebase is a separate docs lane, not
  the next engine G0.
- **Coordination board** still points at
  `docs/dev-log/handover/2026-08-16-cursor-handover.md`. Multi-lane rule:
  do not replace that pointer from leftover; carry both. 2026-08-16 =
  catch-up campaign. **This file** = 3h-queue closeout.
- drmTMB sibling status was **UNKNOWN** on the 2026-08-16 board
  (#1049/#1050 then open). Re-check that repo before touching it. Do not
  start drmTMB work from a DRM.jl tree.

---

## Gotchas & Failed Approaches

- **Line `:555` drifts.** Durable name:
  `_fit_poisson_general_laplace` in `src/sparse_laplace_glmm.jl`.
- **Public `(1|g)` is GHQ-32**, not the Laplace spine
  (`src/poisson.jl`). K=1 crossed Laplace redirects to GHQ.
- **Cell D is not recovery.** Do not headline it.
- **Tree-scale trap:** `ape::vcv(corr=TRUE)` = unit tip variance; raw
  Newick tip variance = height `h`. A clean ~30% phylo VC "bias" is often
  the DGP.
- **`warnonly = true`:** a broken `@ref` fails VitePress/npm, not
  Documenter. Read the failing process.
- **Never `git add -A`.** Never stage
  `.codex/agents/shannon-coordinator.toml`.
- **Do not build `src/` on `docs/a3c-design`.**
- **GLLVM honesty `LOOP/GOAL.md`:** overnight files — do not mutate.
- **Do not steal dirty PRs** or unpushed agent worktrees.

---

## Mission control

| Repo | Branch / state | CI | What shipped | Next by leverage |
|---|---|---|---|---|
| **DRM.jl** | `origin/main` @ `d04ba994` | #444/#446 landed | REML + Cox–Reid GHQ + A8 + A11 + Option A | Shinichi names AGHQ **or** `:555` |
| **DRM.jl** | #420, #406 open | both `CONFLICTING` | leftover docs | rebase in a **docs** lane, not this G0 |
| **DRM.jl** | Dropbox `docs/a3c-design` | leftover | 4 local commits / 114 behind | abandon for engine work |
| **GLLVM.jl** | `origin/main` @ `70c2e95f` | CI + Documenter **success** | A4(3) honesty + `k^d` bound | no A4(4)/A4(5); do not mutate honesty `LOOP/GOAL.md` |

---

## How to Resume (Cursor)

**Working directory:** a **new** worktree or checkout of `origin/main`
(or `handover/2026-08-18-cursor` until this PR merges). Do **not** use
`/Users/z3437171/Dropbox/Github Local/DRM.jl` while it stays on
`docs/a3c-design`. Catchup
(`~/local-scratch/lanes/DRM.jl-catchup`) holds a working copy of this
file and the three-hour after-task; it is **not** the engine tree
(branch `docs/arc1-inventory`, 54 behind).

**Toolchain:** Julia via `juliaup` (`export PATH="$HOME/.juliaup/bin:$PATH"`).
Safe verify (docs-only / read): `git log -1 --oneline origin/main` and
`gh pr view 446 --repo itchyshin/DRM.jl`. Do not run a full `Pkg.test()`
until a named G0 needs it.

**Never stage:** `.codex/agents/shannon-coordinator.toml`; catchup
`docs/dev-log/evidence/2026-08-16*` / `2026-08-17*` unless Shinichi
opens that inventory lane; any foreign worktree files.

**Rehydration recipe (TARGET=cursor):**

1. `~/shinichi-brain/tools/lane_preflight.sh` on the fresh tree.
2. Read `AGENTS.md`, this handover, `HANDOVER.md`.
3. `git fetch origin && git log -12 --oneline origin/main` and
   `gh pr list --repo itchyshin/DRM.jl --state open`.
4. Classify every item **OWED / DONE / RETRACTED / PROTECTED**.
5. Continue **only** the OWED Next Immediate Steps (name the G0, or STOP).

**One-command paste** (human starts a fresh Cursor agent in the repo):

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-18-cursor-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```

`PLATFORM: cursor | ON BRANCH: handover/2026-08-18-cursor | LANE: 3h-queue-handover`
`OTHER LANES: docs/#420 #406 (CONFLICTING) · catchup docs/arc1-inventory · leftover docs/a3c-design · merged cursor+#446 · merged claude/lane-cox-reid-wire`
