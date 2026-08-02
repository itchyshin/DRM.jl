# Session Handoff: DRM.jl Phase 1.0 SCOPED closeout → idle tip

Meta: 2026-08-02 · from **Cursor** (Shannon) · TARGET **Cursor** · AUTHOR **cursor** · context n/a (arc close)

You are **Cursor**, picking up after SCOPED Phase 1.0 remainder closed on
`origin/main`. Inherit **no** chat history. Rehydrate from git + this file.
Classify every item below **`OWED` · `DONE` · `RETRACTED` · `PROTECTED`**;
execute only `OWED`.

**Supersedes** the tip pointer in
[`2026-08-01-cursor-handover.md`](2026-08-01-cursor-handover.md) (Phase 1.5 /
registry→bridge idle). That doc remains historical; **START HERE is this file**.

## Critical Context

1. **Phase 1.0 SCOPED is LANDED.** PR
   [#359](https://github.com/itchyshin/DRM.jl/pull/359) **MERGED** @
   **`e6c3eef`** (`Merge pull request #359 from itchyshin/feat/phase10-scoped-13-jet`).
   Issues **#13**, **#338**, **#3** are **CLOSED** via that PR.
2. **#13 verdict = FAIL (honest).** `fit_em_natgrad` stalls at logLik
   **−259.795539** vs sparse-TMB ref **−256.512618** (Δ≈3.28). Action taken:
   extract **`lc_metric`** infra + close JET Workflow Q gap; **do not** expose
   `algorithm = :natgrad`. Evidence:
   `docs/dev-log/plans/2026-08-01-natgrad-decision-gate.md`.
3. **Tip-honesty already merged** before #359: DRM.jl
   [#358](https://github.com/itchyshin/DRM.jl/pull/358) + drmTMB
   [#887](https://github.com/itchyshin/drmTMB/pull/887).
4. **D-111 fence (PROTECTED):** Julia General / JuliaRegistrator remain **OUT**.
   Do **not** `@JuliaRegistrator register`, chase AutoMerge, or invent ship work.
5. **DRM.jl tip is IDLE.** Owner moves to a **new arc in a different lane**
   (not DRM.jl ship work). Do **not** invent the next DRM goal.

## Goals / mission (if applicable)

Mission (stable): fastest correct engine for the drmTMB model class; formula
parity; MIT twin (never vendor GPL). This session closed SCOPED Phase 1.0
(#13 gate → lc_metric + JET; park leftovers; close #338/#3). No further DRM
LOOP goal is open.

## Plans / roadmap (if applicable)

Beyond this idle tip: optional deeper work (#136 VA, fuller experimental wire,
AI-REML using `lc_metric`, etc.) only if **Shinichi opens a new goal** —
likely in another repo/lane. Ultra-plan text may still list Registrator / FULL
wire — **`LOOP/GOAL.md` for the closed arc + this handover win**; D-111 holds.

## What Was Accomplished

- **S0** #13 decision gate → **FAIL** (ng −259.80 vs ref −256.51).
- **S1b** `src/lc_metric.jl` + `test/test_lc_metric.jl`; experimental
  `fit_em_natgrad.jl` kept unwired with FAIL note; **no** `:natgrad` public API.
- **S2** JET Workflow Q gate (`test/test_qgate_jet.jl` + JET in `test/Project.toml`);
  ROADMAP Q ticks refreshed.
- **S3** Park leftover `experimental/` in tip docs; close #338 (capability-status
  already on tip).
- **S4–S5** Local smoke + Rose PASS in
  `docs/dev-log/after-task/2026-08-01-phase10-scoped-13-jet.md`.
- **Melissa** plan-actual:
  `docs/dev-log/plan-actual/2026-08-01-phase10-remainder.md`.
- **#359** merged @ `e6c3eef`; closes #13 / #338 / #3.
- Prior: Phase 1.5 #5 closed; tip-honesty #358 + drmTMB #887 merged.

## Current Working State

- **Working:** `origin/main` @ **`e6c3eef`** (or later after this handover PR);
  open ship PRs for this arc: **none**. Tip idle.
- **In progress:** none on DRM.jl ship lane.
- **Not working / blocked:** nothing owed for DRM ship. Local `.worktrees/` and
  stale unpushed branches are noise (see Landing State) — not arc debt.

## Key Decisions & Rationale

| Decision | Why |
|---|---|
| **#13 FAIL → S1b** | Natgrad stalls; design says wire only on MLE parity; extract Fisher `lc_metric` instead. |
| **No `:natgrad` public API** | Would oversell a stalling EM; Rose bar. |
| **SCOPED #3** (not FULL wire) | GOAL overrode dump-all-experimental; park leftovers honestly. |
| **D-111** — General OUT | Owner: catch up with drmTMB + both working; CRAN-first likely. |
| **Idle tip / new arc elsewhere** | Owner: move and start a new arc in a **different lane** — do not invent DRM ship work. |
| Melissa hub-only | Standing closeout persona; not a DRM.jl in-repo Cursor agent. |
| AGENTS fence | Never dump commits `a4585bd` / `7520d9d` / `88a2382` / `66514a0` into ship PRs. |

## Landing State

`tools/handoff_gate.sh` (Shinichi / shinichi-brain) **FAIL** at write time —
unlanded local noise declared below (not arc debt). `lane_preflight.sh`: no
foreign Codex ship lane detected (weak evidence; D-87).

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| `DRM.jl` `origin/main` **`e6c3eef`** (#359 + tip-honesty #358 + prior) | y | y | #359/#358 merged; #13/#338/#3 closed | **LANDED** |
| This handover `handover/2026-08-02-cursor` | y (this PR) | y (with PR) | open (human merges) | **LANDED** when PR merges |
| Untracked `?? .worktrees/` (local worktree roots under repo) | n | n | none | **CARRIED-OVER** — never stage; house rule: worktrees stay in `./.worktrees/`. Resume: leave alone |
| Stale local-only / unpushed branches (gate listed e.g. `chore/worktree-house-rule`, `claude/capability-status-parity`, `codex/*`, `docs/rose-*`, `drmjl/*`, `ranef-slope-*`, `shannon/*`, `worktree-agent-*`, …) | mixed | n | none for this arc | **CARRIED-OVER** — prior-lane WIP; **not** this closeout. Do not dump into ship PRs. Resume: ignore unless Shinichi names a branch |

## Next Immediate Steps

Classify on resume. Prefer **idle on DRM.jl**.

1. **DONE (arc):** SCOPED Phase 1.0 — #359 merged; #13/#338/#3 closed. Do not re-run the natgrad gate as ship work.
2. **DONE (tip honesty):** #358 + drmTMB #887 merged.
3. **RETRACTED / PROTECTED:** JuliaRegistrator / General chase; dumping AGENTS fence commits; inventing `algorithm=:natgrad`; engine/`src/` edits without owner; reopening #13/#3 as unfinished ship debt.
4. **OWED (default):** **Idle tip.** Do not invent DRM.jl ship work. A **new goal/arc** starts only if Shinichi opens it — and owner said that arc is in a **different lane**, not DRM.jl.
5. **OWED (hygiene only if asked):** leave `.worktrees/` alone; do not stage it.

## Blockers / Open Questions

- None for Registrator (cancelled — do not ask for app install).
- Public bridge claims stay experimental.
- If a General PR appears: report URL; do not merge.
- Next DRM work needs an **owner-opened** goal — none is open.

## Gotchas & Failed Approaches

- Do **not** treat natgrad’s faster wall-clock as a win — it stalls away from the MLE (−259.80 ≠ −256.51).
- Do **not** treat `v0.1.2` as General-registered.
- Ultra-plan / stale LOOP checkbox text may still look open — trust **merged #359**, closed issues, and this handover over unchecked GOAL boxes left in-tree.
- Coordination board Active branches table is stale (2026-06 era); trust Issues + `gh pr list` + this handover.
- `.worktrees/` is untracked local state — invisible on `origin`; never `git add` it.
- Prior handover `2026-08-01-cursor-handover.md` described pre-#359 idle after Phase 1.5 — **superseded** for the START HERE pointer.

## Files Created / Modified (this handover slice)

- `docs/dev-log/handover/2026-08-02-cursor-handover.md` (this file)
- `LOOP/checkpoint.md` (idle tip + START HERE pointer refresh)

Prior Phase 1.0 paths (already on `main` @ `e6c3eef` — do not redo):
`src/lc_metric.jl`, `test/test_lc_metric.jl`, `test/test_qgate_jet.jl`,
`src/experimental/fit_em_natgrad.jl`, Workflow Q.js, HANDOVER/ROADMAP/README/LOOP,
after-task / plan-actual / natgrad decision-gate under `docs/dev-log/`.

## How to Resume (Cursor)

Working directory:

```bash
cd "/Users/z3437171/Dropbox/Github Local/DRM.jl"
```

Environment / toolchain:

```bash
export PATH="$HOME/.juliaup/bin:$PATH"
# Optional R↔Julia parity (skip-guarded if unset):
# export DRM_PARITY_TESTS=1
```

Rehydrate order:

1. `"/Users/z3437171/Dropbox/Github Local/Shinichi/tools/lane_preflight.sh" .`
2. `git fetch origin && git status -sb && git log --oneline -8 origin/main`
3. Read `AGENTS.md` → `HANDOVER.md` → `LOOP/checkpoint.md` → **this file**
   (`LOOP/GOAL.md` is the closed Phase 1.0 SCOPED card — historical)
4. Classify Next Immediate Steps → execute **only OWED**
5. Expect OWED = idle / wait for owner’s different-lane arc — not invent DRM ship work

Safe verification (docs/idle tip — no engine change expected):

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate(); Pkg.test()'
# Smoke-only on laptop; Totoro for multi-shape / heavy parity.
```

Do **not** stage: `.worktrees/`, secrets, AGENTS fence commits listed above,
foreign untracked trees, anything outside an explicit docs PR path list.

### Mission control (in-doc)

| Repo | Tip / branch | CI | Shipped | Plan by leverage |
|---|---|---|---|---|
| DRM.jl | `origin/main` @ `e6c3eef` (+ this handover PR) | expect green on docs PR | Phase 1.0 SCOPED #359 (#13 FAIL→lc_metric+JET; #338/#3 closed) + tip-honesty #358 | **Idle tip**; new arc elsewhere (owner) |
| drmTMB (paired) | #887 tip-honesty merged; #878 Phase 1.5 | n/a here | `engine=julia` experimental | CRAN-first likely before any Julia General |

### One-command resume (paste into a fresh Cursor agent)

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-02-cursor-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```

*Shannon · perspectives: Ada (coord) + Rose (fence). No spawned subagents. No Registrator. No engine changes. DRM.jl tip idle — new arc in a different lane.*
