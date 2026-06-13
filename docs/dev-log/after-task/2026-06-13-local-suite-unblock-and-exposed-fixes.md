# After-Task: Local-suite unblock + the two failures it exposed (2026-06-13)

**Branch:** `shannon/unblock-locscale-profile-test` → PR #281. Local-only verification
on a core-contended Mac (Julia 1.10).

## Scope

Restore the repo's "local checks over CI" discipline: make routine `Pkg.test()`
complete on macOS instead of stalling, then fix the two latent failures the
completed run exposed (both masked for as long as the suite stalled before reaching
them).

## Changes

1. **Unblock the stall** (`test/test_locscale_profile.jl`). The first testset (a
   30-bisection reference endpoint search + the variance-boundary VM profile — ~140
   constrained Laplace re-solves at n=400) ran for minutes. Gated it behind
   `DRM_SLOW_TESTS=1`, exactly like the full-vector `confint(:profile)` testset
   already in the file. Numerics byte-identical (reverted, only wrapped). Routine run:
   minutes → ~1s. Routine profile-CI coverage retained via
   `test_gaussian_locscale_phylo_boundary.jl`.

2. **Fix the rho12-link inconsistency** (`src/gaussian_core.jl`, review P1). The
   completed suite exposed `test_predict_parameters.jl:106,124` failing: the fit
   stores `RHO_GUARD·tanh` (the 0.99999999 NaN-guard) for `scales[:rho12]`, but
   `_param_response`/`_link_deriv` for `:rho12` used plain `tanh`, so predict diverged
   from the fit by the 1e-8 guard factor (tripping `rtol=1e-8`). Aligned both to the
   guarded link, plus the test's link→response check. **35/35.**

3. **Fix the bridge profile efficiency regression** (`src/bridge.jl`, from `e179820`).
   `test_bridge.jl:131` failed `used==1` (got 4): `drm_bridge_inference(method=:profile)`
   called `profile_result(fit)` over the FULL parameter vector (μ-int, μ-slope, σ,
   resd-SD = 4 targets) then picked the SD row, so a Gaussian phylo-mean bridge query
   did 4 constrained profiles to return 1. Restricted the profile to the SD set the
   bridge actually returns (`parm = [:resd_sigma, :resd, :resd_mu]`), so it profiles
   only the SD target (1) and routes through the efficient single-target path. No-op
   for the σ-phylo route (its stored CIs are already SD rows). **test_bridge 46/46.**

## Verification

- `test_locscale_profile.jl` routine (gated-off): ~1s, clean.
- `test_predict_parameters.jl`: 35/35.
- `test_bridge.jl`: 46/46.
- `test_reml_newton_sigma_phylo.jl`: [pending in this run — confirming the bridge
  `parm` restriction is a no-op for the σ-phylo stored-CI path].
- Full `Pkg.test()`: the run that exposed #2/#3 completed all 176 testsets (no stall);
  re-run after these fixes is the green gate (Linux CI on PR #281 is the uncontended check).

## Notes

- The unblock immediately earned its keep: two real latent failures (a correctness
  link inconsistency + an efficiency regression) had been hidden purely because the
  suite never reached them. This is the "local checks over CI" payoff.
- All three are local-only commits on the PR #281 branch; nothing merged to main.
