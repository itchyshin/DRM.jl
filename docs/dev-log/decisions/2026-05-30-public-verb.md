# Decision: public fit verb `drm()`; formula bundle `bf()` / `drm_formula()`

**Date:** 2026-05-30 · **Resolves:** #18 · **Owner:** Boole / Ada

drmTMB's R call is `drmTMB(drm_formula(y ~ x, sigma ~ x), family = gaussian(), data = dat)`,
with `bf()` an alias for `drm_formula()`. A Julia function literally named
`drmTMB` reads poorly and isn't idiomatic.

**Decision.** Keep the *formula surface* identical to drmTMB — `bf()` /
`drm_formula()`, one formula per distributional parameter, each left-hand side
naming its parameter (`y` → response/μ, `sigma` → log σ). Use **`drm(...)`** as
the Julia fit verb:

```julia
drm(bf(@formula(y ~ x), @formula(sigma ~ x)), Gaussian(); data = dat)
```

`bf` and `drm_formula` are both exported; `@formula` is re-exported from
StatsModels so `using DRM` is enough. R users reach DRM.jl through the planned
bridge as `drmTMB(..., engine = "julia")`, so the Julia verb name need not be
`drmTMB`.

**Rejected:** `fit(...)` (too generic, clashes with many packages); literal
`drmTMB(...)` (awkward as a Julia function name).
