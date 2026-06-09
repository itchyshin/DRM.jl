# After-task: AVONET phylo Gaussian algorithm scout

Date: 2026-06-08

## Summary

Added a reproducible AVONET/Hackett benchmark harness for the large Gaussian
phylogenetic mean cell and wired Gaussian bootstrap refits to accept the same
`algorithm` and `g_tol` controls as `drm(...)`. The harness is intentionally
direct DRM.jl evidence, not an R bridge claim: it times the current
`algorithm = :auto` route on the real 9,993-tip Hackett tree and writes a
Markdown report with timing, logLik, convergence, covariance, profile-objective,
and bootstrap-smoke status.

The main conclusion is organisational rather than celebratory. The current
all-node sparse EM route is the right scalable baseline for fitting this model,
but the more general inference route is still likely a sparse TMB-like
likelihood/gradient path or an equivalent sparse information layer. That is the
route that should make fixed-effect Wald SEs, variance-component profiles, and
auditable random-effect CIs feel natural.

## What Changed

- Added `bench/avonet_phylo_gaussian_algorithms.jl`.
  - Finds local AVONET/Hackett files from `pigauto` or `BACE`.
  - Rewrites exact zero-length Hackett branches to `1e-8` before parsing, because
    the sparse tree precision requires positive branch lengths.
  - Uses the full tree: 9,993 tips, 9,992 internal nodes, and 19,985 all-node
    states.
  - Fits
    `log(Mass) ~ z(Hand-Wing.Index) + z(Beak.Length_Culmen) + phylo(1 | species)`,
    `sigma ~ 1`.
  - Times `g_tol = 1e-4`, `1e-6`, and `1e-8` under the current `:auto` route
    (`:auto -> all-node sparse EM` for this cell).
  - Optionally runs a bootstrap benchmark via `--bootstrap-B`.
  - Supports `--bootstrap-mode=serial`, `threaded`, or `both`, recording worker
    count and per-successful-refit time.
- Updated Gaussian bootstrap entry points:
  - `bootstrap_result(formula, Gaussian(); ..., algorithm, g_tol)`;
  - `bootstrap_result(fit::DrmFit{<:Gaussian}; ..., algorithm, g_tol)`;
  - matching `bootstrap_summary(...)` and `bootstrap_ci(...)` wrappers.
  Non-Gaussian bootstrap dispatch is unchanged.
- Added a focused bootstrap test on a small Gaussian phylo fixture to prove that
  fit-based and formula-based Gaussian bootstrap refits accept the solver
  controls.
- Added `report/avonet-phylo-gaussian-algorithms.md`.

## Measured Result

Run:

```sh
julia --project=. --threads=4 bench/avonet_phylo_gaussian_algorithms.jl --g-tols=1e-4,1e-6,1e-8 --bootstrap-B=20 --bootstrap-mode=both
```

CPU policy: Julia threads = 4, BLAS threads = 1, Julia 1.10.0. The script warms
the current sparse EM route before timing.

| route | g_tol | median_s | converged | logLik | delta from best |
|:------|------:|---------:|:----------|-------:|----------------:|
| auto sparse EM | 1e-4 | 0.790 | yes | -3653.063724 | 7.088e-03 |
| auto sparse EM | 1e-6 | 8.715 | no | -3653.056636 | 0.000e+00 |
| auto sparse EM | 1e-8 | 8.682 | no | -3653.056636 | 0.000e+00 |

The `1e-4` row is a strong candidate for quick smoke/default discussion: it is
about an order of magnitude faster after warmup and changes the log-likelihood
by about `0.007` on this large real data set. It should not be promoted to a
default without a small parity suite across simulated and real fixtures.

The strict `1e-6`/`1e-8` rows reach the same likelihood and estimates, but report
`converged = false` because the current EM iteration cap is reached. That flag is
useful: the estimates are stable, but the convergence criterion and iteration
policy need tidying before this becomes reader-facing evidence.

The B=20 bootstrap benchmark succeeded using explicit Gaussian refit controls
(`algorithm = :auto`, `g_tol = 1e-4`):

| B | mode | workers | used | failed | elapsed_s | sec_per_used |
|--:|:-----|--------:|-----:|-------:|----------:|-------------:|
| 20 | serial | 1 | 20 | 0 | 34.860 | 1.743 |
| 20 | threaded | 4 | 20 | 0 | 10.811 | 0.541 |

Threaded bootstrap was `3.22x` faster than serial on the simulated-refit phase
with four Julia workers.

## Inference Answer

The user's intuition is right: the largest practical Julia payoff is unlikely
to be ordinary fixed-effect Wald intervals. Fixed-effect Wald SEs should be
cheap once an information matrix is available.

The bigger payoff is profile likelihood or bootstrap confidence intervals for
random-effect and variance-component targets, because those workflows refit the
same large model many times and can use warm starts, sparse factors, and Julia
threading.

Current blockers and fixes:

- The EM fit stores an all-`NaN` covariance matrix, so fixed-effect Wald SEs are
  not available from this route yet.
- The EM fit has no attached `nll` closure, so `profile_result(fit; parm = :resd)`
  cannot run on this route yet.
- `bootstrap_result(fit; ...)` can reuse the fitted object, but the Gaussian
  refit closure previously called `drm(...)` without `algorithm` or `g_tol`.
  This slice fixes that control plumbing and records the first larger-B
  serial/threaded evidence.

## Next Engineering Slice

Treat this as an algorithm organisation task:

1. Add `algorithm` and `g_tol` controls to Gaussian `bootstrap_result(...)`
   refits. Done in this slice for Gaussian formula-based and fit-based
   bootstrap.
2. Benchmark `B = 20` and threaded `B = 20` on the AVONET/Hackett model. Done:
   four-worker threaded refits were `3.22x` faster than serial.
3. Next benchmark production-scale bootstrap (`B = 100` or `B = 200`) and, if
   possible, a matched R/TMB repeated-refit comparator. That is the fair place
   to make the "bigger B reveals the Julia advantage" claim.
4. Decide the inference route for the Gaussian phylo mean cell:
   - post-fit sparse information / Louis-style SEs for the EM fit; or
   - a sparse TMB-like likelihood/gradient route that attaches `nll`, `nllgrad`,
     and `vcov`.
5. Once one route exists, run `profile_result(fit; parm = :resd, threads = true)`
   and compare profile/bootstrap intervals for the phylo SD.
6. Only then mirror the successful controls into the R bridge so
   `drmTMB(..., engine = "julia")` can expose fast, auditable uncertainty for
   the models where Julia is actually helping.

## Verification

- `julia --project=. -e 'include("bench/avonet_phylo_gaussian_algorithms.jl"); println("avonet bench harness load ok")'`
- `julia --project=. test/test_bootstrap.jl`
- `julia --project=. --threads=4 bench/avonet_phylo_gaussian_algorithms.jl --g-tols=1e-4,1e-6,1e-8 --bootstrap-B=20 --bootstrap-mode=both`

## Rose Audit

- This is a direct DRM.jl benchmark, not an R/drmTMB bridge speed claim.
- The benchmark uses real local AVONET/Hackett data rather than simulated
  phylogenetic data.
- The report does not claim EM is the final fastest algorithm. It identifies EM
  as the current all-node sparse baseline and names the sparse TMB-like /
  information route as the more general inference target.
- No GPL drmTMB source or private paper material was copied.
