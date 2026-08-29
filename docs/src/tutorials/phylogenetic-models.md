# Phylogenetic structured effects

!!! note "Status — Stable (Gaussian + non-Gaussian mean; NB2/Gamma location–scale)"
    Mirrors drmTMB's [Phylogenetic structured effects](https://itchyshin.github.io/drmTMB/articles/phylogenetic-models.html).
    **In DRM.jl today:** `phylo(1 | species)` on the **mean** — a phylogenetic
    random intercept. For Gaussian it is fit in closed form; for the non-Gaussian
    families (Poisson, NB2, Binomial, Gamma, Beta, BetaBinomial) it is fit by the
    sparse augmented-state Laplace engine (constant `sigma` by default).
    **Non-Gaussian phylogenetic location–scale** (#202) ships for
    `NegBinomial2()` / `Gamma()` via the coupled tag
    `(1 | p | phylo(species))` on **both** `mu` and `sigma` (grammar B). Dual
    issue-text `phylo(1|sp)` on both axes is **not** the public acceptance
    surface. The q=4 bivariate PLSM remains the Gaussian flagship (see
    `HANDOVER.md`).

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
with a non-Gaussian data term). Six families carry the phylo route today:
**Poisson, NegBinomial2, Binomial, Gamma, Beta, BetaBinomial** (#166).

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

`BetaBinomial()` follows the same shape, with `cbind(successes, failures)` for
the known-trials response and constant overdispersion via `sigma ~ 1`
(`φ = 1/σ²`, #166):

```@example phybb
Random.seed!(20260802)
G2 = 24
phy2 = random_balanced_tree(G2; branch_length = 0.20)
species2 = repeat(1:G2, inner = 10)
n2 = length(species2)
x2 = randn(n2)
φbb = 16.0
σphy2 = 0.35
C2 = sigma_phy_dense(phy2; σ²_phy = σphy2^2)
u2 = cholesky(Symmetric(C2)).L * randn(G2)
μbb = 1 ./ (1 .+ exp.(-(-0.10 .+ 0.45 .* x2 .+ u2[species2])))
trials2 = fill(10, n2)
succ2 = Float64.([rand(Distributions.BetaBinomial(trials2[i], μbb[i] * φbb, (1 - μbb[i]) * φbb)) for i in 1:n2])
fail2 = Float64.(trials2) .- succ2

fitbb_phy = drm(bf(@formula(cbind(succ2, fail2) ~ x2 + phylo(1 | species2)), @formula(sigma ~ 1)),
                BetaBinomial(); data = (; succ2, fail2, x2, species2), tree = phy2, se = false)

re_sd(fitbb_phy)[:species2]        # phylogenetic SD on the logit mean (≈ 0.35)
```

A few things worth knowing:

- **Replicates matter.** Use at least two observations per species (`m ≥ 2`
  above). With a single observation per tip the scale of the latent effect is not
  identified — this is a modelling constraint, not a solver limit (see
  `HANDOVER.md` §6).
- **Mean-only phylo keeps constant dispersion.** The default non-Gaussian phylo
  route varies the **mean** with predictors and the structured effect and keeps
  `sigma ~ 1`. Fixed predictors on `sigma` (#164) are separate. For a *structured*
  effect on both axes, see **Phylogenetic location–scale** below (#202).
  `BetaBinomial()`'s phylo/crossed mean routes remain constant-σ (#166).
- **Other families, same shape.** Swap `Poisson()` for `NegBinomial2()` (counts
  with overdispersion), `Binomial()` or `BetaBinomial()` (`cbind(s, f) ~ …` for
  successes/trials, the latter with extra-binomial overdispersion), `Gamma()`, or
  `Beta()` — the `phylo(1 | species)` term and `tree =` argument are unchanged.
- **Standard errors / intervals.** Pass `se = true` for finite-difference Wald
  SEs, or use [`bootstrap_ci`](@ref) for a parametric bootstrap. We used
  `se = false` here to keep the example fast.

## Phylogenetic location–scale (non-Gaussian)

When relatedness shapes **dispersion** as well as the mean (lineages that are
intrinsically more variable), put the same phylogenetic coupler on both axes:

```julia
fit = drm(
    bf(@formula(y ~ x + (1 | p | phylo(species))),
       @formula(sigma ~ 1 + (1 | p | phylo(species)))),
    NegBinomial2(); data = (; y, x, species), tree = phy, se = false)
```

`vc(fit)[:species]` is then a 2×2 named group-level covariance (mean-axis SD,
scale-axis SD, and their correlation) — **not** residual `rho12`. Public
recovery for NB2 and a Gamma public-route smoke live in
`test/test_public_phylo_locscale.jl`. Prefer the coupled `(1 | p | phylo(…))`
spelling; dual `phylo(1 | sp)` on both axes is rejected on the non-Gaussian
families.

## See also

- [Location–scale–scale models](location-scale-scale.md) — predictors on the
  phylogenetic standard deviation (`sd(species, phylogenetic) ~ x`, Mizuno et al.
  macro-evolutionary framework).
- [Known-matrix relatedness with relmat](relmat-known-matrices.md) — the same
  engine with a supplied matrix · [Animal models](animal-models.md)
- [What can I fit today?](../model-guides/model-map.md)
