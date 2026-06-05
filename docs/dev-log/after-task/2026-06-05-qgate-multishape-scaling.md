# After-task: multi-shape q4 scaling gate

## Scope

Completed issue #16 as a local Workflow Q gate for the q=4 sparse PLSM engine.

The old `bench/run_scaling.jl` was a balanced-only time trial with poc-era
`include(...)` wiring. This slice turns it into a package-routed gate that:

- runs through `using DRM`;
- keeps the O(p) sparse precision sampler (`P = kron(Q_cond, inv(Λ))`, CHOLMOD
  triangular solve);
- covers both `balanced` and `caterpillar` tree topologies;
- uses the required p grid `{100, 1000, 10000}` by default;
- writes `report/qgate-multishape-scaling.md`;
- exits non-zero if any row is non-finite, non-converged, or if a three-point
  shape sweep has empirical `k > 1.6` in `wall ~ p^k`.

For the caterpillar tree, branch lengths are scaled so the maximum root-to-tip
height matches the balanced tree at the same `p`. That keeps the gate focused on
sparse topology / factorization scaling rather than letting Brownian variance
grow as O(p) down the ladder.

## Evidence

Smoke gate:

```sh
DRM_QGATE_PS=20,40 DRM_QGATE_NREP=2 julialauncher --project=bench bench/run_scaling.jl
```

Result: passed for both shapes.

Full gate:

```sh
julialauncher --project=bench bench/run_scaling.jl
```

Result:

```text
balanced    p=100/1000/10000: 0.761 / 7.528 / 47.812 s
caterpillar p=100/1000/10000: 1.027 / 9.338 / 68.263 s
balanced empirical k = 0.90
caterpillar empirical k = 0.91
gate verdict: PASS
```

All six fits reported `converged = true` with finite log-likelihoods. The full
table is in `report/qgate-multishape-scaling.md`.

## Rose Audit

- No engine code changed.
- The p=10,000 rows are measured locally, not extrapolated.
- The report distinguishes this topology-scaling gate from drmTMB head-to-head
  timing; no new R/drmTMB speed claim is made.
- The default gate is intentionally bench-only rather than wired into
  `Pkg.test()`, because the full p=10,000 sweep is too expensive for every CI
  run.
