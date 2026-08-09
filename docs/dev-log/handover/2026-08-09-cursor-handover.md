# Session Handoff: DRM.jl tip IDLE after #401 — next lane is drmTMB

Meta: 2026-08-09 · from **Cursor** (Shannon) · TARGET **Cursor** · AUTHOR **cursor**

You are **Cursor**, picking up with **no chat context**. Rehydrate from this
repository + current git state. Classify every item **`OWED` · `DONE` ·
`RETRACTED` · `PROTECTED`**; execute only `OWED`.

**Lane fence (one lane):** DRM.jl tip is **IDLE** after landing #401. Do **not**
continue DRM **#136e** / Rung 4 unless the owner names it in this new chat.
**#49 is PARKED.** Default next work is a **fresh chat in the drmTMB R repo**
(`engine = "julia"` live Workflow G) — **different repository**. Do not start
drmTMB work from this DRM.jl tree.

**Supersedes:** [`2026-08-05-cursor-handover-drm-idle-after-393.md`](2026-08-05-cursor-handover-drm-idle-after-393.md)
as the DRM.jl **START HERE** pointer. That note expected tip `e32a2c6` / #393;
it remains historical. Tip now matches `origin/main` after #397–#401.

**Multi-lane:** do **not** treat a single AGENTS.md snapshot as both repos.
Active-Lane-Split lives on the coordination board (this PR refreshes it). DRM
pointer = this file (IDLE). Sibling next lane = drmTMB R repo (not started here).

## Critical Context

1. **#401 MERGED** — [PR #401](https://github.com/itchyshin/DRM.jl/pull/401)
   @ **`3181eaa198480223685d33a3f62f4bcc882c0c42`** (`gh pr merge 401 --merge`).
   CI green: `test (1.10)` 43m19s · `test (1)` 56m2s · docs pass ·
   `scaling-sweep` skipped. Related to **#136**; must **not** close #136.
2. **#136 stays OPEN** — confirmed after merge
   <https://github.com/itchyshin/DRM.jl/issues/136>. VA is Experimental
   `(1 | g)` on Poisson + Binomial + NB2 + Gamma + Beta. Epic continues;
   136e bias report is **PARKED**.
3. **Already merged this campaign:** #397 (Phase 3 closeout), #398 (Makie ext),
   #399 (Poisson VA frontend), #400 (Rung 1 four families). No other open
   campaign PR.
4. **NEXT LANE ≠ this repo.** Owner direction: drmTMB
   `/Users/z3437171/Dropbox/Github Local/drmTMB` — live `engine = "julia"`
   Workflow G round-trip. Start a **fresh Cursor chat there**. This DRM
   handover only parks the Julia tip.
5. **D-111 OFF.** Leave **`.worktrees/`** alone. No inventing DRM ship from
   ROADMAP. No Registrator / Julia General.

## Goals / mission

DRM.jl is the MIT Julia twin of drmTMB: API/capability parity, Julia speed
edge only where independently evidenced. Bridge direction **R → Julia**
(`drmTMB(..., engine = "julia")`); never vendor GPL drmTMB source. ML default;
REML optional. Lovelace Phase 1.5 / #5 already CLOSED (experimental bar) —
do not rebuild.

## Plans / roadmap

Beyond this desk-clean: owner picks the **drmTMB** live Workflow G slice
(R repo). DRM #136e / phylo-ZI VA / #49 FIML stay on the deferred menu until
named. Credible DRM G0 later (owner only): 136e bias report; result-shape
deepen; #49.

## What Was Accomplished

- Waited CI on #401 (~56 min `test (1)`); merged with merge-commit style
  matching #397–#400.
- Confirmed #136 **OPEN**; local `main` fast-forwarded to `3181eaa1`.
- This docs PR: START HERE handover + LOOP + coordination-board tip refresh.
- Vault `AGENT_LOG` prepend was **not** landed this session (MCP write blocked /
  not approved). Repo doc is the durable source of truth.

