# Session Handoff: new DRM.jl Julia lane — IDLE pending owner G0

Meta: 2026-08-09 (afternoon) · from **Cursor** (Shannon) · TARGET **Cursor** · AUTHOR **cursor**

You are **Cursor**, picking up a **new DRM.jl Julia lane** with **no chat
context**. Rehydrate from this repository + current git state. Classify every
item **`OWED` · `DONE` · `RETRACTED` · `PROTECTED`**; execute only `OWED`.

**Lane fence:** this is a **Julia DRM.jl** lane. Do **not** start drmTMB from
this tree. Do **not** invent a ship G0. **#136e** and **#49 stay PARKED** unless
the owner names them in *this* chat (they have not). After rehydrate, **stop
and ask the owner for the first G0**. Never claim Cursor can be auto-launched.

**Supersedes as DRM.jl START HERE:**
[`2026-08-09-cursor-handover.md`](2026-08-09-cursor-handover.md) (this morning).
That note remains **historical** — it handed the *next* lane to **drmTMB** after
#401. Owner later merged [#402](https://github.com/itchyshin/DRM.jl/pull/402)
@ `a913af8d` and started drmTMB elsewhere. Do not treat the morning note as the
live DRM pointer.

**Multi-lane — never skip:** a single snapshot pointer must not orphan the
sibling. Active-Lane-Split lives on
[`docs/dev-log/coordination-board.md`](../coordination-board.md). This file is
the DRM.jl Julia pointer only. **drmTMB may still be in progress** — unknown
from this DRM.jl session; do **not** claim that sibling lane is finished.

`AGENTS.md` has no Live Phase Snapshot block. Rehydrate via the coordination
board split + this START HERE (and `LOOP/checkpoint.md` after this docs PR).

## Critical Context

