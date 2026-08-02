# #291 Arc 1 — baseline REML first bottleneck

**Scope:** Gaussian q4 REML baseline route only. This is a static route
inspection plus a read small-fixture record, not a candidate-estimator result.

## Evidence

The fresh p=8, nrep=3 baseline record at commit `f159206` converged for both ML
and baseline REML. Its ML elapsed time includes the first call in the Julia
process, so its `15.72 s` versus REML's `3.07 s` is **not** a method comparison.
The record also deliberately leaves `interval_status=not_evaluated`.

The first actionable bottleneck is instead structural and visible in
`src/reml_q4.jl`: `fit_q4_reml` optimizes
\(\phi=(\beta_\rho,\operatorname{lc}(\Lambda))\), sets
`nph = length(phi0)`, and supplies a central finite-difference gradient. Each
gradient request calls `reml_ll_and_mode` at both `+h` and `-h` for every outer
coordinate, after one baseline `neg_reml` evaluation. For the Arc 0 fixture,
there is one \(\beta_\rho\) coordinate and ten log-Cholesky coordinates:

\[
1 + 2(1 + 10) = 23
\]

restricted-objective/mode evaluations per gradient request before any line-search
evaluations. The count is an upper-bound route count rather than a timing
profile: the optimiser may request values without gradients, and individual
perturbations can hit the non-PD barrier. It nevertheless identifies the first
candidate target: replace or reduce the finite-difference restricted-score work
while preserving the exact current restricted objective.

Pinned `lc_zero` directions are set to zero **after** the finite-difference
loop, so their two perturbations are currently still evaluated. That is a
possible later micro-optimisation, but it must first establish that the
constraint semantics and all gates below are unchanged.

## Acceptance gates before any candidate timing

1. Independently cold-re-evaluated restricted log likelihood agrees with the
   baseline within \(10^{-6}\max(1,|\ell_R|)\).
2. \(\beta_\rho\), profiled fixed effects, and transformed \(\Lambda\) agree to
   relative Euclidean discrepancy at most \(10^{-4}\), or carry the same
   declared variance-boundary status.
3. Requested interval status remains finite, one-sided, or unavailable as in
   the baseline; finite endpoints agree to relative \(10^{-4}\).
4. Only after Gates 1--3 pass may timing be recorded, with SHA, dirty state,
   Julia/BLAS/threads, fixture, convergence, objectives, estimates, and
   interval status.

## Precise next slice

Add report-only instrumentation for the number of outer coordinates and
restricted-objective/mode calls requested by the baseline optimiser, with a
contract test. It must not alter `src/reml_q4.jl`, expose an algorithm option,
call itself AI-REML, or report a speed result. A separate approved arc is
required before changing the finite-difference path.

## Fences

No `:natgrad`, AI-REML public API, `src/` change, 10,000-tip run, #136,
bridge work, General/Registrator work, or performance headline follows from this
record.
