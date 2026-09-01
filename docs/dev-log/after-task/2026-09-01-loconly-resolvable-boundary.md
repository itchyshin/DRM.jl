# After-task: sparse phylogenetic Gaussian numerical boundary

## 1. Goal
Repair a Julia 1.12 regression: the automatic sparse Gaussian phylogenetic-mean
route could report convergence with a spurious positive likelihood on a fixed
64-tip fixture.

## 2. Implemented
The sparse location-only objective now treats a residual variance below machine
precision relative to the phylogenetic variance as numerically unavailable.
The guard is shared by the objective, profiled beta solve, and stored gradient.
The test also compares the automatic sparse result with a dense GLS oracle.

## 3a. Decisions and rejected alternatives
The negative-likelihood guard was not weakened and reported estimates are not
silently clamped. Dense GLS was not substituted for all fits because that would
remove the large-tree route. This is a floating-point representation limit, not
a statistical lower bound.

## 4. Files touched
`src/location_only.jl`, `test/test_lss_phylo.jl`, this receipt, and its
collision-free check-log row.

## 5. Checks run
Before repair, the Julia 1.12 probe returned `converged = true`,
`loglik = 130.1325812533177`, and residual `log(sigma) = -18.7334`; direct
dense evaluation at that point gave ML NLL `74.2981`. After repair, the focused
Julia 1.12 `test/test_lss_phylo.jl` passed 36/36 in about 51 seconds. The
automatic result is finite, negative, and agrees with `algorithm = :gls` to
`1e-6` on the regression fixture.

## 6. Tests of the tests
The fixture already failed on the pre-repair source. The new dense-oracle
comparison catches a renewed false sparse optimum even if it is finite.

## 7a. Issue ledger
This advances the Julia–R parity programme and may explain the rolling CI
failure. It does not close Ayumi's profile/bootstrap, polytomy, or R-bridge
control issues. No collaborator message, release, registration, cleanup, or
remote compute action occurred.

## 8. Consistency audit
The ML estimand and public API remain unchanged. Only unrepresentable sparse
objective points are refused. GPL/MIT boundaries and the R bridge are untouched.

## 9. What did not go smoothly
Julia 1.10 is not installed locally. The active GitHub 1.10 job failed before
its log was available while the rolling job remained active, so no CI repair is
claimed until the updated branch runs there.

## 10. Known residuals
The full suite, native-R/direct-Julia/bridge parity campaign, profile/bootstrap
calibration, warm-workflow benchmarks, large-tree evidence, documentation, and
integration gates remain open. This is not proof of stability at every boundary.

## 11. Team learning
A converged optimizer flag does not validate a covariance representation. Check
a compact sparse candidate against a same-estimand dense oracle before relaxing
a numerical regression test.

## 12. Cross-product coverage
This covers one univariate Gaussian phylogenetic-mean ML boundary. It does not
cover REML, sigma-phylo, LSS scale effects, missing predictors, bivariate fits,
profile/bootstrap, the R bridge, parallel performance, DRAC/Totoro, deployment,
or worktree reconciliation.
