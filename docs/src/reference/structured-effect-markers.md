# Structured-effect markers

!!! note "Status — Reference"
    Mirrors drmTMB's [Structured-effect markers](https://itchyshin.github.io/drmTMB/reference/index.html) (6 in drmTMB). These markers wrap a random-effect term inside a [`bf`](@ref) formula to give it a known correlation structure (phylogeny, space, pedigree, an arbitrary relatedness matrix) or a known sampling-variance (meta-analysis).

## Correlation-structured random effects

```@docs
phylo
spatial
animal
relmat
```

## Known sampling variance (meta-analysis)

```@docs
meta_V
```
