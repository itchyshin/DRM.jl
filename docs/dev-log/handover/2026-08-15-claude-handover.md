# Session Handoff: DRM.jl ↔ drmTMB catch-up — arc-loop lane, A4c next

Meta: 2026-08-15 · from **Claude** (arc-loop lane) · TARGET **claude** · AUTHOR **claude**

You are **Claude Code**, picking up **DRM.jl** with **no chat context**. Rehydrate
from this repository + current git state. Classify every item
**`OWED` · `DONE` · `RETRACTED` · `PROTECTED`**; execute only `OWED`.

**Lane fence:** this is the **`engine = "julia"` catch-up campaign**, running as an
`/arc-loop` in a bounded worktree. Work happens in the **lane worktree**, not the
Dropbox checkout. drmTMB is a **narrow lane** (three files) and its PR **must not
be merged**.

**Multi-lane — never skip:** a single pointer must not orphan a sibling.
Active-Lane-Split lives on
[`docs/dev-log/coordination-board.md`](../coordination-board.md). The sibling
**drmTMB `engine="julia"` Workflow G** lane is **unknown from here** — do not
claim it finished, and do not start it from this tree.

## Goals / mission

Close the **measured** drmTMB parity gaps in DRM.jl, each backed by a
native-vs-Julia parity fixture, **without ever claiming more than the twin does**.
The bar is [[DECISIONS#D-111]]: catch up with the R twin, both halves working.
**Julia General registration is NOT the goal** — D-111 forbids pursuing Registrator.

Anchor: **drmTMB 0.7.0, installed**. The twin moves fast (`origin/main` went
`f5ec53634` → `859c0f6e6` → `82cd00560` during the campaign). Re-run before
trusting any count:

```bash
python3 tools/parity_ledger.py --drmtmb ../drmTMB --ref origin/main
```

## Plans / roadmap

`LOOP/GOAL.md` (immutable), `LOOP/arcs.md` (arc list), `LOOP/checkpoint.md`
(resume pointer), `LOOP/ultra-plan.md` (approved G0 plan). **Read GOAL.md at the
top of every arc** — that is the arc-loop contract.

Remaining arcs: **A4c** (phylo penalty) → **A4d-1** (`corpair` marker) →
**A4d-2** (three accessors). Two owner gates are open (below).

## What Was Accomplished

Landed on `main` (PRs #408, #409, #410):

- **A0** parity ledger (`tools/parity_ledger.py`) + closure audit.
- **A1** guarded Hessian→covariance at **45 sites / 17 files**; fixed the
  boundary-singular crash that made drmTMB #406's CI red.
- **A2a** result-shape contract: the five "missing post-fit functions" collapse to
  **one** contract (per-dpar response-scale columns). Fixed a real defect —
  `zero_one_beta`'s `mu` dpar is the *interior beta* mean, not `fitted()`.
- **A3a** `biv_lognormal` — PARITY_PASS (coef 9.15e-07).
- **A3b** `biv_student` — PARITY_PASS (coef 3.12e-06); shared `ν`, `logm2` link.
- **A-fix** — the `biv_student` tolerance, reproduced on **Julia 1.12** locally.

On the lane branch, **not yet merged** (see Landing State):

- **A3c design** + **A3c-1** `gaussian_bernoulli` staged association.
- **A3c-2** all four remaining pair classes; **design correction** —
  `gaussian_nbinom2` is CLOSED FORM, so only **three** need quadrature.
- **A3c-3** `tools/parity_associate.R`; refuses non-converged frozen margins.
- **A-nb2** — **the most important fix of the campaign** (below).
- **A-sigma** — meta `V_known` + correct meta `sigma` dpar, **no API change**.
- **A-drmtmb** — drmTMB **PR #1032 OPEN, NOT MERGED**.
- **A4 design pass** — re-scoped **three of four** clusters.

## Current Working State

**Working:** `origin/main` @ `53ac6a70`. drmTMB **0.7.0 installed**; **Julia 1.12
installed** (`julia +1.12`). All parity harnesses green:
`parity_fixture.R` **7/7**, `parity_associate.R` **5/5**.

**In progress:** nothing mid-edit. Lane is clean and pushed.

**Blocked / gated:** two owner decisions (below) + #412 on CI.

## Key Decisions & Rationale

| Decision | Rationale |
|---|---|
| **A-nb2: the NB2 dispersion seed was on the wrong scale** | The MoM initialiser computes NB2 **size** `r`, but seeds `η_σ = log σ` where `r = exp(−2η_σ)`. The **−0.5 was missing at 6 sites**. Seeded σ=2.71 (size 0.136) where truth was size ≈2.8. It survived because LBFGS recovered on most data — **only a cross-implementation comparison exposed it**. After: staged parity **2/5 → 5/5**. |
| **A-sigma gate dissolved** | No API change needed: `τ` and `V_known` are recoverable **exactly** (1.1e-16) from what the fit already stores. My earlier framing (add `scales` keys, breaking `sigma()`) was wrong. |
| **A4a is not a family** | `categorical()` returns a `drm_impute_family` — **imputation**, belongs to **#49 PARKED**. |
| **A4b is R-side prep** | `make_mesh` validates a projected CRS via `sf` *before* any fit. Porting duplicates a step that never reaches the engine. |
| **`corpair` ≠ `corpairs`** | `corpair` is a formula **marker**; `corpairs` (already exported) is the post-fit accessor. Easy to conflate off a gap list. |
| **drmTMB PR never auto-merges** | 9 live lanes + open 0.7.0 release slice #959. Config **cannot** enforce this (`gh pr merge` patterns are global) — it is a discipline rule. |
| **One branch per arc; auto-merge is the LAST action** | Arming auto-merge then pushing more onto the branch happened **twice**; these two rules make it structurally impossible. |

## Files Created / Modified

**Lane branch `claude/lane-catchup`** (12 commits ahead of `origin/main`):

- `src/associate_pairs.jl` (A3c-1/2/3 — staged association, all 5 pair classes)
- `src/negbinomial.jl` (**A-nb2** — the −0.5 seed fix at 6 sites)
- `src/bridge.jl` (A-sigma — `_bridge_meta_parts`, `V_known`, meta `sigma` dpar)
- `src/DRM.jl`, `Project.toml` (QuadGK dep + compat)
- `test/test_associate_pairs.jl`, `test/test_nb2_dispersion_seed.jl`, `test/test_bridge.jl`, `test/runtests.jl`
- `tools/parity_associate.R`, `tools/parity_fixture.R`, `tools/parity_ledger.py`
- `docs/dev-log/design/2026-08-15-a3c-design-staged-association.md`
- `docs/dev-log/design/2026-08-15-a4-rescope.md`
- `docs/dev-log/evidence/2026-08-15-a3c3-nb2-margin-nonconvergence.md`
- `docs/dev-log/evidence/2026-08-15-anchor-070-reverification.md`
- `docs/dev-log/evidence/parity-associate.tsv`, `parity-fixtures.tsv`
- `docs/dev-log/check-log.d/2026-08-15-*.md` (5 entries)
- `docs/dev-log/after-task/2026-08-15-a3c1-staged-association.md`
- `LOOP/GOAL.md`, `LOOP/arcs.md`, `LOOP/checkpoint.md`, `LOOP/ultra-plan.md`
- **this handover** + `docs/dev-log/coordination-board.md` (Active-Lane-Split)

**drmTMB narrow lane** (`claude/julia-parity-evidence`, PR #1032):
`R/julia-bridge.R`, `inst/extdata/julia-capabilities.tsv`,
`docs/dev-log/dashboard/julia-capabilities.tsv` — **evidence citations only, no
status fields changed**. All three together because
`test-julia-gate-vs-engine.R` asserts they match.

## Landing State

`handoff_gate.sh` **GATE FAIL** — declared in full:

| Artifact / branch | Committed | Pushed | PR | State |
|---|---|---|---|---|
| `origin/main` @ `53ac6a70` | y | y | #408/#409/#410 MERGED | **LANDED** |
| `docs/a3c-design` | y | y | [#412](https://github.com/itchyshin/DRM.jl/pull/412) OPEN, auto-merge ARMED, CI running | **CARRIED-OVER** — lands itself when green. Resume: `gh pr checks 412 --repo itchyshin/DRM.jl` |
| `claude/lane-catchup` | y | y | **NO PR YET** | **CARRIED-OVER** — stacked under #412. Resume: open its PR **after #412 merges**, base `main` |
| drmTMB `claude/julia-parity-evidence` | y | y | [drmTMB #1032](https://github.com/itchyshin/drmTMB/pull/1032) OPEN | **CARRIED-OVER / PROTECTED** — **NEVER MERGE**. Owner-timing gate |
| `docs/github-auto-merge` | y | y | [#406](https://github.com/itchyshin/DRM.jl/pull/406) OPEN | **CARRIED-OVER** — pre-existing policy note; its old `test (1.10)` failure was the A1 defect, now fixed on main. Re-run its CI |
| ~20 stale local branches (`shannon/*`, `ranef-slope-*`, `worktree-agent-*`, `codex/*`, …) | mixed | n | none | **CARRIED-OVER** — pre-existing, not this campaign. **Do not checkout, delete, or force-push** |
| `?? .codex/agents/shannon-coordinator.toml` | n | n | none | **PROTECTED** — never stage |
| drmTMB Workflow G sibling lane | n/a | n/a | unknown | **CARRIED-OVER** — other repo; do not claim finished |

## OWED / classification

| Item | State |
|---|---|
| A0 · A1 · A2a · A3a · A3b · A-fix | **DONE** (merged) |
| A3c design · A3c-1 · A3c-2 · A3c-3 · A-nb2 · A-sigma · A4 design | **DONE** (on lane, unmerged) |
| A-drmtmb PR opened | **DONE** — and **PROTECTED** from merging |
| **A4c** — `drm_phylo_penalty` + `_sweep` | **OWED** — unblocked, no gate |
| **A4d-1** — `corpair` formula marker | **OWED** — grammar ⇒ `DRM_PARITY_TESTS=1` mandatory |
| **A4d-2** — `profile_targets`, `structured_effects`, `meta_vcov_bivariate` | **OWED** — assess each first |
| Open the lane PR once #412 merges | **OWED** |
| A4a `categorical` as a response family | **RETRACTED** — it is an imputation family ⇒ #49 |
| A4b `make_mesh`/`spatial_coords` port | **RETRACTED** pending owner confirm — R-side prep |
| Merging drmTMB #1032 | **PROTECTED** |
| #49 / FIML · Registrator · GPL vendoring · q=4 core · `.worktrees/` | **PROTECTED** |

## Next Immediate Steps

1. **OWED — rehydrate.** `"$HOME/shinichi-brain/tools/lane_preflight.sh" "/Users/z3437171/Dropbox/Github Local/DRM.jl"`,
   then `git fetch origin && git status -sb`. Read `LOOP/GOAL.md` →
   `LOOP/checkpoint.md` → `LOOP/arcs.md` → `AGENTS.md` → this doc. Re-run
   `tools/parity_ledger.py` — the twin moves.
2. **OWED — A4c.** `drm_phylo_penalty(sd_u, sd_alpha, cor_sd)` + `_sweep`
   (drmTMB `R/penalty.R`). A PC-prior-style penalty that **changes the
   objective** ⇒ genuine engine capability. Add a `parity_fixture.R` cell.
3. **OWED — A4d-1, then A4d-2.**
4. **OWED — open the lane PR** once #412 merges (base `main`, auto-merge only as
   the LAST action).
5. **ASK the owner** the two open gates (below) — do not decide them yourself.

## Blockers / Open Questions

**Two owner gates from the A4 design pass:**
1. **A4a → #49 PARKED?** Confirm `categorical` moves rather than being built as a
   response family.
2. **A4b → deliberately-not-ported?** Confirm `make_mesh`/`spatial_coords` are out
   of scope as R-side geospatial prep.

**Measurement problem:** the ledger's **22 export gaps** mixes *missing
capability* with things that **correctly live in R**, so the countdown overstates
the work. Recommend a `deliberately-not-ported` class in `tools/parity_ledger.py`.

**Unexplained, low priority:** one early single run at n=1200 gave
`gaussian_nbinom2` η ≈ 0.395 where the n=2000 5-seed study gives 0.539. Likely
that seed/n, never reproduced after the A-nb2 fix, but not fully explained.

## Gotchas & Failed Approaches

- **A self-consistent simulation cannot catch a shared-assumption bug.** I twice
  blamed my test DGP for NB2 attenuation. It was a real seed bug. The
  **cross-implementation** fixture is what settled it.
- **Tolerances must be MEASURED.** A bound fitted to one Julia 1.10 run failed on
  1.12. **Julia 1.12 is installed — reproduce, don't guess** (`julia +1.12`).
- **Not every drmTMB export needs a Julia twin.** Post-fit adequacy needed a
  *payload*; `make_mesh` is R-side prep. Export-name gaps ≠ capability gaps.
- **`corpair` (marker) vs `corpairs` (accessor)** — different objects.
- **Update all three registry copies together** or `test-julia-gate-vs-engine.R`
  breaks.
- **Never `git checkout` in the shared drmTMB tree** — use a worktree; it has 9
  live lanes.
- **The lane was once cut from the wrong commit**, missing prior arcs. Verify by
  **artefact** (`ls src/associate_pairs.jl`), not by the rebase's exit code.
- The Dropbox checkout produced a transient `.git/index.lock`; the lane lives on
  non-Dropbox scratch for that reason.

## How to Resume (Claude)

```bash
cd "/Users/z3437171/local-scratch/lanes/DRM.jl-catchup"   # the LANE, not Dropbox
export PATH="$HOME/.juliaup/bin:$PATH"
```

Safe verification (targeted; the full suite is ~40–56 min and CI runs it):

```bash
julia --project=. --startup-file=no -e 'using Pkg; Pkg.test(test_args=["associate"])'
DRM_JL_PATH=$(pwd) Rscript tools/parity_fixture.R
DRM_JL_PATH=$(pwd) Rscript tools/parity_associate.R
```

Grammar-touching arcs (A4d-1) **must** run `DRM_PARITY_TESTS=1`.

**Files not to stage:** `.worktrees/`, `.codex/agents/shannon-coordinator.toml`,
`intake/`, anything under a foreign worktree. Never unscoped `git add -A`.

### Mission control

| Repo | Tip / pointer | State |
|---|---|---|
| DRM.jl | `origin/main` `53ac6a70` | **ACTIVE** — arc-loop lane `claude/lane-catchup`; A4c next |
| DRM.jl #412 | `docs/a3c-design` | auto-merge ARMED, CI running |
| DRM.jl lane | `claude/lane-catchup` | pushed, **needs a PR after #412** |
| drmTMB #1032 | `claude/julia-parity-evidence` | **OPEN — NEVER MERGE** |
| #136 epic | OPEN | never `close`/`fix`/`resolve` near that number |
| #49 | PARKED | now also holds `categorical` |

### One-command resume

```text
Read AGENTS.md and docs/dev-log/handover/2026-08-15-claude-handover.md. Run the handover rehydration steps, reconcile them with the current git state, then continue only the OWED Next Immediate Steps.
```

*Shannon · Ada · Rose. No nested subagents were used. Claude is not auto-launched.*
