# After-task: AVONET phylo bootstrap thread scaling

Date: 2026-06-08

## Summary

Ran the requested thread-scaling check for the real AVONET/Hackett Gaussian
phylogenetic bootstrap. This is direct DRM.jl evidence for the sparse all-node
EM route, not an R `engine = "julia"` bridge claim.

## Result

Each cell used `B = 100`, `g_tol = 1e-4`, `OPENBLAS_NUM_THREADS=1`, and
`OMP_NUM_THREADS=1`.

| Julia threads | used | failed | elapsed_s | sec_per_refit | speedup_vs_1_thread |
|---:|---:|---:|---:|---:|---:|
| 1 | 100 | 0 | 178.230 | 1.782 | 1.00 |
| 2 | 100 | 0 | 85.916 | 0.859 | 2.07 |
| 4 | 100 | 0 | 45.241 | 0.452 | 3.94 |
| 8 | 100 | 0 | 32.042 | 0.320 | 5.56 |
| 16 | 100 | 0 | 27.604 | 0.276 | 6.46 |
| 20 | 100 | 0 | 20.291 | 0.203 | 8.78 |

The fastest measured point was 20 Julia threads. Scaling is not linear beyond
four threads, but using all 20 cores still beat the 16-thread performance-core
setting for this B=100 workload.

## Interpretation

This supports the working claim that the most visible Julia gain is likely in
repeated-refit inference: bootstrap, profile-like grids once the sparse profile
objective exists, and ADEMP simulation batches. The single fit is already fast,
but the user-visible gain compounds when thousands of independent refits can be
spread across Julia threads inside one process.

The `B = 10000` row remains a projection until run. At the 20-thread B=100
rate, it would be about 2,029 seconds, or 34 minutes, but that should be
reported as a projection rather than a completed benchmark.

## Follow-up

The next slice is the sparse inference layer for this EM route. Wald SEs need a
finite information calculation, and profile CIs need an attached sparse
objective/closure before `profile_result(fit; parm = :resd, threads = true)`
can run on the AVONET sparse phylogenetic fit.
