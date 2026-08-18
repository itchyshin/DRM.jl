# 2026-08-17 — Shannon recon: clean scratch lane for ordinary Gaussian mean-RE REML

**Author:** Shannon (Cursor). Read-only coordination. No implementation.
**Did not claim** any foreign-lane files. This note is the requested map only.
**Did not edit** `docs/dev-log/coordination-board.md`.

---

## 1. Preflight restatement

Ran `~/shinichi-brain/tools/lane_preflight.sh "/Users/z3437171/Dropbox/Github Local/DRM.jl"` (always exits 0).

| Field | Value |
|---|---|
| ME | **cursor** (foreign = claude, codex; a 2nd cursor lane counts too) |
| ON BRANCH (this leftover checkout) | `docs/a3c-design` @ `bcd2c9dc` |
| `origin/main` | `2c8d3377` |
| This checkout vs `origin/main` | **88 behind, 2 ahead** — leftover Dropbox tree. **DO NOT BUILD HERE.** |
| OPEN PRs (live) | **#429** `feat/a12-biv-meta-recovery` · **#428** `feat/a11-cross-family-formula` · **#423** `feat/a8-biv-meta-vknown` · **#420** `docs/loop-items-1-4` · **#406** `docs/github-auto-merge` |
| Local branches active (12h, not already a PR) | `claude/lane-gaussian-phylo-mean` (foreign: claude) · `docs/a3c-design` (you are here) · `claude/lane-arc1-backlog-after-434` (foreign: claude) |
| LANE CENSUS | **10 LANES LIVE** |
| COORD BOARD | `docs/dev-log/coordination-board.md` — **COMMITTED to `origin/main` ✅** (reaches other lanes). Content is **stale** (2026-08-14 idle/catchup tip). Do not treat its Active-Lane-Split table as the live census. |
| VERDICT | **FOREIGN LANE ACTIVE (claude direct-to-main)** — concurrency allowed; bleed-through is not (D-88). |

**Live lanes (preflight + user-locked census; all foreign to the new scratch lane):**

