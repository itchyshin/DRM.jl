# After-task: crossed sparse-Laplace exact nuisance gradient (#110)

## Slice

Issue: #110, advancing #80.

Implemented exact implicit nuisance-gradient corrections for crossed sparse-Laplace
NB2, Gamma, and Beta random-intercept GLMMs. The previous scalar nuisance
derivative used a central finite difference of the full Laplace objective, which
required extra mode solves inside the optimiser.

## What changed

- Added analytic nuisance derivatives for:
  - NB2 size on `log(size)`.
  - Gamma shape through the `sigma` / CV parameterisation.
  - Beta precision through the `sigma` / precision parameterisation.
- Added `_crossed_mean_laplace_nuisance_fg`, a reusable internal value/gradient
  helper for crossed nuisance fits.
- Removed the whole-objective scalar finite-difference nuisance derivative from
  `_fit_crossed_mean_laplace_nuisance`.
- Made crossed-Laplace convergence checks finite-objective and mean-gradient
  aware: the summed-gradient tolerance now includes `g_tol * n`.
- Added a small exact-gradient polish for crossed Gamma fits to clear the large
  profile false convergence flag without changing estimates.

## Verification

Commands run locally:

- `julia --project=. test/test_crossed_laplace_generic.jl`
- `julia --project=. test/test_poisson_crossed_laplace.jl`
- `julia --project=. test/test_crossed_selected_inverse.jl`
- `julia --project=. -e 'using Pkg; Pkg.test()'`
- `julia --project=docs docs/make.jl`
- `julia --project=bench bench/profile_crossed_laplace.jl`
- `julia --project=bench bench/gen_crossed_family.jl`
- `julia --project=bench bench/fit_crossed_family.jl`
- `Rscript bench/R/fit_crossed_family.R`
- `Rscript bench/R/compare_crossed_family.R`
- `git diff --check`

Focused gradient gate:

- NB2, Gamma, and Beta exact crossed nuisance gradients match central finite
  differences with max error `<= 1e-6` on deterministic fixtures.
- Full `Pkg.test()` passed. Existing warnings remain: project/manifest resolve
  notice and the pre-existing `rtnb` overwrite warning in tests.
- Local docs build passed. Existing warnings remain: index local-link warnings,
  docstrings not in the manual, and npm audit warnings from docs tooling.

Profile report:

- `report/crossed-laplace-family-profile.md`
- All large and fixed-q profile convergence flags are true.
- Medium medians: Poisson 0.0286 s, Binomial 0.3810 s, NB2 0.1769 s,
  Gamma 0.1695 s, Beta 1.4330 s.

Paired drmTMB report:

- `report/crossed-family-benchmark.md`
- Successful paired cells are Poisson and NB2.
- Median successful-cell speedup is 39.70x.
- Range is 17.91x to 133.16x.
- Coefficient, RE-SD, and objective-parity gates pass on successful paired cells.
- Fixedq Poisson convergence is now TRUE/TRUE.

## Claim guardrails

- drmTMB still rejects Binomial, Gamma, and Beta crossed random-effect fixtures in
  this local target; those cells remain reported as unsupported R failures.
- Beta remains comparatively expensive because the exact beta third-derivative
  path is dominated by polygamma calls; large Beta is still skipped in the quick
  profile.
- No private uploaded paper or non-public manuscript material was referenced.
