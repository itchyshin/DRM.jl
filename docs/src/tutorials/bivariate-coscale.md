# Changing residual coupling with rho12

!!! note "Status — Stable"
    Mirrors drmTMB's [Changing residual coupling with rho12](https://itchyshin.github.io/drmTMB/articles/bivariate-coscale.html).
    **In DRM.jl today:** bivariate Gaussian location–scale with a
    predictor-dependent residual correlation `ρ12` (fixed effects, ML).

With two responses, the interesting structure is often the **residual
correlation** ρ12 — how `y1` and `y2` co-vary *after* accounting for their means.
DRM.jl lets ρ12 depend on predictors, with its own formula, exactly as drmTMB.

## A correlation that changes with a covariate

We simulate two standard responses whose residual correlation rises with `x`,
then recover that structure. ρ12 is modelled on the `atanh` scale (so it always
stays in `(-1, 1)`):

```@example bc
using DRM, Random
Random.seed!(11)

n = 3000
x = randn(n)
ρ = tanh.(0.2 .+ 0.6 .* x)          # true residual correlation, rising with x
z1 = randn(n); z2 = randn(n)
y1 = z1
y2 = ρ .* z1 .+ sqrt.(1 .- ρ .^ 2) .* z2
dat = (; y1, y2, x)

fit = drm(bf(mu1 = @formula(y1 ~ x), mu2 = @formula(y2 ~ x),
             sigma1 = @formula(sigma1 ~ 1), sigma2 = @formula(sigma2 ~ 1),
             rho12 = @formula(rho12 ~ x)), Gaussian(); data = dat)

coef(fit, :rho12)        # atanh(ρ12): (Intercept), x  — ≈ [0.2, 0.6]
```

The coefficients are on the `atanh` scale. Back on the correlation scale, the
residual correlation at `x = 0` is:

```@example bc
tanh(coef(fit, :rho12)[1])     # ρ12 at x = 0  (≈ tanh(0.2) ≈ 0.197)
```

and it increases with `x` (positive `atanh` slope). The means (`mu1`, `mu2`) and
the scales (`sigma1`, `sigma2`) each have their own formula too — here the
scales were held constant (`~ 1`).

!!! note "Group-level vs residual correlation"
    `rho12` is the **residual** coupling of the two responses. Correlations that
    come from a shared phylogeny / spatial field / study are *group-level*
    covariance summaries, reported separately — not `rho12`.

## Phylogenetic location-scale coevolution

For the q=4 phylogenetic location-scale model, put the same
`phylo(1 | species)` marker on all four location/scale predictors: `mu1`,
`mu2`, `sigma1`, and `sigma2`. The residual `rho12` formula stays separate.

```julia
using DRM, Random
Random.seed!(42)

phy = random_balanced_tree(6; branch_length = 0.2)
species = repeat(phy.leaf_names, inner = 3)
n = length(species)
x = randn(n)

# Tiny runnable smoke fixture. Use larger seeded simulations for recovery checks.
u = Dict(name => 0.15 .* randn(4) for name in phy.leaf_names)
y1 = [1 + 0.4*x[i] + u[species[i]][1] +
      exp(-0.4 + u[species[i]][3]) * randn() for i in 1:n]
y2 = [-0.2 + 0.3*x[i] + u[species[i]][2] +
      exp(-0.5 + u[species[i]][4]) * randn() for i in 1:n]
dat = (; y1, y2, x, species)

fit_phy = drm(
    bf(mu1 = @formula(y1 ~ x + phylo(1 | species)),
       mu2 = @formula(y2 ~ x + phylo(1 | species)),
       sigma1 = @formula(sigma1 ~ 1 + phylo(1 | species)),
       sigma2 = @formula(sigma2 ~ 1 + phylo(1 | species)),
       rho12 = @formula(rho12 ~ 1)),
    Gaussian();
    data = dat,
    tree = phy,
    q4_vcov = false,
)

fit_phy.ranef.Sigma_a      # 4x4 group-level covariance, axes below
fit_phy.ranef.axes         # (:mu1, :mu2, :sigma1, :sigma2)
coevolution(fit_phy; method = :none).correlation.s1s2   # group-level ρ_a(s1s2)
```

The internal `:phylocov` coefficient block is not a distributional predictor, so
[`predict_parameters`](@ref) returns `:mu1`, `:mu2`, `:sigma1`, `:sigma2`, and
`:rho12`, but not `:phylocov`. [`coevolution`](@ref) labels the group-level
phylogenetic SDs and correlations from `Σ_a`. If the fit was run with the
default `q4_vcov = true`, `coevolution(fit_phy)` also returns Fisher-z Wald
intervals; with `q4_vcov = false`, use `method = :none` for point summaries.

## See also

- [When variance carries signal](location-scale.md) — the single-response
  location–scale model.
- The verified **q=4 phylogenetic** bivariate location–scale engine (the speed
  headline) — see [`HANDOVER.md`](https://github.com/itchyshin/DRM.jl/blob/main/HANDOVER.md).
