# Check-log: quantile residuals for the remaining families (#183)

> **Status: UNVERIFIED in-session.** No Julia runtime in this cloud session
> (package servers blocked). Verification is **CI-only** via the PR's GitHub
> Actions (`test (1)`, `test (1.10)`, `docs`). Nothing here is "verified" until
> those checks are green.

## What was checked (by derivation against the family kernels + `simulate`)

The mechanism (`r_i = Φ⁻¹(u_i)`; continuous `u = F(y)`; discrete randomized
`u ~ Uniform[F(y⁻), F(y)]`) already existed for Gaussian/Poisson. The only new,
error-prone content is the per-family parameter → `Distributions.jl` map, factored
into `_conditional_dist(fam, i; μ, scales, obs)`. Each map was cross-checked against
the family's own NLL kernel AND the existing `simulate(fit)` draws (the definitive
in-repo source for these conventions):

| Family | conditional dist | scale convention (verified) |
|---|---|---|
| Gaussian | `Normal(μ, σ)` | σ = `scales[:sigma]` |
| Student-t | `μ + σ·TDist(ν)` | σ = `scales[:sigma]`, ν = `scales[:nu]` (DRM `log ν`) |
| LogNormal | `LogNormal(log μ̂, σ)` | μ̂ stored = `exp(η_μ)` = response median ⇒ meanlog = `log μ̂`; sdlog = σ |
| Gamma | `Gamma(α, μ/α)` | **α = σ⁻²** (shape) |
| Beta | `Beta(μφ, (1−μ)φ)` | **φ = σ⁻²** (precision) |
| Poisson | `Poisson(μ)` | — |
| NegBinomial2 | `NegativeBinomial(θ, θ/(θ+μ))` | **θ = σ⁻² = `exp(-2·coef(:sigma))`** (size). Superseded by #328: the NB2 kernel now carries the dispersion on the log-σ scale like Beta/Gamma, so `θ = 1/σ² = exp(-2·η_σ)` (NOT the earlier `exp(η_σ)`). `scales[:sigma]` stores σ; recover θ via `1 ./ scales[:sigma].^2`. |
| TruncNB2 | base NB2, then zero-truncate | `F_t(k) = (NB.cdf(k) − NB.cdf(0))/(1 − NB.cdf(0))`, k ≥ 1 (avoids the `truncated` discrete-lower-bound convention) |
| Binomial | `Binomial(n, p)` | p = μ (success prob), n = `scales[:trials]`; PIT count = `obs[:mu]·trials` (obs stores the proportion) |
| BetaBinomial | `BetaBinomial(n, μφ, (1−μ)φ)` | **φ = σ⁻²**, n = `scales[:trials]` |
| CumulativeLogit | ordinal cumulative `F(k)=logistic(cuts[k]−η)` | η = `scales[:ordinal_eta]`, cuts = `scales[:ordinal_cuts]`; randomize within `[F(k−1), F(k)]` |
| ZeroOneBeta | atomic mixture | mass at 0 = `zoi(1−coi)`, at 1 = `zoi·coi`; interior `(1−zoi)·Beta(μβφ,(1−μβ)φ)`; μβ = `scales[:beta_mu]`, φ = σ⁻²; randomize across the hit atom |
| Tweedie | **scoped out** | no closed-form CDF in `Distributions.jl`; throws a clear `ArgumentError` (follow-up) |

## Key parameterization gotchas confirmed

- **NB2 size (superseded by #328): now σ⁻², like Beta/Gamma.** The 2026-06-07 note
  recorded the kernel storing size directly as `exp(η_σ)`. #328 changed this so the
  NB2 dispersion is `θ = 1/σ² = exp(-2·η_σ)`, matching Beta/Gamma/BetaBinomial. The
  kernel and `simulate` now use `NegativeBinomial(θ, θ/(θ+μ))` with
  `θ = 1 ./ scales[:sigma].^2` (`scales[:sigma]` stores σ). Recover θ via
  `exp(-2·coef(:sigma))`.
- **LogNormal `means[:mu]` is the response-scale median `exp(η_μ)`, not meanlog.**
  Recovered meanlog as `log(means[:mu])`.
- **Binomial/BetaBinomial `obs[:mu]` is the observed proportion**, so the PIT count
  is `proportion · trials` (rounded).

## Tests (`test/test_quantile_residuals.jl`)

One `@testset` per family: simulate correctly-specified, seeded data, fit, compute
`residuals(fit; type=:quantile)`, then gate on BOTH:
- **moments** `|mean| < 0.15`, `0.85 < std < 1.18`;
- **seeded one-sample KS** vs N(0,1): `√n·D < 1.7` (≈ α 0.006). A wrong CDF map
  gives D ≈ 0.1–0.5 ⇒ `√n·D ≫ 1.7`, so the gate is sharp.

Plus: discrete-RNG reproducibility (`MersenneTwister(99)` twice ⇒ identical),
Tweedie `@test_throws ArgumentError`, and the existing back-compat / unknown-type
tests retained. The previous Gamma `@test_throws` (Gamma now supported) was
removed.

## Known-unknowns for CI

- `Distributions.cdf` on `BetaBinomial`, `truncated`-free zero-truncated NB2,
  ordinal cumulative, and the ZOI atomic mixture — all standard `Distributions.jl`
  CDF calls or hand arithmetic; no exotic dependency.
- KS thresholds are tolerant but seed-fixed; if a single family's seed lands
  unlucky, bump the seed (not the parameterization) — the moment gate is the
  redundant cross-check.
