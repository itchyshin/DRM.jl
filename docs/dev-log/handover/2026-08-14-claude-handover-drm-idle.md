# Session Handoff: IDLE pending owner G0 — Claude pickup

Meta: 2026-08-14 · from **Cursor** (Shannon) · TARGET **claude** · AUTHOR **cursor**

You are **Claude Code**, picking up **DRM.jl** with **no chat context**.
Rehydrate from this repository + current git state. Classify every item
**`OWED` · `DONE` · `RETRACTED` · `PROTECTED`**; execute only `OWED`.

**Lane fence:** this is a **Julia DRM.jl** lane. Tip is **IDLE** pending an
**owner-named G0**. Do **not** invent a ship G0. Do **not** start drmTMB from
this tree. Do **not** start two-part / ZI×RE, **#49**, or any other open issue
until the owner names it in *this* chat. After rehydrate, **stop and ask the
owner for the next G0**.

**Supersedes as DRM.jl START HERE:**
[`2026-08-13-cursor-handover-drm-idle-after-404.md`](2026-08-13-cursor-handover-drm-idle-after-404.md)
(Cursor idle pointer after #404; #405 later merged). That note remains
**historical** — keep the file. Do not treat it as the live DRM pointer.

2026-08-09 Julia-lane and morning drmTMB-handoff notes stay historical too:
[`2026-08-09-cursor-handover-drm-julia-lane.md`](2026-08-09-cursor-handover-drm-julia-lane.md),
[`2026-08-09-cursor-handover.md`](2026-08-09-cursor-handover.md).

**Multi-lane — never skip:** a single snapshot pointer must not orphan the
sibling. Active-Lane-Split lives on
[`docs/dev-log/coordination-board.md`](../coordination-board.md). This file is
the DRM.jl Julia pointer only. **drmTMB may still be in progress** — unknown
from this DRM.jl session; do **not** claim that sibling lane is finished.

`AGENTS.md` has no Live Phase Snapshot block. Rehydrate via the coordination
board split + this START HERE (and `LOOP/checkpoint.md` after this docs PR).

## Critical Context

1. **`origin/main` tip @ `d0fac9d7`** —
   `d0fac9d7a0cfc9736ad8caa09f01ce53267d5441` = Merge [#405](https://github.com/itchyshin/DRM.jl/pull/405)
   (`docs/tip-idle-after-404`). Confirmed `git fetch origin main` +
   `git rev-parse origin/main`. This docs branch was cut from that tip.
2. **#405 already MERGED** (2026-08-14T00:02:52Z). Tip-idle Cursor START HERE
   is on main. #404 (136e public Gamma RI report) is also on main under that.
3. **Issue 136 stays OPEN.** Confirm with
   `gh issue view 136 --repo itchyshin/DRM.jl`. The VA epic continues
   (two-part / ZI×RE still later). **Do not put close/fix/resolve words next
   to issue 136** in any new PR body.
4. **#406 is OPEN, not merged.** [`PR #406`](https://github.com/itchyshin/DRM.jl/pull/406)
   records the GitHub auto-merge policy. Auto-merge is **enabled** on that PR
   (`allow_auto_merge` true) but `mergeStateStatus` was **BLOCKED** at handoff
   write because required check `test (1.10)` **FAILED** (docs + `test (1)`
   passed). Do **not** treat #406 as landed. Do **not** invent a ship G0 from
   it. The durable decision file
   `docs/dev-log/decisions/2026-08-13-github-auto-merge.md` lives on that
   branch until it merges.
5. **No named ship G0.** Credible *candidates* only (owner picks; do not
   autoload): later #136 two-part/ZI×RE (**not public**); #49 FIML **PARKED**;
   drmTMB `engine="julia"` (other repo); stay idle. **Do not invent G0 from
   ROADMAP.**
6. **D-111 OFF.** Leave **`.worktrees/`** alone. No q=4 core rewrite. No GPL
   vendoring. No Registrator / Julia General. Never stage
   `.codex/agents/shannon-coordinator.toml`.

## Goals / mission

DRM.jl is the MIT Julia twin of drmTMB: API/capability parity, Julia speed
edge only where independently evidenced. Bridge direction **R → Julia**
(`drmTMB(..., engine = "julia")`); never vendor GPL drmTMB source. ML default;
REML optional. Lovelace Phase 1.5 / #5 already CLOSED (experimental bar) —
do not rebuild. 136e-as-scoped (public Gamma `(1 | g)` report) **landed** in
#404 — do not re-run that smoke as the next G0 unless the owner asks.

This lane’s mission after this hygiene PR is **desk-ready Julia work after
the owner names G0** — not to invent the next ship slice, and not to start
drmTMB from this tree. Next pickup is **Claude**.

## Plans / roadmap

Beyond this tip-idle hygiene: owner names the **next DRM.jl G0**, then a
fresh `/ultra-plan` → `/goal` (or equivalent) in this Julia lane. Do not
invent from `ROADMAP.md` milestone umbrellas (#8 / #9). Deferred menu that
must stay visible (not dropped by narrowing to “this arc”):

- Later **#136** two-part / ZI×RE / phylo / crossed public VA — epic **OPEN**
  (not a public next slice unless the owner names it)
- **#49** FIML / EM missing data — **PARKED**
- Sibling **drmTMB** `engine = "julia"` Workflow G — other repo; status unknown
- D-111 / Julia General — OFF
- **#406** auto-merge policy note — OPEN / BLOCKED on CI `test (1.10)`; not a G0

136e public-path report is **DONE** (on main via #404), not parked.

## What Was Accomplished

- Verified tip: `git fetch origin main`; `origin/main` = **`d0fac9d7`** (Merge #405).
- Confirmed **issue 136 OPEN**; open PRs = #406 only (policy note, BLOCKED).
- `handoff_gate.sh` **GATE FAIL** on stale local unpushed *other* branches
  plus untracked `.codex/agents/shannon-coordinator.toml` (declared
  CARRIED-OVER below; not this tip).
- This docs PR: Claude START HERE while tip is idle + LOOP pointer +
  coordination-board Active-Lane-Split (next pickup Claude; Cursor
  idle/handing off). 2026-08-13 Cursor idle note kept (historical banner).
- No `src/` edits. No drmTMB edits from this tree. Did not invent a ship G0.

## Current Working State

- **Working:** `origin/main` @ **`d0fac9d7`** (Merge #405). Tip **IDLE**
  pending owner G0. Julia lane pointer = this file (Claude). drmTMB = sibling
  (possibly active).
- **In progress:** this docs Claude-handover kit only.
- **Not working / blocked:** no DRM implementation blocker. Material condition
  for ship work = **owner-named G0**. #49 parked by policy. Later #136 slices
  not named. #406 blocked on CI `test (1.10)` — not this slice.
- **Evidence:** `report/va-vs-laplace-bias.md`;
  `docs/dev-log/after-task/2026-08-09-136e-va-bias.md`;
  `docs/dev-log/after-task/2026-08-13-tip-idle-after-404.md`; this after-task
  `docs/dev-log/after-task/2026-08-14-claude-handover-idle.md`.

## Key Decisions & Rationale

| Decision | Rationale |
|---|---|
| New START HERE file (do not overwrite 2026-08-13 Cursor idle note) | That note is the post-#404 Cursor pointer; overwriting would erase the chain. Banner it historical. |
| TARGET = claude · AUTHOR = cursor | Owner asked for a Claude Code pickup. Cursor lane idle/handing off. |
| DRM.jl = IDLE pending owner G0 | #405 merged; no next ship G0 named. LOOP must not still say “wait for merge #405”. |
| 136e-as-scoped = DONE | Public Gamma RI report is on main. Do not re-open that slice. |
| Issue 136 stays OPEN | Epic continues; GitHub auto-close trap documented. |
| #49 PARKED | Explicit owner fence. |
| drmTMB = sibling, status unknown | Do not claim finished; do not start from this tree. |
| Auto-merge policy A is ON | `allow_auto_merge` true. Agents may `gh pr merge N --auto --merge`. Still pause for `src/` engine / formula / version / `AGENTS.md` / `CLAUDE.md` / unfinished epic / foreign lane. Closer-keyword trap: never put close/fix/resolve next to #136 unless finishing the epic. Durable decision file is on #406 until that PR lands. |
| #406 = CARRIED-OVER, not a G0 | OPEN + BLOCKED on `test (1.10)`. Do not resume as ship work. |
| D-111 OFF · `.worktrees/` untouched · no q=4 · no GPL | Standing PROTECTED. |

## Landing State

`~/shinichi-brain/tools/handoff_gate.sh` on DRM.jl **GATE FAIL** — 1 uncommitted
untracked file on the authoring checkout + 26 unpushed commits on *other* local
branches. Every failure declared:

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| `origin/main` `d0fac9d7` | y | y | #405 MERGED | **LANDED** |
| #397–#404 + 136e report + tip-idle #405 | y | y | MERGED | **LANDED** |
| `docs/tip-idle-after-404` | y | y | #405 MERGED | **LANDED** — do not resume |
| `docs/claude-handover-idle` (this handover) | y | y | this PR | **LANDED** (artifact) once pushed |
| `docs/github-auto-merge` | y | y | [#406](https://github.com/itchyshin/DRM.jl/pull/406) OPEN / BLOCKED (`test (1.10)` FAIL) | **CARRIED-OVER** — policy note, not a G0. Resume: do not checkout unless the owner names it; wait for CI or owner. |
| 2026-08-13 Cursor idle START HERE | y | y | #405 MERGED | **LANDED** — now **historical** |
| Stale local unpushed (26 commits / many old branches: `chore/worktree-house-rule`, `shannon/va-frontend`, `codex/local-qgate-fd-gradient`, `docs/rose-registry-claim-audit`, …) | mixed | n | none for this handoff | **CARRIED-OVER** — ignore unless owner names a branch. Resume: **do not checkout**. |
| `?? .codex/agents/shannon-coordinator.toml` | n | n | none | **CARRIED-OVER** — never stage; not this lane |
| `?? .worktrees/` (gitignored) | n | n | none | **CARRIED-OVER** / **PROTECTED** |
| drmTMB sibling working tree / PRs | n/a | n/a | unknown | **CARRIED-OVER** — other repo; do not inspect-as-done from here |

## OWED / classification

| Item | State |
|---|---|
| Merge #405 / confirm tip `d0fac9d7` | **DONE** (at write time) |
| Confirm issue 136 stays OPEN | **DONE** |
| Write Claude START HERE while tip is idle (not overwrite 2026-08-13 Cursor note) | **DONE** (this PR) |
| Point LOOP at this Claude handover; Cursor lane idle/handing off | **DONE** (this PR) |
| Refresh Active-Lane-Split without orphaning drmTMB | **DONE** (this PR) |
| Invent DRM ship G0 from ROADMAP / chat | **RETRACTED** |
| Start later #136 two-part/ZI×RE / Rung 4 / #49 | **RETRACTED** unless owner names them |
| Re-run 136e public Gamma smoke as the next G0 | **RETRACTED** unless owner asks |
| Start drmTMB from this DRM.jl tree | **RETRACTED** |
| Claim drmTMB sibling lane finished | **RETRACTED** |
| Rebuild Phase 1.5 / Lovelace #5 | **RETRACTED** |
| Flip VA Experimental → Implemented | **RETRACTED** |
| Treat #406 as the next ship G0 / merge it from this lane | **RETRACTED** |
| Stage/clean `.worktrees/` or `.codex/agents/shannon-coordinator.toml` | **PROTECTED** |
| Registrator / Julia General | **PROTECTED** — D-111 OFF |
| q=4 core / unapproved `src/` / claim inflation / GPL vendoring | **PROTECTED** |
| Rehydrate + confirm idle-or-named-work + **STOP and ask owner for next G0** | **OWED** (next Claude chat) |

## Next Immediate Steps

1. **OWED — rehydrate only.** `"$HOME/shinichi-brain/tools/lane_preflight.sh" "/Users/z3437171/Dropbox/Github Local/DRM.jl"`
   then `git fetch origin && git status -sb && git log --oneline -8 origin/main`.
   Confirm tip **≥ `d0fac9d7`** (#405 MERGED, or this docs PR merged on top).
   `gh issue view 136 --repo itchyshin/DRM.jl` → **OPEN**. `gh pr list --state open`.
   Read `AGENTS.md` → `HANDOVER.md` → `docs/dev-log/coordination-board.md`
   (every Active-Lane-Split row) → this handover. Classify vs git.
2. **OWED — confirm idle-or-named-work.** If the owner already named a G0 in
   *this* new Claude chat, that supersedes the idle default. If not, DRM.jl
   remains IDLE.
3. **OWED — stop and ask.** Ask the owner for the **next G0**. Do not start
   later #136 slices, #49, result-shape, or drmTMB until they name it.
   **Do not invent G0. Do not start drmTMB from this tree.**
4. **RETRACTED / PROTECTED:** inventing G0; drmTMB from this tree; `.worktrees/`;
   D-111; q=4; GPL; claim inflation; declaring the drmTMB sibling finished;
   flipping Experimental → Implemented; auto-closing issue 136; treating #406
   as ship work.

## Auto-merge policy (DRM.jl)

`allow_auto_merge` is **true**. After opening a docs/hygiene PR, agents may:

```sh
gh pr merge N --auto --merge
```

Use `--merge` (merge commit), not squash. Still **pause** (no `--auto`) when
the PR touches `src/` engine, formula grammar, a version bump, `AGENTS.md` /
`CLAUDE.md`, an unfinished epic, or a foreign lane.

**Closer-keyword trap:** never put `close` / `fix` / `resolve` next to `#136`
unless the slice is finishing that epic. Say “Related to issue 136. The VA
epic stays OPEN.” GitHub auto-closed issue 136 on #404 from “does not close”
wording; it was reopened.

Required checks on `main`: `test (1.10)`, `test (1)`, `docs`. D-111 Julia
General still OFF. The durable settings note is on OPEN #406 until that PR
lands; this paragraph is the live text if that file is not yet on `main`.

## Blockers / Open Questions

No DRM implementation blocker. **Open question (owner):** which Julia G0
next? Candidates (not a queue): later #136 two-part/ZI×RE (not public);
#49 FIML later; drmTMB `engine="julia"` in that repo; stay idle.

Sibling drmTMB status is **unknown here** — ask the owner or read that repo’s
own handover if coordination requires it; do not guess.

#406 CI `test (1.10)` FAILURE is a **policy-PR residual**, not a ship blocker.

## Gotchas & Failed Approaches

- 2026-08-13 Cursor idle START HERE still says tip `733ae972` / wait-for-#405
  in places — **historical** after this PR. Tip is now `d0fac9d7` (+ this
  docs PR when merged).
- LOOP files on `origin/main` after #405 still said “wait for owner merge
  #405” — **that is why this PR exists**. After this PR, do not treat the
  old #405 GOAL as current.
- GitHub will auto-close issue 136 if a PR body uses close/fix/resolve words
  near that number — even “does not close”. Never `Closes #`.
- Do **not** start drmTMB from this tree “to be helpful.”
- Full `Pkg.test()` on tip is ~40–56 min (CI). Do not claim subset = CI.
- ELBO ≠ logLik; VA Experimental ≠ “implemented everywhere”; 136e smoke is
  public Gamma RI only, not ZINB / two-part.
- `handoff_gate.sh` will keep FAIL-ing on stale local branches — declare, don’t
  delete or force-push them.
- #406 has auto-merge ON but is BLOCKED on `test (1.10)`. Do not “helpfully”
  rebase or invent a fix unless the owner names that as G0.
- Claude is not auto-launched from the authoring Cursor session.

## Files Created / Modified

- `docs/dev-log/handover/2026-08-14-claude-handover-drm-idle.md` (this)
- `docs/dev-log/handover/2026-08-13-cursor-handover-drm-idle-after-404.md` (historical banner only)
- `docs/dev-log/coordination-board.md` (tip + Active-Lane-Split; next pickup Claude)
- `LOOP/GOAL.md`, `LOOP/arcs.md`, `LOOP/checkpoint.md`, `LOOP/ultra-plan.md`
- `docs/dev-log/check-log.d/2026-08-14-claude-handover-idle.md`
- `docs/dev-log/after-task/2026-08-14-claude-handover-idle.md`
- `docs/dev-log/plan-actual/2026-08-14-claude-handover-idle.md`

No `src/`. 136e ship already on `main` via #404. Tip-idle Cursor kit already
on `main` via #405.

## How to Resume (Claude)

Working directory:

```bash
cd "/Users/z3437171/Dropbox/Github Local/DRM.jl"
export PATH="$HOME/.juliaup/bin:$PATH"
```

1. `"$HOME/shinichi-brain/tools/lane_preflight.sh" "/Users/z3437171/Dropbox/Github Local/DRM.jl"`
2. `git fetch origin && git status -sb && git log --oneline -8 origin/main`
3. Confirm tip **≥ `d0fac9d7`** (Merge #405, or newer docs-PR merge) and
   `gh issue view 136 --repo itchyshin/DRM.jl` → **OPEN**.
4. Read `AGENTS.md` → `HANDOVER.md` → `docs/dev-log/coordination-board.md` →
   this handover. Reconcile with git; classify; execute only **OWED**.
5. **Stop.** Ask the owner for the next Julia G0. Do not start drmTMB here.

**Files not to stage:** `.worktrees/`, `.codex/agents/shannon-coordinator.toml`,
`intake/`, secrets, any path under foreign worktrees. Never `git add -A`.

**Safe verify (only after owner names a G0 that changes code):**

```bash
# Full suite (CI truth; ~40–56 min):
julia --project=. --startup-file=no -e 'using Pkg; Pkg.instantiate(); Pkg.test()'

# Optional: DRM_PARITY_TESTS=1
```

### Mission control

| Repo | Tip / pointer | State |
|---|---|---|
| DRM.jl | `origin/main` `d0fac9d7` + this docs PR | **IDLE** Julia lane — next pickup **Claude**; pending owner G0 |
| drmTMB (R) | sibling repo / its own handover | **possibly in progress** — unknown here; do not claim finished |
| #136 epic | OPEN | 136e public Gamma report **DONE**; two-part/ZI×RE later |
| #49 | parked menu | **PARKED** until named |
| #406 | OPEN / BLOCKED | auto-merge policy note; not a G0 |

### One-command resume

Interactive (human steers a fresh Claude Code session in this repo):

```text
claude "Rehydrate from docs/dev-log/handover/2026-08-14-claude-handover-drm-idle.md + the AGENTS.md snapshot, then continue with the Next Immediate Steps."
```

Paste-ready prompt for a fresh Claude session:

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-14-claude-handover-drm-idle.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```

*Shannon · Ada · Rose. No nested subagents. Claude is not auto-launched.*
