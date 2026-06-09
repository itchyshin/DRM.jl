# AVONET phylogenetic Gaussian algorithm scout

This report times the current Julia route for a real 9,993-tip AVONET/Hackett Gaussian phylogenetic mean model. It is a direct DRM.jl benchmark, not the R bridge timing table.

## Data and model

- AVONET CSV: `/Users/z3437171/Dropbox/Github Local/pigauto/avonet/AVONET3_BirdTree.csv`
- Hackett tree: `/Users/z3437171/Dropbox/Github Local/pigauto/avonet/Stage2_Hackett_MCC_no_neg.tre`
- Tree tips: 9993; total all-node tree states: 19985; internal nodes: 9992
- AVONET input rows: 9993; skipped incomplete rows: 0
- Exact zero-length tree branches rewritten to `1e-8` before parsing: 193
- Model: `log(Mass) ~ z(Hand-Wing.Index) + z(Beak.Length_Culmen) + phylo(1 | species)`, `sigma ~ 1`
- CPU policy: Julia threads = 8, BLAS threads = 1, Julia 1.10.0

## Timings

| route | g_tol | reps | median_s | min_s | converged | logLik | delta_from_best | beta_hand_wing | beta_beak | sigma | sd_phylo | finite_vcov | nll_for_profile |
|---|---:|---:|---:|---:|---|---:|---:|---:|---:|---:|---:|---|---|
| auto_sparse_em | 1.000e-04 | 1 | 0.790 | 0.790 | yes | -3653.063724 | 0.000e+00 | 0.014172 | 0.773001 | 0.173772 | 0.098043 | no | no |

Reference row for coefficient deltas is the highest-logLik row (`g_tol = 1.000e-04`).

## Inference pipeline status

| target | current status | implication |
|---|---|---|
| Fixed-effect Wald SEs | EM fit stores an all-`NaN` covariance matrix | Fixed-effect point estimates are fast, but ordinary Wald intervals need either a post-fit information calculation or a different fit route with `vcov`. |
| Random-effect / variance-component profile CIs | EM fit has no attached `nll` closure | `profile_result(fit; parm = :resd)` is the high-value CI target, but it needs a sparse objective/profile wrapper first. |
| Parametric bootstrap | `bootstrap_result(fit; ...)` can reuse a fitted object and Gaussian refits now accept `algorithm` / `g_tol` controls | Bootstrap is the natural Julia speed-payoff path because refits are independent and threadable; use the benchmark below to check whether the advantage appears at the requested B. |

## Bootstrap benchmark

| B | mode | workers | algorithm | g_tol | ok | used | failed | elapsed_s | sec_per_used | total_time_s | message |
|---:|---|---:|---|---:|---|---:|---:|---:|---:|---:|---|
| 100 | threaded | 8 | auto_sparse_em | 1.000e-04 | yes | 100 | 0 | 32.042 | 0.320 | 32.441 | bootstrap refits used explicit Gaussian algorithm/g_tol controls |

## Reading

The single-fit sparse EM route is already using the all-node tree representation and exact Takahashi traces, so it is the right baseline for large phylogenies. The unresolved algorithm question is not whether to form the dense tip covariance; that path is not the scalable one. The unresolved question is which sparse optimizer/inference route should sit next to EM: a TMB-like sparse likelihood/gradient route, Louis or selected-inverse information for Wald SEs, and profile/bootstrap wrappers that can reuse the fast sparse machinery.

For applied users, the largest Julia advantage is likely the repeated-refit pipeline: profile likelihood or bootstrap confidence intervals for random-effect and variance-component targets. Fixed-effect Wald intervals should be cheap once information is available, but they are not where the dramatic speedup should be sold.
