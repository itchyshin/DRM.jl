# Session Handoff: DRM.jl tip idle after #393 — clean desk before next DRM lane

Meta: 2026-08-05 · from **Cursor** (Shannon) · TARGET **Cursor** · AUTHOR **cursor**

You are **Cursor**, picking up **DRM.jl only**. You inherit no chat context.
Rehydrate from the current repository and classify every item below
**`OWED` · `DONE` · `RETRACTED` · `PROTECTED`**; execute only `OWED`.

**Lane fence:** this handover is **DRM.jl tip-idle cleanup**. Do not open or
continue work on other subjects from chat memory. Next ship work must be an
**owner-named DRM.jl G0** (or a named twin R-repo G0) in a fresh chat.

**Supersedes:** [`2026-08-04-cursor-handover-drm-idle-after-386.md`](2026-08-04-cursor-handover-drm-idle-after-386.md)
as the DRM.jl **START HERE** pointer. That after-386 note expected tip
`d543f94` / tip-idle #387; it remains historical. Tip now matches
`origin/main` after #390 + #393 (and this tip-idle docs PR when merged).

## Critical Context

1. **#389 CLOSED / MERGED** via [PR #390](https://github.com/itchyshin/DRM.jl/pull/390)
   @ `d5adb57` — measured warm wall-clock for +4 FE + `nbinom2-dispersion`
   (scoped ≈ **11.4×–59.6×**; not a general Nx headline).
2. **#392 CLOSED / MERGED** via [PR #393](https://github.com/itchyshin/DRM.jl/pull/393)
   @ **`e32a2c6`** — original six Workflow G fixtures re-anchored to drmTMB
   **0.6.0**; all eleven cells share one numeric pin; native+bridge 11/11.
