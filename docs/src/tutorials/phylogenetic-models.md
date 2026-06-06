# Phylogenetic structured effects

!!! note "Status — Stable (Gaussian + non-Gaussian mean)"
    Mirrors drmTMB's [Phylogenetic structured effects](https://itchyshin.github.io/drmTMB/articles/phylogenetic-models.html).
    **In DRM.jl today:** `phylo(1 | species)` on the **mean** — a phylogenetic
    random intercept. For Gaussian it is fit in closed form; for the non-Gaussian
    families (Poisson, NB2, Binomial, Gamma, Beta) it is fit by the sparse
    augmented-state Laplace engine, currently with a **constant `sigma`**. The q=4
    phylogenetic *location–scale* model (a shared effect on `log σ` too) is
    Gaussian-only today and uses the verified sparse-Laplace engine (see
    `HANDOVER.md`); the non-Gaussian location–scale extension is scoped on the
    ledger (issue #202).

Related species are not independent: closely related species have correlated
trait values. `phylo(1 | species)` adds a random intercept with the
**phylogenetic** correlation built from a tree, `u ~ N(0, σ_phylo² C)`. For a
Gaussian mean the marginal is Gaussian, so the fit is closed-form.

Pass the tree via `tree =` (an `AugmentedPhy` from `random_balanced_tree` /
`augmented_phy`, or a Newick string). Species in the data align to the tree's
leaves:

```@example phy
using DRM, Random, LinearAlgebra
Random.seed!(7)

G = 64
phy = random_balanced_tree(G; branch_length = 0.3)     # a tree over G species
C = sigma_phy_dense(phy; σ²_phy = 1.0)                 # phylogenetic covariance
d = sqrt.(diag(C)); K = C ./ (d * d')

m = 4; n = G * m
species = repeat(1:G, inner = m)
x = randn(n)
u = 0.9 .* (cholesky(Symmetric(K)).L * randn(G))       # phylogenetic effect
y = 0.2 .+ 0.5 .* x .+ u[species] .+ 0.4 .* randn(n)

fit = drm(bf(@formula(y ~ x + phylo(1 | species)), @formula(sigma ~ 1)),
          Gaussian(); data = (; y, x, species), tree = phy)

re_sd(fit)[:species]      # phylogenetic SD (≈ 0.9)
```

```@example phy
exp(coef(fit, :sigma)[1])     # residual SD (≈ 0.4)
```

The phylogenetic correlation comes straight from the verified engine's
`sigma_phy_dense`; the closed-form GLS then estimates the phylogenetic SD and the
residual SD jointly.

## Non-Gaussian responses (counts, proportions, …)

Phylogenetic signal is not a Gaussian-only luxury — abundances, presence/absence,
and rates are all correlated across related species. For a non-Gaussian family the
marginal is no longer closed-form, so `phylo(1 | species)` routes to the **sparse
augmented-state Laplace** engine (the same machinery behind the q=4 PLSM, here
with a non-Gaussian data term). Five families carry the phylo route today:
**Poisson, NegBinomial2, Binomial, Gamma, Beta**.

The call site is identical — add `phylo(1 | species)` to the mean formula, pass
`tree =`. Here is a phylogenetic Poisson count model: a shared tree effect on
`log λ` on top of a fixed slope. We simulate with a known phylogenetic SD and
recover it.

```@example phycount
using DRM, Random, LinearAlgebra
import Distributions
Random.seed!(20260603)

G = 32                                              # species
phy = random_balanced_tree(G; branch_length = 0.20)
m = 8                                               # replicates per species (≥ 2)
species = repeat(1:G, inner = m)
n = length(species)
x = randn(n)
β = [0.15, 0.35]                                    # (intercept, slope) on log λ
σphy = 0.45                                         # true phylogenetic SD
C = sigma_phy_dense(phy; σ²_phy = σphy^2)
u = cholesky(Symmetric(C)).L * randn(G)            # phylogenetic effect on log λ
λ = exp.(β[1] .+ β[2] .* x .+ u[species])
y = Float64.([rand(Distributions.Poisson(λi)) for λi in λ])

fit = drm(bf(@formula(y ~ x + phylo(1 | species))), Poisson();
          data = (; y, x, species), tree = phy, se = false)

coef(fit, :mu)            # (intercept, slope) — slope ≈ 0.35
```

```@example phycount
re_sd(fit)[:species]      # phylogenetic SD on log λ (≈ 0.45)
```

A few things worth knowing:

- **Replicates matter.** Use at least two observations per species (`m ≥ 2`
  above). With a single observation per tip the scale of the latent effect is not
  identified — this is a modelling constraint, not a solver limit (see
  `HANDOVER.md` §6).
- **Dispersion is constant (for now).** The non-Gaussian phylo route fixes the
  scale axis: vary the **mean** with predictors and the structured effect, and
  keep `sigma ~ 1`. A predictor on `sigma` (#164) and a *structured* effect on
  `sigma` — the non-Gaussian phylogenetic *location–scale* model (#202) — are on
  the ledger.
- **Other families, same shape.** Swap `Poisson()` for `NegBinomial2()` (counts
  with overdispersion), `Binomial()` (`cbind(s, f) ~ …` for successes/trials),
  `Gamma()`, or `Beta()` — the `phylo(1 | species)` term and `tree =` argument are
  unchanged.
- **Standard errors / intervals.** Pass `se = true` for finite-difference Wald
  SEs, or use [`bootstrap_ci`](@ref) for a parametric bootstrap. We used
  `se = false` here to keep the example fast.

## See also

- [Known-matrix relatedness with relmat](relmat-known-matrices.md) — the same
  engine with a supplied matrix · [Animal models](animal-models.md)
- [What can I fit today?](../model-guides/model-map.md)
