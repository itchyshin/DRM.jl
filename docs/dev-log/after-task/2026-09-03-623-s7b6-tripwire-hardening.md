# After-Task Report: S7b.6 scaling tripwire hardened (#623, closes #622)

- **Date:** 2026-09-03
- **Issue:** #622 (flaky CI); PR #623, branch `test/s7b6-tripwire-robust`,
  merged `7a5672e038ab61dad7d5ded7fb101e1c13a696e0`
- **Perspectives:** Shannon (Rose after-task pass, retrospective)

## 1. Goal

Fix #622: the S7b.6 scaling tripwire from #610 asserted `t2000 / t500 ≤ 8`
from single timings; on a contended runner (#618's `test (1)` job, Julia
1.12.7) it measured 10.7 (`t500 = 0.148 s`, `t2000 = 1.586 s`) while the fixed
sparse route sits near 1.8 locally, and the cubic router bug the tripwire
guards against gives 25–48 — i.e. the tripwire was flaking on host noise while
still leaving a wide margin to the actual regression it guards.

## 2. Implemented

- `test/test_lss_sparse_multi_public.jl`: minimum of three timings per size
  (instead of one), ratio bar raised 8 → 12, absolute cap raised 15 → 20 s.
  Test-only change: 7 insertions, 4 deletions, one file.

## 3a. Decisions and Rejected Alternatives

- **Raised the bar and added repeat timings rather than removing the
  tripwire.** The tripwire exists to catch the cubic-router regression (ratio
  25–48); a bar of 12 still catches that by a wide margin (more than 2×) while
  clearing the observed contended-runner noise floor (10.7).
- **Minimum of three timings, not mean or median.** Using the minimum is the
  standard defence against transient scheduler contention inflating a single
  sample — it converges toward the true (uncontended) cost as sample count
  grows, whereas a mean stays biased upward by every contended sample.
- **Did not lower fidelity by disabling the tripwire on CI or skipping it on
  slow runners** — the fix keeps the gate live everywhere, just less sensitive
  to noise, which is the narrower and more defensible change.

## 4. Files Touched

Per `git diff --stat 7a5672e0~1..7a5672e0`:

```
test/test_lss_sparse_multi_public.jl | 11 +++++++----
1 file changed, 7 insertions(+), 4 deletions(-)
```

## 5. Checks Run

- Local run of `test/test_lss_sparse_multi_public.jl`: green, measured ratio
  2.77 (well under the new bar of 12; per the coordinating session's local
  verification at merge time). This after-task pass did not independently
  re-run the test: the working tree is a shared checkout with many concurrent
  lanes on this same repo's Julia depot, and a fresh `include()` failed on a
  package-precompilation pidfile lock from that contention (not a test
  failure) — re-running was not pursued further since this task is docs-only.

## 6. Tests of the Tests

- The PR body states the new bar (12) still catches the cubic-router
  regression (measured ratio 25–48) "by a wide margin" — i.e. the fix was
  checked against both failure modes it must discriminate: it must stay quiet
  on contended-host noise (10.7, now below 12) and still fire on the actual
  regression it guards (25–48, still well above 12). A bar that only solved
  one side (e.g. raised to 50) would not be a tripwire at all; a bar that
  only solved the other (unchanged at 8) is the defect being fixed.
- This after-task pass takes the coordinating session's local-run confirmation
  (green, ratio 2.77) as the evidence; no independent re-run was performed for
  this report (see §5 — attempted, blocked by depot contention from
  concurrent lanes, not pursued further given the docs-only scope).

## 7a. Issue Ledger

- Closes #622.

## 8. Consistency Audit

- Single-file, test-only change confined to the one tripwire; no other
  scaling/timing assertion in the suite was touched, so no sibling flake was
  swept in this PR (none was in scope — #622 named this one test file
  specifically).

## 9. What Did Not Go Smoothly

- The original #610 tripwire used a single timing sample with a bar (8) close
  enough to normal contended-host variance (10.7 observed) that it flaked on
  a shared CI runner rather than only on the regression it was meant to catch
  — the class of mistake being fixed is "a statistical assertion built from
  one sample, on a shared/contended machine."

## 10. Known Residuals

- The new bar (12) and cap (20 s) are still empirical, chosen from one
  contended-runner observation (10.7) and the router bug's known range
  (25–48); no formal false-positive-rate analysis across many CI runs.
- Minimum-of-three still assumes the true cost is reachable within three
  samples on a given runner; an unusually persistently loaded runner could in
  principle still exceed the new bar (untested).

## 11. Team Learning

- **A scaling-ratio tripwire built from a single timing sample is fragile on
  shared CI runners.** The durable pattern: take a minimum of several repeat
  timings (defends against transient contention inflating the "before" size,
  which understates the ratio's denominator and inflates the ratio), and set
  the bar with headroom against the actual regression's measured range, not
  just against one previously-passing observation.

## 12. Cross-Product Coverage

This is a test-infrastructure hardening, not an engine change — it does not
touch `src/`.

- **Covers ✓:** the S7b.6 sparse-multi-component LSS scaling tripwire
  (`test/test_lss_sparse_multi_public.jl`), on the specific contended-runner
  failure mode observed in #622.
- **Does NOT cover:** any other timing/scaling assertion elsewhere in the
  suite (not audited for the same single-sample fragility in this PR); a
  formal statistical characterisation of the new bar's false-positive rate
  across many runs; the underlying router performance itself (unchanged —
  this PR only widens the test's tolerance to host noise, it does not touch
  `src/`).
