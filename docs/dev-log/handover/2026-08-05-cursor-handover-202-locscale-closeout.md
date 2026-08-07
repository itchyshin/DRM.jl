# Session Handoff: DRM.jl #202 locscale closeout — mid-flight

Meta: 2026-08-05 · from **Cursor** (Shannon) · TARGET **Cursor** · AUTHOR **cursor**

You are **Cursor**, picking up **DRM.jl only**. You inherit no chat context.
Rehydrate from the repository and classify every item below
**`OWED` · `DONE` · `RETRACTED` · `PROTECTED`**; execute only `OWED`.

**Lane fence:** active ship lane is **#202 non-Gaussian phylo location–scale
closeout** on branch `feat/202-locscale-closeout`. Do not open tip-idle hygiene,
Registrator, Lovelace rebuild, or other subjects from chat memory.

**Supersedes as START HERE:**
[`2026-08-05-cursor-handover-drm-idle-after-393.md`](2026-08-05-cursor-handover-drm-idle-after-393.md)
for *this* DRM ship lane. That idle note remains historical for tip-at-rest;
`origin/main` @ `7bfe609` is still the idle tip until this PR merges.

## Critical Context

1. **G0 APPROVED** for #202 closeout (judgment defaults):
   - **Grammar B:** `(1 | p | phylo(species))` on both axes.
   - Dual issue-text `phylo(1|sp)` on both axes (**A**) is **out of cohort**.
   - **D-94:** ship public phylo locscale; defer R `nbinom2-locscale` fixture
     until drmTMB supports coupled `(1|p|species)`.
