# Six-tip LSS boundary diagnostic

## Scope

This is a diagnostic only.  It reproduces the two retained ordered-versus-
shuffled six-tip ML fits from `test/test_lss_tip_identity.jl` without importing
that test file.  It does not alter the coefficient gate, optimiser, model
formula, or tolerance.

## Checks

1. In the default `original-test-bytes` mode, evaluate only the fixture
   definitions preceding the first `@testset` in
   `test/test_lss_tip_identity.jl`.  The runner verifies every supplied
   fixture field byte-for-byte against a separately reconstructed copy that
   uses the test's `DRM._phylo_correlation` generation call.  No testset body
   is evaluated.  The hard-coded asymmetric correlation matrix is used only
   for the independent covariance/nll oracle.
2. Fit the dedicated `sd_phylo ~ z` and the multi-component scalar-phylogeny
   cases in tree order and in the retained shuffled order.
3. Record each optimum's objective, the opposite-order objective evaluated at
   that theta, ForwardDiff score and Hessian spectrum, reported covariance
   spectrum, raw coefficient blocks, and covariance-component norms.
4. Examine the exact objective along the line between the two fitted
   `sd_phylo` blocks.  This is evidence about local flatness only; it cannot
   replace the required 4e-6 raw-coefficient parity gate.

## Acceptance / interpretation

The runner fails closed for non-convergence, non-finite objectives or
derivatives, a mismatch between `-fit.nll(theta)` and `loglik(fit)`, or a
non-PD independently rebuilt covariance.  It intentionally does **not**
declare the retained coefficient discrepancies explained merely because the
phylogenetic covariance contribution is small.  A boundary-flatness diagnosis
requires the recorded objective, score, and curvature evidence.

## Command and estimate

Estimated wall time: under three minutes at one Julia and one BLAS thread.

```sh
JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 \
  julia --project=. tools/lss_boundary_diagnostic.jl
```

The invoking shell must enforce a 180-second timeout.  The resulting log is
retained beside this contract.
