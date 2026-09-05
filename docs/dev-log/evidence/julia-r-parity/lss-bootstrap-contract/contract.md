# Gaussian LSS bootstrap contract — approved programme S11

Root owns src/inference.jl and test/test_lss_bootstrap_contract.jl. Other lanes
are read-only reviewers or own disjoint diagnostic paths. Preflight found only
our active lease. All-ref scout found no prior repair to reuse; eff22d9d warm
starts apply to fixed effects only and are not transplanted.

For each replicate: y*=X beta + sum_c Z_c D_c L_c xi_c + D_e epsilon.
All xi_c and epsilon are independent standard normal vectors. Every fitted mean
variance component contributes, including scalar terms without an sd formula.
LSS phylogenetic covariance is normalized tree correlation; iid is identity.
Named phylogenetic indices and SD designs use full tree-tip order before masks.
IID components and coefficient segments follow mean-formula order. Every draw
allocates scratch separately; prepared designs/factors are read-only.

Original missing response positions remain unobserved in simulated refits.
Gaussian LSS fit-based refits preserve ML/REML. Formula-based Gaussian bootstrap
must use the same marginal simulator. Existing non-LSS and non-Gaussian behavior
is outside the new helper; LSS seed methods other than ML/REML must error. Ordinary Gaussian REML and MAP
refit propagation remain required existing gaps outside this helper.

Tests use explicit known coefficients and independent seeded component draws,
then public fit-based REML summaries versus manually seeded REML refits. This
checks the simulator separately from optimizer behavior. Include dedicated,
multiple iid, iid+phylo, scalar phylo, missing masks, serial/threaded workflows.
No covariance result substitutes for the two original strict coefficient failures.
Dense phylogenetic simulation remains a performance limitation, not a speed win.
Previously denied gaussian_structured.jl and gaussian_sparse_lss.jl are untouched.

## Review and RED receipts
Rose approved this contract with full-design/name/finite-value guards. Corrected
RED003:13pass/9fail, including the isolated single-phylo REML refit mismatch.
RED001 accidentally shadowed the phylo marker with a Boolean keyword; it is
retained as a harness mistake, not claimed as clean model-failure evidence.
RED002 fixes that error. New deterministic draws are checked at known nonzero
component scales. B3 public comparisons use check_converged=false to isolate
estimator propagation; zero exceptions is not evidence all optimizers converged.

## Shared parallel collector defect (approved S5/S11)
The existing neighbouring Poisson test failed two identical-seed comparisons.
A no-fit collector regression then recorded249successfulslots outof250 while
every refit succeeded. The packed BitVector `ok=falses(B)` shares words across
workers. It is replaced by byte-addressable `fill(false,B)`, preserving the
meaning of success and failure. A word-aligned B256 probe did not reproduce the
race and is retained; B250 over300batches does. Rose approved the minimal fix.
No optimizer setting or convergence criterion was weakened.

Final001 retained185pass/1fail: new observed-count test accidentally removed an
already-missing response, leaving the observed count unchanged. Corrected test
removes the first (observed) row and asserts that precondition. All125 existing
neighbours passed after the flag repair, including both earlier Poisson failures.
This test correction does not change the simulator or its declared count guard.
