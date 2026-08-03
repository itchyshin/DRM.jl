# Session Handoff: DRM.jl #189 + #166 landed → tip idle

Meta: 2026-08-03 · from **Cursor** (Shannon) · TARGET **Cursor** · AUTHOR **cursor**

You are **Cursor**, picking up the DRM.jl repository after #189 and #166 both
landed. You inherit no chat context. Rehydrate from the current repository and
classify every item below **`OWED` · `DONE` · `RETRACTED` · `PROTECTED`**;
execute only `OWED`.

**Supersedes:** [`2026-08-02-cursor-handover-drm-idle.md`](2026-08-02-cursor-handover-drm-idle.md)
as the DRM.jl **START HERE** pointer. That #291-arcs-closed idle record and the
[2026-08-02 Phase 1.0 closeout handover](2026-08-02-cursor-handover.md) remain
historical. This is the tip-idle record after #189 (PR #367) and #166 (PR #368).

## Critical Context

1. **Both #189 and #166 are CLOSED and merged.** #189 (q=4 coevolution from
   relmat/animal/spatial) closed via [PR #367](https://github.com/itchyshin/DRM.jl/pull/367)
   (merge `b7893c9`). #166 (beta-binomial phylo + crossed random intercepts via
   sparse Laplace) closed via [PR #368](https://github.com/itchyshin/DRM.jl/pull/368)
   (merge `5b93b0b`).
2. **Tip is IDLE.** `origin/main` is at `0d93070` ("docs(loop): tip idle after
   #166"), which is at/after the `5b93b0b` merge. Local `main` matches
   `origin/main` exactly (verified `git log origin/main..main` and
   `git log main..origin/main` both empty at handover preflight).
3. **Default next action is DRM.jl tip IDLE — wait for an owner-opened G0.**
   Start a **fresh Cursor chat**; Ada picks the next twin-mission DRM.jl-only
   issue, or Shinichi names one; then `/ultra-plan` → G0 → `/goal`. **Do not
   invent ship work without G0.**

## Goals / mission

DRM.jl is the MIT Julia twin of drmTMB: API and capability parity, with a
Julia speed edge only where independently evidenced. The bridge direction is
**R → Julia** (`drmTMB(..., engine = "julia")`); never vendor GPL drmTMB
source.

## What Was Accomplished

- #189: q=4 coevolution route from `relmat()`/`animal()`/`spatial()` markers
  (not only a phylogenetic tree) — merged via PR #367.
- #166: beta-binomial phylo + crossed random-intercept route via the sparse
  augmented-state Laplace kernel — merged via PR #368 (see
  `docs/dev-log/after-task/2026-08-02-166-betabinomial-phylo-crossed-laplace.md`
  for the full worked-example / grad-gate / CI record).
- `LOOP/checkpoint.md` already reflects tip-idle-after-#166 accurately: no
  refresh was needed this handover (checked; not stale).

## Current Working State

- **Working:** `origin/main` at `0d93070`; #189/#367 and #166/#368 are both
  complete and merged.
- **In progress:** no DRM.jl ship lane or open DRM pull request at preflight
  (other than this handover's own docs-only PR).
- **Not working / blocked:** nothing. Do not manufacture a follow-on task
  after two closed issues.

## Key Decisions & Rationale

| Decision | Rationale |
|---|---|
| Tip idle after #166 | Both #189 and #166 are closed and merged; future work requires owner G0. |
| No AI-REML / `:natgrad` invention | The parked natural-gradient route does not establish MLE parity; not a public solver. |
| D-111: no General or Registrator | DRM.jl remains GitHub/`Pkg.develop` distributed until the twin is ready; no `@JuliaRegistrator register`. |
| Preserve the verified engine | No `src/` work without Noether plus maintainer sign-off; never regress the q=4 −256.51 / 2.18× baseline. |
| Preserve MIT boundary | drmTMB is GPL(≥3); parity uses generated outputs, never vendored source. |
| Leave `.worktrees/` alone | Untracked local worktree roots; never stage, never delete. |

## Landing State

`"$HOME/Dropbox/Github Local/Shinichi/tools/handoff_gate.sh" .` was run before
this handover (exit 1 — gate reports unlanded state until every item is
declared; no new uncommitted work exists in this session). Every item is
declared below.

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| `origin/main` `0d93070` | y | y | #367, #368 merged; #189, #166 closed | **LANDED** |
| `handover/2026-08-03-cursor-drm-idle` (this handoff) | y | y | docs-only PR opened, not merged | **LANDED** (handover artifact; merge is the maintainer's call) |
| `?? .worktrees/` | n | n | none | **CARRIED-OVER** — local worktree roots, unrelated to any issue. Resume: leave untouched; never stage. |
| `chore/worktree-house-rule`, `claude/capability-status-parity`, `codex/local-qgate-fd-gradient`, `codex/q4-bridge-vcov-skip`, `docs/rose-claim-drift-fix`, `docs/rose-registry-claim-audit`, `drmjl/sigma-phylo-reml-beta-psi-fix`, `ranef-slope-{beta,gamma,nbinom2}`, `shannon/{coord-spatial-counts,gaussian-sigma-phylo,issue-164-nonconst-sigma,tip-verify-checkpoint,unblock-locscale-profile-test,va-frontend}`, `worktree-agent-{a3ad2899248b152fc,a7df907e709972cb2,af2df784265dc24cf}` | mixed | n | none for this handoff | **CARRIED-OVER** — foreign/stale local WIP already declared in the 2026-08-02 handover; unchanged since. Resume: ignore unless Shinichi names the branch; do not stage or merge. |

## Next Immediate Steps

1. **DONE:** #189 (PR #367) and #166 (PR #368). Do not reopen or repeat them
   as work owed by this handover.
2. **OWED (default):** classify tip as **IDLE** and wait for an owner-opened
   DRM.jl G0. In a fresh Cursor chat: Ada picks the next twin-mission
   DRM.jl-only issue, or Shinichi names one; then run `/ultra-plan` → G0 →
   `/goal`. Do not invent ship work without G0.
3. **OWED (optional hygiene only):** `LOOP/checkpoint.md`'s START HERE pointer
   was checked at this handover and is **not** stale (it already says tip
   idle after #166, matching `origin/main` `0d93070`). No change made. If a
   future resume finds it stale, refresh it in a small scoped docs update —
   do not create a new research arc to do so.
4. **PROTECTED / RETRACTED:** Registrator/General work, invented AI-REML or
   `algorithm=:natgrad`, unapproved `src/` changes, AGENTS fence commits,
   `.worktrees/`, GPL vendoring.

## Blockers / Open Questions

No DRM implementation blocker exists. The material condition for new work is
an owner-opened G0, not an inference from an old roadmap checkbox.

## Gotchas & Failed Approaches

- **Prior chats drifted into cockpit and human tasks.** SORTEE blog, Advisory
  Board, CERC, and any other personal lane are bleed-through: resume agents
  must ignore them in this DRM.jl handover.
- The coordination board's active-branch table may be stale. Use
  `lane_preflight`, `git fetch`, and current GitHub state instead.
- `.worktrees/` is local-only and untracked. Leave it alone.
- The long list of foreign/stale local branches in the Landing State table
  above is unchanged since the 2026-08-02 handover — it is not new debt from
  this session; do not attempt to clean it up without Shinichi naming a
  branch.

## Files Created / Modified

- `docs/dev-log/handover/2026-08-03-cursor-handover-drm-idle.md` (this
  handover — new file)
- No other repository files were modified in this session (no `src/`, test,
  or `LOOP/checkpoint.md` changes were needed; checkpoint pointer verified
  current, not refreshed).

## How to Resume (Cursor)

Working directory:

```bash
cd "/Users/z3437171/Dropbox/Github Local/DRM.jl"
export PATH="$HOME/.juliaup/bin:$PATH"
```

Rehydrate in this order:

1. `"$HOME/Dropbox/Github Local/Shinichi/tools/handoff_gate.sh" .` (or
   `lane_preflight.sh .` if present) to confirm current landing state.
2. `git fetch origin && git status -sb && git log --oneline -8 origin/main`
3. Read `AGENTS.md` → `HANDOVER.md` → `LOOP/checkpoint.md` → this handover.
4. Classify the Next Immediate Steps and execute only `OWED`.

Safe verification for a future scoped change:

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.test()'
```

The optional R-parity suite requires `DRM_PARITY_TESTS=1`; do not assume R,
Julia, credentials, extensions, or terminal state transfer to a fresh Cursor
session. Never stage `.worktrees/`, secrets, foreign WIP, or fence commits.

### Mission control

| Repo | Tip / branch | CI | Shipped | Plan by leverage |
|---|---|---|---|---|
| DRM.jl | `origin/main` `0d93070` + this docs PR | docs-only PR; no engine check implied | #189 (#367), #166 (#368) | **Idle** unless owner opens G0 |
| Vault / Mission Control | adjacent only | n/a in DRM.jl | Julia surface / twin doctrine / R→Julia-only context | Not DRM ship debt |

### One-command resume

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-03-cursor-handover-drm-idle.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```

*Shannon · active perspectives: Ada (coordination) and Rose (scope/license
fence). No nested subagents are running.*
