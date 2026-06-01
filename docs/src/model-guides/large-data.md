# Working with large data

!!! note "Status — Stable"
    Mirrors drmTMB's [Working with large data](https://itchyshin.github.io/drmTMB/articles/large-data.html). How DRM.jl stays fast as the number of units grows, and what to reach for when a model is large.

The selling-point model — the q=4 phylogenetic bivariate location–scale fit — is
built to scale. The marginal likelihood is a **sparse augmented-state Laplace
approximation with an exact O(p) gradient**: it never forms the dense p×p
phylogenetic covariance, and it gets the gradient from a Takahashi selected
inverse rather than by differentiating a dense factorisation. The practical
consequence is near-linear scaling in the number of tips.

## Verified scaling

The biological per-dimension-variance model (a 4×4 Λ: a separate phylogenetic
variance per axis plus cross-covariance, `nrep = 4` replicates) was timed end to
end with the O(p) sparse-precision sampler:

| p (tips, ×4 obs) | wall | iters | per-obs logLik |
|---|---|---|---|
| 100 | 0.77 s | 37 | −2.09 |
| 1000 | 4.49 s | 15 | −2.36 |
| 5000 | 49.5 s | 22 | −2.35 |
| **10000** | **112.9 s** | 23 | −2.61 |

The fitted scaling exponent is **k = 1.08 — near-perfect O(p)**: iteration counts
stay flat and the per-observation logLik is stable as `p` grows. These are
reproduced numbers (`report/comparison-grid.md`); the harness is
`bench/run_scaling.jl`.

!!! note "On head-to-head claims"
    The O(p) result above is measured for DRM.jl. A drmTMB head-to-head at
    `nrep = 4` / `p > 100` was **not** run, so any "N× faster at p = 10,000" figure
    would be an extrapolation, not a measurement — this guide does not claim one.
    The measured single-fit comparison (same model, real data) is **2.18× over
    drmTMB**; see the [model map](model-map.md) and `HANDOVER.md`.

## Why it scales

- **Sparse precision, never dense covariance.** The phylogenetic prior precision
  is sparse (≈ 8p non-zeros for a binary tree). The engine factorises that sparse
  matrix with CHOLMOD; it never materialises the dense Σ.
- **Exact O(p) gradient.** The implicit-function gradient reuses a Takahashi
  selected inverse — the entries of the inverse that the sparse Cholesky already
  touches — instead of an O(p²) or O(p³) dense differentiation. This is the
  difference that lets the fit reach p = 10,000 with flat iteration counts.
- **A precision sampler for uncertainty.** Posterior draws of the random effects
  come from the same sparse precision (`Cov(û) ≈ P⁻¹`), so bootstrap and
  conditional-mode work stays O(p) too.

## Practical tips for large fits

- **Stay in ML.** ML is the default and is comparable across fixed-effect
  structures — keep it for model selection on large data. REML is an option, not
  the default.
- **Standardise covariates.** Good conditioning matters more as `p` grows; centre
  and scale continuous predictors so the optimiser's Hessian stays well-behaved.
- **Thread the bootstrap and the profile CIs.** Parametric bootstrap replicates
  are independent refits; profile-likelihood endpoints are independent per
  coefficient. `confint(fit; method = :profile, threads = true)` profiles
  coefficients in parallel when the objective is thread-safe — set
  `JULIA_NUM_THREADS` to engage it.
- **Check the fit cheaply.** [`check_drm`](@ref) reports convergence and
  covariance conditioning without re-fitting — useful before committing to an
  expensive bootstrap.

## Beyond the verified engine

The O(p) machinery lives in the verified phylogenetic engine. The non-Gaussian
GLMM paths (Poisson/NB2/Beta/Gamma random effects via quadrature) are designed
for moderate group counts rather than p = 10,000-scale phylogenies; for very
large structured problems, the phylogenetic location–scale engine is the path
that has been benchmarked to scale.
