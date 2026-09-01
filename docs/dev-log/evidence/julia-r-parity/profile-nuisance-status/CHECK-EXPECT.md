# Profile nuisance-status leaf — CHECK / EXPECT

## CHECK

Run the standalone deterministic test after it is wired by the parent:

```sh
JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 \
  julia --project=. -e 'using DRM; include("test/test_profile_nuisance_status.jl")'
```

Expected budget: under 30 seconds warm and under 120 seconds including first
compilation. Stop and retain the log if it exceeds 120 seconds. This is pure
analytic objective work; it does not fit a statistical model or use remote
compute.

## EXPECT

For `f(v,u) = v²/2 + (u - 2v)²/2`, nuisance profiling at fixed `v` accepts
only a finite minimizer, a finite re-evaluated objective, and successful Optim
termination. It records method, fallback use, and reason. The direct one-
parameter case remains valid without an optimizer.

A failed primary solver may use a successful Nelder--Mead fallback. An exhausted
fallback, non-finite value, or caught objective exception fails the endpoint:
the relevant CI arm is signed infinity, `endpoint_failed=true`, and
`unbounded=false`; its failed solve never warms the next point. Interrupts are
re-thrown.

Generic `profile_result` exposes arm method/fallback/reason in diagnostics only;
the existing CI row shape is unchanged. Plot-data providers either report an
indexed profiling failure or explicitly carry status/NaN. They do not clamp a
materially negative likelihood-ratio value to zero. A no-nuisance 2-D surface
still evaluates directly.

This leaf records solver termination, not stationarity proof. It does not claim
that a first LR crossing is globally unique when a profile is non-monotone, and
does not alter the specialised location-only or location-scale backends.
