# After Task: #291 Arc 1 — baseline REML bottleneck record

**Date:** 2026-08-02  
**Branch:** `feat/291-reml-arc1-bottleneck` (stacked on Arc 0 PR #361)  
**Personas:** Ada (scope) and Rose (claim audit). **No spawned subagents.**

## 1. Goal

Identify the first evidence-backed bottleneck in the Gaussian q4 baseline REML
route and state candidate gates without implementing an acceleration.

## 2. Implemented

- Added a concise bottleneck note based on the current `fit_q4_reml` evaluation
  route and a newly read deterministic p=8/nrep=3 harness artifact.
- Recorded the central-finite-difference route count: up to 23
  restricted-objective/mode evaluations per gradient request for the fixture.
- Retained objective, estimate, and interval-status acceptance gates before any
  candidate timing.

## 3a. Decisions and Rejected Alternatives

I did not interpret the one-run ML and REML elapsed times as a speed comparison:
ML runs first and includes Julia compilation. I also did not change the
finite-difference route, skip pinned directions, add instrumentation, or expose
an algorithm; each would be a separate candidate slice requiring the listed
agreement gates.

## 4. Files Touched

- `docs/dev-log/plans/2026-08-02-291-reml-arc1-bottleneck.md`
- `docs/dev-log/check-log.d/2026-08-02-291-reml-arc1-bottleneck.md`
- `docs/dev-log/after-task/2026-08-02-291-reml-arc1-bottleneck.md`
- `LOOP/arcs.md`
- `LOOP/checkpoint.md`

## 5. Checks Run

```sh
DRM_REML_LADDER_OUTPUT=/tmp/reml-arc1-baseline.md julia --project=. bench/reml_baseline_ladder.jl
julia --project=. -e 'using DRM, Test; include("test/test_reml_baseline_ladder.jl")'
git diff --check
```

The emitted artifact was read: both fits converged, and each reports
`interval_status=not_evaluated`. The focused contract test passed 13/13.

## 6. Tests of the Tests

No executable behavior changed. The existing report-contract test was run
directly and passed 13/13; the Arc 1 route count is a documented static
inspection of `fit_q4_reml`, not a newly asserted runtime counter.

## 7a. Issue Ledger

This continues issue #291 only. Arc 0 is in [PR #361](https://github.com/itchyshin/DRM.jl/pull/361)
with CI pending. This stacked follow-up records a precise possible next slice
(report-only evaluation-count instrumentation); it does not close #291.

## 8. Consistency Audit

The design boundary, harness, and `fit_q4_reml` agree that the q4 route profiles
fixed effects and optimizes \(\beta_\rho\) plus ten log-Cholesky coordinates.
The new note preserves ML as default, REML as opt-in, and `lc_metric` as
non-REML infrastructure. No drmTMB source was added.

## 9. What Did Not Go Smoothly

The existing `bench/README.md` path is absent, so the runnable invocation was
verified from the harness docstring and actual execution instead. The route
helper also has no DRM.jl LOAD-FIRST manifest; repository files remained the
technical source of truth.

## 10. Known Residuals

The 23-evaluation count is a route upper bound for a gradient request, not a
profiled elapsed-time attribution. It does NOT cover an exact REML score,
candidate correctness, interval comparison, general-scale timing, non-Gaussian
REML, AI-REML, public APIs, #136, bridge work, or release readiness.

## 11. Team Learning

An elapsed-time ordering from a single Julia process is not performance evidence
when the first fit compiles. Inspect evaluation multiplicity first, then
instrument it before changing an optimiser.

**Memory receipt:** loaded the hub operating contract, after-task protocol, DRM
handover/team contract, and local brain search. The Golden Set is not applicable:
this arc changes no executable behavior.
**Golden Set:** not applicable; no executable behavior or behavioral test changed.

## 12. Cross-Product Coverage

| Surface | This arc covers | This arc does NOT cover |
|---|---|---|
| REML baseline route | ✓ finite-difference evaluation multiplicity | ✗ exact restricted score or modified solver |
| Small fixture | ✓ convergence and explicit no-interval status | ✗ performance ranking or interval parity |
| Candidate gate | ✓ objective/estimate/interval criteria | ✗ candidate execution or speed claim |
| Public/package surface | ✓ no API change | ✗ `:natgrad`, AI-REML, bridge, General, or Registrator |

## Rose Verdict

**PASS — bounded bottleneck documentation.** The bottleneck is a code-supported
evaluation-multiplicity finding, not an acceleration claim. The note explicitly
rejects the contaminated first-run timing comparison and retains all candidate
acceptance gates.
