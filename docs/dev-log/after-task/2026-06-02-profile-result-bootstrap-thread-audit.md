# After-task: profile-result and threaded inference audit

Issue: #133

Date: 2026-06-02

## Summary

Inference now has an auditable profile-likelihood result object to match the
existing bootstrap result workflow. `confint(..., method = :profile)` remains
unchanged at the public row level, while `profile_result(fit; ...)` exposes the
same CI rows plus timing, thread/BLAS metadata, and endpoint work counts.

## What Changed

- Added exported `profile_result(fit; level, threads, parm)`.
- Added per-coefficient profile stats:
  - endpoint evaluations;
  - gradient evaluations;
  - bracket expansions;
  - guarded-Newton root iterations;
  - lower/upper unbounded flags.
- Added CPU metadata shared with bootstrap-style reporting:
  - `worker_threads`;
  - `julia_threads`;
  - `blas_threads`;
  - `blas_oversubscribed`;
  - `elapsed`.
- Added endpoint-arm threading for one-coefficient profile jobs. Multi-coefficient
  jobs keep the existing coefficient-level threaded path.
- Extended `bootstrap_result` metadata with `worker_threads` and
  `blas_oversubscribed`.
- Added serial-vs-threaded determinism tests for Gaussian and Poisson bootstrap.
- Updated `bench/profile_inference_quick.jl` and regenerated
  `report/inference-profile-quick.md`.

## Measured Result

Protocol: 4 Julia threads, BLAS pinned to 1, deterministic fixtures, median of
five post-warm runs for the baseline-vs-branch check.

| task | baseline | branch | interpretation |
|:-----|---------:|-------:|:---------------|
| crossed Gaussian profile CI, serial | 0.3600s | 0.3584s | no serial regression |
| crossed Gaussian profile CI, threaded | 0.1599s | 0.1590s | existing coefficient threading preserved |
| Poisson `(1\|g)` `parm=:resd`, serial | 0.0342s | 0.0358s | small noise-level overhead |
| Poisson `(1\|g)` `parm=:resd`, threaded | 0.0342s | 0.0234s | new endpoint-arm threading helps one-coefficient profiles |

Quick benchmark report (`report/inference-profile-quick.md`), same CPU policy:

| task | elapsed |
|:-----|--------:|
| crossed Gaussian profile CI serial | 0.3711s |
| crossed Gaussian profile CI threaded | 0.1703s |
| Poisson `(1\|g)` profile-result `parm=:resd` serial | 0.0203s |
| Poisson `(1\|g)` profile-result `parm=:resd` endpoint-threaded | 0.0121s |
| Poisson `(1\|g)` bootstrap result B=12 serial | 0.1873s |
| Poisson `(1\|g)` bootstrap result B=12 threaded | 0.0788s |

All reported serial/threaded CI deltas were `0.000e+00`.

## Verification

- `julia --project=. --threads=4 test/test_profile_ci.jl`
- `julia --project=. --threads=4 test/test_bootstrap.jl`
- `julia --project=. --threads=4 test/test_bootstrap_nongaussian.jl`
- `julia --project=bench --threads=4 bench/profile_inference_quick.jl`
- baseline-vs-branch timing check against `origin/main` at `1c5094e`

## Rose Audit

- This is a DRM.jl local inference-speed claim only. No R/drmTMB comparison was
  run or claimed in this slice.
- Endpoint-arm threading is retained because it improves the heavier
  one-coefficient Poisson random-effect SD profile; it is not claimed as a win
  for tiny fixed-effect Gaussian profiles, where spawn overhead dominates.
- No private uploaded paper material and no GPL drmTMB source were used.
