# Session Handoff: DRM.jl tip idle after #386 — clean desk before next DRM lane

Meta: 2026-08-04 · from **Cursor** (Shannon) · TARGET **Cursor** · AUTHOR **cursor**

You are **Cursor**, picking up **DRM.jl only**. You inherit no chat context.
Rehydrate from the current repository and classify every item below
**`OWED` · `DONE` · `RETRACTED` · `PROTECTED`**; execute only `OWED`.

**Lane fence:** this handover is **DRM.jl tip-idle cleanup**. Do not open or
continue work on other subjects from chat memory. Next ship work must be an
**owner-named DRM.jl G0** in a fresh chat.

**Supersedes:** [`2026-08-03-cursor-handover-drm-idle-after-381.md`](2026-08-03-cursor-handover-drm-idle-after-381.md)
as the DRM.jl **START HERE** pointer. That after-381 note expected tip
`08bc4dc` before later tip-idle and ship merges; it remains historical. Tip now
matches `origin/main` after #384 + #386 (and this tip-idle docs PR when merged).

## Critical Context

1. **#383 CLOSED / MERGED** via [PR #384](https://github.com/itchyshin/DRM.jl/pull/384)
   @ `c9b9bd9` — Workflow G +4 FE bridge cells (`poisson` / `gamma` / `binomial` /
   `lognormal`); epic **#186** closed on ledger.
2. **#385 CLOSED / MERGED** via [PR #386](https://github.com/itchyshin/DRM.jl/pull/386)
   @ **`d543f94`** — admit `nbinom2-dispersion`; FE NB2 Dual `check_args=false`
   guard; bridge cohort **11/11**.
3. **Prior tip-idle docs #378–#382 MERGED** (after-381 START HERE was
   `08bc4dc`; #382 @ `b538768`). This PR refreshes START HERE after the ship
   landings that followed.
4. **Tip is IDLE** at `origin/main` **`d543f94`** (or newer tip-idle merge —
   `git log -1 --oneline origin/main`). Prefer owner-named ship G0 over another
   SHA-churn hygiene PR.
5. **Mission Control drmTMB (vault):** `next_safe_action` for the Julia twin =
   **owner G0 only**.
6. **D-111 OFF.** Leave **`.worktrees/`** alone. No inventing ship from ROADMAP.

## Goals / mission

DRM.jl is the MIT Julia twin of drmTMB: API/capability parity, Julia speed edge
only where independently evidenced. Bridge direction **R → Julia**
(`drmTMB(..., engine = "julia")`); never vendor GPL drmTMB source. ML default;
REML optional.

## Plans / roadmap

No active DRM ship arc. After owner opens a **named DRM.jl G0**: fresh chat →
`/ultra-plan` → `/goal`. Do not invent G0 here.

Credible DRM G0 candidates (owner picks; do not autoload):
- Time +4 FE / `nbinom2-dispersion` wall-clock cells (evidence-first; no claim inflation)
- Refresh original six Workflow G fixtures to drmTMB **0.6.0** numbers
- **#202** / **#49** / Lovelace bridge surface (Phase 1.5+) when named

## What Was Accomplished (this DRM session chain)

- #383/#384 +4 FE bridge parity admitted; #186 closed on ledger.
- #385/#386 `nbinom2-dispersion` admitted; native+bridge 11; Dual NB2 guard.
- Tip-idle START HERE cascade #378→#382 landed before those ships; this docs PR
  cleans LOOP/START HERE so tip SHA and OPEN GATES match #386 MERGED (stale
  LOOP still said OPEN GATE merge #386 / TRUTH on feat branch).

## Current Working State

- **Working:** `origin/main` @ `d543f94`; tip IDLE; no open DRM ship PR.
- **In progress:** this docs tip-idle START HERE refresh only (until owner merges).
- **Not working / blocked:** nothing DRM-implementation-related. New DRM work =
  owner G0 only.
- **Evidence:** `report/comparison-grid.md` (q4 baseline); parity fixtures under
  `test/parity/fixtures/` (cohort 11). Do not promote unmeasured speed claims.

## Key Decisions & Rationale

| Decision | Rationale |
|---|---|
| Tip idle after #386 | Ship + prior hygiene landed; next DRM slice needs owner G0. |
| after-386 START HERE | Clean desk; fix stale LOOP “merge #386” after #386 already merged. |
| DRM-only lane | No cross-subject bleed from chat; DRM.jl repo is the lane. |
| D-111 OFF | No Registrator / Julia General until twin readiness. |
| `.worktrees/` untouched | Foreign local checkouts; never stage. |

