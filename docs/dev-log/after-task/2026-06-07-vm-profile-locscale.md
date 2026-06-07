# After-task: Venzon–Moolgavkar guarded-Newton profile endpoints (location–scale)

Issue: #202, scout backlog #227 item C15, #209. Builds on #221/#223
(`_ls_profile_ci`, public `confint(:profile)` routing).

## What changed

- `src/locscale_profile.jl` — the location–scale profile-CI endpoint search is
  now a **Venzon–Moolgavkar-style guarded-Newton** root-find. The previous
  `_ls_profile_root` did bracket EXPANSION + 18 fixed BISECTIONS per endpoint
  (~30–50 constrained re-optimisations). The new search:
  - brackets the χ²₁ crossing with a short geometric expansion, then
  - refines with a guarded Newton step that uses the profile deviance value AND
    its **envelope-theorem slope** `h'(t) = dir · ∂nll/∂θ[idx]`, where
    `∂nll/∂θ[idx]` is the `idx`-component of the exact `_ls_marginal_grad`
    evaluated at the constrained optimum (the free-parameter gradient vanishes
    there by stationarity, so the total derivative reduces to that one
    component — no extra constrained solves);
  - falls back to bisection whenever a Newton step would leave the maintained
    bracket or the slope is unusable, so correctness stays bracket-guaranteed;
  - warm-starts the free-parameter init and inner mode across steps.
- `_ls_profile_nll` now returns `(minval, minimizer, ok)`. `ok = false` flags an
  infeasible constrained solve (the documented `1e18` value sentinel, a
  non-finite optimum, or a non-finite minimiser).
- **Variance/correlation robustness.** When a trial point is infeasible (Λ driven
  near-singular toward a boundary), the root-finder treats that direction as a
  boundary: if no crossing has been bracketed, the endpoint is unbounded
  (`±Inf`); once bracketed, the upper bracket end is pulled into the feasible
  region and the search bisects there. So `confint(fit; method = :profile)` now
  runs on the **FULL** location–scale parameter vector, including the covariance
  block — the `parm = :mu` scoping that #223 had to use is removed from the
  public test.

## Why this is correct (not just faster)

The defining property of a profile endpoint is `2(ℓ̂ − ℓ_profile) = χ²₁`, i.e. the
profile deviance sits exactly on the threshold. The guarded Newton converges to
the *same root* as bisection — the slope only changes *how fast*, never *where*.
The test gates this two ways: (a) the VM endpoints match a reference
bracket+bisection search to `rtol = 1e-3` on the well-identified mean slope, and
(b) the profile NLL at the returned endpoint lands on the χ²₁ threshold
(`rtol = 1e-2`).

## Scope / non-changes

- The **generic** Gaussian/crossed profile path (`profile_result`,
  `_profile_endpoint_result` in `src/inference.jl`) is untouched — it already
  used a guarded-Newton + bisection scheme. Only the location–scale
  `_ls_profile_ci`/`_ls_profile_root` were upgraded.
- The `_ls_profile_result` router in `inference.jl` is unchanged; it still calls
  `_ls_profile_ci`, which now uses the VM search internally.
- Wald inference, `check_drm`, and the `LocScaleObjective` wiring are unchanged.

## Verification

CI-only this session — no local Julia/R runtime (package servers blocked by the
environment network policy). Checks run on the PR CI matrix (Julia 1.10 + 1).

Extended `test/test_locscale_profile.jl`:
- VM endpoints vs a reference bracket+bisection helper on the mean slope, agree
  to `rtol = 1e-3`;
- profile NLL at an endpoint on the χ²₁ threshold (`rtol = 1e-2`);
- FULL-vector `confint(fit; method = :profile)` (covariance block included) runs
  without error; every endpoint is finite or `±Inf` (never `NaN`) and brackets
  the estimate; `profile_result` lower/upper unbounded flags agree with the
  returned endpoints.

## Honest caveats

- I cannot measure wall-clock here (no local Julia). The "far fewer constrained
  re-optimisations than 18 bisections" claim is by construction (Newton's
  quadratic convergence with warm-started solves) and is *expected*, not
  measured this session. What CI verifies is **correctness**: same endpoints as
  bisection to tolerance, and the χ²₁ threshold property.
- Full-vector profiling of a covariance parameter toward a boundary may return
  `±Inf` (an unbounded / non-identified direction). That is the correct profile
  answer at a Watanabe-singular boundary, not a failure — it mirrors the Wald
  path returning `Inf` SEs there.

## Follow-ups

- Optional: parallelise the two endpoint arms for the location–scale route
  (mirroring the generic endpoint-threaded path) once inner-solve thread-safety
  is confirmed.
