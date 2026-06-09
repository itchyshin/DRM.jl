# After-task: Gaussian phylo Sparse L-BFGS default

Date: 2026-06-09

## Summary

Promoted the Gaussian phylogenetic mean cell to the all-node sparse L-BFGS route
for `algorithm = :auto`. The model cell is
`log(Mass) ~ x + phylo(1 | species)`, `sigma ~ 1` in formula terms: one
phylogenetic intercept on the mean and constant residual scale.

The route uses the same sparse all-node tree representation as the EM baseline,
but optimizes the marginal Gaussian objective directly. Mean coefficients are
profiled by sparse GLS at each variance trial, and the two log-SD gradients use
exact Takahashi selected-inverse trace terms.

## Evidence

Direct AVONET/Hackett 9,993-tip scout:

```text
route              g_tol   median_s   converged   logLik        delta_from_best   nll_for_profile
auto_sparse_lbfgs  1e-04   2.623      yes         -3653.055261  0.00e+00          yes
auto_sparse_lbfgs  1e-06   2.644      yes         -3653.055261  0.00e+00          yes
forced_sparse_em   1e-04   0.901      yes         -3653.063724  8.46e-03          no
forced_sparse_em   1e-06   8.771      no          -3653.056636  1.38e-03          no
```

Focused tests passed:

```sh
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 julia --project=. test/test_conjugate_em.jl
OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 julia --project=. -e 'using Test; include("test/test_bridge.jl"); include("test/test_conjugate_em.jl")'
```

The paired R bridge smoke in `drmTMB` now reports `partial: mu` covariance for
the admitted phylogenetic route and keeps variance-component covariance
unavailable.

## Interpretation

Loose EM can still be the fastest point-estimate shortcut, but it is not the
right default for the R bridge. Sparse L-BFGS gives the best smoke likelihood,
converges under the current gate, stores the mean fixed-effect covariance block,
and attaches the sparse objective needed for profile likelihood and bootstrap
workflows.

The next engineering target is bridge overhead and inference plumbing: separate
direct Julia kernel time from JuliaCall marshalling time, then benchmark
profile and bootstrap workers on the same default route.
