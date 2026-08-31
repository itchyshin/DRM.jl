# Canonical location-scale profile failure disclosure

## Approved internal contract

`_ls_profile_nll_result` returns a structured nuisance result while the existing
`_ls_profile_nll` three-tuple wrapper remains compatible with callers that
destructure it. The result records `value`, `minimizer`, `accepted`, `method`,
`fallback`, `reason`, `converged`, and `gradient_maxabs`.

Acceptance requires all of the following: a finite minimizer; successful
`Optim` termination; a fresh finite objective evaluation; and a fresh free
gradient whose maximum absolute entry is at most the existing L-BFGS `g_tol`
of `1e-7`. The implementation keeps the 200-iteration budget and likelihood
unchanged. A finite but non-converged solve is therefore rejected as
`:not_converged`; an exception or non-finite reevaluation has its own reason.
`InterruptException` is rethrown.

`_ls_profile_root_result` returns

```
(value, accepted, unbounded, endpoint_failed, reason,
 bracket_expansions, root_iterations, evaluations, gradient_evaluations,
 candidate, residual, nuisance)
```

`candidate` is the evaluated parameter coordinate, not the internal positive
displacement. A certified finite crossing is `accepted = true`. A finite
negative gap across the configured expansion range is `:no_crossing`, carries
the directional infinity convention, and has `unbounded = true`; this means no
crossing **within the searched range**, not mathematical unboundedness. Failed
or non-finite evaluations, an invalid search budget, bracket collapse, or
`:max_iterations` return directional infinity with `endpoint_failed = true` and
`unbounded = false`.

`_ls_profile_ci_result` keeps both arm results. `_ls_profile_result` propagates
endpoint flags and sums endpoint counters into the existing stats rows without
changing `_ProfileStatsRow`; its additive `endpoint_diagnostics` records the
lower/upper terminal reason, coordinate, residual, counters, and terminal
nuisance record. The existing `confint` warning path reports failed arms.

Canonical location-scale profiling remains serial, including when
`threads=true`. The earlier threading test remains on disk but is intentionally
excluded from default `runtests.jl` until a separate cache/thread-safety slice.

## TDD checks

1. The default 30-step root refinement of `h(t) = t^2 - 1` from `1e20` rejects
   the still-large candidate as `:max_iterations`.
2. A failed refinement after a valid bracket is an endpoint failure, not an
   accepted coordinate or an unbounded interval.
3. A valid quadratic root is accepted with an evaluated residual below `1e-7`;
   a nonzero origin and negative direction prove diagnostics report the actual
   parameter coordinate.
4. Flat/no-crossing, invalid-budget, failed-evaluation, and interrupt controls
   distinguish searched-range no crossing from numerical failure.
5. A finite nuisance candidate with either exhausted `Optim` termination or a
   fresh non-stationary free gradient is rejected while the legacy three-tuple
   wrapper remains usable.
6. A deterministic canonical Gamma fit propagates failed-arm diagnostics,
   counters, and the existing `confint` warning. In its current run it has one
   attempted row, zero certified endpoints, zero no-crossing endpoints, and two
   `:not_converged` nuisance arm failures; this is disclosure evidence, not a
   valid finite-interval claim.

## Commands and retained receipts

The pure status controls are estimated below 60 seconds. The canonical-model
smoke is estimated below five minutes with a hard process-group deadline.

```
JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. --startup-file=no \
  test/test_locscale_profile_status.jl
```

- `.unlazy/locscale-profile-status-red-001.log` — pre-implementation RED:
  missing structured helpers (3 errors, 0.7 s).
- `.unlazy/locscale-profile-status-green-005.log` — pure controls: 52 passes,
  3.5 s.
- `.unlazy/locscale-profile-status-green-006.log` — focused module test: 65
  passes, 34.6 s, with the model-arm counts above.

## Executable acceptance gates

- [x] G0: focused source test
  CWD: .
  CHECK: JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. --startup-file=no test/test_locscale_profile_status.jl && printf 'LOCSCALE_PROFILE_STATUS_OK\n'
  EXPECT: LOCSCALE_PROFILE_STATUS_OK
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/integration/DRM.jl; path=92301ffe9a62/34 entries; output=│   lower_reason = :not_converged | └   upper_reason = :not_converged
- [x] G1: module one thread
  CWD: .
  CHECK: python3 /private/tmp/drm-parity-20260830/integration/run_profile_status_module.py 1 final003
  EXPECT: MODULE_PROFILE_STATUS_OK
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/integration/DRM.jl; path=92301ffe9a62/34 entries; output=MODULE_PROFILE_STATUS_OK | {"started_utc": "2026-08-31T12:53:59.689003+00:00", "ended_utc": "2026-08-31T12:54:38.912381+00:00", "elapsed_seconds": 39.22279924992472, "exit_code": 0, "timed_out": false, "deadline_seconds": 90, "julia_threads
- [x] G2: module four threads
  CWD: .
  CHECK: python3 /private/tmp/drm-parity-20260830/integration/run_profile_status_module.py 4 final004
  EXPECT: MODULE_PROFILE_STATUS_OK
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/drm-parity-20260830/integration/DRM.jl; path=92301ffe9a62/34 entries; output=MODULE_PROFILE_STATUS_OK | {"started_utc": "2026-08-31T12:54:39.229845+00:00", "ended_utc": "2026-08-31T12:55:18.227348+00:00", "elapsed_seconds": 38.996953665977344, "exit_code": 0, "timed_out": false, "deadline_seconds": 90, "julia_thread
- [x] G3: Rose review of G0–G2 receipts and serial canonical-location-scale scope
  EVIDENCE: Rose Sol/high approved production e92eb7c5/8f483d5b and test160b4c73; root verified fresh G0-G2 pass with current hashes, 196/200 assertions; docs/dev-log/evidence/julia-r-parity/locscale-profile-status-20260831/rose-final-review.md

## Deferred threading

`test/test_locscale_profile_threads.jl` and its retained RED logs remain on
disk. The early timeout fixture bytes were overwritten before a source/hash
snapshot, so no hash is claimed for that transient draft. The later behavioural
RED remains retained. No coefficient threading is implemented or claimed here.
