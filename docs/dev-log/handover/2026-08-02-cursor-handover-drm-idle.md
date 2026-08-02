# Session Handoff: DRM.jl #291 Arcs 0–3 landed → tip idle

Meta: 2026-08-02 · from **Cursor** (Shannon) · TARGET **Cursor** · AUTHOR **cursor**

You are **Cursor**, picking up the DRM.jl repository after the #291 REML
characterisation arcs. You inherit no chat context. Rehydrate from the current
repository and classify every item below **`OWED` · `DONE` · `RETRACTED` ·
`PROTECTED`**; execute only `OWED`.

**Supersedes:** [`2026-08-02-cursor-handover.md`](2026-08-02-cursor-handover.md)
as the DRM.jl **START HERE** pointer. That Phase 1.0 closeout handover remains
historical. This is the tip-idle record after #291 Arcs 0–3 / #361–#365.

## Critical Context

1. **#291 is CLOSED; all four narrow arcs landed.** #361 (Arc 0 design and
   harness), #362 (Arc 1 FD bottleneck), #363 (Arc 2 sparse-first
   characterisation), #364 (arc closeout pointer), and #365 (Arc 3 p=16/nrep=3
   intermediate fixture) are merged. `origin/main` at handover preflight was
   `8debacd` (merge #365).
2. **The #291 result is evidence, not an acceleration claim.** Arc 3's timed
   REML fits did not converge, so its artifact is `diagnostic_only`; it cannot
   rank methods or support a speed headline. The broader #291 issue was closed,
   not converted into public solver work.
3. **Default next action is DRM.jl tip IDLE.** Start new DRM work only when the
   owner opens an explicit G0. The only optional hygiene is to refresh an
   obsolete LOOP pointer if a current checkout still says #365 is open.

## Goals / mission

DRM.jl is the MIT Julia twin of drmTMB: API and capability parity, with a Julia
speed edge only where independently evidenced. The bridge direction is
**R → Julia** (`drmTMB(..., engine = "julia")`); never vendor GPL drmTMB source.

## What Was Accomplished

- #291 Arcs 0–3 landed through PRs #361–#365; #291 is closed.
- Arc 1 records the central finite-difference REML route as the actionable
  structural bottleneck.
- Arc 2 records sparse-first warm/order accounting without claiming acceleration.
- Arc 3 adds a named deterministic p=16/nrep=3/seed=291 fixture and its
  `diagnostic_only` evidence classification.
- The Mission Control Julia surface, twin doctrine, and R→Julia-only direction
  are **vault/Mission-Control context**, not DRM.jl ship debt.

## Current Working State

- **Working:** `origin/main` at or after `8debacd`; #291/#361–#365 are complete.
- **In progress:** no DRM.jl ship lane or open DRM pull request at preflight.
- **Not working / blocked:** nothing. Do not manufacture a follow-on acceleration
  task after a closed issue.

## Key Decisions & Rationale

| Decision | Rationale |
|---|---|
| Tip idle after #365 | All scoped #291 arcs merged and the parent issue is closed; future work requires owner G0. |
| No AI-REML / `:natgrad` invention | The parked natural-gradient route does not establish MLE parity; `lc_metric` is infrastructure, not a public solver. |
| D-111: no General or Registrator | DRM.jl remains GitHub/`Pkg.develop` distributed until the twin is ready; no `@JuliaRegistrator register`. |
| Preserve the verified engine | No `src/` work without Noether plus maintainer sign-off; never regress the q=4 −256.51 / 2.18× baseline. |
| Preserve MIT boundary | drmTMB is GPL(≥3); parity uses generated outputs, never vendored source. |
| Fence AGENTS commits | Do not pull `a4585bd`, `7520d9d`, `88a2382`, or `66514a0` into DRM ship work. |

## Landing State

`$HOME/Dropbox/Github Local/Shinichi/tools/handoff_gate.sh .` was run before
this handover. It reported only local carry-over state; every item is declared
below. This handover branch is committed, pushed, and submitted as a separate
docs-only PR before handoff completion; it is fetchable but remains unmerged
until the maintainer merges it.

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| `origin/main` `8debacd` | y | y | #361–#365 merged; #291 closed | **LANDED** |
| `handover/2026-08-02-cursor-drm` | y | y | docs-only PR open | **LANDED** (handover artifact; merge pending) |
| `?? .worktrees/` | n | n | none | **CARRIED-OVER** — local worktree roots, unrelated. Resume: leave untouched; never stage. |
| `chore/worktree-house-rule`, `claude/capability-status-parity`, `codex/local-qgate-fd-gradient`, `codex/q4-bridge-vcov-skip`, `docs/rose-claim-drift-fix`, `docs/rose-registry-claim-audit`, `drmjl/sigma-phylo-reml-beta-psi-fix`, `ranef-slope-{beta,gamma,nbinom2}`, `shannon/{coord-spatial-counts,gaussian-sigma-phylo,issue-164-nonconst-sigma,tip-verify-checkpoint,unblock-locscale-profile-test,va-frontend}`, `worktree-agent-{a3ad2899248b152fc,a7df907e709972cb2,af2df784265dc24cf}` | mixed | n | none for this handoff | **CARRIED-OVER** — foreign/stale local WIP named by the handoff gate. Resume: ignore unless Shinichi names the branch; do not stage or merge it. |

## Next Immediate Steps

1. **DONE:** #291 Arcs 0–3 / #361–#365 and the parent issue. Do not reopen or
   repeat them as work owed by this handover.
2. **OWED (default):** classify tip as **IDLE** and wait for an owner-opened
   DRM.jl G0.
3. **OWED (optional hygiene only):** if `LOOP/checkpoint.md` still calls #365
   open, replace it with this handover's START HERE pointer in a separate scoped
   docs update; do not create a new research arc.
4. **PROTECTED / RETRACTED:** Registrator/General work, invented AI-REML or
   `algorithm=:natgrad`, unapproved `src/` changes, AGENTS fence commits,
   `.worktrees/`, GPL vendoring, and claims based on Arc 3 timing.

## Blockers / Open Questions

No DRM implementation blocker exists. The material condition for new work is an
owner-opened G0, not an inference from an old roadmap checkbox.

## Gotchas & Failed Approaches

- **Prior chat drifted into cockpit and human tasks.** SORTEE blog, Advisory
  Board, CERC, and any other personal lane are bleed-through: resume agents must
  ignore them in this DRM.jl handover.
- `diagnostic_only` means Arc 3 did not produce a comparative performance
  result; timed REML fits did not converge.
- The coordination board's active-branch table is old. Use `lane_preflight`,
  `git fetch`, and current GitHub state instead.
- `.worktrees/` is local-only and untracked. Leave it alone.

## Files Created / Modified

- `docs/dev-log/handover/2026-08-02-cursor-handover-drm-idle.md` (this handover)
- `LOOP/checkpoint.md` (tip-idle START HERE refresh)

## How to Resume (Cursor)

Working directory:

```bash
cd "/Users/z3437171/Dropbox/Github Local/DRM.jl"
export PATH="$HOME/.juliaup/bin:$PATH"
```

Rehydrate in this order:

1. `"$HOME/Dropbox/Github Local/Shinichi/tools/lane_preflight.sh" .`
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
| DRM.jl | `origin/main` `8debacd` + this docs PR | docs-only PR; no engine check implied | #291 Arcs 0–3 (#361–#365) | **Idle** unless owner opens G0 |
| Vault / Mission Control | adjacent only | n/a in DRM.jl | Julia surface / twin doctrine / R→Julia-only context | Not DRM ship debt |

### One-command resume

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-02-cursor-handover-drm-idle.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```

*Shannon · active perspectives: Ada (coordination) and Rose (scope/license
fence). No nested subagents are running.*
