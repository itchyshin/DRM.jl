# After-task — #291 Arc 3 intermediate fixture rung

**Date:** 2026-08-02  
**Branch:** `feat/291-reml-arc3-intermediate-fixture`  
**Related:** #291  
**Personas:** Ada (scope), Curie (harness), Rose (claim fence). No spawned subagents.

## 1. Goal

Add the smallest reproducible rung above the p=8 smoke fixture to the existing
warm q4 REML harness, then record the resulting evidence class without changing
the optimizer.

## 2. Implemented

- Added `REML_BASELINE_LADDER_INTERMEDIATE_FIXTURE = (p=16, nrep=3, seed=291)`.
- Documented the named invocation and tested its data and tip counts.
- Ran and read the intermediate warm-harness artifact. Timed REML fits did not
  converge, so the harness correctly emitted `diagnostic_only`.
- Updated the sparse-first framing and `LOOP/` records; added the check-log row.

## 3a. Decisions and Rejected Alternatives

Chose p=16/nrep=3 to retain the deterministic generator and identifiable
scale-RE fixture while remaining a local intermediate check. Did not use p=32,
alter iteration controls, add live counters, change `src/`, or diagnose/fix the
nonconvergence: each would widen this evidence-only arc and the latter two need
a separate G0.

## 4. Files Touched

- `bench/reml_baseline_ladder.jl`
- `test/test_reml_baseline_ladder.jl`
- `docs/dev-log/plans/2026-08-02-291-sparse-first-characterization.md`
- `docs/dev-log/check-log.d/2026-08-02-291-reml-arc3-intermediate-fixture.md`
- `docs/dev-log/after-task/2026-08-02-291-reml-arc3-intermediate-fixture.md`
- `LOOP/GOAL.md`
- `LOOP/arcs.md`
- `LOOP/checkpoint.md`

## 5. Checks Run

```sh
julia --project=. -e 'using DRM, Test; include("test/test_reml_baseline_ladder.jl")'
# PASS 26/26

julia --project=. -e 'include("bench/reml_baseline_ladder.jl"); report = reml_baseline_ladder_report(; REML_BASELINE_LADDER_INTERMEDIATE_FIXTURE...); write("/tmp/reml-arc3-intermediate.md", reml_baseline_ladder_markdown(report)); println(report.evidence_class)'
# diagnostic_only

git diff --check
```

Read `/tmp/reml-arc3-intermediate.md`: fixture is p=16/nrep=3/seed=291; both
timed REML records have `converged=false`; all records retain
`interval_status=not_evaluated`.

`Pkg.test()` and direct `test/runtests.jl` do not currently reach this slice:
the first stops before test execution with the repository's project-merge /
manifest mismatch; the latter passes its first 14 engine-load checks, then stops
because `Aqua` is unavailable in the active project. Neither error references
Arc 3 files.

## 6. Tests of the Tests

The focused test was added before the fixture constant. Its first run failed
with `UndefVarError: REML_BASELINE_LADDER_INTERMEDIATE_FIXTURE not defined`.
After defining the fixture and correcting the test to use the actual
`leaf_names` field, it passed 26/26.

## 7a. Issue Ledger

Continues #291 and does not close it: the broader acceleration issue remains
open. This PR is related to #291; it records a fixture rung and does not claim
to satisfy an acceleration acceptance gate.

## 8. Consistency Audit

Checked the Arc 2 harness protocol, report evidence classification, framing
note, and existing contract test. The new rung keeps the p=8 defaults intact,
uses nrep≥2, and never turns `diagnostic_only` output into a rank or speed
claim. No drmTMB source was added.

## 9. What Did Not Go Smoothly

The p=16 run did not earn `warm_comparable`: baseline REML timed fits reported
nonconvergence. This is a result to preserve, not a reason to tune or alter the
solver inside this arc.

## 10. Known Residuals

This does NOT establish a p=16 performance comparison, a general
nonconvergence rate, an exact REML gradient, live optimizer call counts,
AI-REML validity, profile/bootstrap behavior, or any p=10,000/Ayumi result.
The full suite remains unavailable in this checkout until its existing test
environment dependency/project merge state is repaired.

## 11. Team Learning

A named intermediate fixture makes the next rung reproducible even when its
evidence classification is negative. Preserve that classification rather than
quietly changing controls until it becomes comparable.

**Memory receipt:** loaded the hub operating contract, DRM handover/team
contract, `LOOP/`, issue #291 history, and a cross-project brain search before
choosing the fixture rung. The route manifest was absent; repository files
remained technical truth.  
**Golden Set:** not applicable; this arc does not alter the estimator or public
behavior.

## 12. Cross-Product Coverage

| Surface | This arc covers | This arc does NOT cover |
|---|---|---|
| REML baseline harness | ✓ named p=16/nrep=3 deterministic fixture | ✗ modified solver, live counters, or exact score |
| Timing evidence | ✓ explicit `diagnostic_only` classification | ✗ method ranking or public speed headline |
| Inference | ✓ explicit `not_evaluated` status remains visible | ✗ profile/bootstrap/CI validation |
| Public/package surface | ✓ no public API change | ✗ `:natgrad`, AI-REML, bridge, General, or Registrator |

## Rose Verdict

**PASS — bounded intermediate-harness evidence.** No `src/` edit, AI-REML or
`:natgrad` API, 10k/General/Registrator work, GPL source, or public speed
headline. The p=16 nonconvergence is explicitly constrained to its artifact
and `diagnostic_only` evidence class.
