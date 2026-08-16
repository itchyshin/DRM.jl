# coordination-board.md — branch / PR overlap

Check this before editing shared files (`src/DRM.jl`, `AGENTS.md`, `CLAUDE.md`,
`ROADMAP.md`, `test/runtests.jl`, `docs/`). Record active branches + which files
they touch so two agents don't collide.

_Light tip refresh 2026-08-14 (`docs/claude-handover-idle`):
`origin/main` @ `d0fac9d7` (#405 MERGED). DRM.jl Julia = **IDLE** pending
owner G0. Next pickup = **Claude**. Cursor lane idle/handing off. Issue 136
stays OPEN (136e public Gamma RI report landed; VA stays Experimental).
#49 PARKED. drmTMB = **sibling** (status unknown here; do not claim finished;
do not start from this tree). 2026-08-13 Cursor idle handover is historical.
Live START HERE:
`docs/dev-log/handover/2026-08-14-claude-handover-drm-idle.md`.
Prior 2026-08-07 Phase 3 / #7 complete-with-carveouts still holds._

_GitHub auto-merge (2026-08-13, option A): `allow_auto_merge` is ON.
Agents may `gh pr merge N --auto --merge` after opening a PR. Pause
(no `--auto`) on `src/` engine / formula grammar / version bump /
`AGENTS.md` / `CLAUDE.md` / unfinished epic / foreign lane. Never put
close/fix/resolve next to `#NN` unless the slice is meant to finish
that issue. D-111 Julia General still OFF. Durable decision file is on
OPEN [#406](https://github.com/itchyshin/DRM.jl/pull/406) (BLOCKED on
CI `test (1.10)` at last check) until that PR lands._

## Active-Lane-Split (2026-08-16 — Claude lane HANDED OVER to Cursor)

_**START HERE:** `docs/dev-log/handover/2026-08-16-cursor-handover.md`, then
`LOOP/GOAL.md`. Working tree stays `~/local-scratch/lanes/DRM.jl-catchup`._

_**The ledger countdown reached 0 export gaps** (17 raw, 17 accounted for) —
`CLOSURE: PASS`. Read that as "no drmTMB export lacks a DRM.jl twin", **not** as
parity complete: 11 unsupported capability rows remain, each with a written
`claim_boundary`. Re-measure before trusting it._

_Landed 2026-08-15/16: #414 (A4c penalized-MAP phylo), #415 (A4d), #416 (A4e
ledger honesty), #417 (`check_drm` NaN vcov), #418 (A5), #419 (A6 tree scale).
`origin/main` = `0a4c2dc9`._

_**CARRIED-OVER — the CI queue is the binding constraint, not correctness.**
Five PRs open and `BLOCKED`: #420, #421, #423, #424, #425. Three branches pushed
with **no PR opened on purpose** (CI is PR-triggered, so a branch costs zero
queue): `docs/overnight-close-out`, `feat/a11-cross-family-formula`,
`feat/a12-biv-meta-recovery`. #406 is a **foreign** PR — untouched._

_**Tree-scale trap, worth knowing across lanes:** `ape::vcv(corr=TRUE)` gives
unit tip variance; raw Newick branch lengths give tip variance = tree height `h`.
A DGP that ignores this manufactures a convincing ~30% phylo variance-component
"bias" that is entirely the simulator's error (predicted −29.3%, observed
−29.4%). Suspect the DGP before the engine._

| Lane | Repo | State | Pointer |
|---|---|---|---|
| DRM.jl catch-up | this repo | **HANDED OVER** to Cursor; ledger at 0; 5 PRs blocked on CI, 3 branches unPR'd | `docs/dev-log/handover/2026-08-16-cursor-handover.md` · `LOOP/GOAL.md` |
| drmTMB bridge (narrow) | `/Users/z3437171/Dropbox/Github Local/drmTMB` | **#1049 + #1050 OPEN — NEVER MERGE UNATTENDED** (9 live lanes + release slice #959). #1032 and #1038 landed | drmTMB PRs #1049, #1050 |
| drmTMB `engine="julia"` Workflow G | `/Users/z3437171/Dropbox/Github Local/drmTMB` | **sibling — status UNKNOWN from here**; do not claim finished, do not start from DRM.jl | that repo's own handover |

## Active-Lane-Split (2026-08-15 — arc-loop lane ACTIVE)

_The `engine = "julia"` catch-up campaign runs as an **/arc-loop** in a bounded
worktree at `~/local-scratch/lanes/DRM.jl-catchup` on `claude/lane-catchup` (off
the Dropbox path). **START HERE:**
`docs/dev-log/handover/2026-08-15-claude-handover.md`, then `LOOP/GOAL.md`._

_Anchor: drmTMB **0.7.0 INSTALLED**. The twin moves fast — re-run
`python3 tools/parity_ledger.py --drmtmb ../drmTMB --ref origin/main` before
trusting any count. Landed via #408/#409/#410: A0, A1, A2a, A3a, A3b, A-fix.
On the lane, unmerged: A3c-1/2/3, **A-nb2**, A-sigma, A4-design. Next: **A4c**._

_**A-nb2 is worth knowing about across lanes:** DRM.jl's NB2 dispersion seed was
on the size scale rather than log-σ (the `-0.5` was missing at 6 sites), so NB2
fits could silently converge to the Poisson boundary. Fixed; it changes NB2
starting values everywhere. Found only by a cross-implementation parity fixture._

