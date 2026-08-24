# Session Handoff: AGHQ + Cox–Reid landed; scout sequence STOP — Claude pickup

Meta: 2026-08-24 · from **Cursor** (Shannon) · TARGET **claude** · AUTHOR **cursor**

You are **Claude Code**, picking up **DRM.jl** with **no chat context**.
Rehydrate from this repository + current git state. Classify every item
**`OWED` · `DONE` · `RETRACTED` · `PROTECTED`**; execute only `OWED`.

**Lane fence:** Julia DRM.jl only. Engine slices **#449 AGHQ** and **#451 Cox–Reid
phylo** are **merged**. Scout sequence items 1–5 **STOP** (docs on `main`).
Do **not** restart AGHQ / Cox–Reid / scout work in this chat unless the owner
explicitly renames a G0. Shinichi is away for several days — default is **IDLE**
pending owner-named next G0.

**Supersedes as DRM.jl START HERE:**
[`2026-08-14-claude-handover-drm-idle.md`](2026-08-14-claude-handover-drm-idle.md)
and all earlier handovers — keep those files; banner them **historical**.

**Multi-lane — never skip:** Active-Lane-Split lives on
[`docs/dev-log/coordination-board.md`](../coordination-board.md). This file is
the DRM.jl Julia pointer only. **drmTMB** is a sibling repo — status unknown
from here; do not claim finished or start from this tree.

`AGENTS.md` has no Live Phase Snapshot block. Rehydrate via coordination-board
Active-Lane-Split + this START HERE + scout closure
[`docs/dev-log/check-log.d/2026-08-19-scout-sequence-closure.md`](../check-log.d/2026-08-19-scout-sequence-closure.md).

## Critical Context

1. **`origin/main` tip @ `6ee03fd`** (GitHub API 2026-08-24) =
   `6ee03fd554f462ce29824e2a30bbda7658346e1a` — Merge
   [#455](https://github.com/itchyshin/DRM.jl/pull/455) (scout #420/#406
   housekeeping). Confirm with `git fetch origin && git rev-parse origin/main`.
