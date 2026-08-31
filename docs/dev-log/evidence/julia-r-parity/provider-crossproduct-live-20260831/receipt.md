# Animal and spatial actual-R receipt

The driver source-loads `/private/tmp/drm-parity-20260830/integration/drmTMB`
with `drmTMB.DRM.jl.path` pinned to
`/private/tmp/drm-parity-20260830/integration/DRM.jl`. It fits public
`engine = "julia"` Gaussian fixed-effect profile and `B = 2` bootstrap cells
for `animal(1 | id, A = A)` and `spatial(1 | id, coords = coords)`.

For animal, the driver asserts that the stored A matrix has the exact numerical
entries of the supplied A after canonical double/dimname conversion and sends
that retained A to direct
`DRM.drm_bridge_inference`. For spatial, it asserts the R payload is the
established fixed-range converted K and `relmat(1 | id)` formula, and sends
that exact retained K to direct inference. In both cases the public profile
bounds and public bootstrap point/bounds equal direct Julia at tolerance
`1e-12`; bootstrap records 2/2 successful refits and zero failures.

Final corrected evidence commands:

```
env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 Rscript docs/dev-log/evidence/julia-r-parity/provider-crossproduct-live-20260831/actual-r-animal-spatial.R > docs/dev-log/evidence/julia-r-parity/provider-crossproduct-live-20260831/actual-r-animal-spatial-threads1-final.log 2>&1
env JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 Rscript docs/dev-log/evidence/julia-r-parity/provider-crossproduct-live-20260831/actual-r-animal-spatial.R > docs/dev-log/evidence/julia-r-parity/provider-crossproduct-live-20260831/actual-r-animal-spatial-threads4-final.log 2>&1
```

The corrected driver queries `Threads.nthreads()` from the loaded Julia runtime,
asserts the public bootstrap and profile threading metadata, and queries BLAS.
The logs prove actual Julia 1/4, public threaded false/true, one/two workers and
BLAS one. Each rerun took about one minute including JuliaCall startup, below
the two-minute estimate.

Exact SHA-256 hashes are bound by `manifest.json` and checked by `verify.py`.

Both retained logs contain two `vcov_guard.jl:87` pseudo-inverse warnings for
a variance/dispersion boundary (flat coordinate 4, rcond
`5.3091723410547726e-18`). They are preserved verbatim. They did not prevent
finite profile/bootstrap intervals or exact public-to-direct agreement, so this
run found no provider-forwarding source defect. This is same-engine plumbing
evidence only, with no native-R parity, coverage, calibration, or performance
claim.
