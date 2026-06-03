# After-task: q4 benchmark gate repair

## Scope

Repaired the q4 sparse-engine regression command used by the PR template:

```sh
julia --project=bench bench/run_sparse_tmb_nd.jl
```

The runner had stale poc-era assumptions:

- `include(joinpath(@__DIR__, "fit_q4_sparse_tmb.jl"))`, but the verified q4
  engine now lives in `src/`.
- `../../fixtures`, but the tracked q4 fixture lives in `bench/fixtures/`.
- CSV/DataFrames imports in a bench environment that does not declare those deps.

The repaired runner now:

- Activates the root package project and uses `DRM`.
- Reads `bench/fixtures/q4_p100.csv` via `DelimitedFiles`, already declared in
  the bench environment.
- Leaves the q4 engine untouched.

## Evidence

Focused gate:

```sh
julia --project=bench bench/run_sparse_tmb_nd.jl
```

Result:

```text
logLik Julia=-256.5177  drmTMB=-256.5200  |Δ|=0.0023
converged=true iters=97 g_resid=7.21e-03 f_calls=118 g_calls=118
wall Julia=1.099s (best of 2: 1.119, 1.099)  drmTMB=2.48s  ratio=2.26x JULIA FASTER
```

Hygiene:

```sh
git diff --check
```

Result: passed.

## Rose Audit

- This repairs the PR-template regression gate that future `src/` PRs need.
- The q4 speed/logLik numbers are measured from the local command above, not
  extrapolated.
- No q4 engine code changed.
- Scope is intentionally narrow: adjacent historical q4 bench runners still use
  stale includes/fixture paths and should be audited separately if they become
  active gates.
