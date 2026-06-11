# coevo_accessors.jl — user-facing accessors for the q=4 phylogenetic bivariate
# location–scale ("coevolution") fit. The engine fits a shared phylogenetic
# random effect on the four axes (mu1, mu2, sigma1, sigma2) with a 4×4 among-axis
# group-level covariance Σ_a, parameterised on the WORKING scale by 10 log-
# Cholesky entries (`lc_to_Λ` builds a lower-triangular C with positive diagonal
# exp(lcᵢ) and returns Σ_a = C·Cᵀ, PD by construction). The back-transformed Σ_a
# is already stored on the fit as `fit.ranef.Sigma_a`, with the axis order in
# `fit.ranef.axes == (:mu1, :mu2, :sigma1, :sigma2)`.
#
# These accessors turn that stored covariance into the comparative-biology
# quantities a user actually reads off a coevolution fit:
#
#   * the 4×4 among-axis CORRELATION matrix R = D^{-1/2} Σ_a D^{-1/2} — the
#     coevolutionary correlations between the four axes (e.g. ρ_a(mu1,mu2) is the
#     correlated-means / coevolution-of-trait-means signal);
#   * the per-axis phylo VARIANCES diag(Σ_a) and SDs sqrt(diag(Σ_a));
#   * a tidy long-form summary of both.
#
# We do NOT touch the fit itself (no re-optimisation) — every quantity is a
# deterministic map of the stored Σ_a. Uncertainty on these (delta/profile CIs on
# the off-diagonal correlations) is a separate follow-up; here we report point
# estimates, matching `vc` / `corpairs` / `re_sd`.

using LinearAlgebra: diag, Symmetric, Diagonal, isposdef

# ---------------------------------------------------------------------------
# Guard: pull the stored 4×4 Σ_a + axis labels off a q=4 coevolution fit, or
# error with a clear message on any other fit. Centralised so all three
# accessors share one detection path (mirrors `_variance_component_indices` in
# heritability.jl).
# ---------------------------------------------------------------------------
function _coevo_sigma_a(fit::DrmFit)
    if fit.ranef isa NamedTuple && haskey(fit.ranef, :Sigma_a) && haskey(fit.ranef, :axes)
        Σ = Matrix{Float64}(fit.ranef.Sigma_a)
        size(Σ) == (4, 4) || error("coevolution accessors: stored Σ_a is " *
            "$(size(Σ)), expected (4, 4)")
        axes = collect(Symbol, fit.ranef.axes)
        return Σ, axes
    end
    error("coevolution accessors require a q=4 phylogenetic bivariate " *
          "location–scale fit (the shared `phylo(1 | group)` marker on " *
          "mu1/mu2/sigma1/sigma2); this fit stores no 4×4 among-axis Σ_a")
end

