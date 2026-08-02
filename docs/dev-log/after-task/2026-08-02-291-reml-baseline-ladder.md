# After Task: #291 REML baseline ladder — LOOP and claim fence

**Date:** 2026-08-02
**Branch:** `feat/291-reml-baseline-ladder`
**Personas:** Rose (claim audit) with Shannon coordination. **No spawned subagents.**

## 1. Goal

Freeze the approved issue #291 Arc 0 scope and record its Definition-of-Done
ledger without promoting the proposed REML baseline work into an acceleration,
speed, interval, or AI-REML claim.

## 2. Implemented

- Preserved the approved Arc 0 plan in `LOOP/GOAL.md` and
  `LOOP/ultra-plan.md`; the older Phase 1.0 plan is labelled archived and
  non-authoritative for #291.
- Recorded the Arc 0 control-plane state in `LOOP/arcs.md` and
  `LOOP/checkpoint.md`.
- Added this after-task report and its collision-free check-log entry.
- Integrated the sibling-lane design-boundary note, purpose-built small-fixture
  ML-vs-baseline-REML harness, and report-contract test after their commits
  landed.
- Ran the harness with `DRM_REML_LADDER_OUTPUT=/tmp/reml-baseline.md`, then read
  its emitted Markdown artifact. Both fits converged; the record explicitly
  retains `interval_status=not_evaluated`.
- Ran the focused report-contract test directly after `Pkg.test(...;
  test_args=...)` proved incompatible with the project's test environment. It
  passed 13/13.

## 3a. Decisions and Rejected Alternatives

The verdict is **PASS** for Arc 0's scope and evidence gate. The authoritative
plan requires a reproducible report and read local output; both are now present,
and the focused report-contract test passes.

I also rejected treating the sibling harness source itself as an acceleration
result. The source deliberately labels itself a baseline record and records
interval status as `:not_evaluated`; it does not supply a completed comparison
or a public speed claim without an emitted report and the acceptance gates.

## 4. Files Touched

- `LOOP/GOAL.md`
- `LOOP/arcs.md`
- `LOOP/checkpoint.md`
- `LOOP/ultra-plan.md`
- `docs/dev-log/check-log.d/2026-08-02-291-reml-baseline-ladder.md`
- `docs/dev-log/after-task/2026-08-02-291-reml-baseline-ladder.md`

## 5. Checks Run

```sh
git status --short --branch
git diff -- LOOP/GOAL.md LOOP/arcs.md LOOP/checkpoint.md LOOP/ultra-plan.md
git diff --name-only
git ls-files "bench/ml_vs_reml_boundary.jl" "docs/dev-log/plans/*291*" "test/*reml*"
rg -n "#291|291-reml|baseline ladder|AI-REML" --glob '*.md'
bash ~/shinichi-brain/tools/lane_preflight.sh "$PWD"
git diff --check
DRM_REML_LADDER_OUTPUT=/tmp/reml-baseline.md julia --project=. bench/reml_baseline_ladder.jl
julia --project=. -e 'using DRM, Test; include("test/test_reml_baseline_ladder.jl")'
```

The branch is `feat/291-reml-baseline-ladder`. The #291 LOOP files are
uncommitted control-plane changes; `.worktrees/` is untracked and untouched.
The sibling lane committed and this lane read
`docs/dev-log/plans/2026-08-02-291-gaussian-q4-reml-acceleration-boundary.md`,
`bench/reml_baseline_ladder.jl`, and `test/test_reml_baseline_ladder.jl`; the
test is included by `test/runtests.jl`. They were not run in this lane and no
emitted harness report was present. `bench/ml_vs_reml_boundary.jl` and existing
REML tests remain tracked baseline materials. Lane preflight reported no Codex
lane in the last 12 hours, explicitly as weak evidence only; it cannot see
newly opened or uncommitted foreign work.

## 6. Tests of the Tests

The report-contract test is included by `test/runtests.jl`. `Pkg.test(...;
test_args=...)` stopped before executing tests with `can not merge projects`;
direct inclusion under `julia --project=.` passed all 13 assertions. The emitted
report confirms its required metadata and fit fields, while preserving the
negative claim fence: no interval comparison, acceleration evaluation, or speed
headline is asserted.

## 7a. Issue Ledger

Issue #291's Arc 0 is ready for a narrow PR. This evidence does not close the
broader issue. Merge, publication, speed claims, and heavy compute remain OPEN
GATES.

## 8. Consistency Audit

The LOOP files consistently state: Gaussian q4 only; ML default and REML
opt-in; baseline finite-difference REML only; `lc_metric` is future
infrastructure; no `:natgrad`, engine-control API, public AI-REML claim, or
speed headline. The plan’s required agreement on estimate, objective, and
interval status remains a future gate.

License boundary check: this documentation lane adds no drmTMB code or fixture;
DRM.jl remains MIT and any future parity evidence must use generated outputs,
not GPL source.

## 9. What Did Not Go Smoothly

The repository routing helper reported no DRM.jl LOAD-FIRST manifest. The
preflight result is necessarily weak because it cannot observe uncommitted work.
Neither result changes the directly verified branch scope or claim fence.

## 10. Known Residuals

The baseline record covers only one deterministic p=8, nrep=3 fixture on the
recorded local environment. Its observed elapsed times are retained as audit
metadata, not a general performance comparison.

This lane does NOT cover the restricted-objective derivation, estimate/objective
agreement gate, candidate acceleration, AI-REML, public API, general-scale
benchmark, non-Gaussian REML, bridge behaviour, issue #136, or release
readiness.

## 11. Team Learning

For a proposed optimizer, a scaffold is not a result. Keep the baseline report
fields and the estimate/objective/interval agreement gate co-located before
describing any speed or AI-REML outcome.

**Memory receipt:** loaded the hub operating contract and after-task protocol,
the DRM.jl handover and team contract, and searched the local brain across
projects before auditing. The #291-specific artifact inventory in the repo,
not recalled memory, determined this conditional verdict.

**Golden Set:** not applicable; this lane changes no executable behavior and
does not add or modify a behavioral test.

## 12. Cross-Product Coverage

| Surface | This lane covers | This lane does NOT cover |
|---|---|---|
| Scope / gates | ✓ Arc 0 boundaries, OPEN GATES, and archived-plan separation | ✗ human approval for PR, merge, publication, claim, or heavy compute |
| REML baseline | ✓ ML/REML objectives, convergence, estimates, timing metadata, and explicit no-CI status | ✗ estimate/objective agreement or interval-comparison gate |
| Candidate acceleration | ✓ explicit prohibition on `:natgrad` / public AI-REML claim | ✗ AI / observed-information implementation or evaluation |
| Evidence harness | ✓ local execution, emitted report, direct contract-test verification | ✗ general performance comparison or interval evaluation |

## Rose Verdict

**PASS — Arc 0 harness evidence, scope honesty, and claim fence.** The
documentation makes no speed or AI-REML overclaim, and keeps ML default / REML
opt-in explicit. The read local artifact shows both p=8/nrep=3 fits converged
and records intervals as not evaluated; the direct focused report-contract test
passes 13/13. This does not validate acceleration, general-scale performance,
or any public AI-REML surface.