1. **`origin/main` tip @ `a913af8d`** —
   `a913af8d91c979649da4a213e20c07ac7bffa137` = Merge [#402](https://github.com/itchyshin/DRM.jl/pull/402)
   (`docs(loop): tip idle START HERE after #401`). Confirmed `git fetch` +
   `git rev-parse origin/main`. Local `main` matched origin at handoff write.
2. **#401 already MERGED** (morning) @ `3181eaa1` — VA Rung 2+3. **#136 stays
   OPEN** (`gh issue view 136`). Public VA is Experimental `(1 | g)` on Poisson
   + Binomial + NB2 + Gamma + Beta. Epic continues; **136e bias report PARKED**.
3. **No open DRM ship PR** at handoff write (`gh pr list --state open` → empty).
   This docs PR opens after. Campaign already on main: #397–#401 + #402.
4. **Owner asked for a new Julia DRM.jl lane.** drmTMB was started in a
   **sibling** session / repo. This chat must **not** begin drmTMB work, and
   must **not** declare the drmTMB lane done.
5. **No ship G0 has been named.** Credible *candidates* only (owner picks):
   #136e bias report; #49 FIML later; result-shape deepen beyond the #5
   experimental trio; other open issues (#227 scout backlog, #269 λ, #270
   NNGP/relmat, #280 mixed-family, #327 Hutchinson REML). **Do not autoload
   any of them.**
6. **D-111 OFF.** Leave **`.worktrees/`** alone. No q=4 core rewrite. No GPL
   vendoring. No Registrator / Julia General.

## Goals / mission

DRM.jl is the MIT Julia twin of drmTMB: API/capability parity, Julia speed
edge only where independently evidenced. Bridge direction **R → Julia**
(`drmTMB(..., engine = "julia")`); never vendor GPL drmTMB source. ML default;
REML optional. Lovelace Phase 1.5 / #5 already CLOSED (experimental bar) —
do not rebuild.

This lane’s mission is **desk-ready Julia work after owner names G0** — not
to continue this morning’s drmTMB handoff, and not to invent the next ship
slice.

## Plans / roadmap

Beyond this lane-switch hygiene: owner names the **first DRM.jl G0**, then a
fresh `/ultra-plan` → `/goal` (or equivalent) in this Julia lane. Do not
invent from `ROADMAP.md` milestone umbrellas (#8 / #9). Deferred menu that
must stay visible (not dropped by narrowing to “this arc”):

- **#136e** VA vs Laplace bias report (`report/va-vs-laplace-bias.md`) — PARKED
- **#49** FIML / EM missing data — PARKED
- Phylo / ZI / crossed public VA (still inside #136 epic, not named)
- Sibling **drmTMB** `engine = "julia"` Workflow G — other repo; status unknown
- D-111 / Julia General — OFF

## What Was Accomplished

- Verified tip: `git fetch`; `origin/main` = **`a913af8d`** (Merge #402).
- Confirmed **#136 OPEN**; **#49 OPEN**; no open PRs on DRM.jl.
- `handoff_gate.sh` **GATE FAIL** on stale local unpushed *other* branches
  (declared CARRIED-OVER below; not this tip).
- This docs PR: new Julia-lane START HERE + LOOP + coordination-board
  Active-Lane-Split refresh. Morning handover file kept (historical banner).
- No `src/` edits. No drmTMB edits from this tree.

## Current Working State

- **Working:** `origin/main` @ **`a913af8d`** (Merge #402). Tip IDLE pending
  owner G0. Julia lane = this file. drmTMB = sibling (possibly active).
- **In progress:** this docs lane-switch START HERE only (owner merges).
- **Not working / blocked:** no DRM implementation blocker. Material condition
  for ship work = **owner-named G0**. #136e / #49 are parked by policy.
- **Evidence:** `docs/dev-log/after-task/2026-08-09-136-va-rung2-3.md`;
  morning idle kit `docs/dev-log/after-task/2026-08-09-tip-idle-after-401.md`;
  this after-task `docs/dev-log/after-task/2026-08-09-cursor-handover-drm-julia-lane.md`.

## Key Decisions & Rationale

| Decision | Rationale |
|---|---|
| New START HERE file (do not overwrite morning note) | Morning note is the drmTMB handoff; overwriting would erase that sibling pointer. |
| DRM.jl = IDLE Julia lane pending owner G0 | Owner asked for a new Julia lane and did **not** name #136e / #49 / any ship G0. |
| drmTMB = sibling, status unknown | Owner started drmTMB elsewhere; this session cannot see that repo’s tip. Do not claim finished. |
| #136e / #49 PARKED | Explicit owner fence this turn. |
| Docs PR, do not auto-merge | Handover protocol Step 7; human merges. |
| D-111 OFF · `.worktrees/` untouched · no q=4 · no GPL | Standing PROTECTED. |

## Landing State

`~/shinichi-brain/tools/handoff_gate.sh` on DRM.jl **GATE FAIL** — 25 unpushed
commits on *other* local branches (not `main` / not this handover branch).
Every failure declared:

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| `origin/main` `a913af8d` | y | y | #402 MERGED | **LANDED** |
| #397 #398 #399 #400 #401 | y | y | MERGED | **LANDED** |
| `docs/handover-2026-08-09` (morning START HERE) | y | y | #402 MERGED | **LANDED** — historical drmTMB handoff |
| `docs/handover-2026-08-09-drm-julia-lane` (this handover) | y | y (when PR opened) | docs PR open | **LANDED** (artifact); merge = owner |
| `feat/136-va-rung2-3` | y | y | #401 MERGED | **LANDED** — do not resume |
| Stale local unpushed (25 commits / many old branches: `chore/worktree-house-rule`, `shannon/va-frontend`, `codex/local-qgate-fd-gradient`, `docs/rose-registry-claim-audit`, …) | mixed | n | none for this handoff | **CARRIED-OVER** — ignore unless owner names a branch. Resume: **do not checkout**. |
| `?? .worktrees/` (gitignored) | n | n | none | **CARRIED-OVER** / **PROTECTED** |
| drmTMB sibling working tree / PRs | n/a | n/a | unknown | **CARRIED-OVER** — other repo; do not inspect-as-done from here |
| Vault AGENT_LOG 2026-08-09 Julia-lane prepend | y (local file write; brain has no remote) | n/a | n/a | **LANDED** locally at `~/shinichi-brain/memory/AGENT_LOG.md` (uncommitted unless owner commits the vault) |

## OWED / classification

| Item | State |
|---|---|
| Merge #402 / confirm tip ≥ `a913af8d` | **DONE** (at write time) |
| Confirm #136 stays OPEN | **DONE** |
| Write new Julia-lane START HERE (not overwrite morning note) | **DONE** (this PR) |
| Refresh Active-Lane-Split without orphaning drmTMB | **DONE** (this PR) |
| Invent DRM ship G0 from ROADMAP / chat | **RETRACTED** |
| Start #136e / Rung 4 / #49 | **RETRACTED** unless owner names them |
| Start drmTMB from this DRM.jl tree | **RETRACTED** |
| Claim drmTMB sibling lane finished | **RETRACTED** |
| Rebuild Phase 1.5 / Lovelace #5 | **RETRACTED** |
| Stage/clean `.worktrees/` | **PROTECTED** |
| Registrator / Julia General | **PROTECTED** — D-111 OFF |
| q=4 core / unapproved `src/` / claim inflation / GPL vendoring | **PROTECTED** |
| Rehydrate + confirm idle-or-named-work + **ask owner for first G0** | **OWED** (next Cursor chat) |
| Owner-merge this docs PR | **OWED** (human; not the next agent’s ship work) |

## Next Immediate Steps

1. **OWED — rehydrate only.** `"$HOME/shinichi-brain/tools/lane_preflight.sh" .`
   then `git fetch origin && git status -sb && git log --oneline -8 origin/main`.
   Confirm tip **≥ `a913af8d`** (#402 MERGED, or this docs PR merged on top).
   `gh issue view 136` → **OPEN**. `gh pr list --state open`. Read
   `AGENTS.md` → `HANDOVER.md` → `docs/dev-log/coordination-board.md`
   (every Active-Lane-Split row) → this handover. Classify vs git.
2. **OWED — confirm idle-or-named-work.** If the owner already named a G0 in
   *this* new chat, that supersedes the idle default. If not, DRM.jl remains
   IDLE.
3. **OWED — stop and ask.** Ask the owner for the **first G0**. Do not start
   #136e, #49, result-shape, or any other open issue until they name it.
4. **RETRACTED / PROTECTED:** drmTMB from this tree; inventing G0; `.worktrees/`;
   D-111; q=4; GPL; claim inflation; declaring the drmTMB sibling finished.

## Blockers / Open Questions

No DRM implementation blocker. **Open question (owner):** which Julia G0
first? Candidates (not a queue): #136e bias report; #49 FIML later;
result-shape deepen; #227 / #269 / #270 / #280 / #327; something else.

Sibling drmTMB status is **unknown here** — ask the owner or read that repo’s
own handover if coordination requires it; do not guess.

## Gotchas & Failed Approaches

- Morning START HERE still says “NEXT LANE = drmTMB” and tip `3181eaa1` —
  **historical**. Tip is now `a913af8d` (+ this docs PR when merged).
- Do **not** open a second drmTMB chat from this tree “to be helpful.”
- Do **not** treat LOOP files that still talk about “merge #401 / next = drmTMB”
  as current after this docs PR — they are refreshed here.
- Full `Pkg.test()` on tip is ~40–56 min (CI). Do not claim subset = CI.
- ELBO ≠ logLik; VA Experimental ≠ “implemented everywhere”; do not close #136.
- `handoff_gate.sh` will keep FAIL-ing on stale local branches — declare, don’t
  delete or force-push them.
- Cursor cannot be launched automatically from the authoring session.

## Files Created / Modified

- `docs/dev-log/handover/2026-08-09-cursor-handover-drm-julia-lane.md` (this)
- `docs/dev-log/handover/2026-08-09-cursor-handover.md` (historical banner only)
- `docs/dev-log/coordination-board.md` (tip + Active-Lane-Split)
- `LOOP/GOAL.md`, `LOOP/arcs.md`, `LOOP/checkpoint.md`, `LOOP/ultra-plan.md`
- `docs/dev-log/check-log.d/2026-08-09-cursor-handover-drm-julia-lane.md`
- `docs/dev-log/after-task/2026-08-09-cursor-handover-drm-julia-lane.md`

No `src/`. Morning ship already on `main` via #401/#402.

## How to Resume (Cursor)

Working directory:

```bash
cd "/Users/z3437171/Dropbox/Github Local/DRM.jl"
export PATH="$HOME/.juliaup/bin:$PATH"
```

1. `"$HOME/shinichi-brain/tools/lane_preflight.sh" .`
2. `git fetch origin && git status -sb && git log --oneline -8 origin/main`
3. Confirm tip **≥ `a913af8d`** (Merge #402, or newer docs-PR merge) and
   `gh issue view 136` → **OPEN**.
4. Read `AGENTS.md` → `HANDOVER.md` → `docs/dev-log/coordination-board.md` →
   this handover. Reconcile with git; classify; execute only **OWED**.
5. **Stop.** Ask the owner for the first Julia G0. Do not start drmTMB here.

**Files not to stage:** `.worktrees/`, `intake/`, secrets, any path under
foreign worktrees. Never `git add -A`.

**Safe verify (only after owner names a G0 that changes code):**

```bash
# Full suite (CI truth; ~40–56 min):
julia --project=. --startup-file=no -e 'using Pkg; Pkg.instantiate(); Pkg.test()'

# Optional: DRM_PARITY_TESTS=1
```

### Mission control

| Repo | Tip / pointer | State |
|---|---|---|
| DRM.jl | `origin/main` `a913af8d` + this docs PR | **IDLE** Julia lane — pending owner G0 |
| drmTMB (R) | sibling repo / its own handover | **possibly in progress** — unknown here; do not claim finished |
| #136e / #49 | parked menu | **PARKED** until named |

### One-command resume

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-09-cursor-handover-drm-julia-lane.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```

*Shannon · Ada · Rose. No nested subagents. Cursor is not auto-launched.*
