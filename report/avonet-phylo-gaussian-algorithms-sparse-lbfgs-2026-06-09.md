# AVONET phylogenetic Gaussian algorithm scout

This report times the current Julia route for a real 9,993-tip AVONET/Hackett Gaussian phylogenetic mean model. It is a direct DRM.jl benchmark, not the R bridge timing table.

## Data and model

- AVONET CSV: `/Users/z3437171/Dropbox/Github Local/pigauto/avonet/AVONET3_BirdTree.csv`
- Hackett tree: `/Users/z3437171/Dropbox/Github Local/pigauto/avonet/Stage2_Hackett_MCC_no_neg.tre`
- Tree tips: 9993; total all-node tree states: 19985; internal nodes: 9992
- AVONET input rows: 9993; skipped incomplete rows: 0
- Exact zero-length tree branches rewritten to `1e-8` before parsing: 193
- Model: `log(Mass) ~ z(Hand-Wing.Index) + z(Beak.Length_Culmen) + phylo(1 | species)`, `sigma ~ 1`
- CPU policy: Julia threads = 1, BLAS threads = 1, Julia 1.10.0

## Timings

| route | g_tol | reps | median_s | min_s | converged | logLik | delta_from_best | beta_hand_wing | beta_beak | sigma | sd_phylo | finite_vcov | nll_for_profile |
|---|---:|---:|---:|---:|---|---:|---:|---:|---:|---:|---:|---|---|
| auto_sparse_lbfgs | 1.000e-04 | 1 | 2.623 | 2.623 | yes | -3653.055261 | 0.000e+00 | 0.014181 | 0.772964 | 0.174114 | 0.097931 | no | yes |
| auto_sparse_lbfgs | 1.000e-06 | 1 | 2.644 | 2.644 | yes | -3653.055261 | 0.000e+00 | 0.014181 | 0.772964 | 0.174114 | 0.097931 | no | yes |
| auto_sparse_lbfgs | 1.000e-08 | 1 | 2.638 | 2.638 | yes | -3653.055261 | 0.000e+00 | 0.014181 | 0.772964 | 0.174114 | 0.097931 | no | yes |
| forced_sparse_em | 1.000e-04 | 1 | 0.901 | 0.901 | yes | -3653.063724 | 8.463e-03 | 0.014172 | 0.773001 | 0.173772 | 0.098043 | no | no |
| forced_sparse_em | 1.000e-06 | 1 | 8.771 | 8.771 | no | -3653.056636 | 1.375e-03 | 0.014181 | 0.772964 | 0.174114 | 0.097931 | no | no |
| forced_sparse_em | 1.000e-08 | 1 | 8.745 | 8.745 | no | -3653.056636 | 1.375e-03 | 0.014181 | 0.772964 | 0.174114 | 0.097931 | no | no |

Reference row for coefficient deltas is the highest-logLik row (`g_tol = 1.000e-04`).

## Inference pipeline status

| target | current status | implication |
|---|---|---|
| Fixed-effect Wald SEs | Sparse L-BFGS stores the profiled sparse-GLS fixed-effect covariance block | Fixed-effect Wald intervals can be read from the `:mu` block; scale and variance-component Wald rows remain deliberately unset in this first slice. |
| Random-effect / variance-component profile CIs | Sparse L-BFGS attaches the full sparse objective closure | `profile_result(fit; parm = :resd)` is the high-value CI target; it is now mechanically possible and should be benchmarked next. |
| Parametric bootstrap | `bootstrap_result(fit; ...)` can reuse a fitted object and Gaussian refits now accept `algorithm` / `g_tol` controls | Bootstrap is the natural Julia speed-payoff path because refits are independent and threadable; use the benchmark below to check whether the advantage appears at the requested B. |

No bootstrap smoke was requested. Run with `--bootstrap-B=1` or larger to record the current refit behavior.
## Reading

The single-fit sparse EM route and the sparse L-BFGS route both use the all-node tree representation, so the algorithm question is no longer dense tips versus sparse nodes. The current default for this cell is sparse profiled L-BFGS with exact Takahashi trace gradients and an attached objective for profile/bootstrap workflows. EM remains available as an explicit comparator and can be very fast at loose tolerance, but it does not carry the profile objective or covariance surface in this slice.

For applied users, the largest Julia advantage is likely the repeated-refit pipeline: profile likelihood or bootstrap confidence intervals for random-effect and variance-component targets. Fixed-effect Wald intervals should be cheap once information is available, but they are not where the dramatic speedup should be sold.
