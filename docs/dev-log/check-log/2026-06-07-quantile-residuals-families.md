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
| NegBinomial2 | `NegativeBinomial(φ, φ/(φ+μ))` | **φ = `scales[:sigma]` directly** — the NB2 kernel stores size θ = `exp(η_σ)` in the sigma slot, **NOT** σ⁻². (Design table's "σ⁻²" was wrong here; the kernel and `simulate` both use the value directly.) |
| TruncNB2 | base NB2, then zero-truncate | `F_t(k) = (NB.cdf(k) − NB.cdf(0))/(1 − NB.cdf(0))`, k ≥ 1 (avoids the `truncated` discrete-lower-bound convention) |
| Binomial | `Binomial(n, p)` | p = μ (success prob), n = `scales[:trials]`; PIT count = `obs[:mu]·trials` (obs stores the proportion) |
| BetaBinomial | `BetaBinomial(n, μφ, (1−μ)φ)` | **φ = σ⁻²**, n = `scales[:trials]` |
| CumulativeLogit | ordinal cumulative `F(k)=logistic(cuts[k]−η)` | η = `scales[:ordinal_eta]`, cuts = `scales[:ordinal_cuts]`; randomize within `[F(k−1), F(k)]` |
| ZeroOneBeta | atomic mixture | mass at 0 = `zoi(1−coi)`, at 1 = `zoi·coi`; interior `(1−zoi)·Beta(μβφ,(1−μβ)φ)`; μβ = `scales[:beta_mu]`, φ = σ⁻²; randomize across the hit atom |
| Tweedie | **scoped out** | no closed-form CDF in `Distributions.jl`; throws a clear `ArgumentError` (follow-up) |

## Key parameterization gotchas confirmed

- **NB2 size is stored directly, not as σ⁻².** This is the single biggest trap and
  the design doc's table had it as σ⁻². The kernel (`negbinomial.jl`) uses
  `r = exp(η_σ)` and `scales[:sigma] = exp(Xσβ)`, and `simulate` uses
  `NegativeBinomial(θ, θ/(θ+μ))` with `θ = scales[:sigma]`. The residuals map
  matches that exactly. (Beta/Gamma/BetaBinomial *do* use σ⁻².)
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