## Landing State

`handoff_gate.sh` **GATE FAIL** on undeclared local state — every failure declared:

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| `origin/main` `d543f94` | y | y | #384 + #386 MERGED | **LANDED** |
| `docs/tip-idle-after-386` (this handover) | y | y | docs PR open (merge pending) | **LANDED** (artifact); merge = owner |
| Vault MC drmTMB Julia tip string | y | n/a (brain local) | n/a | **LANDED** (vault) when refreshed |
| `?? .worktrees/` | n | n | none | **CARRIED-OVER** / **PROTECTED** |
| Stale local unpushed branches (`chore/*`, `claude/*`, `codex/*`, `docs/rose-*`, `drmjl/*`, `ranef-slope-*`, `shannon/*`, `worktree-agent-*`, …) | mixed | n | none for this handoff | **CARRIED-OVER** — ignore unless Shinichi names the branch |

## OWED / classification

| Item | State |
|---|---|
| Wait for owner-opened **DRM.jl** G0 only | **OWED** (default) |
| Invent next DRM ship slice without owner G0 | **RETRACTED** |
| Re-ultra-plan tip-idle as ship / rebuild #376/#383/#385 | **RETRACTED** |
| Refresh START HERE + LOOP after #386 | **DONE** (this docs PR) |
| Stage/clean `.worktrees/` | **PROTECTED** |
| Registrator / Julia General | **PROTECTED** — D-111 OFF |
| Unapproved `src/` / claim inflation | **PROTECTED** |

## Next Immediate Steps

1. **DONE:** #383/#384 + #385/#386 ship; tip `d543f94`.
2. **OWED:** tip IDLE — wait for owner-opened **DRM.jl** G0; then fresh chat
   `/ultra-plan` + `/goal` on that named slice.
3. **PROTECTED / RETRACTED:** inventing ship; `.worktrees/`; D-111; rebuild
   closed ship; claim inflation; unapproved `src/`.

## Blockers / Open Questions

No DRM implementation blocker. Material condition for new DRM work = owner G0.

## Gotchas & Failed Approaches

- after-#385 LOOP still said NEXT = merge #386 / OPEN GATE merge after #386
  already landed @ `d543f94` — do not treat as current.
- Do not invent G0 from ROADMAP checkboxes.
- Prefer owner-named ship over endless tip-idle SHA-churn PRs.
- Scoped timing / scaling ratios ≠ general Nx ≠ q4 2.18× unless that evidence
  is the claim under discussion.

## Files Created / Modified

- `docs/dev-log/handover/2026-08-04-cursor-handover-drm-idle-after-386.md` (this)
- `LOOP/{GOAL,arcs,checkpoint,ultra-plan}.md`
- `docs/dev-log/plans/2026-08-04-tip-idle-after-386-ultra-plan.md`
- `docs/dev-log/check-log.d/2026-08-04-tip-idle-after-386.md`
- `docs/dev-log/after-task/2026-08-04-tip-idle-after-386.md`

## How to Resume (Cursor)

```bash
cd "/Users/z3437171/Dropbox/Github Local/DRM.jl"
export PATH="$HOME/.juliaup/bin:$PATH"
```

1. `"$HOME/Dropbox/Github Local/Shinichi/tools/lane_preflight.sh" .`
2. `git fetch origin && git status -sb && git log --oneline -8 origin/main`
3. Confirm tip `d543f94` (or newer tip-idle merge) and #386 MERGED.
4. Read `AGENTS.md` → `HANDOVER.md` → `LOOP/checkpoint.md` → this handover.
5. Classify; execute only **OWED**. Stay on **DRM.jl**.

Safe verify (future scoped change): `julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.test()'`.
Optional: `DRM_PARITY_TESTS=1`. Never stage `.worktrees/`.

### Mission control (DRM only)

| Repo | Tip | State |
|---|---|---|
| DRM.jl | `origin/main` `d543f94` + this docs PR | Idle — owner DRM G0 only |
| Vault MC drmTMB | tip idle after #386 | Julia twin: owner G0 |

### One-command resume

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-04-cursor-handover-drm-idle-after-386.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```

*Shannon · Ada · Rose. DRM.jl lane only. No nested subagents.*