3. **Prior tip-idle #378–#387 MERGED.** Phase 1.5 / Lovelace **#5 CLOSED**
   (experimental `engine = "julia"`; #349 + drmTMB #878) — do **not** rebuild.
4. **Tip is IDLE** at `origin/main` **`e32a2c6`** (or newer tip-idle merge —
   `git log -1 --oneline origin/main`). Prefer owner-named ship G0 over another
   SHA-churn hygiene PR.
5. **Mission Control drmTMB (vault):** Julia twin `next_safe_action` =
   **owner G0 only**.
6. **D-111 OFF.** Leave **`.worktrees/`** alone. No inventing ship from ROADMAP.

## Goals / mission

DRM.jl is the MIT Julia twin of drmTMB: API/capability parity, Julia speed edge
only where independently evidenced. Bridge direction **R → Julia**
(`drmTMB(..., engine = "julia")`); never vendor GPL drmTMB source. ML default;
REML optional.

## Plans / roadmap

No active DRM ship arc. After owner opens a **named G0**: fresh chat →
`/ultra-plan` → `/goal`. Do not invent G0 here.

Credible next G0 candidates (owner picks; do not autoload):
- Live R `engine = "julia"` round-trip of the eleven Workflow G fixtures
  (drmTMB R-repo lane; skip-safe without JuliaCall)
- Result-shape deepen beyond the #5 experimental trio
- **#202** / **#49** when named

## What Was Accomplished (this DRM session chain)

- #389/#390 +5 bridge timing measured and documented.
- #392/#393 original six fixtures → drmTMB 0.6.0; docs/AGENTS numeric pin unified.
- This docs PR cleans LOOP/START HERE so tip SHA and OPEN GATES match #393 MERGED.

## Current Working State

- **Working:** `origin/main` @ `e32a2c6`; tip IDLE; no open DRM ship PR.
- **In progress:** this docs tip-idle START HERE refresh only (until owner merges).
- **Not working / blocked:** nothing DRM-implementation-related. New DRM work =
  owner G0 only.
- **Evidence:** `docs/dev-log/evidence/2026-08-05-389-plus5-bridge-timing.md`;
  `docs/dev-log/after-task/2026-08-05-392-refresh-six-fixtures-060.md`.

## Key Decisions & Rationale

| Decision | Rationale |
|---|---|
| Tip idle after #393 | Ship + prior hygiene landed; next slice needs owner G0. |
| after-393 START HERE | Clean desk; retire stale merge-#393 LOOP wording. |
| Lovelace #5 not rebuilt | Already CLOSED experimental bar. |
| D-111 OFF | No Registrator / Julia General. |
| `.worktrees/` untouched | Foreign local checkouts; never stage. |

## Landing State

`handoff_gate.sh` **GATE FAIL** on undeclared local state — every failure declared:

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| `origin/main` `e32a2c6` | y | y | #390 + #393 MERGED | **LANDED** |
| `docs/tip-idle-after-393` (this handover) | y | y | docs PR open (merge pending) | **LANDED** (artifact); merge = owner |
| Vault MC drmTMB Julia tip | y | n/a (brain local) | n/a | **LANDED** when refreshed |
| `?? .worktrees/` | n | n | none | **CARRIED-OVER** / **PROTECTED** |
| Stale local unpushed branches | mixed | n | none for this handoff | **CARRIED-OVER** — ignore unless named |

## OWED / classification

| Item | State |
|---|---|
| Wait for owner-opened **DRM.jl** (or named twin) G0 only | **OWED** (default) |
| Invent next ship slice without owner G0 | **RETRACTED** |
| Rebuild Phase 1.5 / Lovelace #5 | **RETRACTED** |
| Refresh START HERE + LOOP after #393 | **DONE** (this docs PR) |
| Stage/clean `.worktrees/` | **PROTECTED** |
| Registrator / Julia General | **PROTECTED** — D-111 OFF |
| Unapproved `src/` / claim inflation | **PROTECTED** |

## Next Immediate Steps

1. **DONE:** #390 timing + #393 fixture re-anchor; tip `e32a2c6`.
2. **OWED:** tip IDLE — wait for owner-opened G0; then fresh chat
   `/ultra-plan` + `/goal` on that named slice.
3. **PROTECTED / RETRACTED:** inventing ship; Lovelace rebuild; `.worktrees/`;
   D-111; claim inflation; unapproved `src/`.

## Blockers / Open Questions

No DRM implementation blocker. Material condition for new work = owner G0.

## Gotchas & Failed Approaches

- Stale LOOP “merge #393” after #393 already on main — do not treat as current.
- Do not invent G0 from ROADMAP; do not rebuild closed #5.
- Prefer owner-named ship over endless tip-idle SHA-churn.
- Scoped timing ratios ≠ general Nx ≠ q4 2.18×.

## Files Created / Modified

- `docs/dev-log/handover/2026-08-05-cursor-handover-drm-idle-after-393.md` (this)
- `LOOP/{GOAL,arcs,checkpoint,ultra-plan}.md`
- `docs/dev-log/plans/2026-08-05-tip-idle-after-393-ultra-plan.md`
- `docs/dev-log/check-log.d/2026-08-05-tip-idle-after-393.md`
- `docs/dev-log/after-task/2026-08-05-tip-idle-after-393.md`

## How to Resume (Cursor)

```bash
cd "/Users/z3437171/Dropbox/Github Local/DRM.jl"
export PATH="$HOME/.juliaup/bin:$PATH"
```

1. `"$HOME/Dropbox/Github Local/Shinichi/tools/lane_preflight.sh" .`
2. `git fetch origin && git status -sb && git log --oneline -8 origin/main`
3. Confirm tip `e32a2c6` (or newer tip-idle merge) and #393 MERGED.
4. Read `AGENTS.md` → `HANDOVER.md` → `LOOP/checkpoint.md` → this handover.
5. Classify; execute only **OWED**. Stay on **DRM.jl** unless owner names twin lane.

Safe verify (future scoped change): `julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.test()'`.
Optional: `DRM_PARITY_TESTS=1`. Never stage `.worktrees/`.

### Mission control (DRM only)

| Repo | Tip | State |
|---|---|---|
| DRM.jl | `origin/main` `e32a2c6` + this docs PR | Idle — owner G0 only |
| Vault MC drmTMB | tip idle after #393 | Julia twin: owner G0 |

### One-command resume

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-05-cursor-handover-drm-idle-after-393.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```

*Shannon · Ada · Rose. DRM.jl lane only. No nested subagents.*
