# After-task: Sparse phylo location-only profile parity

Date: 2026-06-09

## Summary

The Gaussian phylogenetic mean route now has a specialised profile-likelihood
path for the single random-effect SD block used by the R bridge. The fitted
object stores a `LocOnlyObjective`, and `profile_result(fit; parm = :resd)`
routes through a one-dimensional constrained profile for this model cell rather
than the generic full-vector profiler.

The specialised route fixes the phylogenetic log-SD, optimises the residual
log-SD, and profiles the mean coefficients by sparse GLS at each trial value.
This matches the model structure more directly and removes the earlier
lower-endpoint mismatch seen from the R bridge.

## Evidence

Focused Julia checks passed with BLAS/OpenMP pinned to one thread:

```sh
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 /Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin/julia --project=. --threads=4 test/test_bridge.jl
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 /Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin/julia --project=. --threads=4 test/test_profile_ci.jl
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 /Users/z3437171/.julia/juliaup/julia-1.10.0+0.aarch64.apple.darwin14/bin/julia --project=. --threads=4 test/test_conjugate_em.jl
```

Results:

```text
test_bridge.jl:       46/46 pass
test_profile_ci.jl:   focused profile sets pass
test_conjugate_em.jl: 34/34 pass
```

The live R bridge parity probe on the AVONET/Hackett 1,000-species row returned:

| engine | lower | upper |
| --- | ---: | ---: |
| native R profile | 1.162186 | 1.350848 |
| Julia bridge profile | 1.162188 | 1.350846 |

## Scope

This is an R-bridge parity fix for the Gaussian phylogenetic location-only SD
target. It does not make every DRM.jl profile route equivalent to drmTMB, and
it does not widen the R bridge beyond the one admitted
`sd:mu:phylo(1 | species)` target.
