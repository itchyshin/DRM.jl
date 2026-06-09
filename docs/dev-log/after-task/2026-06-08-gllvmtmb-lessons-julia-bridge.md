# After-task: gllvmTMB/GLLVM.jl lessons for the Julia bridge

Date: 2026-06-08

## Summary

Added `report/gllvmtmb-lessons-for-julia-bridge.md`, a source-grounded note on
what the gllvmTMB/GLLVM.jl pair is doing well and what DRM.jl should copy before
advertising `drmTMB(..., engine = "julia")` speedups.

The note keeps the current local blocker explicit: `{JuliaCall}` is not
installed in the R library, so no live R bridge timing was produced in this
slice.

## What changed

- Audited local GLLVM.jl docs for the Gaussian reduced-rank benchmark pattern:
  same data, same Gaussian marginal likelihood, convergence gates, warm-up
  caveats, and `abs(Delta logLik)` agreement.
- Audited local gllvmTMB source/docs for the sparse phylo lesson:
  tree-input sparse `A^-1` over tips plus internal nodes is the recommended
  route, while dense tip covariance is a superseded compatibility path.
- Added a DRM.jl bridge measurement plan that separates pure Julia kernel time,
  warm R bridge time, cold R bridge time, and native TMB comparator time.
- Connected the plan to the current AVONET/Hackett direct Julia benchmark and
  the repeated-refit bootstrap/profile speed story.

## Verification

```sh
Rscript -e 'cat("JuliaCall installed: ", requireNamespace("JuliaCall", quietly=TRUE), "\n", sep="")'
```

Output:

```text
JuliaCall installed: FALSE
```

No package tests were needed for this report-only slice.

## Next

Install or activate `{JuliaCall}` for the R library used by drmTMB checks, then
run the fixed-effect Gaussian bridge timing before the phylogenetic bridge
timing. The phylogenetic rows should wait until the R bridge passes `tree =`
objects through to Julia and both engines are using sparse tree
representations.