2. **Engine landed:** [#449](https://github.com/itchyshin/DRM.jl/pull/449)
   AGHQ lever-2 (closes #448) merged `93c3db6b`; [#451](https://github.com/itchyshin/DRM.jl/pull/451)
   Cox–Reid Poisson phylo Laplace (closes #450) merged `8c6d4f78`. Both on
   `main` before scout docs.
3. **Scout sequence 1–5 complete on `main`:** [#452](https://github.com/itchyshin/DRM.jl/pull/452)
   lever-extension (`aa9ce55f`), [#453](https://github.com/itchyshin/DRM.jl/pull/453)
   q4/#49 parked (`7f910e3d`), [#454](https://github.com/itchyshin/DRM.jl/pull/454)
   Cell D ADEMP pre-run (`9602399c`), [#455](https://github.com/itchyshin/DRM.jl/pull/455)
   #420/#406 housekeeping (`6ee03fd`). Closure table:
   `docs/dev-log/check-log.d/2026-08-19-scout-sequence-closure.md`.
4. **Capability chip AGHQ still `missing`.** Do not flip. No recovery headlines.
   Cite drmTMB −7.3 / −5.0 / −0.9 as **drmTMB's** only.
5. **Open PRs (only two):** [#420](https://github.com/itchyshin/DRM.jl/pull/420)
   and [#406](https://github.com/itchyshin/DRM.jl/pull/406) — both **DIRTY /
   CONFLICTING**; scout verdict **leave OPEN**. Do not rebase or merge while
   owner is away. See
   `docs/dev-log/plans/2026-08-19-420-406-housekeeping.md`.
6. **#49 / q4 / `reml_q4.jl`:** **PARKED** (scout #453). No edits.
7. **Optional next G0 (not started):** Binomial `(1|g)` Cox–Reid — draft only in
   `docs/dev-log/plans/2026-08-19-lever-extension-next-g0.md`. Needs issue +
   `/goal` + owner approval. Cell D Totoro ADEMP is a **separate campaign**
   (plan #454); do not start without new G0.

## Goals / mission

DRM.jl is the MIT Julia twin of drmTMB. This session finished the approved
**AGHQ lever-2** and **Cox–Reid phylo Laplace** engine slices, then ran the
**honesty scout sequence 1–5** and **STOP**ped before Shinichi's vacation.
Mission now: **desk-ready IDLE** — rehydrate, confirm landed state, **ask owner**
for the next G0 when they return.

Deferred menu (must stay visible):

- **#420 / #406** — owner decides after vacation (close-as-superseded vs docs rebase)
- **Binomial Cox–Reid** — scout recommendation only; not a queue item
- **Cell D ADEMP / Totoro** — scoped in plan #454; not started
- **#49** FIML — **PARKED**
- **#136** VA epic — **OPEN**; do not auto-close
- **drmTMB** `engine="julia"` — sibling repo
- **D-111** Julia General — **OFF**

## Plans / roadmap

No active `/goal` or `/arc-loop`. Plans on `main` (docs only):

| Plan | PR | Verdict |
|---|---|---|
| Lever extension | #452 merged | Next G0 candidate: Binomial Cox–Reid (draft) |
| q4 / #49 parked | #453 merged | **Keep PARKED** |
| Cell D ADEMP pre-run | #454 merged | Scope + STOP; Totoro ~1.5–4 h |
| #420 / #406 housekeeping | #455 merged | **Leave both OPEN** |

Do not invent G0 from `ROADMAP.md`.

## What Was Accomplished

- **#449** — DRM-native 1-D Liu–Pierce AGHQ; Poisson `(1|g)` opt-in
  `marginal=:AGHQ`, `nAGQ=5`; default `:LA` unchanged; `src/aghq_1d.jl` +
  `test/test_aghq_1d.jl`.
- **#451** — Opt-in Cox–Reid REML on Poisson phylo/relmat Laplace;
  `test/test_cox_reid_poisson_phylo.jl` (27 assertions, standalone).
- **Scout 1–5** — honesty/chip already on disk; plans #452–454 merged; closure
  #455 on `main`.
- **Worktrees torn down** — AGHQ / Cox–Reid / scout lanes removed from
  `~/local-scratch/lanes/`; use Dropbox canonical tree only.
- **This handover** — Cursor → Claude; shell gate **INCONCLUSIVE** in authoring
  session (see Landing State).

## Current Working State

- **Working:** `origin/main` @ **`6ee03fd`** (or newer). Engine + scout docs
  **LANDED**. Julia lane = **IDLE** / vacation STOP.
- **In progress:** this handover docs PR only (`handover/2026-08-24-claude`).
- **Not working / blocked:** Cursor shell returned no output — local gate/git
  unverified from authoring tool; Claude must re-run gate on pickup.
- **Open PRs:** #420, #406 only (foreign/stale; not this lane).

## Key Decisions & Rationale

| Decision | Rationale |
|---|---|
| AGHQ chip **missing** | Rose / capability-status honesty; opt-in plumbing only |
| ML default; `:REML` opt-in on phylo | #451 contract; Cell D ≠ recovery |
| Scout sequence STOP | Owner away; #453/#454 auto-merged before #455 |
| #420 / #406 leave OPEN | DIRTY conflicts; owner call after vacation |
| #49 PARKED | Scout #453; no `reml_q4.jl` campaign |
| No Totoro ADEMP without G0 | Plan #454 scope only |
| Do not re-merge #449 / reopen #448 | Already on `main` |
| D-111 OFF · no Julia General | Standing PROTECTED |

## Landing State

`handoff_gate.sh` — **INCONCLUSIVE** in Cursor authoring session (shell returned
empty output). Landing state from **GitHub API** + scout closure (2026-08-24).
Claude **OWED** to re-run gate locally.

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| `origin/main` `6ee03fd` | y | y | #455 MERGED | **LANDED** |
| #449 AGHQ engine | y | y | #449 MERGED `93c3db6b` | **LANDED** |
| #451 Cox–Reid phylo | y | y | #451 MERGED `8c6d4f78` | **LANDED** |
| #452 lever-extension scout | y | y | #452 MERGED | **LANDED** |
| #453 q4/#49 parked scout | y | y | #453 MERGED | **LANDED** |
| #454 Cell D pre-run plan | y | y | #454 MERGED | **LANDED** |
| #455 scout closure + #420/#406 plan | y | y | #455 MERGED | **LANDED** |
| #420 loop checkpoint docs | y | y | [#420](https://github.com/itchyshin/DRM.jl/pull/420) OPEN DIRTY | **CARRIED-OVER** — do not merge/rebase now. Resume: owner after vacation per `docs/dev-log/plans/2026-08-19-420-406-housekeeping.md` |
| #406 auto-merge policy files | y | y | [#406](https://github.com/itchyshin/DRM.jl/pull/406) OPEN DIRTY | **CARRIED-OVER** — same plan; policy text partially on `main` via coordination-board |
| `docs/dev-log/handover/2026-08-24-claude-handover.md` (this) | n→y on branch | n until push | this PR | **CARRIED-OVER** until PR merges |
| Stale local branches / worktrees | n/a | n/a | none | **CARRIED-OVER** — ignore unless owner names |
| `?? .codex/agents/shannon-coordinator.toml` | n | n | none | **PROTECTED** — never stage |
| drmTMB sibling | n/a | n/a | unknown | **CARRIED-OVER** — other repo |

## OWED / classification

| Item | State |
|---|---|
| Rehydrate + re-run `handoff_gate.sh` + classify vs git | **OWED** |
| Confirm `origin/main` ≥ `6ee03fd` and scout closure on disk | **OWED** |
| Confirm open PRs = #420, #406 only | **OWED** |
| **STOP** — ask owner for next G0 when they return | **OWED** |
| #449 / #451 engine work | **DONE** |
| Scout sequence 1–5 | **DONE** |
| Merge/rebase #420 / #406 from this chat | **RETRACTED** |
| Binomial Cox–Reid build without owner + issue + `/goal` | **RETRACTED** |
| Cell D Totoro ADEMP without new G0 | **RETRACTED** |
| Reopen #49 / edit `reml_q4.jl` | **RETRACTED** |
| Flip AGHQ capability chip | **RETRACTED** |
| Restart AGHQ / Cox–Reid lanes | **RETRACTED** |
| Stage `.worktrees/` / `intake/` / shannon-coordinator.toml | **PROTECTED** |
| Julia General / Registrator | **PROTECTED** — D-111 |

## Next Immediate Steps

1. **OWED — rehydrate.** Working directory:
   `cd "/Users/z3437171/Dropbox/Github Local/DRM.jl"`.
   Run `"$HOME/shinichi-brain/tools/lane_preflight.sh"` on that path, then
   `git fetch origin && git status -sb && git log --oneline -8 origin/main`.
   Run `"$HOME/shinichi-brain/tools/handoff_gate.sh"` on the same path; declare
   any failures not already in the Landing State table above.
2. **OWED — confirm STOP state.** Read `AGENTS.md` → `HANDOVER.md` →
   `docs/dev-log/coordination-board.md` → this handover → scout closure check-log.
   Verify: #449/#451/#452/#453/#454/#455 merged; AGHQ chip still `missing`;
   `gh pr list --state open` shows only #420 and #406.
3. **OWED — safe smoke (optional, fast).** After `git pull --ff-only` on `main`:
   ```bash
   export PATH="$HOME/.juliaup/bin:$PATH"
   julia --project=. --startup-file=no -e 'include("test/test_aghq_1d.jl")'
   julia --project=. --startup-file=no -e 'include("test/test_cox_reid_poisson_phylo.jl")'
   ```
4. **OWED — stop and ask.** When Shinichi returns, ask for **next G0**. Credible
   *candidates* (not a queue): #420/#406 housekeeping; Binomial Cox–Reid (needs
   issue); Cell D ADEMP (needs G0 + Totoro approval); stay idle.
5. **RETRACTED unless owner names:** anything in the table above marked RETRACTED
   or PROTECTED.

## Auto-merge policy (DRM.jl)

`allow_auto_merge` is **ON**. Docs-only PRs may use `gh pr merge N --auto --merge`.
**Pause** (no `--auto`) on `src/` engine, formula, version bump, `AGENTS.md` /
`CLAUDE.md`, unfinished epic, foreign lane. This handover PR is docs-only —
auto-merge OK after CI green; **do not self-merge** if policy says human merge
for handover kits (owner preference: open PR, human merges).

Required checks: `test (1.10)`, `test (1)`, `docs`. D-111 Julia General **OFF**.

## Blockers / Open Questions

- **Authoring tool:** Cursor shell could not run gate/git — Claude must verify locally.
- **Owner away:** no G0 until Shinichi names one in the new chat.
- **#420 / #406:** DIRTY — owner decides close vs rebase after vacation.
- **drmTMB sibling:** status unknown here.

## Gotchas & Failed Approaches

- Do **not** treat AGHQ k=1 or fitted loglik agreement as recovery evidence.
- `:REML` × `:AGHQ` is rejected; AGHQ fails on phylo by design.
- `test/test_cox_reid_poisson_phylo.jl` is **not** in `runtests.jl` by G0 design —
  run standalone for smoke.
- Scout closure check-log was written before #453/#454 merged — **main tip is
  newer**; trust git + GitHub over stale RESUME lines inside that file.
- LOOP/checkpoint pointers may still mention awaiting #451 — **historical**;
  #451 merged `8c6d4f78`.
- Full `Pkg.test()` ≈ 40–56 min — subset ≠ CI truth.
- Never `git add -A`. Never stage foreign coordinator toml.

## Files Created / Modified

**Already on `main` (engine + scouts):**

- `src/aghq_1d.jl`, `src/poisson.jl`, `src/sparse_laplace_glmm.jl`, `src/variational.jl`
- `test/test_aghq_1d.jl`, `test/test_cox_reid_poisson_phylo.jl`
- `docs/dev-log/plans/2026-08-19-{lever-extension-next-g0,cell-d-ademp-pre-run,q4-49-parked-scout,420-406-housekeeping}.md`
- `docs/dev-log/check-log.d/2026-08-19-scout-sequence-closure.md`
- `docs/design/capability-status.md` (AGHQ row `missing` — pre-existing honesty)

**This handover PR:**

- `docs/dev-log/handover/2026-08-24-claude-handover.md` (this)
- `docs/dev-log/coordination-board.md` (Active-Lane-Split refresh)

No new `src/` in this PR.

## How to Resume (Claude)

```bash
cd "/Users/z3437171/Dropbox/Github Local/DRM.jl"
export PATH="$HOME/.juliaup/bin:$PATH"
```

1. `"$HOME/shinichi-brain/tools/lane_preflight.sh" "/Users/z3437171/Dropbox/Github Local/DRM.jl"`
2. `"$HOME/shinichi-brain/tools/handoff_gate.sh" "/Users/z3437171/Dropbox/Github Local/DRM.jl"`
3. `git fetch origin && git status -sb && git log --oneline -8 origin/main`
4. Read `AGENTS.md` → `HANDOVER.md` → `docs/dev-log/coordination-board.md` → this file.
5. Classify; execute only **OWED**; **stop and ask** for next G0.

**Files not to stage:** `.worktrees/`, `.codex/agents/shannon-coordinator.toml`,
`intake/`, secrets. Never `git add -A`.

**Safe verify (after owner names code-changing G0):**

```bash
julia --project=. --startup-file=no -e 'using Pkg; Pkg.instantiate(); Pkg.test()'
```

### Mission control

| Repo | Tip / pointer | State |
|---|---|---|
| DRM.jl | `origin/main` `6ee03fd` + this handover PR | **IDLE** — engine + scouts **LANDED**; vacation STOP |
| Engine #449/#451 | on `main` | **DONE** — AGHQ + Cox–Reid phylo |
| Scout 1–5 | #452–#455 merged | **DONE** |
| #420 / #406 | OPEN DIRTY | **CARRIED-OVER** — owner after vacation |
| #49 / q4 | parked | **PARKED** |
| drmTMB (R) | sibling | **unknown** — do not start from here |

### One-command resume

Interactive:

```text
claude "Rehydrate from docs/dev-log/handover/2026-08-24-claude-handover.md + AGENTS.md, then continue with the Next Immediate Steps."
```

Paste-ready prompt for a fresh Claude session:

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-24-claude-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```

*Shannon · Ada · Rose. Cursor shell INCONCLUSIVE on gate — Claude verifies locally.*
