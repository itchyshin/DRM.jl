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

## Active-Lane-Split (2026-08-14, updated — campaign ACTIVE)

_Owner named the G0 on 2026-08-14: **catch up with drmTMB's capability so
`engine = "julia"` admits what an R user actually fits.** DRM.jl is no longer
idle. Lane = `feat/drmtmb-catchup-ledger` (Claude). Anchor = drmTMB **0.7.0**
`f5ec53634`. Countdown: `python3 tools/parity_ledger.py --drmtmb ../drmTMB --ref origin/main`.
A0 (ledger) + A1 (vcov guard) landed; next A2a. Live pointer: `LOOP/GOAL.md`._

**drmTMB narrow lane claimed** (Claude, same campaign): `R/julia-bridge.R`,
`tests/testthat/test-julia-*`, `vignettes/julia-engine.Rmd` **only** — nothing
else in that repo. Its tree carries 9 live lanes, a foreign codex lane, and the
open 0.7.0 release slice #959; the bridge PR is gated on owner timing. No drmTMB
edits have been made yet.

| Lane | Repo | State | Pointer |
|---|---|---|---|
| DRM.jl Julia | this repo | **ACTIVE — `engine="julia"` catch-up**; A0+A1 landed on `feat/drmtmb-catchup-ledger` | `LOOP/GOAL.md` · `LOOP/checkpoint.md` |
| drmTMB bridge (narrow) | `/Users/z3437171/Dropbox/Github Local/drmTMB` | **claimed, not yet edited** — `R/julia-bridge.R` + its tests/vignette only | `LOOP/arcs.md` A2b/A3 gates |
| DRM.jl Julia (prior) | this repo | superseded — tip-idle handover of 2026-08-14 is now **historical** | `docs/dev-log/handover/2026-08-14-claude-handover-drm-idle.md` |
| drmTMB `engine="julia"` Workflow G | `/Users/z3437171/Dropbox/Github Local/drmTMB` | **sibling — possibly in progress** (unknown from this session) | that repo’s own handover; do not start from DRM.jl; do not claim finished |
| #136 epic | DRM.jl | **OPEN** — 136e public Gamma report **DONE** on main; two-part / ZI×RE later | issue 136; `report/va-vs-laplace-bias.md` |
| #49 | DRM.jl | **PARKED** | owner-named only |

Rehydrate must read **every** row. A single START HERE must not orphan the
drmTMB sibling lane or the parked DRM epics.

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