## Current Working State

- **Working:** `origin/main` @ **`3181eaa1`** (Merge #401). Tip IDLE. No open
  DRM ship PR at handoff write time (this docs PR opens after).
- **In progress:** this docs tip-idle START HERE refresh only (owner merges).
- **Not working / blocked:** nothing DRM-implementation-related. #136e / #49
  are parked by policy, not by a code blocker.
- **Evidence:** `docs/dev-log/after-task/2026-08-09-136-va-rung2-3.md`;
  CI on #401.

## Key Decisions & Rationale

| Decision | Rationale |
|---|---|
| Merge #401; do not close #136 | Owner asked merge-what-we-can; epic stays open. |
| DRM tip IDLE after #401 | Rungs 2+3 landed; 136e not named. |
| Next = drmTMB `engine="julia"` (other repo) | Owner: one lane; do not start drmTMB from DRM.jl. |
| #136e / #49 PARKED | Explicit owner fence. |
| Docs PR, do not auto-merge | Handover protocol Step 7; human merges. |
| D-111 OFF · `.worktrees/` untouched | Standing PROTECTED. |

## Landing State

`handoff_gate.sh` **GATE FAIL** — undeclared local unpushed branches on *other*
refs (not this tip). Every failure declared:

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| `origin/main` `3181eaa1` | y | y | #401 MERGED | **LANDED** |
| #397 #398 #399 #400 | y | y | MERGED | **LANDED** |
| `docs/handover-2026-08-09` (this handover) | y | y (when PR opened) | docs PR open | **LANDED** (artifact); merge = owner |
| `feat/136-va-rung2-3` | y | y | #401 MERGED | **LANDED** — do not resume |
| Stale local unpushed (25 commits / many old branches: `chore/worktree-house-rule`, `shannon/va-frontend`, `codex/local-qgate-fd-gradient`, …) | mixed | n | none for this handoff | **CARRIED-OVER** — ignore unless owner names a branch. Resume: **do not checkout**. |
| `?? .worktrees/` (gitignored) | n | n | none | **CARRIED-OVER** / **PROTECTED** |
| Vault AGENT_LOG 2026-08-09 prepend | n | n/a (brain local) | n/a | **CARRIED-OVER** — optional; owner may append. Resume: edit `~/shinichi-brain/memory/AGENT_LOG.md` if desired. |

## OWED / classification

| Item | State |
|---|---|
| Merge #401 if CI green | **DONE** |
| Confirm #136 stays OPEN | **DONE** |
| `git fetch` + local main pull | **DONE** |
| If #401 not merged: merge/CI triage | **DONE** (was OWED only while open) |
| Continue DRM #136e / Rung 4 | **RETRACTED** unless owner names it |
| #49 FIML | **PROTECTED** / PARKED |
| Invent DRM ship from ROADMAP | **RETRACTED** |
| Rebuild Phase 1.5 / Lovelace #5 | **RETRACTED** |
| Stage/clean `.worktrees/` | **PROTECTED** |
| Registrator / Julia General | **PROTECTED** — D-111 OFF |
| q=4 core / unapproved `src/` / claim inflation | **PROTECTED** |
| Fresh drmTMB `engine="julia"` Workflow G lane | **OWED** — **other repo**, fresh chat only |
| Owner-merge this docs PR | **OWED** (human; not the next agent’s ship work) |

## Next Immediate Steps

1. **DONE:** #401 merged @ `3181eaa1`; #136 OPEN; #397–#400 already merged.
2. **OWED (this DRM.jl chat, only if still true after rehydrate):** if #401 is
   somehow **not** merged on `origin/main`, triage CI / merge that PR only.
   Else **stop DRM ship work**.
3. **OWED (default next lane):** start a **fresh Cursor agent** in
   `/Users/z3437171/Dropbox/Github Local/drmTMB` for live `engine = "julia"`
   Workflow G. Do **not** begin that work inside DRM.jl.
4. **PARKED:** DRM #136e; #49. Do not autoload.
5. **PROTECTED / RETRACTED:** inventing DRM G0; Lovelace rebuild; `.worktrees/`;
   D-111; q=4; claim inflation.

## Blockers / Open Questions

No DRM implementation blocker. Material condition for new **DRM.jl** work =
owner-named G0. Material condition for the **next** chat = open drmTMB repo
(not this one).

## Gotchas & Failed Approaches

- PR #401 body said “OPEN GATE = owner merge / Do not merge from this agent” —
  **superseded** by the later owner instruction to merge what we can.
- Do not treat LOOP files still talking about “merge GATE” on `feat/136-va-rung2-3`
  as current after this docs PR — they are refreshed here.
- Stale after-393 START HERE still says tip `e32a2c6` — historical only.
- Full `Pkg.test()` on tip is ~40–56 min (CI). Do not claim subset = CI.
- ELBO ≠ logLik; VA Experimental ≠ “implemented everywhere”.
- Cursor cannot be launched automatically from this session.

## Files Created / Modified

- `docs/dev-log/handover/2026-08-09-cursor-handover.md` (this)
- `docs/dev-log/coordination-board.md` (tip + Active-Lane-Split)
- `LOOP/GOAL.md`, `LOOP/arcs.md`, `LOOP/checkpoint.md`, `LOOP/ultra-plan.md`
- `docs/dev-log/check-log.d/2026-08-09-tip-idle-after-401.md`
- `docs/dev-log/after-task/2026-08-09-tip-idle-after-401.md`

Session ship already on `main` via #401 (not this PR): `src/comparison.jl`,
`src/variational.jl`, VA tests, capabilities/NEWS/guide, after-task
`2026-08-09-136-va-rung2-3.md`.

## How to Resume (Cursor)

Working directory:

```bash
cd "/Users/z3437171/Dropbox/Github Local/DRM.jl"
export PATH="$HOME/.juliaup/bin:$PATH"
```

1. `"$HOME/shinichi-brain/tools/lane_preflight.sh" .`
2. `git fetch origin && git status -sb && git log --oneline -8 origin/main`
3. Confirm tip **`3181eaa1`** (or newer docs-PR merge) and **#401 MERGED**;
   `gh issue view 136` → **OPEN**.
4. Read `AGENTS.md` → `HANDOVER.md` → `docs/dev-log/coordination-board.md` →
   this handover. Reconcile with git; classify; execute only **OWED**.
5. If DRM stays idle: **do not** start 136e. Open a **new** Cursor chat in
   **drmTMB** for the julia-engine lane.

**Files not to stage:** `.worktrees/`, `intake/`, secrets, any path under
foreign worktrees.

**Safe verify (only if staying on DRM and changing code):**

```bash
# Full suite (CI truth; ~40–56 min):
julia --project=. --startup-file=no -e 'using Pkg; Pkg.instantiate(); Pkg.test()'

# VA subset note (not a substitute for CI) — include via runtests order:
# test/test_aic_bic.jl
# test/test_variational.jl
# test/test_va_frontend_poisson.jl
# test/test_va_frontend_families.jl
# test/test_variational_{binomial,nb2,gamma}.jl (+ beta kernel file if present)
# Optional: DRM_PARITY_TESTS=1
```

### Mission control

| Repo | Tip | State |
|---|---|---|
| DRM.jl | `origin/main` `3181eaa1` + this docs PR | **IDLE** — #136e / #49 PARKED |
| drmTMB (R) | *(open that repo)* | **NEXT LANE** — `engine="julia"` Workflow G |
| Vault MC | AGENT_LOG prepend not landed | optional |

### One-command resume

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-09-cursor-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```

*Shannon · Ada · Rose. No nested subagents. Cursor is not auto-launched.*
