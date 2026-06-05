# Design: randomized quantile residuals for the remaining families — #183

**Status:** design / implementation map. Extends an existing, working mechanism;
the only new content is the **per-family conditional CDF/parameterization** (the
part that's easy to get subtly wrong, so each cell is verified locally). No engine
changes. Independent of #186/#187. DHARMa / glmmTMB / drmTMB parity.

## What exists

`residuals(fit; type = :quantile)` (`src/gaussian_core.jl:327`,
`_quantile_residuals` at `:339`) already implements the Dunn–Smyth randomized
quantile residual `r_i = Φ⁻¹(u_i)` for **Gaussian** (continuous) and **Poisson**
(discrete). The two mechanisms are generic:

- **continuous:** `u_i = F(y_i ; θ_i)`;
- **discrete (randomized):** `u_i ~ Uniform[F(y_i⁻ ; θ_i), F(y_i ; θ_i)]`
  (`a + (b−a)·rand(rng)`), `clamp`ed to `(eps, 1−eps)`.

Per-observation parameters come from the stored `fit.means[:mu]` (μ) and
`fit.scales` (σ etc.); `rng` is already threaded for reproducibility.

The `else` branch (`:361`) throws "needs a verified per-family CDF mapping —
tracked in a follow-up" — **this issue**.

## The gap = one dispatch + correct parameterization

Add a per-family `_conditional_dist(fam, i; μ, scales, aux) -> Distributions.Distribution`
and route each family to the **continuous** or **discrete (randomized)** driver
that already exists — plus an **atomic** driver for mixtures with point masses
(zero-inflation / Tweedie mass at 0 / ZOI). The residual math is unchanged; the
risk is entirely in the **parameter map** from DRM's stored working scale to the
`Distributions.jl` constructor.

### DRM scale convention (the gotchas, from the parity suite + family kernels)
`fit.scales[:sigma]` stores **σ = exp(η_σ)** (per-obs). The dispersion/shape used
by several families is **`σ⁻²`** (the kernels use `exp(−2 logσ)`; e.g. Gamma α,
Beta φ in `sparse_laplace_glmm.jl`). NB2/Student have documented transforms
(parity `README.md`): NB2 size `φ = σ⁻²` (DRM `log θ = −2 log σ`), Student
`ν = exp(η)` (DRM `log ν`, vs drmTMB `log(ν−2)`). **Get these exact** — they are
the failure mode this issue exists to prevent.

### Per-family map

| Family | Kind | `Distributions.jl` (per-obs) | Param map from (μ, σ=`scales[:sigma]`, aux) |
|---|---|---|---|
| **Student-t** | continuous | `μ + σ·TDist(ν)` (`LocationScale`) | `ν` = stored df (`log ν` scale) |
| **LogNormal** | continuous | `LogNormal(meanlog, sdlog)` | `meanlog = η_μ` (log-link), `sdlog = σ` — confirm μ stored as meanlog vs mean |
| **Gamma** | continuous | `Gamma(α, μ/α)` (shape, scale ⇒ mean μ) | `α = σ⁻²` |
| **Beta** | continuous | `Beta(μ·φ, (1−μ)·φ)` (mean–precision) | `φ = σ⁻²` |
| **NegBinomial2** | discrete (rand.) | `NegativeBinomial(φ, φ/(φ+μ))` | `φ = σ⁻²` (size) |
| **TruncatedNegBinomial2** | discrete (rand.) | `truncated(NegativeBinomial(φ, p); lower)` | as NB2 + truncation point |
| **Binomial** | discrete (rand.) | `Binomial(nᵢ, pᵢ)` | `pᵢ = logistic(η)`, `nᵢ` = trials from `cbind(s,f)` |
| **BetaBinomial** | discrete (rand.) | `BetaBinomial(nᵢ, μφ, (1−μ)φ)` | `φ = σ⁻²`, `nᵢ` = trials |
| **ZeroOneBeta** | **atomic** | mass at 0 and/or 1 + `Beta(·)` on (0,1) | ZOI probs + Beta as above |
| **Tweedie** | **atomic** (1<p<2) | compound Poisson–Gamma; mass at 0, continuous >0 | needs a Tweedie CDF (see below) — *as feasible* |
| **CumulativeLogit** | discrete ordinal (rand.) | category cumulative probs `F(k)=logistic(θ_k−η)` | randomize within the observed category's prob interval |

### Atomic driver (ZOI / Tweedie)
For a distribution with point mass `π₀` at 0 (and `π₁` at 1 for ZOI) plus a
continuous part `G` on the interior: `F(y⁻)`/`F(y)` straddle the atom, so a value
**at** an atom gets `u ~ Uniform[F(atom⁻), F(atom)]` (randomized across the mass),
and interior values use `π₀ + (1−π₀−π₁)·G(y)`. This generalizes the discrete
driver; implement once and reuse for ZOI and Tweedie.

### Tweedie caveat
`Distributions.jl` has no Tweedie CDF; the compound Poisson–Gamma CDF needs a
series/`tweedie`-style evaluation. **Scope Tweedie as "as feasible" / a separate
follow-up** — don't block the other nine families on it. Same posture for any
family whose CDF can't be evaluated cleanly.

## Acceptance / test plan (local Julia — per family)

Per the issue, each CDF mapping is verified, not taken on faith:
1. **Calibration:** simulate from a correctly-specified model for that family
   (seeded), fit, compute `residuals(fit; type=:quantile)`; assert the residuals
   are ≈ `N(0,1)` — moments (mean≈0, var≈1) **and** a KS test against the standard
   normal at a fixed seed. This is the real correctness gate (catches a wrong
   parameterization immediately).
2. **Discrete randomization:** residuals finite, in range; reproducible under a
   fixed `rng`; uniform-within-interval verified on a tiny hand case.
3. **Atomic:** ZOI residuals well-calibrated with non-trivial 0/1 masses.
4. **De-list:** remove each verified family from the `else`-branch error message.
5. One test per family in `test/test_quantile_residuals.jl`.

## Dependencies & sequencing

- Independent of the coevolution work; pure post-fit. Can proceed now.
- **Order:** continuous families first (Student-t, LogNormal, Gamma, Beta —
  simplest, no randomization), then discrete (NB2/TruncNB2, Binomial,
  BetaBinomial, CumulativeLogit), then atomic (ZOI), then Tweedie *as feasible*.
- Shares the **per-obs parameter→distribution map** with any future
  `simulate`/PIT/predictive-check work — implement `_conditional_dist` so it's
  reusable beyond residuals.

## Implementation checklist

- [ ] `_conditional_dist(fam, i; μ, scales, aux)` per family (the table above), with the σ⁻² / `log ν` conventions correct.
- [ ] Continuous + discrete drivers reuse the existing code; add the **atomic** driver for ZOI/Tweedie.
- [ ] Route each family in `_quantile_residuals`; shrink the `else` error to only the genuinely-unsupported (Tweedie, until done).
- [ ] Per-family calibration test (moments + KS, seeded) in `test/test_quantile_residuals.jl`.
- [ ] Docstring: list supported families; note discrete randomization + `rng`.
- [ ] (stretch) factor `_conditional_dist` for reuse by `simulate`/PIT checks.
