# Session Handoff: DRM.jl #376+#377+#378 landed → tip idle

Meta: 2026-08-03 · from **Cursor** (Shannon) · TARGET **Cursor** · AUTHOR **cursor**

You are **Cursor**, picking up the DRM.jl repository after tip-idle hygiene
landed. You inherit no chat context. Rehydrate from the current repository and
classify every item below **`OWED` · `DONE` · `RETRACTED` · `PROTECTED`**;
execute only `OWED`.

**Supersedes:** [`2026-08-03-cursor-handover-drm-idle-after-376.md`](2026-08-03-cursor-handover-drm-idle-after-376.md)
as the DRM.jl **START HERE** pointer. That after-376 note was written expecting
tip `ae4e67d` **before** tip-idle docs [PR #378](https://github.com/itchyshin/DRM.jl/pull/378)
merged; it remains historical. This is the tip-idle record after #376+#377+#378,
with tip SHA matching `origin/main`.

## Critical Context

1. **#376 is CLOSED and merged.** Measured drmTMB q4 scaling head-to-head
   (retire extrapolated ~12×) closed via [PR #377](https://github.com/itchyshin/DRM.jl/pull/377)
   (squash `ae4e67d`).
2. **Tip-idle docs PR #378 is MERGED** @ `91565f4`
   (`docs(loop): tip idle after #376+#377`).
3. **Tip is IDLE.** `origin/main` tip for this handover is **`91565f4`**.
4. **Mission Control drmTMB board** (vault `f39f4dc`):
   `next_safe_action` = **owner G0 only** — do not invent ship work; do not
   rebuild the #376 harness; do not re-ultra-plan tip-idle.
5. **Default next action is DRM.jl tip IDLE — wait for an owner-opened G0.**
   Leave `.worktrees/` alone. **D-111 OFF** (no Registrator / Julia General).

## Goals / mission

DRM.jl is the MIT Julia twin of drmTMB: API and capability parity, with a Julia
speed edge only where independently evidenced. The bridge direction is
**R → Julia** (`drmTMB(..., engine = "julia")`); never vendor GPL drmTMB source.
ML is the default; REML is an option.

## Plans / roadmap

No active ship arc. After owner G0: open a **fresh** chat and run
`/ultra-plan` + `/goal` — do **not** invent G0 in this idle lane. See
`ROADMAP.md` only after G0 names the slice.

## What Was Accomplished

- #376 / PR #377 measured q4 PLSM scaling H2H; extrapolated ~12× retired.
- Tip-idle docs PR #378 MERGED @ `91565f4` (LOOP + after-376 START HERE kit).
- Vault Mission Control drmTMB NOW refreshed (`f39f4dc`): tip idle; owner G0.
- This docs PR refreshes START HERE so the pointer tip SHA is `91565f4`, not the
  pre-#378 `ae4e67d` expectation in after-376.

## Current Working State

- **Working:** `origin/main` @ `91565f4`; #376/#377/#378 complete; tip IDLE.
- **In progress:** none (docs tip-idle START HERE refresh only).
- **Not working / blocked:** nothing DRM-implementation-related. New work needs
  owner G0, not inference from an old roadmap checkbox.
- **Evidence:** `docs/dev-log/evidence/2026-08-03-376-q4-scaling-h2h.md`
  (paired Julia/R medians on Totoro; nrep=4; p∈{100,1000,5000,10000} —
  scoped ratios only; not the real-data q4_p100 2.18× cell; not #372 bridge
  ratios).

## Key Decisions & Rationale

| Decision | Rationale |
|---|---|
| Tip idle after #378 | Ship + tip-idle hygiene both landed; inventing the next arc is forbidden until owner G0. |
| New after-378 START HERE | after-376 still said tip `ae4e67d`; tip is now `91565f4` (#378 merged). |
| D-111 OFF | No Julia General / Registrator until twin readiness (owner decision). |
| Preserve verified engine | No `src/` without Noether + maintainer; never regress q=4 −256.51 / 2.18×. |
| MIT boundary | drmTMB GPL(≥3); parity uses generated outputs only. |
| `.worktrees/` untouched | Local foreign checkouts; never stage. |

## Landing State

`~/shinichi-brain/tools/handoff_gate.sh` was run before this handover (**GATE
FAIL** on undeclared local state). Every failure is declared below. This
handover branch is committed, pushed, and submitted as a docs-only PR; it is
fetchable but remains unmerged until the maintainer merges it.

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| `origin/main` `91565f4` | y | y | #377 MERGED (closes #376); #378 MERGED | **LANDED** |
| `docs/tip-idle-after-378` (this handover) | y | y | docs PR open (merge pending) | **LANDED** (artifact); merge = owner |
| Vault MC drmTMB `f39f4dc` | y | n/a (brain local) | n/a | **LANDED** (vault) |
| `?? .worktrees/` | n | n | none | **CARRIED-OVER** / **PROTECTED** — leave untouched; never stage. |
| Stale local unpushed branches named by handoff_gate (`chore/worktree-house-rule`, `claude/capability-status-parity`, `codex/*`, `docs/rose-*`, `drmjl/sigma-phylo-reml-beta-psi-fix`, `ranef-slope-*`, `shannon/*`, `worktree-agent-*`, …) | mixed | n | none for this handoff | **CARRIED-OVER** — foreign/stale WIP. Resume: ignore unless Shinichi names the branch. |

## OWED / classification

| Item | State |
|---|---|
| Wait for owner-opened DRM.jl G0 only | **OWED** (default; do not invent the G0) |
| Pick / invent next DRM ship slice without owner G0 | **RETRACTED** |
| Re-ultra-plan tip-idle / rebuild #376 harness | **RETRACTED** |
| Refresh START HERE + LOOP tip SHA after #378 | **DONE** (this docs PR) |
| Stage or clean `.worktrees/` | **PROTECTED** |
| Registrator / Julia General | **PROTECTED** — D-111 OFF |
| Rewrite measured #376 ratios / invent new speed headlines | **PROTECTED** |
| Unapproved `src/` / engine edits | **PROTECTED** |

## Next Immediate Steps

1. **DONE:** #376/#377 ship; #378 tip-idle docs; MC board owner-G0.
2. **OWED (default):** classify tip as **IDLE** and wait for an owner-opened
   DRM.jl G0. Then, in a **fresh** chat: `/ultra-plan` + `/goal`.
3. **PROTECTED / RETRACTED:** inventing ship work; `.worktrees/`; D-111;
   rebuilding #376; claim inflation; unapproved `src/`.

## Blockers / Open Questions

No DRM implementation blocker. Material condition for new work = owner G0.

## Gotchas & Failed Approaches

- **after-376 tip SHA drift:** written for `ae4e67d` before #378 merged; do not
  treat it as current START HERE.
- **Do not invent G0** from ROADMAP checkboxes or chat momentum.
- Coordination board active-branch table is old — use `lane_preflight` +
  `git fetch` + GitHub.
- `.worktrees/` is local-only and untracked. Leave it alone.
- Scoped #376 ratios ≠ general Nx headline ≠ q4 2.18× ≠ #372 six-cell ratios.

## Files Created / Modified

- `docs/dev-log/handover/2026-08-03-cursor-handover-drm-idle-after-378.md` (this)
- `LOOP/checkpoint.md` (tip `91565f4` + START HERE → after-378)
- `LOOP/arcs.md` (note #378 MERGED / after-378 START HERE)
- `docs/dev-log/check-log.d/2026-08-03-tip-idle-after-378.md`
- `docs/dev-log/after-task/2026-08-03-tip-idle-after-378.md`

## How to Resume (Cursor)

Working directory:

```bash
cd "/Users/z3437171/Dropbox/Github Local/DRM.jl"
export PATH="$HOME/.juliaup/bin:$PATH"
```

Rehydrate in this order:

1. `"$HOME/Dropbox/Github Local/Shinichi/tools/lane_preflight.sh" .` (or repo equivalent)
2. `git fetch origin && git status -sb && git log --oneline -8 origin/main`
3. Confirm tip is `91565f4` (or newer docs tip-idle merge) and #378 is MERGED.
4. Read `AGENTS.md` → `HANDOVER.md` → `LOOP/checkpoint.md` → this handover.
5. Classify Next Immediate Steps; execute only **`OWED`**.

Safe verification for a *future* scoped change (not owed now):

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.test()'
```

Optional R-parity: `DRM_PARITY_TESTS=1`. Do not assume R, Julia, credentials,
extensions, or terminal state transfer. Never stage `.worktrees/`, secrets,
foreign WIP, or fence commits.

### Mission control

| Repo | Tip / branch | CI | Shipped | Plan by leverage |
|---|---|---|---|---|
| DRM.jl | `origin/main` `91565f4` + this docs PR | docs-only; no engine check | #376/#377 ship; #378 tip-idle | **Idle** — owner G0 only |
| Vault / MC drmTMB | `f39f4dc` | n/a | NOW = tip idle; `next_safe_action` = owner G0 | Not DRM ship debt |

### One-command resume

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-03-cursor-handover-drm-idle-after-378.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```

*Shannon · perspectives: Ada (coordination), Rose (scope). No nested subagents.*
