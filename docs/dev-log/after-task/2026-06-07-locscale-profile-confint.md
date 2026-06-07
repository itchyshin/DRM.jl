# After-task: public confint(:profile) for the location–scale fit

Issue: #202 (tracked as item 2 of #209). Builds on #221 (`_ls_profile_ci`).

## What changed

- `confint(fit; method = :profile)` and `profile_result(fit)` now work on a
  `drm()`-fitted non-Gaussian location–scale model (the coupled
  `(1 | tag | group)` random effect shared by the `mu` and `sigma` formulas).
  Previously they threw *"profile intervals require the fitted objective; this
  model was not built with one"* because the location–scale `DrmFit` carried
  neither an `nll` closure nor its structured design.
- The fit now stores its structured design in the existing `DrmFit.nll` slot
  (typed `Any`) as a callable `LocScaleObjective` — a valid `θ ↦ marginal-NLL`
  objective in the engine packing, so generic objective-evaluation still works.
  No `DrmFit` field was added.
- `profile_result` recognises the `LocScaleObjective` type and routes to the
  robust trust-region profiler `_ls_profile_ci`, permuting between the `DrmFit`
  `:recov` coefficient order `[logL11, logL22, L21]` and the engine packing
  `[logL11, L21, logL22]` (the permutation is an involution).
- `check_drm` uses the exact analytic outer gradient (`_ls_marginal_grad`) for
  these fits — ForwardDiff cannot differentiate the Float64-only inner
  mode-solve — which also upgrades `max_abs_grad` from `NaN` to a real norm.

## Scope / non-changes

- The generic Gaussian profile path is untouched: the `LocScaleObjective`
  branch is gated on the exact type, and every other fit hits the existing
  `fit.nll === nothing` guard exactly as before.
- Threading is not yet used for the location–scale route (it profiles serially);
  `profile_result(...).autodiff` reports `:locscale` for this backend.
- Wald inference (`confint`, `stderror`, `coeftable`) is unchanged.

## Verification

CI-only this session — no local Julia/R runtime (the package servers are
blocked by the environment network policy), so all checks ran on the PR CI
matrix (Julia 1.10 + 1).

New public-API testset in `test/test_locscale_profile.jl` on a
`drm(bf(y ~ x + (1|p|species), sigma ~ x + (1|p|species)), NegBinomial2())` fit:

- `confint(:profile)` brackets every estimate and matches `:wald` on the
  well-identified mean slope (`rtol = 0.35`);
- the variance parameter (`logL11`) gets a finite, bracketed profile CI;
- `parm = :mu` restricts to that block; `profile_result(...).autodiff === :locscale`;
- `check_drm` reports a finite `max_abs_grad`.

The pre-existing internal `_ls_profile_ci` tests (mean slope ≈ Wald, χ²₁
threshold at the endpoint, finite variance-param CI) remain and continue to
pass.

## Follow-ups

- Optional: parallelise the location–scale profile arms (mirroring the generic
  endpoint-threaded path) once thread-safety of the inner solve is confirmed.
- The remaining #209 items (drmTMB parity fixture for `nbinom2-locscale`,
  blocked on network egress to CRAN; suite-runtime trimming) are unaffected.
