# After-task: fast Gaussian crossed profile likelihood

Issue: #125

Date: 2026-06-02

## Summary

Gaussian crossed and multi-random-effect fits now expose an analytic gradient
for the closed-form marginal objective. Profile-likelihood inference reuses that
stored gradient through the existing `nllgrad` path, so nuisance optimisation for
Gaussian crossed profiles no longer relies on ForwardDiff through the full
objective at each profile point.

The same gradient is also used by the Gaussian multi-RE fit optimiser.

## What Changed

- Added `grad!(Gout, theta)` inside `_fit_multi_ranef_gaussian`.
- Used the Woodbury capacitance inverse to compute:
  - `alpha = V^-1 r` for fixed-effect gradients;
  - `diag(V^-1)` for residual-scale gradients;
  - `trace(Z_k' V^-1 Z_k) - ||Z_k' alpha||^2` for each RE SD.
- Attached the gradient with `_withnll(fit, nll, grad!)`.
- Switched the Gaussian multi-RE optimiser to `Optim.OnceDifferentiable`.
- Added a profile test that checks the stored gradient against central finite
  differences away from the optimum and profiles the crossed RE SDs.

## Measured Result

Fixture: Gaussian `y ~ x + (1 | g) + (1 | h), sigma ~ 1`, deterministic seed
9302, `n = 1200`, `G = 30`, `H = 30`, `BLAS.set_num_threads(1)`.

Baseline is `origin/main` at `cde98ca` before this branch.

| target | baseline | gradient branch | speedup |
|:-------|---------:|----------------:|--------:|
| fit | 0.3860s | 0.1733s | 2.23x |
| `confint(fit; method = :profile)` | 6.5288s | 1.2014s | 5.44x |
| `profile_curve(fit, beta_x; npoints = 31)` | 2.8208s | 0.4766s | 5.92x |

Correctness checks:

- Stored gradient versus central finite difference max absolute error:
  `5.7e-08`.
- Serial and threaded profile endpoints matched exactly on the timing fixture.
- Profile-curve deviance range remained finite with max `8.966`.

## Verification

- `julia --project=. test/test_profile_ci.jl`
- `julia --project=. test/test_gaussian_ranef.jl`
- `julia --project=. test/test_multi_re.jl`
- `julia --project=. test/test_visualization.jl`
- `julia --project=. -e 'using Pkg; Pkg.test()'`
- targeted timing fixtures above

## Rose Audit

- Speed claims are baseline-to-branch measurements on the same deterministic
  fixture, not extrapolations.
- This is an internal Gaussian engine/profile speed claim, not an R/drmTMB
  comparison claim.
- No private uploaded paper or GPL source was used.
