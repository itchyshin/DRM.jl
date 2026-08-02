# Issue #291 Arc list

| Arc | Scope | Status | Verification / gate |
|---|---|---|---|
| 0 | Gaussian q4 REML design boundary and small ML-vs-baseline-REML harness | **done** | Design note + emitted p=8/nrep=3 record read; focused contract test passed 13/13; Rose PASS. PR [#361](https://github.com/itchyshin/DRM.jl/pull/361) CI remains a merge gate. |
| 1 | Document the baseline route's first bottleneck and its candidate acceptance gates; leave the report-only instrumentation slice precise | **done** | Fresh p=8/nrep=3 record read; direct test 13/13; static FD route establishes at most 23 restricted-objective/mode evaluations per fixture gradient request. |

## Arc 0 completion record

- Design boundary: `docs/dev-log/plans/2026-08-02-291-gaussian-q4-reml-acceleration-boundary.md`
- Harness + report contract: `bench/reml_baseline_ladder.jl` +
  `test/test_reml_baseline_ladder.jl`, wired in `test/runtests.jl`
- Local verification: `DRM_REML_LADDER_OUTPUT=/tmp/reml-arc1-baseline.md julia
  --project=. bench/reml_baseline_ladder.jl` emitted a read p=8/nrep=3 report;
  both fits converged and intervals remained `not_evaluated`. Direct focused
  test passed 13/13.
- Rose: PASS for baseline evidence and claim fence; no acceleration, general
  performance, interval, or AI-REML result.
- PR: [#361](https://github.com/itchyshin/DRM.jl/pull/361), open; CI is a merge
  gate only, not a block on the reversible Arc 1 documentation follow-up.

## Arc 1 completion record

- Bottleneck note: `docs/dev-log/plans/2026-08-02-291-reml-arc1-bottleneck.md`
- Finding: current central finite differences span 11 outer coordinates in the
  fixture, producing up to 23 restricted-objective/mode evaluations per gradient
  request before line-search calls. This is a structural route count, not a
  timing or acceleration result.
- Candidate gates: independently cold objective, estimates/boundary state, and
  interval status must agree before timing.
- Next precise slice: report-only counters for outer coordinates and requested
  restricted-objective/mode calls, with a contract test; no `src/` optimizer
  change is authorized.
