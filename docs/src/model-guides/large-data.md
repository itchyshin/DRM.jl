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
end with the O(p) sparse-precision sampler. Iteration counts stay flat and the
per-observation logLik is stable as the number of tips grows, which is the
signature of near-linear scaling. The timings, the fitted scaling exponent and
the caveats live in `report/comparison-grid.md`; the harness is
`bench/run_scaling.jl`.

!!! note "On head-to-head claims"
    The scaling result above is measured for DRM.jl alone, on a synthetic
    near-balanced tree grid with equal branch lengths and replicates. A paired drmTMB head-to-head on
    the same `nrep = 4` grid was measured separately on Totoro against drmTMB
    0.6.0 (#376;
    `docs/dev-log/evidence/2026-08-03-376-q4-scaling-h2h.md`) and does **not**
    show DRM.jl faster everywhere: Julia leads at the smallest tip count, and
    drmTMB is comparable or faster at larger ones under that protocol. Any
    extrapolated "N× faster" figure is **retired**. Read the numbers in
    `report/comparison-grid.md` and `HANDOVER.md` rather than quoting a ratio
    here.

## Why it scales

- **Sparse precision, never dense covariance.** The phylogenetic prior precision
  is sparse (3N − 2 stored non-zeros for a tree with N nodes, about 6p for
  a binary tree with p tips). The engine factorises that sparse
  matrix with CHOLMOD; it never materialises the dense Σ.
- **Exact O(p) gradient.** The implicit-function gradient reuses a Takahashi
  selected inverse — the entries of the inverse that the sparse Cholesky already
  touches — instead of an O(p²) or O(p³) dense differentiation. This is the
  difference that keeps the iteration cost near-linear in the number of tips.
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
  `JULIA_NUM_THREADS` to engage it. Within a single coefficient the lower and
  upper endpoint chains stay serial, so the gain scales with the number of
  coefficients profiled, not with threads per coefficient.
- **Check the fit cheaply.** [`check_drm`](@ref) reports convergence and
  covariance conditioning without re-fitting — useful before committing to an
  expensive bootstrap.

## Beyond the verified engine

The O(p) machinery lives in the verified phylogenetic engine. The non-Gaussian
GLMM paths (Poisson/NB2/Beta/Gamma random effects via quadrature) are designed
for moderate group counts rather than p = 10,000-scale phylogenies; for very
large structured problems, the phylogenetic location–scale engine is the path
that has been benchmarked to scale.