| Lane | Repo | State | Pointer |
|---|---|---|---|
| DRM.jl catch-up (arc-loop) | this repo | **ACTIVE** — `claude/lane-catchup`; A4c next; two owner gates open (A4a→#49, A4b→not-ported) | `docs/dev-log/handover/2026-08-15-claude-handover.md` · `LOOP/GOAL.md` |
| DRM.jl #412 | this repo | `docs/a3c-design` — auto-merge ARMED, CI running | PR #412 |
| drmTMB bridge (narrow) | `/Users/z3437171/Dropbox/Github Local/drmTMB` | **PR #1032 OPEN — NEVER MERGE** (9 live lanes + release slice #959). Evidence citations only, no status changed | drmTMB PR #1032 |
| drmTMB `engine="julia"` Workflow G | `/Users/z3437171/Dropbox/Github Local/drmTMB` | **sibling — status UNKNOWN from here**; do not claim finished, do not start from DRM.jl | that repo's own handover |
| DRM.jl (prior, historical) | this repo | superseded — tip-idle handover of 2026-08-14 | `docs/dev-log/handover/2026-08-14-claude-handover-drm-idle.md` |

Rehydrate must read **every** row. A single pointer must not orphan the drmTMB
sibling lane or the parked epics (#136 OPEN, #49 PARKED — which now also holds
`categorical`, an imputation family, not a response family).

## Lane split — Claude ↔ Codex

Full Codex brief: **#76** (pinned).

- **Claude (Shannon)** — family front-ends, post-fit, docs.
  Files: family `src/*.jl`
  (`poisson` / `negbinomial` / `beta` / `gamma` / `student` / `lognormal` /
  `betabinomial` / `binomial` / `zeroonebeta` / `tweedie` / `cumulative`),
  `summary.jl`, `inference.jl`, `variational.jl`, `docs/`, `test/runtests.jl`,
  `model-map.md`, `check-log.d/`.
- **Codex** — engine core + estimators.
  Files: `src/sparse_aug_plsm.jl`, `src/fit_q4_sparse_tmb.jl`,
  `src/takahashi_selinv.jl`, `src/experimental/*`, `bench/*`, `report/*`.
- **Shared — coordinate on the PR:** `src/DRM.jl` (include/export list).
  Append engine/experimental symbols in their own spot; flag on the PR.

## Verified state (as of HEAD)

- **All 13 families done / exported / tested.** Each has a `struct … end`
  marker in `src/` (`gaussian_core.jl` `Gaussian`, `student.jl` `Student`,
  `poisson.jl` `Poisson`, `negbinomial.jl` `NegBinomial2` + `TruncatedNegBinomial2`,
  `beta.jl` `Beta`, `betabinomial.jl` `BetaBinomial`, `binomial.jl` `Binomial`,
  `gamma.jl` `Gamma`, `lognormal.jl` `LogNormal`, `zeroonebeta.jl` `ZeroOneBeta`,
  `tweedie.jl` `Tweedie`, `cumulative.jl` `CumulativeLogit`) and all 13 appear in
  the `src/DRM.jl` export list. Family parity completed at **v0.1.1**
  (see `NEWS.md`).
- **Inference is wired** in `src/inference.jl` — Wald (`confint(…, method=:wald)`,
  boundary-aware SEs, #106), profile-likelihood (`method=:profile`, #103), and
  bootstrap (coefficient summaries #101 / auditable results #105 / fit-based
  entry points #132).
- **Tagged releases:** `v0.1.0` and `v0.1.1` (`git tag`).
- **Engine — crossed/structured Laplace merged.** Codex's lane landed crossed
  random effects (`closes #70`) plus a series of crossed/structured Laplace
  speed/correctness merges: #89, #97, #108, #111, #114, #119, #123, #126, #128.
- **Phase 3 / #7 complete-with-carveouts (2026-08-07).** All 26 drmTMB-target
  Documenter slugs exist; carve-outs named (phylo×spatial Theory+roadmap;
  VA Experimental #136). Public VA is Experimental `(1 | g)` on Poisson /
  Binomial / NB2 / Gamma / Beta (`marginal = :VA`); Laplace remains default;
  `_fit_va` still errors for unwired families; #136 stays OPEN. Inventory:
  `docs/dev-log/evidence/2026-08-07-7-phase3-inventory.md`.
- **#136e public-path report (2026-08-13 on main via #404).** Gamma `(1 | g)`
  smoke: LA ≈ VA on α; LA faster warm. VA stays Experimental. Not ZINB / not
  two-part. Report: `report/va-vs-laplace-bias.md`.

## Active branches

| Branch | Owner | Touching | Status |
|---|---|---|---|
| `main` | — | tip @ `d0fac9d7` (Merge #405) | landed idle START HERE; ship = idle pending G0 |
| `docs/claude-handover-idle` | Shannon (Cursor → Claude) | Claude handover + LOOP + coord + DoD docs | **this docs lane**; no closer for issue 136 |
| `docs/github-auto-merge` | Shannon (Cursor) | auto-merge policy note | **OPEN #406** / BLOCKED on CI `test (1.10)`; not a G0 |
| `docs/tip-idle-after-404` | — | handover + LOOP + coord + DoD docs | **MERGED** via #405; now historical |
| `feat/136e-va-bias-report` | — | report + bench + docs honesty | **MERGED** via #404; do not resume |
| `docs/handover-2026-08-09-drm-julia-lane` | — | Julia-lane START HERE | **MERGED** via #403; now historical |
| `feat/136-va-rung2-3` | — | — | **MERGED** via #401; do not resume |
| #49 | — | fenced | **PARKED** — owner-named only |
| drmTMB `engine="julia"` | — | **other repo** | **sibling** — possibly in progress; unknown here |

> Note: Phase 3 article-fill work is exhausted (26/26). Do not invent tip-idle
> SHA padding after this PR. Never stage `.worktrees/`. Coordinate on
> `src/DRM.jl` if an engine lane reopens.
