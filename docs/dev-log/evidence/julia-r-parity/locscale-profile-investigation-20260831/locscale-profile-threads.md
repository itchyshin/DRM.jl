# Canonical location-scale profile coefficient threading

## CHECK

```sh
JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=2 julia --project=. --startup-file=no \
  -e 'include("test/test_locscale_profile_threads.jl")'
```

## EXPECT

The canonical public location-scale fit exposes two selected mean coefficients.
`threads=false` profiles them serially.  With at least two Julia threads,
`threads=true` profiles independent coefficients concurrently and returns the
same finite intervals on a repeated call.  One selected coefficient remains
serial, as do all calls when threading is disabled.  The process BLAS thread
count is restored after each call.

## Boundaries

Only canonical `LocScaleObjective` fits use this coefficient-level schedule.
Endpoint arms remain serial within each coefficient so each private warm-start
chain is unchanged.  This slice changes neither the estimator nor profile
status semantics.

## Runtime

Estimated 2--4 minutes on four Julia threads, hard cap five minutes.  The
focused test is the only local fit pilot in this slice.