# ---------------------------------------------------------------------------
# Public accessors.
# ---------------------------------------------------------------------------
"""
    coevolution_cor(fit) -> NamedTuple

Among-axis **correlation** matrix of a q=4 phylogenetic bivariate
location–scale ("coevolution") fit: the 4×4 group-level correlation between the
four shared-phylogenetic axes `(mu1, mu2, sigma1, sigma2)`,

    R = D^{-1/2} Σ_a D^{-1/2},   D = Diagonal(Σ_a),

back-transformed from the log-Cholesky parameterisation of the stored covariance
`fit.ranef.Sigma_a`. The off-diagonals are the coevolutionary correlations — e.g.
`R[1, 2] = ρ_a(mu1, mu2)` is the among-species correlation of the two trait means
(the "coevolution of means" signal), `R[3, 4] = ρ_a(sigma1, sigma2)` the
coevolution of the two log-scales, and the mean↔scale entries the lability
couplings.

Returns a `NamedTuple`:

- `cor`  — the `4×4` correlation matrix (symmetric, PD, unit diagonal);
- `axes` — the axis labels `(:mu1, :mu2, :sigma1, :sigma2)`, the row/column order.

For the residual between-response correlation `ρ12` see [`corpairs`](@ref); for
the raw covariance see [`coevolution_vc`](@ref) or [`vc`](@ref).

# Example

```julia
fit = drm(bf(mu1 = @formula(y1 ~ x + phylo(1 | species)),
             mu2 = @formula(y2 ~ x + phylo(1 | species)),
             sigma1 = @formula(sigma1 ~ 1 + phylo(1 | species)),
             sigma2 = @formula(sigma2 ~ 1 + phylo(1 | species)),
             rho12 = @formula(rho12 ~ 1)),
          Gaussian(); data, tree = phy)
R = coevolution_cor(fit)
R.cor[1, 2]        # ρ_a(mu1, mu2): coevolution-of-means correlation
```
"""
function coevolution_cor(fit::DrmFit)
    Σ, axes = _coevo_sigma_a(fit)
    sd = sqrt.(diag(Σ))
    Dinv = Diagonal(inv.(sd))
    R = Matrix(Dinv * Symmetric(Σ) * Dinv)
    R = (R + R') / 2                      # exact symmetry (kill round-off)
    @inbounds for i in axes_indices(R)
        R[i, i] = 1.0                     # exact unit diagonal
    end
    return (; cor = R, axes = Tuple(axes))
end

# `axes` is a public field name; use a tiny helper for the diagonal index range
# so the loop above doesn't shadow Base.axes inside the NamedTuple-building scope.
axes_indices(M) = 1:size(M, 1)

"""
    coevolution_vc(fit) -> NamedTuple

Per-axis phylogenetic **variance components** of a q=4 coevolution fit: the
diagonal of the group-level covariance `Σ_a` (the among-species variance on each
of the four shared-phylogenetic axes) and the matching standard deviations.

Returns a `NamedTuple`:

- `axes`     — the axis labels `(:mu1, :mu2, :sigma1, :sigma2)`;
- `variance` — `Dict(:mu1 => σ²_a(mu1), …)`, the per-axis phylo variances
  (`diag(Σ_a)`);
- `sd`       — `Dict(:mu1 => σ_a(mu1), …)`, their square roots;
- `cov`      — the full `4×4` covariance `Σ_a` (`== fit.ranef.Sigma_a`).

The variances are positive by construction (the log-Cholesky parameterisation
keeps `Σ_a` positive-definite). For the correlations see [`coevolution_cor`](@ref);
`vc(fit)[group]` returns the same `Σ_a` keyed by grouping factor.
"""
function coevolution_vc(fit::DrmFit)
    Σ, axes = _coevo_sigma_a(fit)
    v = diag(Σ)
    variance = Dict{Symbol,Float64}(axes[i] => v[i] for i in eachindex(axes))
    sd = Dict{Symbol,Float64}(axes[i] => sqrt(v[i]) for i in eachindex(axes))
    return (; axes = Tuple(axes), variance = variance, sd = sd, cov = Σ)
end

"""
    coevolution_summary(fit) -> NamedTuple

Tidy summary of a q=4 coevolution fit's among-axis structure, combining
[`coevolution_vc`](@ref) and [`coevolution_cor`](@ref) into long-form vectors
convenient for printing or assembling a table.

Returns a `NamedTuple`:

- `axes`        — the axis labels `(:mu1, :mu2, :sigma1, :sigma2)`;
- `variance`    — per-axis phylo variances, in `axes` order;
- `sd`          — per-axis phylo SDs, in `axes` order;
- `pair`        — the 6 unordered axis pairs as `Tuple{Symbol,Symbol}` (upper
  triangle of the correlation matrix);
- `correlation` — the among-axis correlation for each `pair`, in matching order;
- `covariance`  — the among-axis covariance for each `pair`, in matching order;
- `cor`         — the full `4×4` correlation matrix;
- `cov`         — the full `4×4` covariance matrix `Σ_a`.
"""
function coevolution_summary(fit::DrmFit)
    vcres = coevolution_vc(fit)
    corres = coevolution_cor(fit)
    Σ = vcres.cov
    R = corres.cor
    axes = collect(vcres.axes)
    npair = 4 * 3 ÷ 2
    pair = Vector{Tuple{Symbol,Symbol}}(undef, npair)
    correlation = Vector{Float64}(undef, npair)
    covariance = Vector{Float64}(undef, npair)
    k = 0
    @inbounds for i in 1:4, j in (i+1):4
        k += 1
        pair[k] = (axes[i], axes[j])
        correlation[k] = R[i, j]
        covariance[k] = Σ[i, j]
    end
    return (;
        axes = vcres.axes,
        variance = [vcres.variance[a] for a in axes],
        sd = [vcres.sd[a] for a in axes],
        pair = pair,
        correlation = correlation,
        covariance = covariance,
        cor = R,
        cov = Σ,
    )
end
