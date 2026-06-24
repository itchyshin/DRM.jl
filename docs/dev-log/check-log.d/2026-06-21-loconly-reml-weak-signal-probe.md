# 2026-06-21 — Location-only Gaussian REML weak-signal recovery probe

Goal:

- Add an explicitly labelled weak-signal recovery probe where boundary states
  are expected diagnostic outcomes rather than routine-test failures.

Checks:

```sh
julia --project=. test/test_location_only_reml_mme.jl
git diff --check
rg -n "AI-REML solves|AI-REML validates|HSquared proves|non-Gaussian REML|q4 AI-REML|10k-scale intervals|Ayumi reply|public estimator claim|AI-REML optimizer" src/location_only.jl test/test_location_only_reml_mme.jl docs/dev-log/check-log.d/2026-06-21-loconly-reml-weak-signal-probe.md docs/dev-log/after-task/2026-06-21-loconly-reml-weak-signal-probe.md docs/dev-log/validation-status/2026-06-21-loconly-gaussian-reml-mme.tsv
```

Result:

- Added `_loconly_reml_weak_signal_recovery_probe()`, a wrapper around the
  recovery grid with `expected_behavior = :boundary_states_allowed`.
- The focused test passed: 277/277 assertions.

Boundary:

- This is a weak-signal point-recovery diagnostic only. It does not claim
  interval coverage, R bridge support, q4 support, non-Gaussian support,
  10k-scale intervals, or Ayumi readiness.
