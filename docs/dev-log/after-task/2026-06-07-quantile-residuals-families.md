# After-task: quantile residuals for the remaining families (#183)

Issue: #183. Spec: `report/quantile-residuals-design.md` (merged). Builds on the
existing Gaussian/Poisson `residuals(fit; type=:quantile)` mechanism.

## What changed

- `src/gaussian_core.jl`
  - Added `_conditional_dist(fam, i; μ, scales, obs)` — the per-family parameter →
    `Distributions.jl` map, the one place the working-scale conventions live, so it
    is reusable by future `simulate`/PIT/predictive-check work. Methods for
    Gaussian, Student, LogNormal, Gamma, Beta, Poisson, NegBinomial2,
    TruncatedNegBinomial2, Binomial, BetaBinomial.
  - Added `_is_continuous_family` (continuous PIT vs discrete randomized) and
    `_pit_obs` (Binomial/BetaBinomial store the observed proportion → PIT count =
    proportion · trials).
  - Rewrote `_quantile_residuals` to dispatch through the above: continuous driver
    (`u = F(y)`), discrete randomized driver (`u ~ Uniform[F(y⁻), F(y)]`), a
    zero-truncated NB2 branch (renormalized CDF), and two atomic/ordinal drivers
    (`_quantile_residuals_zeroonebeta`, `_quantile_residuals_cumulative`).
  - Tweedie throws a clear `ArgumentError` (no `Distributions.jl` CDF; follow-up).
  - Updated the `residuals` docstring to list every supported family.
- `test/test_quantile_residuals.jl` — one calibration `@testset` per family
  (moments + seeded KS vs N(0,1)), discrete-RNG reproducibility, Tweedie error,
  retained back-compat / unknown-type tests.

## Why this is correct (not just plausible)

The residual math is unchanged and already verified for Gaussian/Poisson. The
risk is entirely the parameter map, and each map was cross-checked against TWO
in-repo sources: the family's own NLL kernel and the existing `simulate(fit)`
draws (which already encode these conventions). The calibration tests then close
the loop empirically: under a correctly-specified DGP the quantile residuals must
be N(0,1), so a wrong scale convention (e.g. using σ⁻² for the NB2 size instead of
the stored value) blows up the KS statistic and the variance gate immediately.

## Parameterization notes (the traps)

- **NB2 size is stored directly in `scales[:sigma]`, NOT as σ⁻².** The design
  table said σ⁻²; the kernel and `simulate` both use the value directly
  (`NegativeBinomial(θ, θ/(θ+μ))`, θ = `scales[:sigma]`). Beta/Gamma/BetaBinomial
  genuinely use σ⁻².
- **LogNormal `means[:mu]` is `exp(η_μ)`** (response-scale median), so meanlog =
  `log(means[:mu])`.
- **TruncatedNegBinomial2** uses an explicit zero-truncated CDF rather than
  `Distributions.truncated(...; lower=0)`, to avoid relying on the discrete
  lower-bound inclusivity convention.

## Scope / non-changes

- The verified q4 engine, fitters, and all other tests are untouched.
- **Tweedie is scoped out** as the design doc allows ("as feasible") — no
  closed-form CDF in `Distributions.jl`; it raises a clear `ArgumentError`. A
  series/`tweedie`-style CDF is a clean follow-up.

## Verification

CI-only this session (no local Julia; package servers blocked). Achieved
calibration stats are produced by the CI run of `test_quantile_residuals.jl`; the
in-session derivation is in the check-log.

## Honest caveats

- KS thresholds are tolerant (`√n·D < 1.7`) and seed-fixed. They are designed to
  pass well-specified data and fail a wrong parameterization; an unlucky seed
  should be fixed by changing the seed, never by loosening the map. The moment
  gate is the redundant cross-check.
- `_conditional_dist` covers the single-distribution families; ZOI/CumulativeLogit
  remain in their own drivers (point-mass mixture / cut intervals) and are not
  expressed as a single `Distribution`.
