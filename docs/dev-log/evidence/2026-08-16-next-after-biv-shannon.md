# Shannon — lane-collision map after #434 (`b73d9241`)

**Role:** Shannon (Cursor), read-and-decide. No impl. No checkout of shared drmTMB. No PRs. No `src/` edits. Never stage `.codex/agents/shannon-coordinator.toml`.
**When:** 2026-08-16 (session clock). **Campaign:** 2026-08-14 admit-what-R-fits.
**This checkout:** leftover Dropbox `docs/a3c-design` @ `34d96402` — **not claimed.**
**No nested Task subagents.**

Commands cited (this pass; do not invent):

```
~/shinichi-brain/tools/lane_preflight.sh "/Users/z3437171/Dropbox/Github Local/DRM.jl"
~/shinichi-brain/tools/branch_drift_check.sh "/Users/z3437171/Dropbox/Github Local/DRM.jl"
gh pr list --repo itchyshin/DRM.jl --state open --limit 50 --json number,title,headRefName,baseRefName,files
git worktree list
git -C "/Users/z3437171/Dropbox/Github Local/DRM.jl" log origin/main -8 --oneline
git show origin/main:docs/dev-log/coordination-board.md
git show origin/main:LOOP/GOAL.md
git show origin/main:LOOP/checkpoint.md
git cat-file -e origin/main:docs/dev-log/coordination-board.md   # preflight: COMMITTED ✅
```

---

## 1. Preflight verdict

