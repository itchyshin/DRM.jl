# Animal models and additive relatedness

!!! note "Status — Stable (Gaussian mean, supplied A)"
    Mirrors drmTMB's [Animal models and additive relatedness](https://itchyshin.github.io/drmTMB/articles/animal-models.html).
    **In DRM.jl today:** `animal(1 | id)` on the Gaussian **mean** with a supplied
    additive-relatedness matrix `A` — a structured random intercept fit in closed
    form (same engine as [`relmat`](relmat-known-matrices.md) and
    [`phylo`](phylogenetic-models.md)).

The quantitative-genetic *animal model* splits phenotypic variation into an
additive-genetic random effect with a known relatedness matrix `A` (from a
pedigree) plus residual: `a ~ N(0, σ_A² A)`. For a Gaussian mean the marginal is
Gaussian, so DRM.jl fits it in closed form. Supply `A` over the levels of `id`:

```@example animal
using DRM, Random, LinearAlgebra
Random.seed!(3)

G = 60
M = randn(G, G); A0 = M * M' / G + I
d = sqrt.(diag(A0)); A = A0 ./ (d * d')          # additive-relatedness matrix
m = 6; n = G * m
id = repeat(1:G, inner = m)
x = randn(n)
a = 0.8 .* (cholesky(Symmetric(A)).L * randn(G)) # additive-genetic effect
y = 0.3 .+ 0.5 .* x .+ a[id] .+ 0.4 .* randn(n)

fit = drm(bf(@formula(y ~ x + animal(1 | id)), @formula(sigma ~ 1)),
          Gaussian(); data = (; y, x, id), A = A)

re_sd(fit)[:id]           # additive-genetic SD σ_A (≈ 0.8)
```

The ratio `σ_A² / (σ_A² + σ²)` is the (narrow-sense) heritability — computable
from `re_sd(fit)` and `sigma(...)`. Pedigree → `A` construction and the sparse
large-pedigree path are planned.

## See also

- [Known-matrix relatedness with relmat](relmat-known-matrices.md) ·
  [Phylogenetic structured effects](phylogenetic-models.md)
