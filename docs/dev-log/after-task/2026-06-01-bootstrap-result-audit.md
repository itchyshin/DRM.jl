# After-task — auditable bootstrap result

**Date:** 2026-06-01 · **Branch:** `codex/bootstrap-result-audit` · **Closes:** #104

## Landed

- `bootstrap_result(...)` returns bootstrap summaries plus audit metadata:
  attempted, used, failed, per-replicate seeds, threaded flag, and failure rows
  `(replicate, seed, message)`.
- `bootstrap_ci(...)` and `bootstrap_summary(...)` remain backward-compatible
  row-returning helpers, now backed by the shared audited runner.
- `failures = :error` remains the default; `failures = :skip` supports long or
  exploratory runs where users need successful-replicate summaries plus failure
  accounting.
- `check_converged = true` can treat non-converged refits as failed bootstrap
  replicates.
- `bench/profile_inference_quick.jl` now includes a Poisson `(1|g)` bootstrap
  cell, serial vs threaded.

## Verified

- `julia --project=. test/test_bootstrap.jl` — 22/22 pass.
- `julia --project=. test/test_bootstrap_nongaussian.jl` — 33/33 pass.
- `julia --project=. -e 'using Pkg; Pkg.test()'` — full suite pass.
- `julia --project=docs docs/make.jl` — local docs build pass; existing site
  warnings only.
- `julia --project=bench --threads=4 bench/profile_inference_quick.jl` —
  Poisson `(1|g)` B=12 bootstrap: 0.1837s serial vs 0.0787s threaded, both
  used 12/12 replicates.

## Rose Notes

- The timing is a local DRM.jl inference-pipeline timing, not an R comparison.
- The bootstrap accounting records failures without hiding them; skipped
  failures are only available through `bootstrap_result`, not silently discarded
  by the row-only helpers.
