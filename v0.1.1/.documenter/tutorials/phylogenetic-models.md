
# Phylogenetic structured effects {#Phylogenetic-structured-effects}

::: tip Status — Stable (Gaussian mean)

Mirrors drmTMB's [Phylogenetic structured effects](https://itchyshin.github.io/drmTMB/articles/phylogenetic-models.html). **In DRM.jl today:** `phylo(1 | species)` on the Gaussian **mean** — a phylogenetic random intercept fit in closed form from a tree. The q=4 phylogenetic _location-scale_ model (effect on `log σ` too) uses the verified sparse-Laplace engine (see `HANDOVER.md`).

:::

Related species are not independent: closely related species have correlated trait values. `phylo(1 | species)` adds a random intercept with the **phylogenetic** correlation built from a tree, `u ~ N(0, σ_phylo² C)`. For a Gaussian mean the marginal is Gaussian, so the fit is closed-form.

Pass the tree via `tree =` (an `AugmentedPhy` from `random_balanced_tree` / `augmented_phy`, or a Newick string). Species in the data align to the tree's leaves:

```julia
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


```ansi
1.0619969047347249
```


```julia
exp(coef(fit, :sigma)[1])     # residual SD (≈ 0.4)
```


```ansi
0.3657184211882256
```


The phylogenetic correlation comes straight from the verified engine's `sigma_phy_dense`; the closed-form GLS then estimates the phylogenetic SD and the residual SD jointly.

## See also {#See-also}
- [Known-matrix relatedness with relmat](relmat-known-matrices.md) — the same engine with a supplied matrix · [Animal models](animal-models.md)
  
- [What can I fit today?](../model-guides/model-map.md)
  
