# After-task: Sparse L-BFGS phylo profile gradient

Date: 2026-06-09

## Summary

The Gaussian phylogenetic mean default already follows the useful GLLVM.jl lesson:
use the all-node sparse representation and a sparse L-BFGS likelihood route for
the profile/bootstrap inference pipeline. This slice tightens that route by
attaching the exact full gradient for the sparse location-only marginal
objective.

The fitted parameter vector is `[beta_mu..., log_sigma, log_sigma_phy]`. The new
gradient callback fills:

- the fixed-effect score from `-X'V^{-1}(y - X beta)`;
- the residual log-SD score from the exact Takahashi trace term for
  `S M^{-1} S'`;
- the phylogenetic log-SD score from the exact Takahashi trace term for
  `Q M^{-1}`.

This means `profile_result(fit; parm = :resd)` can use `autodiff = :stored` on
the sparse L-BFGS phylo fit, instead of the finite-difference fallback used for
Float64-only sparse objectives.

## Evidence

Focused tests passed with Julia threads enabled and BLAS/OpenMP pinned:

```sh
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 /Users/z3437171/.juliaup/bin/julia --project=. --threads=4 test/test_conjugate_em.jl
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 /Users/z3437171/.juliaup/bin/julia --project=. --threads=4 test/test_profile_ci.jl
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 /Users/z3437171/.juliaup/bin/julia --project=. --threads=4 test/test_bootstrap.jl
```

Results:

```text
test_conjugate_em.jl: 34/34 pass
test_profile_ci.jl:   56/56 pass
test_bootstrap.jl:    46/46 pass
```

The new focused checks compare the stored sparse L-BFGS gradient with central
finite differences and verify that serial and threaded profile-result calls on
the default Gaussian phylo fit return identical CI rows.

## Interpretation

This is plumbing, not a new speed headline. It makes the default sparse phylo
fit more inference-ready by giving the existing profile machinery the same kind
of stored-gradient path already used by faster crossed/profile routes. The next
measured step is to benchmark `profile_result(fit; parm = :resd, threads = true)`
on AVONET/Hackett-sized sparse L-BFGS fits, separately from any R bridge
marshalling overhead.

Rose scope note: no R-vs-Julia timing claim is made here, and no user-facing
algorithm selector is added beyond the existing `algorithm` surface.
