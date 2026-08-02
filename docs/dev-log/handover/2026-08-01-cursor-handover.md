# Session Handoff: DRM.jl Phase 1.5 / registry→bridge LOOP closeout

Meta: 2026-08-01 · from **Cursor** (Shannon) · TARGET **Cursor** · context n/a (arc close)

You are **Cursor**, picking up DRM.jl after the Phase 1.5 / registry→bridge LOOP
arc. Inherit **no** chat history. Rehydrate from git + this file. Classify every
item below **`OWED` · `DONE` · `RETRACTED` · `PROTECTED`**; execute only `OWED`.

## Critical Context

1. **Arc closed.** Phase 1.5 bridge closeout is DONE: #5 CLOSED; DRM.jl #349 +
   drmTMB #878 merged; Rose PASS (experimental bar). Tip hygiene #352, Cursor
   agents #353, checkpoint #354, Melissa S8 plan-actual #356 all **MERGED**.
   `origin/main` tip at write time: **`1c49656`** (Merge #356) or later.
2. **D-111 fence (PROTECTED):** Julia General / JuliaRegistrator are **OUT**
   until R-twin catch-up **and** both halves working well; **drmTMB likely goes
   CRAN first**. Do **not** post `@JuliaRegistrator register`, chase AutoMerge,
   or merge a surprise General PR (report URL only). `v0.1.2` / tag `v0.1.2` =
   git only — **not** General membership. Distribute via GitHub / `Pkg.develop`.

## Goals / mission (if applicable)

Mission (stable): fastest correct engine for the drmTMB model class; formula
parity; MIT twin (never vendor GPL). This LOOP pursued Phase 1.5 #5 close + tip
honesty with General explicitly cancelled (D-111).

## Plans / roadmap (if applicable)

Beyond this idle tip: optional deeper Hopper R-parity (#17) only if Shinichi
opens it; Phase 3 articles / VA (#136) remain deferred. No new LOOP goal until
owner opens one. Do not invent ship work.

## What Was Accomplished

- S2–S3 hygiene + tip verify; version **0.1.2** / `v0.1.2` (git tag only).
- **S4 CANCELLED** (D-111) — #352 fenced General out of scope @ `6d73539`.
- **S5** Hopper finish-matrix: DRM.jl #349 @ `d296703` + drmTMB #878 @ `fb59cd3`;
  Rose PASS @ `docs/dev-log/plans/rose-phase15-5-verdict-2026-08-01.md`; **#5 CLOSED**.
- **#353** Cursor project agents (Ada/Rose/Noether/Hopper) @ `14cec07`.
- **#354** tip checkpoint hygiene @ `81e02c7`.
- **#356** Melissa S8 plan-actual @ `1c49656` —
  `docs/dev-log/plan-actual/2026-08-01-registry-bridge.md` (clean-with-adaptations;
  zero drift rows).
- Mission Control `drmTMB.json`: idle / off Registrator.
- Melissa = hub standing closeout (not one of DRM’s 12); `~/.cursor/agents/melissa.md`
  exists — do **not** add Melissa under DRM.jl `.cursor/agents/`.

## Current Working State

- **Working:** `origin/main` @ `1c49656` (or later); LOOP S0–S8 checked; #5 closed;
  open PRs for this arc: **none expected**.
- **In progress:** none for this arc.
- **Not working / blocked:** nothing owed for ship. Optional non-blocking Rose
  nit only (see Next).

## Key Decisions & Rationale

| Decision | Why |
|---|---|
| **D-111** — General OUT | Owner: catch up with drmTMB + both working; CRAN-first likely. Tip-green ≠ registered. |
| Q2 **SCOPED** (not FULL `#3`) | GOAL overrode ultra-plan; avoid swallowing bridge closeout with experimental wire. |
| Bridge claims stay **experimental** | Rose #5 bar; vignette / CRAN Depends fences hold. |
| Melissa hub-only | Standing closeout persona; not a DRM.jl in-repo Cursor agent. |
| AGENTS fence | Never dump commits `a4585bd` / `7520d9d` / `88a2382` / `66514a0` into ship PRs. |

## Landing State

`handoff_gate.sh` (Shinichi tools) **FAIL** at write time — unlanded local noise
declared below (not arc debt). Paste/annotate:

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| `DRM.jl` `origin/main` `1c49656` (#356 + prior arc merges) | y | y | #349/#352/#353/#354/#356 merged; #5 closed | **LANDED** |
| This handover `handover/2026-08-01-cursor` | y (this PR) | y (with PR) | open (human merges) | **LANDED** when PR merges |
| Untracked `?? .worktrees/` (local worktree roots under repo) | n | n | none | **CARRIED-OVER** — never stage; house rule: worktrees stay in `./.worktrees/`. Resume: leave alone or `echo '/.worktrees/' >> .gitignore` in a separate hygiene PR if desired |
| Stale local-only / unpushed branches (gate listed e.g. `chore/worktree-house-rule`, `claude/capability-status-parity`, `codex/local-qgate-fd-gradient`, `codex/q4-bridge-vcov-skip`, `drmjl/sigma-phylo-reml-beta-psi-fix`, `ranef-slope-*`, `shannon/*`, `worktree-agent-*`, …) | mixed | n | none for this arc | **CARRIED-OVER** — prior-lane WIP; **not** this closeout. Do not dump into ship PRs. Resume: ignore unless Shinichi names a branch |

## Next Immediate Steps

Classify on resume. Prefer idle.

1. **DONE (arc):** Phase 1.5 / registry→bridge LOOP — no further LOOP steps.
2. **DONE (tip honesty):** Rose nit — uni `r_bridge_status` aligned to
   `experimental` where `claim_status=partial`; ROADMAP/HANDOVER/README #17/#5
   closed wording refreshed (follow-up PR after this handover landed).
3. **RETRACTED / PROTECTED:** JuliaRegistrator / General chase; dumping AGENTS
   fence commits; engine/`src/` edits; opening #136/#291/#13 without owner.
4. **Default:** arc closed; next is a **new goal** from Shinichi — do not invent
   one. (#17 is already closed; do not reopen casually.)

## Blockers / Open Questions

- None for Registrator (cancelled — do not ask for app install).
- Public bridge claims stay experimental.
- If a General PR appears: report URL; do not merge.

## Gotchas & Failed Approaches

- Do **not** treat `v0.1.2` as General-registered.
- Ultra-plan may still mention Registrator / Q2 FULL — **`LOOP/GOAL.md` wins**.
- Coordination board Active branches table is stale (2026-06 era); trust Issues +
  `gh pr list` + this handover for current lane state.
- `.worktrees/` is untracked local state — invisible on `origin`; never `git add` it.

## Files Created / Modified (this handover slice)

- `docs/dev-log/handover/2026-08-01-cursor-handover.md` (this file)
- `LOOP/checkpoint.md` (tip SHA + START HERE pointer refresh)

Prior arc paths (already on `main` — do not redo): LOOP/*, HANDOVER.md, README.md,
`.cursor/agents/{ada,rose,noether,hopper}.md`, after-task/check-log/plan-actual
`2026-08-01-*`, Rose verdict + bridge matrix under `docs/dev-log/plans/`.

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
3. Read `AGENTS.md` → `HANDOVER.md` → `LOOP/GOAL.md` → `LOOP/checkpoint.md` → **this file**
4. Classify Next Immediate Steps → execute **only OWED**

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
| DRM.jl | `origin/main` @ `1c49656` (+ this handover PR) | expect green on docs PR | Phase 1.5 #5 + D-111 fence + agents + Melissa S8 | Idle; optional Rose nit; else new goal |
| drmTMB (paired) | #878 merged; MC idle | n/a here | `engine=julia` experimental finish | CRAN-first likely before any Julia General |

### One-command resume (paste into a fresh Cursor agent)

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-01-cursor-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```

*Shannon · perspectives: Ada (coord) + Rose (fence). No spawned subagents. No Registrator. No engine changes.*