| # | Lane | Where | Note |
|---|---|---|---|
| 1 | #429 A12 | `feat/a12-biv-meta-recovery` | OPEN PR |
| 2 | #428 A11 | `feat/a11-cross-family-formula` | OPEN PR — owns `test/runtests.jl` |
| 3 | #423 A8 | `feat/a8-biv-meta-vknown` | OPEN PR — owns `src/DRM.jl` + `test/runtests.jl` |
| 4 | #420 | `docs/loop-items-1-4` | OPEN PR — `LOOP/checkpoint.md` only |
| 5 | #406 | `docs/github-auto-merge` | OPEN PR — owns the coordination board |
| 6 | `claude/lane-gaussian-phylo-mean` | `~/local-scratch/lanes/DRM.jl-gaussian-phylo-mean` | leftover; dirty `LOOP/*` |
| 7 | `claude/lane-arc1-backlog-after-434` | `~/local-scratch/lanes/DRM.jl-arc1-backlog-after-434` | leftover; dirty `LOOP/checkpoint.md` |
| 8 | `claude/lane-biv-q4-phylo-reml` | `~/local-scratch/lanes/DRM.jl-biv-q4-phylo-reml` | leftover (#434 already merged) |
| 9 | `docs/a3c-design` | **this Dropbox checkout** | 88 behind `origin/main`; **DO NOT BUILD HERE** |
| 10 | `DRM.jl-catchup` | `~/local-scratch/lanes/DRM.jl-catchup` on `docs/arc1-inventory` | leftover; many untracked evidence files |

Preflight also counted **main-direct** (6 non-merge commits to `main` in 12h). Authorship proves nothing. Do not commit to `main` from this session.

**Channel check:** `git cat-file -e origin/main:docs/dev-log/coordination-board.md` succeeds. Board reaches other lanes. It is stale, not missing.

**User lock (this G0):** NEW scratch lane — not catchup, not a3c-design, not biv-q4 / gaussian-phylo leftovers. Start NOW; do not wait for #423+#428. **Do not edit `test/runtests.jl` this PR.** Cut from `origin/main`.

---

## 2. Files this new lane MUST NOT touch (foreign)

Do not edit these paths in any checkout, including the new worktree's eventual PR, while the owning lane is live. Overlap is Shinichi's call (D-87), not Ada's to resolve.

**User-locked this PR**

- `test/runtests.jl` — also owned by #428 and #423. Standalone test file only.

**#429 A12**

- `LOOP/checkpoint.md`
- `docs/dev-log/check-log.d/2026-08-16-a12-biv-meta-recovery.md`
- `docs/dev-log/evidence/2026-08-16-a12-biv-meta-recovery.md`
- `docs/src/model-guides/meta-analysis.md`
- `tools/recovery_biv_meta.jl`
- `tools/sensitivity_biv_meta_cor12.jl`

**#428 A11**

- `LOOP/checkpoint.md`
- `docs/dev-log/check-log.d/2026-08-16-a11-cross-family-formula.md`
- `docs/src/cross-family.md`
- `src/mixed_family.jl`
- `src/mixed_family_postfit.jl`
- `test/runtests.jl`
- `test/test_cross_family_formula.jl`

**#423 A8**

- `LOOP/checkpoint.md`
- `docs/dev-log/check-log.d/2026-08-16-a8-biv-meta-vknown.md`
- `docs/dev-log/evidence/parity-biv-meta.tsv`
- `docs/make.jl`
- `docs/src/model-guides/meta-analysis.md`
- `docs/src/reference/structured-effect-markers.md`
- `docs/src/rosetta.md`
- `src/DRM.jl` — shared include/export contract
- `src/gaussian_bivariate.jl`
- `src/meta_vcov_bivariate.jl`
- `test/runtests.jl`
- `test/test_meta_vcov_bivariate.jl`
- `tools/parity_biv_meta.R`
- `tools/parity_ledger.py`

**#420**

- `LOOP/checkpoint.md`

**#406**

- `docs/dev-log/check-log.d/2026-08-13-github-auto-merge.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/decisions/2026-08-13-github-auto-merge.md`

**Leftover scratch / this Dropbox tree**

- `LOOP/GOAL.md`, `LOOP/arcs.md`, `LOOP/checkpoint.md`, `LOOP/ultra-plan.md` on `claude/lane-gaussian-phylo-mean` and `claude/lane-arc1-backlog-after-434` (dirty there).
- Entire `docs/a3c-design` leftover tree — **do not build; do not stage its dirty files into the new lane.**
- Untracked catchup evidence under `~/local-scratch/lanes/DRM.jl-catchup/docs/dev-log/evidence/2026-08-16-*` and `2026-08-17-*` (except this recon note, which lives only in the Dropbox leftover until copied).
- `claude/lane-biv-q4-phylo-reml` leftover — do not resume.

**Shared contracts (coordinate; do not silently append)**

- `src/DRM.jl` — #423 owns this PR cycle. If an export is required, surface to Shinichi; do not race #423.
- `AGENTS.md` / `CLAUDE.md` / `ROADMAP.md` — maintainer sign-off.
- `LOOP/checkpoint.md` — collision magnet across #429/#428/#423/#420 plus two leftover Claude trees. `lane_launch.sh` will write a **local** `LOOP/` kit in the new worktree; keep that kit local. **Do not put `LOOP/checkpoint.md` in the PR** while those PRs are open.

**Clean claim for this G0 (not in the foreign PR file lists):** `src/gaussian_core.jl`, `src/gaussian_ranef.jl`, new `test/test_reml_ordinary_ranef.jl`, plus a uniquely named check-log / after-task. Do not regress FE REML, σ-phylo REML, or q4 REML.

---

## 3. Proposed lane name + worktree path

`lane_launch.sh` names the branch `claude/lane-<name>` and the dest `$HOME/local-scratch/lanes/DRM.jl-<name>`, base default `origin/main`. No existing branch or scratch dir collides with `mean-re-reml`.

```text
~/shinichi-brain/tools/lane_launch.sh "/Users/z3437171/Dropbox/Github Local/DRM.jl" mean-re-reml --base origin/main
```

| | |
|---|---|
| **Lane name** | `mean-re-reml` |
| **Branch** (script) | `claude/lane-mean-re-reml` |
| **Worktree** | `~/local-scratch/lanes/DRM.jl-mean-re-reml` |
| **Base** | `origin/main` (`2c8d3377` at recon time) |

Do **not** launch from, or rebase onto, `docs/a3c-design`. Do **not** reuse `DRM.jl-catchup`, `DRM.jl-gaussian-phylo-mean`, or `DRM.jl-biv-q4-phylo-reml`.

---

## 4. Existing issue or "need new issue"

`gh issue list` / search (2026-08-17): **no ordinary Gaussian mean-RE / iid `(1 \| g)` REML ticket.**

| Issue | State | Why it is not this G0 |
|---|---|---|
| **#11** | CLOSED | FE / `reml_q4.jl` public-API wire. Mean-axis bias-correction verified; this is not ordinary RE REML. **Do not reopen as the closer.** |
| **#136** | CLOSED (2026-08-17 13:45Z) | VA epic. Board still says OPEN (stale). **Do not write `closes #136`.** |
| **#49** | OPEN | **PARKED** — FIML / missing data. Do not touch. |
| **#327** | OPEN | Idea: matrix-free / Hutchinson REML for huge n. Not ordinary `(1 \| g)`. |
| **#291** | CLOSED | REML *speed* track (AI-REML / q4). Not this hole. |
| **#433** | CLOSED | `biv_q4_phylo_reml` fixture. Different lane. |

**Verdict: need new issue.** Open it and **commit the number** (read-then-append is a race). Do not close #136. Do not close #49.

---

## 5. Dirty prior-session files (leave them)

This Dropbox leftover (`docs/a3c-design`) is a **prior session**. Do not stage these into the new lane.

| Status | Path |
|---|---|
| `M` | `docs/dev-log/after-task/2026-08-17-overnight-handover.md` |
| `??` | `.codex/agents/shannon-coordinator.toml` |
| `??` | `docs/dev-log/after-task/2026-08-17-recommended-next-g0.md` |
| `??` | `docs/dev-log/evidence/2026-08-17-what-else.md` |

This recon note (`docs/dev-log/evidence/2026-08-17-recon-shannon-lanes.md`) is also untracked **here**. Ada may *read* it from this path. Do not `git add` it (or the four rows above) onto `claude/lane-mean-re-reml`. The new worktree is cut from `origin/main` and will not contain them.

---

## 6. One-line STATE THIS LINE for the GOAL block

`PLATFORM: cursor | LANE: mean-re-reml | FOREIGN LANE: claude+#429+#428+#423+#420+#406+phylo-mean+arc1+biv-q4+a3c+catchup`
