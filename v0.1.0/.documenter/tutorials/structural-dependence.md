
# Structural dependence overview {#Structural-dependence-overview}

::: tip Status — Stable

Mirrors drmTMB's [Structural dependence overview](https://itchyshin.github.io/drmTMB/articles/structural-dependence.html). **In DRM.jl today:** all four structured-effect markers on the mean — `relmat` (supplied `K`), `animal` (pedigree `A`), `phylo` (tree), and `spatial` (coordinates) — are fitted in closed form, plus the verified q=4 phylogenetic bivariate engine.

:::

A structured effect puts a **known correlation** among the group-level random intercepts instead of treating groups as independent. The marker names where that correlation comes from:

|                Marker |            Correlation source |                         Supply |
| ---------------------:| -----------------------------:| ------------------------------:|
|     `relmat(1 \| id)` | an arbitrary known matrix `K` |                        `K = …` |
|     `animal(1 \| id)` |  an additive-genetic pedigree |                        `A = …` |
| `phylo(1 \| species)` |           a phylogenetic tree |                     `tree = …` |
|  `spatial(1 \| site)` |  distance between coordinates | `coords = …` (range estimated) |


All four reduce to the same closed-form generalised-least-squares marginal `V = D + σ_s² Z K Zᵀ` (no Laplace needed when the structure is on the mean). Each has its own worked tutorial — see below.

## See also {#See-also}
- [Known-matrix relatedness with relmat](relmat-known-matrices.md)
  
- [Animal models and additive relatedness](animal-models.md)
  
- [Phylogenetic structured effects](phylogenetic-models.md)
  
- [Coordinate-spatial structured effects](spatial-models.md)
  
