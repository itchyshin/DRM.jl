# Session Handoff: IDLE pending owner G0 after #404

Meta: 2026-08-13 · from **Cursor** (Shannon) · TARGET **Cursor** · AUTHOR **cursor**

You are **Cursor**, picking up **DRM.jl** with **no chat context**. Rehydrate
from this repository + current git state. Classify every item
**`OWED` · `DONE` · `RETRACTED` · `PROTECTED`**; execute only `OWED`.

**Lane fence:** this is a **Julia DRM.jl** lane. Tip is **IDLE** pending an
**owner-named G0**. Do **not** invent a ship G0. Do **not** start drmTMB from
this tree. Do **not** start two-part / ZI×RE, **#49**, or any other open issue
until the owner names it in *this* chat. After rehydrate, **stop and ask the
owner for the next G0**. Never claim Cursor can be auto-launched.

**Supersedes as DRM.jl START HERE:**
[`2026-08-09-cursor-handover-drm-julia-lane.md`](2026-08-09-cursor-handover-drm-julia-lane.md)
(2026-08-09 afternoon Julia-lane pointer). That note remains **historical** —
it expected tip `a913af8d` / idle-before-136e. Owner later named 136e; [#404](https://github.com/itchyshin/DRM.jl/pull/404)
merged @ `733ae972`. Keep that file; do not treat it as the live DRM pointer.

Morning 2026-08-09 drmTMB-handoff note stays historical too:
[`2026-08-09-cursor-handover.md`](2026-08-09-cursor-handover.md).

**Multi-lane — never skip:** a single snapshot pointer must not orphan the
sibling. Active-Lane-Split lives on
[`docs/dev-log/coordination-board.md`](../coordination-board.md). This file is
the DRM.jl Julia pointer only. **drmTMB may still be in progress** — unknown
from this DRM.jl session; do **not** claim that sibling lane is finished.

`AGENTS.md` has no Live Phase Snapshot block. Rehydrate via the coordination
board split + this START HERE (and `LOOP/checkpoint.md` after this docs PR).

## Critical Context

1. **`origin/main` tip @ `733ae972`** —
   `733ae9728af4fa1c50bbebfb8075061cfb9bb126` = Merge [#404](https://github.com/itchyshin/DRM.jl/pull/404)
   (`feat/136e-va-bias-report`). Confirmed `git fetch origin main` +
   `git rev-parse origin/main`. This docs branch was cut from that tip, **not**
   from `feat/136e-va-bias-report`.
2. **#404 already MERGED.** Public Gamma `(1 | g)` smoke:
   **LA ≈ VA** on shape α (`|α_VA−α_LA|` ≤ 0.015 vs a 7× collapse would be
   α̂≈0.57); **LA faster** (~15–20× warm). VA stays **Experimental**. Report:
   `report/va-vs-laplace-bias.md`. Evidence:
   `docs/dev-log/after-task/2026-08-09-136e-va-bias.md`.
3. **Issue 136 stays OPEN.** GitHub auto-closed it on the #404 merge from
   “does not close” wording in that PR body; it was **reopened**. Confirm with
   `gh issue view 136 --repo itchyshin/DRM.jl`. The VA epic continues
   (two-part / ZI×RE still later). **Do not put close/fix/resolve words next
   to issue 136** in any new PR body.
4. **No competing DRM ship PR** at handoff write (`gh pr list --state open`
   was empty before this docs PR). Campaign already on main: #397–#404.
5. **No ship G0 has been named for the next slice.** Credible *candidates*
   only (owner picks; do not autoload): later #136 two-part/ZI×RE; #49 FIML;
   drmTMB `engine="julia"` (other repo); result-shape deepen; other open
   issues (#227 scout backlog, #269 λ, #270 NNGP/relmat, #280 mixed-family,
   #327 Hutchinson REML). **Do not invent G0 from ROADMAP.**
6. **D-111 OFF.** Leave **`.worktrees/`** alone. No q=4 core rewrite. No GPL
   vendoring. No Registrator / Julia General. Never stage
   `.codex/agents/shannon-coordinator.toml`.

## Goals / mission

DRM.jl is the MIT Julia twin of drmTMB: API/capability parity, Julia speed
edge only where independently evidenced. Bridge direction **R → Julia**
(`drmTMB(..., engine = "julia")`); never vendor GPL drmTMB source. ML default;
REML optional. Lovelace Phase 1.5 / #5 already CLOSED (experimental bar) —
do not rebuild. 136e-as-scoped (public Gamma RI report) **landed** in #404 —
do not re-run that smoke as the next G0 unless the owner asks.

This lane’s mission after this hygiene PR is **desk-ready Julia work after
the owner names G0** — not to invent the next ship slice, and not to start
drmTMB from this tree.

## Plans / roadmap

Beyond this tip-idle hygiene: owner names the **next DRM.jl G0**, then a
fresh `/ultra-plan` → `/goal` (or equivalent) in this Julia lane. Do not
invent from `ROADMAP.md` milestone umbrellas (#8 / #9). Deferred menu that
must stay visible (not dropped by narrowing to “this arc”):

- Later **#136** two-part / ZI×RE / phylo / crossed public VA — epic **OPEN**
- **#49** FIML / EM missing data — PARKED
- Sibling **drmTMB** `engine = "julia"` Workflow G — other repo; status unknown
- D-111 / Julia General — OFF

136e public-path report is **DONE** (on main via #404), not parked.

## What Was Accomplished

- Verified tip: `git fetch origin main`; `origin/main` = **`733ae972`** (Merge #404).
- Confirmed **issue 136 OPEN**; no competing open ship PR on DRM.jl.
- `handoff_gate.sh` **GATE FAIL** on stale local unpushed *other* branches
  plus untracked `.codex/agents/shannon-coordinator.toml` (declared
  CARRIED-OVER below; not this tip).
- This docs PR: idle START HERE after #404 + LOOP overwrite (no longer
  “wait for merge #404 / 136e in flight”) + coordination-board
  Active-Lane-Split refresh. 2026-08-09 Julia-lane handover kept (historical).
- No `src/` edits. No drmTMB edits from this tree. Did not invent a ship G0.

## Current Working State

- **Working:** `origin/main` @ **`733ae972`** (Merge #404). Tip **IDLE**
  pending owner G0. Julia lane = this file. drmTMB = sibling (possibly active).
- **In progress:** this docs tip-idle START HERE only (owner merges).
- **Not working / blocked:** no DRM implementation blocker. Material condition
  for ship work = **owner-named G0**. #49 parked by policy. Later #136 slices
  not named.
- **Evidence:** `report/va-vs-laplace-bias.md`;
  `docs/dev-log/after-task/2026-08-09-136e-va-bias.md`; this after-task
  `docs/dev-log/after-task/2026-08-13-tip-idle-after-404.md`.

## Key Decisions & Rationale

| Decision | Rationale |
|---|---|
| New START HERE file (do not overwrite 2026-08-09 Julia-lane note) | That note is the pre-136e idle pointer; overwriting would erase the chain. Banner it historical. |
| DRM.jl = IDLE pending owner G0 | #404 merged; no next ship G0 named. LOOP must not still say “merge #404 / 136e in flight”. |
| 136e-as-scoped = DONE | Public Gamma RI report is on main. Do not re-open that slice. |
| Issue 136 stays OPEN | Epic continues; GitHub auto-close trap documented. |
| drmTMB = sibling, status unknown | Do not claim finished; do not start from this tree. |
| #49 PARKED | Explicit owner fence. |
| Docs PR, do not auto-merge | Handover protocol Step 7; human merges. |
| D-111 OFF · `.worktrees/` untouched · no q=4 · no GPL | Standing PROTECTED. |

## Landing State

`~/shinichi-brain/tools/handoff_gate.sh` on DRM.jl **GATE FAIL** — 1 uncommitted
untracked file on this branch + 26 unpushed commits on *other* local branches.
Every failure declared:

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| `origin/main` `733ae972` | y | y | #404 MERGED | **LANDED** |
| #397–#403 + 136e report | y | y | MERGED | **LANDED** |
| `feat/136e-va-bias-report` | y | y | #404 MERGED | **LANDED** — do not resume |
| `docs/tip-idle-after-404` (this handover) | y | y (when PR opened) | docs PR open | **LANDED** (artifact); merge = owner |
| 2026-08-09 Julia-lane START HERE | y | y | #403 MERGED | **LANDED** — now **historical** |
| Stale local unpushed (26 commits / many old branches: `chore/worktree-house-rule`, `shannon/va-frontend`, `codex/local-qgate-fd-gradient`, `docs/rose-registry-claim-audit`, …) | mixed | n | none for this handoff | **CARRIED-OVER** — ignore unless owner names a branch. Resume: **do not checkout**. |
| `?? .codex/agents/shannon-coordinator.toml` | n | n | none | **CARRIED-OVER** — never stage; not this lane |
| `?? .worktrees/` (gitignored) | n | n | none | **CARRIED-OVER** / **PROTECTED** |
| drmTMB sibling working tree / PRs | n/a | n/a | unknown | **CARRIED-OVER** — other repo; do not inspect-as-done from here |

## OWED / classification

| Item | State |
|---|---|
| Merge #404 / confirm tip `733ae972` | **DONE** (at write time) |
| Confirm issue 136 stays OPEN | **DONE** |
| Write idle START HERE after #404 (not overwrite 2026-08-09 Julia-lane note) | **DONE** (this PR) |
| Overwrite LOOP so tip pointer says IDLE, not “merge #404 / 136e in flight” | **DONE** (this PR) |
| Refresh Active-Lane-Split without orphaning drmTMB | **DONE** (this PR) |
| Invent DRM ship G0 from ROADMAP / chat | **RETRACTED** |
| Start later #136 two-part/ZI×RE / Rung 4 / #49 | **RETRACTED** unless owner names them |
| Re-run 136e public Gamma smoke as the next G0 | **RETRACTED** unless owner asks |
| Start drmTMB from this DRM.jl tree | **RETRACTED** |
| Claim drmTMB sibling lane finished | **RETRACTED** |
| Rebuild Phase 1.5 / Lovelace #5 | **RETRACTED** |
| Flip VA Experimental → Implemented | **RETRACTED** |
| Stage/clean `.worktrees/` or `.codex/agents/shannon-coordinator.toml` | **PROTECTED** |
| Registrator / Julia General | **PROTECTED** — D-111 OFF |
| q=4 core / unapproved `src/` / claim inflation / GPL vendoring | **PROTECTED** |
| Rehydrate + confirm idle + **STOP and ask owner for next G0** | **OWED** (next Cursor chat) |
| Owner-merge this docs PR | **OWED** (human; not the next agent’s ship work) |

## Next Immediate Steps

1. **OWED — rehydrate only.** `"$HOME/shinichi-brain/tools/lane_preflight.sh" "/Users/z3437171/Dropbox/Github Local/DRM.jl"`
   then `git fetch origin && git status -sb && git log --oneline -8 origin/main`.
   Confirm tip **≥ `733ae972`** (#404 MERGED, or this docs PR merged on top).
   `gh issue view 136 --repo itchyshin/DRM.jl` → **OPEN**. `gh pr list --state open`.
   Read `AGENTS.md` → `HANDOVER.md` → `docs/dev-log/coordination-board.md`
   (every Active-Lane-Split row) → this handover. Classify vs git.
2. **OWED — confirm idle.** If the owner already named a G0 in *this* new chat,
   that supersedes the idle default. If not, DRM.jl remains IDLE.
3. **OWED — stop and ask.** Ask the owner for the **next G0**. Do not start
   later #136 slices, #49, result-shape, or drmTMB until they name it.
4. **RETRACTED / PROTECTED:** inventing G0; drmTMB from this tree; `.worktrees/`;
   D-111; q=4; GPL; claim inflation; declaring the drmTMB sibling finished;
   flipping Experimental → Implemented; auto-closing issue 136.

## Blockers / Open Questions

No DRM implementation blocker. **Open question (owner):** which Julia G0
next? Candidates (not a queue): later #136 two-part/ZI×RE; #49 FIML later;
drmTMB `engine="julia"` in that repo; result-shape deepen; #227 / #269 /
#270 / #280 / #327; something else.

Sibling drmTMB status is **unknown here** — ask the owner or read that repo’s
own handover if coordination requires it; do not guess.

## Gotchas & Failed Approaches

- 2026-08-09 Julia-lane START HERE still says tip `a913af8d` / idle-before-136e —
  **historical**. Tip is now `733ae972` (+ this docs PR when merged).
- LOOP files on `origin/main` after #404 still said “wait for owner merge #404 /
  136e in flight” — **that is why this PR exists**. After this PR, do not treat
  the old 136e GOAL as current.
- GitHub will auto-close issue 136 if a PR body uses close/fix/resolve words
  near that number — even “does not close”. Say “Related to issue 136. The VA
  epic stays OPEN.” Never `Closes #`.
- Do **not** start drmTMB from this tree “to be helpful.”
- Full `Pkg.test()` on tip is ~40–56 min (CI). Do not claim subset = CI.
- ELBO ≠ logLik; VA Experimental ≠ “implemented everywhere”; 136e smoke is
  public Gamma RI only, not ZINB / two-part.
- `handoff_gate.sh` will keep FAIL-ing on stale local branches — declare, don’t
  delete or force-push them.
- Cursor cannot be launched automatically from the authoring session.

## Files Created / Modified

- `docs/dev-log/handover/2026-08-13-cursor-handover-drm-idle-after-404.md` (this)
- `docs/dev-log/handover/2026-08-09-cursor-handover-drm-julia-lane.md` (historical banner only)
- `docs/dev-log/coordination-board.md` (tip + Active-Lane-Split)
- `LOOP/GOAL.md`, `LOOP/arcs.md`, `LOOP/checkpoint.md`, `LOOP/ultra-plan.md`
- `docs/dev-log/check-log.d/2026-08-13-tip-idle-after-404.md`
- `docs/dev-log/after-task/2026-08-13-tip-idle-after-404.md`
- `docs/dev-log/plan-actual/2026-08-13-tip-idle-after-404.md`

No `src/`. 136e ship already on `main` via #404.

## How to Resume (Cursor)

Working directory:

```bash
cd "/Users/z3437171/Dropbox/Github Local/DRM.jl"
export PATH="$HOME/.juliaup/bin:$PATH"
```

1. `"$HOME/shinichi-brain/tools/lane_preflight.sh" "/Users/z3437171/Dropbox/Github Local/DRM.jl"`
2. `git fetch origin && git status -sb && git log --oneline -8 origin/main`
3. Confirm tip **≥ `733ae972`** (Merge #404, or newer docs-PR merge) and
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
| DRM.jl | `origin/main` `733ae972` + this docs PR | **IDLE** Julia lane — pending owner G0 |
| drmTMB (R) | sibling repo / its own handover | **possibly in progress** — unknown here; do not claim finished |
| #136 epic | OPEN | 136e public Gamma report **DONE**; two-part/ZI×RE later |
| #49 | parked menu | **PARKED** until named |

### One-command resume

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-13-cursor-handover-drm-idle-after-404.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```

*Shannon · Ada · Rose. No nested subagents. Cursor is not auto-launched.*