`lane_preflight.sh` (exit 0, ~114 s):

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
VERDICT         : ** FOREIGN LANE ACTIVE (claude direct-to-main) **
```

Census named 8 then “… and 2 more”: the seven open-PR heads + `main-direct` + leftover `docs/a3c-design` (this tree) + leftover `claude/lane-biv-q4-phylo-reml`.

**Read of that verdict (not a rewrite):** concurrency is allowed; bleed-through is not (D-88). The 7 uncommitted paths on this Dropbox tree are this planning session’s leftover notes (after-task / evidence / never-stage toml) — still a live lane for preflight. `claude/lane-biv-q4-phylo-reml` is **leftover after #434 merged**, not a second implementer. Silence is not sole-ownership proof (D-87).

`branch_drift_check.sh` (exit 3): `docs/a3c-design` vs `origin/main` = **0 ahead, 67 behind**. Do not build here.

`origin/main` tip this pass: `b73d9241` (#434 merged 2026-08-17T00:39:07Z). Log `-8`:

```
b73d9241 Merge pull request #434 from itchyshin/claude/lane-biv-q4-phylo-reml
428ca4c9 loop: STATE done-pending-CI for PR #434
29f35cf5 loop: STOP after unarmed PR #434
6d62b0ca loop: checkpoint PR #434 open and unarmed
0578782b test: add biv_q4_phylo_reml same-target fixture (#433)
8b0aa5e3 lane(biv-q4-phylo-reml): scaffold LOOP/ kit for the fixture G0
2209ecd8 Merge pull request #432 from itchyshin/docs/arc1-inventory
c36ff3b9 docs: land late Arc 1 recon S2 on inventory PR
```

Board on `origin/main` still says catch-up **HANDED OVER** to Cursor and “nine PRs open, #420–#429”; tip cited there is stale `0a4c2dc9`. `#406` owns that file — this map does not edit it.

Ada after-#434 (untracked on catchup only; **not** on `origin/main`): next implement = include `test/test_parity_biv_q4_phylo_reml.jl` in `test/runtests.jl` **after** `#423`+`#425`+`#428`. No remaining fixture-gap row. Fresh G0: **no** for that include; **yes** before any new ledger-row. Arc 0 `@ref` already merged (`#430`/`#431`).

---

## 2. Live PR file ownership

Open PRs this pass (`gh pr list --state open`): **#429 #428 #425 #423 #421 #420 #406** only. `#432` `#431` `#430` `#427` `#426` `#434` are MERGED.

| PR | Branch | base | merge / auto (this `gh pr view`) | Owns |
|---|---|---|---|---|
| **#429** A12 | `feat/a12-biv-meta-recovery` | **#423** | CLEAN · unarmed | `LOOP/checkpoint.md`; `docs/src/model-guides/meta-analysis.md`; `docs/dev-log/check-log.d/2026-08-16-a12-biv-meta-recovery.md`; `docs/dev-log/evidence/2026-08-16-a12-biv-meta-recovery.md`; `tools/recovery_biv_meta.jl`; `tools/sensitivity_biv_meta_cor12.jl` |
| **#428** A11 | `feat/a11-cross-family-formula` | main | **DIRTY / CONFLICTING** · unarmed · CI green | `LOOP/checkpoint.md`; `src/mixed_family.jl`; `src/mixed_family_postfit.jl`; `test/runtests.jl`; `test/test_cross_family_formula.jl`; `docs/src/cross-family.md`; `docs/dev-log/check-log.d/2026-08-16-a11-cross-family-formula.md` |
| **#425** A10 | `fix/a10-boundary-polish` | main | **BLOCKED** · **ARMED** · checks empty/in-flight this pass | `src/binomial.jl`; `src/sparse_laplace_glmm.jl`; `test/runtests.jl`; `test/test_boundary_polish.jl`; `docs/dev-log/evidence/parity-phylo-nongaussian.tsv`; `docs/dev-log/check-log.d/2026-08-16-a10-boundary-polish.md` |
| **#423** A8 | `feat/a8-biv-meta-vknown` | main | **DIRTY / CONFLICTING** · **ARMED** · `test (1)` **FAILURE** | `LOOP/checkpoint.md`; `docs/make.jl`; `docs/src/model-guides/meta-analysis.md`; `docs/src/reference/structured-effect-markers.md`; `docs/src/rosetta.md`; `src/DRM.jl`; `src/gaussian_bivariate.jl`; `src/meta_vcov_bivariate.jl`; `test/runtests.jl`; `test/test_meta_vcov_bivariate.jl`; `tools/parity_biv_meta.R`; `tools/parity_ledger.py`; `docs/dev-log/evidence/parity-biv-meta.tsv`; `docs/dev-log/check-log.d/2026-08-16-a8-biv-meta-vknown.md` |
| **#421** | `fix/rosetta-corpair` | main | BEHIND · **ARMED** · CI green | `docs/src/rosetta.md` only |
| **#420** | `docs/loop-items-1-4` | main | **DIRTY / CONFLICTING** · **ARMED** | `LOOP/checkpoint.md` only |
| **#406** | `docs/github-auto-merge` | main | **DIRTY / CONFLICTING** · **ARMED** · `test (1.10)` **FAILURE** | `docs/dev-log/coordination-board.md`; `docs/dev-log/decisions/2026-08-13-github-auto-merge.md`; `docs/dev-log/check-log.d/2026-08-13-github-auto-merge.md` |

### Hot paths (asked)

| Path | Who owns it now |
|---|---|
| **`test/runtests.jl`** | **#428 + #425 + #423** — collision wait for any include |
| **`LOOP/`** | `#429` `#428` `#423` `#420` all edit `LOOP/checkpoint.md`. `origin/main` LOOP is still the **#434 kit** (`GOAL.md` = feat-biv-q4-phylo-reml-fixture; `checkpoint.md` STATE `done-pending-CI`, NEXT STOP). Do not reuse that kit. |
| **`src/`** | **#428** `mixed_family*`; **#425** `binomial.jl` + `sparse_laplace_glmm.jl`; **#423** `DRM.jl` + `gaussian_bivariate.jl` + `meta_vcov_bivariate.jl`. Treat **all of `src/` as foreign**. |
| **`docs/src/`** | **#429+#423** `model-guides/meta-analysis.md`; **#428** `cross-family.md`; **#423+#421** `rosetta.md`; **#423** `reference/structured-effect-markers.md` |
| **`docs/make.jl`** | **#423** only |

`#429` stays stacked on `#423` — do not rebase by hand (board).

---

## 3. Scratch worktrees

`git worktree list` (relevant rows):

| Path | HEAD | Branch | Verdict |
|---|---|---|---|
| `~/local-scratch/lanes/DRM.jl-catchup` | `c36ff3b9` | `docs/arc1-inventory` | **LEFTOVER.** `merge-base --is-ancestor` of `origin/main` = YES (#432 merged). Dirty: **6 untracked** evidence files **not** on `origin/main` (biv-q4 recon + `2026-08-16-next-arc-ada-advise.md`). Do not reuse; do not `git clean` without Shinichi. |
| `~/local-scratch/lanes/DRM.jl-biv-q4-phylo-reml` | `428ca4c9` | `claude/lane-biv-q4-phylo-reml` | **LEFTOVER.** Ancestor of `origin/main` YES (#434 merge). Working tree **clean**. Still the #434 LOOP kit. Do not reuse. |

**MUST use a NEW scratch lane** from `origin/main` (`b73d9241`). Not catchup. Not biv-q4. Not Dropbox `docs/a3c-design`.

Many stale `.claude/worktrees/` and `.worktrees/` also exist — do not claim them.

---

## 4. Recommended ONE lane

**Name:** `docs/include-biv-q4-runtests`  
**New scratch:** `~/local-scratch/lanes/DRM.jl-include-biv-q4-runtests`  
**Branch from:** `origin/main` (`b73d9241`) — `git checkout -B docs/include-biv-q4-runtests origin/main` **in that new worktree only**.

**Start `/goal`?** **WAIT.** `#423` + `#425` + `#428` all own `test/runtests.jl`. Ada after-#434: this include is the next implement, **not** a new ledger-row; fresh G0 is **no** for the include. There is **no remaining fixture-gap row** after #434. Arc 0 `@ref` already shipped (#430).

If a `/goal` is forced **before** those three merge: there is **no collision-free implement**. The only now-safe work is unique-path docs under `docs/dev-log/{evidence,after-task,check-log.d}/` with new filenames — still a **new** scratch, still not this Dropbox tree. Do not invent a ledger-row G0 (`phylo_gamma_beta_binomial` is smoke-only). Do not flip TSV `supported`. Do not unpark `#49`. `#136` stays OPEN. D-111 OFF. drmTMB `#1049`/`#1050` STOP GATE — never checkout the shared drmTMB tree.

### Files the new lane MUST NOT touch

- **Entire `src/`** (live: `#428` `#425` `#423`; verified engine)
- **`test/runtests.jl`** until `#423` `#425` `#428` have merged (then this lane’s *only* shared edit)
- **`LOOP/`** (`LOOP/checkpoint.md` owned by `#429` `#428` `#423` `#420`; main kit is leftover #434)
- **`docs/make.jl`** (`#423`)
- **`docs/src/model-guides/meta-analysis.md`** (`#429` `#423`)
- **`docs/src/cross-family.md`** (`#428`)
- **`docs/src/rosetta.md`** (`#423` `#421`)
- **`docs/src/reference/structured-effect-markers.md`** (`#423`)
- **`docs/dev-log/coordination-board.md`** (`#406`)
- **`docs/dev-log/evidence/parity-phylo-nongaussian.tsv`** (`#425`)
- **`docs/dev-log/evidence/parity-biv-meta.tsv`** (`#423`)
- **`tools/parity_ledger.py`** (`#423`)
- **`test/parity/runparity.jl`**, `gen_fixtures.R`, `runparity_bridge.jl` (frozen by #434 GOAL)
- leftover branches / worktrees: `docs/a3c-design`, `docs/arc1-inventory`, `claude/lane-biv-q4-phylo-reml`, `~/local-scratch/lanes/DRM.jl-catchup`, `~/local-scratch/lanes/DRM.jl-biv-q4-phylo-reml`
- `.codex/agents/shannon-coordinator.toml` (never stage)
- drmTMB checkout; TSV `claim_status` → `supported`

When the wait clears, the include lane may touch **`test/runtests.jl` plus a new unique check-log / after-task** — nothing else from the list above.

---

`PLATFORM: cursor | ON BRANCH: docs/a3c-design | LANE: shannon-collision-map-after-434`  
`OTHER LANES: 7 open PRs (#429 #428 #425 #423 #421 #420 #406) + leftover claude/lane-biv-q4-phylo-reml + leftover docs/a3c-design + main-direct`