2. **Not greenfield.** Engine already in `src/locscale_*.jl`; Gamma private
   recovery + FD in `test/test_phylo_locscale.jl` (PR #253). Gap was public
   `tree=` forward + public evidence + ledger close.
3. **RECON proved:** A errors (“only mean may carry RE”); B parses
   `structkind=:phylo` but failed with `needs tree=` because NB2/Gamma did not
   forward `tree=` into `_fit_locscale_frontend`; iid B fits.
4. **S1 code is on the branch** (forward `tree/K/A/coords`, stale #209 comment
   fixed, `test/test_public_phylo_locscale.jl` added) — **Julia recovery test
   was interrupted / never log-verified**. Do not claim green until you read
   the test log.
5. **Accidental `.worktrees/` gitlinks** were staged in checkpoint
   `8c6e961a` — must be removed before PR (this handoff lands that fix).
6. **Fences:** no q=4 core edits; D-111 OFF; never stage `.worktrees/`; no GPL;
   no #49/#136; no tip-idle padding.

## Goals / mission

DRM.jl = MIT Julia twin of drmTMB. Close or honestly re-scope open **#202** by
landing public phylo location–scale (NB2 primary) + docs/capability + DoD PR.

## Plans / roadmap

Authoritative: `LOOP/ultra-plan.md` /
`docs/dev-log/plans/2026-08-05-202-locscale-closeout-ultra-plan.md`.
After #202 closes: tip returns to IDLE / owner next G0 (not invent from ROADMAP).

## What Was Accomplished (this lane)

- Ultra-plan + Arc Card; G0 with grammar B + D-94 defaults.
- LOOP scaffold commit `3addf4aa`.
- RECON probes (A fail / B needs tree= / B-iid OK).
- S1 implementation on branch: `src/negbinomial.jl`, `src/gamma.jl`,
  `src/locscale_frontend.jl`, `test/test_public_phylo_locscale.jl`,
  `test/runtests.jl` include.
- Handoff: strip bad `.worktrees/` gitlinks; ignore `/.worktrees/`.

## Current Working State

- **Working:** branch `feat/202-locscale-closeout` (ahead of `origin/main`).
- **In progress:** S2 verify → S3 Gamma honesty → S4 capability/tutorial/NEWS →
  Rose → PR `closes #202` (**L2 merge gate**).
- **Blocked:** none DRM-impl — only missing local/CI verify of the new test.
- **Evidence owed:** `julia --project=. test/test_public_phylo_locscale.jl` log
  (recovery + Gamma public smoke + A still throws).

## Key Decisions & Rationale

| Decision | Rationale |
|---|---|
| Grammar B not A | drmTMB-style coupled tag; A would fight Boole / existing guards |
| Defer R nbinom2-locscale fixture | generator still skips coupled `(1\|p\|·)` for nbinom2 |
| Closeout not kernel rewrite | locscale engine + private Gamma gate already exist |
| Never stage `.worktrees/` | foreign local checkouts; D-111 / lane fence |

## Landing State

`handoff_gate.sh` **GATE FAIL** until push — every failure declared:

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| `origin/main` `7bfe609` | y | y | #394 MERGED | **LANDED** (idle tip) |
| `feat/202-locscale-closeout` S1+LOOP | y | **push with this handoff** | none yet | **CARRIED-OVER → land push** |
| `.worktrees/` gitlinks in `8c6e961a` | bad | n | n | **FIXED** in handoff commit (rm + gitignore) |
| `?? .worktrees/` on disk | n | n | none | **PROTECTED** / never stage |
| Stale foreign branches (many unpushed) | mixed | n | none | **CARRIED-OVER** — ignore unless named |
| Public test Julia log | n | n | n | **OWED** — first resume step |

## OWED / classification

| Item | State |
|---|---|
| Run `test/test_public_phylo_locscale.jl`; fix until green (log not exit code) | **OWED** |
| S3: Gamma public honesty (covered by same test smoke or docs) | **OWED** |
| S4: capability-status row + tutorial + NEWS; disposition #202 | **OWED** |
| check-log.d + after-task + Rose; open PR `closes #202` | **OWED** |
| Owner merge of that PR | **OWED** (L2 human gate) |
| Rebuild q=2 kernel / touch q=4 core | **RETRACTED** |
| Implement grammar A dual-phylo alias | **RETRACTED** (unless under-run + owner) |
| Generate R nbinom2-locscale fixture | **RETRACTED** / deferred |
| Registrator / D-111 / tip-idle SHA-churn | **PROTECTED** |
| Stage `.worktrees/` | **PROTECTED** |

## Next Immediate Steps

1. `git fetch origin && git checkout feat/202-locscale-closeout && git pull` (if pushed).
2. `export PATH="$HOME/.juliaup/bin:$PATH"`
3. `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 julia --project=. test/test_public_phylo_locscale.jl`
   — **read the log**; repair if recovery tols fail (may need Totoro for large fixture).
4. S4 docs: `docs/design/capability-status.md` row for non-Gaussian phylo
   location–scale; tutorial note; NEWS; update #202 body honesty (B grammar).
5. DoD: `docs/dev-log/check-log.d/` + `after-task/`; Rose pass; `gh pr create`
   with `closes #202`. **Pause for owner merge.**
6. After merge: tip-idle START HERE refresh only if owner asks (prefer ship over hygiene).

## Blockers / Open Questions

- None blocking resume. If NB2 recovery is flaky at p=40/m=20, shrink fixture or
  run on Totoro — do not invent a second estimand.
- Optional under-run: grammar A as soft alias — **only if owner renames**.

## Gotchas & Failed Approaches

- Stale comment “phylo waits on #209” was wrong — #209 CLOSED; fix is on branch.
- Checkpoint `8c6e961a` title is opaque and briefly added `.worktrees/` gitlinks —
  stripped in this handoff commit; do not re-add.
- `git add -A` is forbidden; never stage `.worktrees/`.
- Private `test_phylo_locscale.jl` / `test_locscale_phylo_e2e.jl` ≠ public API proof.

## Files Created / Modified (session / branch)

- `LOOP/{GOAL,arcs,checkpoint,ultra-plan}.md`
- `docs/dev-log/plans/2026-08-05-202-locscale-closeout-ultra-plan.md`
- `src/negbinomial.jl` — forward structured kwargs; docstring example
- `src/gamma.jl` — forward structured kwargs
- `src/locscale_frontend.jl` — comment + error string
- `test/test_public_phylo_locscale.jl` — **new**
- `test/runtests.jl` — include new test
- `.gitignore` — `/.worktrees/`
- `docs/dev-log/handover/2026-08-05-cursor-handover-202-locscale-closeout.md` (this)

## How to Resume (Cursor)

```bash
cd "/Users/z3437171/Dropbox/Github Local/DRM.jl"
export PATH="$HOME/.juliaup/bin:$PATH"
```

1. `"$HOME/Dropbox/Github Local/Shinichi/tools/lane_preflight.sh" .` (or vault twin)
2. `git fetch origin && git checkout feat/202-locscale-closeout && git status -sb`
3. Read `AGENTS.md` → `LOOP/GOAL.md` → `LOOP/checkpoint.md` → this handover →
   `LOOP/ultra-plan.md`
4. Classify; execute only **OWED**. Stay on DRM.jl.

Safe verify (first):

```bash
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 julia --project=. test/test_public_phylo_locscale.jl
```

Never stage `.worktrees/`. No q=4 core. No Registrator.

### Mission control (DRM only)

| Repo | Tip / branch | State |
|---|---|---|
| DRM.jl main | `7bfe609` | Idle until #202 PR merges |
| DRM.jl ship | `feat/202-locscale-closeout` | Mid-flight closeout — verify then PR |

### One-command resume

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-05-cursor-handover-202-locscale-closeout.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```

*Shannon · Ada · Noether · Rose. DRM.jl #202 lane only. No nested subagents.*
