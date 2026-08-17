# Shannon — Arc 1 inventory vs open PRs (2026-08-16)

**Lane:** Cursor Shannon, **read-only**. No impl. No commit. No nested subagents.
**Preflight:** `bash ~/shinichi-brain/tools/lane_preflight.sh "/Users/z3437171/Dropbox/Github Local/DRM.jl"` (this pass).
**PR census:** `gh pr list --repo itchyshin/DRM.jl --state open --json number,title,mergeStateStatus,autoMergeRequest,headRefName` (this pass).
**Board:** `docs/dev-log/coordination-board.md` is **committed to `origin/main`** (reaches other lanes).

---

## Verdict

**FOREIGN LANE ACTIVE (direct-to-main) · 9 lanes live.** Inventory may run in parallel **only as new evidence files**. Do not steal another lane’s files. Overlap is Shinichi’s call (D-87). Silence is not sole-ownership proof (D-88).

**Inventory is docs-only: CONFIRMED.** Arc 1 *this slice* = read the 11 `claim_status != supported` rows and write a backlog note. Not `src/`. Not `test/`. Not `LOOP/checkpoint.md`. Not the coordination board. Not a TSV `supported` flip. Not drmTMB checkout. Not Arc 1′ (REML-RE / natgrad / VA / AGHQ / #49). Implementation one-issue PRs are a *later* owner G0.

---

## Must-avoid PRs (do not mix / rebase / edit their files)

| PR | Branch | merge / auto-merge | Why inventory must not touch it |
|---|---|---|---|
| **#428** A11 | `feat/a11-cross-family-formula` | BEHIND · **unarmed** | Owns `cross_family_latent` + `src/mixed_family*.jl` + `docs/src/cross-family.md` + `test/runtests.jl` + `LOOP/checkpoint.md`. |
| **#423** A8 | `feat/a8-biv-meta-vknown` | BEHIND · armed | Owns `src/DRM.jl`, `tools/parity_ledger.py`, `LOOP/checkpoint.md`, meta/rosetta/markers docs. `test (1)` red on 1.12. |
| **#429** A12 | `feat/a12-biv-meta-recovery` | CLEAN · unarmed | Stacked on **#423**. `LOOP/checkpoint.md` + meta-analysis docs. Do not rebase. |
| **#425** A10 | `fix/a10-boundary-polish` | BEHIND · armed | Owns `src/binomial.jl`, `src/sparse_laplace_glmm.jl`, `test/runtests.jl`. Adjacent to binomial / structured-marker rows. |
| **#420** | `docs/loop-items-1-4` | BEHIND · armed | `LOOP/checkpoint.md` only — 4-way race with #423/#428/#429. |
| **#406** | `docs/github-auto-merge` | **DIRTY** · armed | Owns `docs/dev-log/coordination-board.md`. Do not append a board row. |
| **#421** | `fix/rosetta-corpair` | BEHIND · armed | Soft unless inventory edits `docs/src/rosetta.md` (also on #423). |

Also do not build on: leftover Dropbox `docs/a3c-design` (this preflight checkout; 57 behind `origin/main`; never-stage `.codex/agents/shannon-coordinator.toml`); leftover scratch `docs/arc0-after-task` (ahead 1 / behind 4); `main-direct` (6 non-merge commits to `main` in 12h). `#426` is gone from the open list.

---

## Safe parallel (inventory only)

Write **new** files under `docs/dev-log/evidence/2026-08-16-arc1-*.md` (this note’s siblings). Read `git show origin/main:…` / `parity_ledger.py` read-only. Do not refresh `LOOP/`. Do not cut `feat/` branches. Do not add `runtests` includes.

Hottest shared file if someone “helpfully” updates the catch-up kit: **`LOOP/checkpoint.md` (4-way: #420 #423 #428 #429).**

---

## STATE

`PLATFORM: cursor | ON BRANCH: docs/a3c-design (Dropbox leftover; note written in scratch) | LANE: arc1-inventory-collisions (read-only)`

`OTHER LANES: #429 A12 · #428 A11 · #425 A10 · #423 A8 · #421 rosetta · #420 LOOP · #406 board · main-direct · leftover docs/a3c-design · scratch docs/arc0-after-task`
