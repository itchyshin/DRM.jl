using LinearAlgebra: I, diag, dot
using Distributions: Normal, quantile
using ForwardDiff: gradient

const _COEV_PARAM_AXES = (:mu1, :mu2, :sigma1, :sigma2)
const _COEV_LABEL_AXES = (:l1, :l2, :s1, :s2)
const _COEV_SD_KEYS = (:l1, :l2, :s1, :s2)
const _COEV_CORR_PAIRS = (
    (:l1l2, :l1, :l2, 1, 2),
    (:s1s2, :s1, :s2, 3, 4),
    (:l1s2, :l1, :s2, 1, 4),
    (:l2s1, :l2, :s1, 2, 3),
    (:l1s1, :l1, :s1, 1, 3),
    (:l2s2, :l2, :s2, 2, 4),
)

"""
    coevolution(fit; level = 0.95, method = :wald)

Summarise the **group-level** coevolution covariance `Σ_a` from a bivariate
q=4 phylogenetic location-scale fit. The returned named tuple contains:

- `covariance` — the raw 4×4 `Σ_a` with axes `(:mu1, :mu2, :sigma1, :sigma2)`;
- `sd` — named phylogenetic SDs `l1`, `l2`, `s1`, `s2`;
- `correlation` — the six named group-level correlations
  `l1l2`, `s1s2`, `l1s2`, `l2s1`, `l1s1`, `l2s2`;
- `correlation_matrix` — the labelled 4×4 correlation matrix;
- `ci` and `rows` — Wald confidence intervals when `method = :wald`, or
  `missing` interval endpoints when `method = :none`.

The `s1` and `s2` axes are random effects on the **log σ** scale. These
correlations are phylogenetic / group-level covariance summaries and are
deliberately distinct from the fitted **residual** correlation [`rho12`](@ref)
and [`corpairs`](@ref).
"""
function coevolution(fit::DrmFit; level::Real=0.95, method::Symbol=:wald)
    fit.ranef isa NamedTuple && haskey(fit.ranef, :Sigma_a) || throw(
        ArgumentError(
            "coevolution requires a bivariate q=4 structured fit with `fit.ranef.Sigma_a`; residual `rho12` fits use rho12/corpairs instead",
        ),
    )
    axes = haskey(fit.ranef, :axes) ? Tuple(fit.ranef.axes) : _COEV_PARAM_AXES
    axes == _COEV_PARAM_AXES || throw(
        ArgumentError("coevolution expected Sigma_a axes $(_COEV_PARAM_AXES), got $axes"),
    )
    Σ = Matrix{Float64}(fit.ranef.Sigma_a)
    size(Σ) == (4, 4) ||
        throw(ArgumentError("coevolution expected a 4x4 Sigma_a matrix, got $(size(Σ))"))
    method in (:wald, :none, :point) ||
        throw(ArgumentError("coevolution: method must be :wald or :none (got :$method)"))
    0 < level < 1 || throw(ArgumentError("coevolution: level must be between 0 and 1"))

    sds = sqrt.(diag(Σ))
    sd = NamedTuple{_COEV_SD_KEYS}(Tuple(sds))
    cor_mat = _coevolution_cor_matrix(Σ, sds)
    corr_keys = Tuple(p[1] for p in _COEV_CORR_PAIRS)
    corr_vals = Tuple(cor_mat[p[4], p[5]] for p in _COEV_CORR_PAIRS)
    correlation = NamedTuple{corr_keys}(corr_vals)
    ci = method === :wald ? _coevolution_wald_ci(fit, level) : _coevolution_missing_ci()
    group = haskey(fit.ranef, :group) ? Symbol(fit.ranef.group) : :unknown
    rows = _coevolution_rows(sd, correlation, ci)
    return (;
        group,
        source=:phylo,
        axes=_COEV_PARAM_AXES,
        labels=_COEV_LABEL_AXES,
        covariance=Σ,
        sd,
        correlation,
        correlation_matrix=cor_mat,
        ci,
        rows,
        level=method === :wald ? Float64(level) : missing,
        method,
    )
end

function _coevolution_cor_matrix(Σ::AbstractMatrix, sds)
    C = Matrix{Float64}(I, 4, 4)
    for i in 1:4, j in (i + 1):4
        C[i, j] = C[j, i] = Σ[i, j] / (sds[i] * sds[j])
    end
    return C
end

function _coevolution_missing_ci()
    keys = (_COEV_SD_KEYS..., Tuple(p[1] for p in _COEV_CORR_PAIRS)...)
    vals = ntuple(_ -> (missing, missing), length(keys))
    return NamedTuple{keys}(vals)
end

function _coevolution_wald_ci(fit::DrmFit, level::Real)
    block = findfirst(p -> first(p) === :phylocov, fit.blocks)
    block === nothing && throw(
        ArgumentError(
            "coevolution Wald intervals require the q=4 :phylocov coefficient block"
        ),
    )
    r = fit.blocks[block].second
    V = fit.vcov[r, r]
    all(isfinite, V) || throw(
        ArgumentError(
            "coevolution Wald intervals require a finite q=4 covariance matrix; refit with q4_vcov=true or call coevolution(fit; method=:none)",
        ),
    )
    lc = fit.theta[r]
    z = quantile(Normal(), 1 - (1 - level) / 2)

    sd_ci = ntuple(4) do i
        _coevolution_delta_ci(lc, V, z, v -> log(sqrt(lc_to_Λ(v)[i, i])), exp)
    end
    corr_ci = ntuple(length(_COEV_CORR_PAIRS)) do k
        _, _, _, i, j = _COEV_CORR_PAIRS[k]
        _coevolution_delta_ci(lc, V, z, v -> _coevolution_corr_z(lc_to_Λ(v), i, j), tanh)
    end
    keys = (_COEV_SD_KEYS..., Tuple(p[1] for p in _COEV_CORR_PAIRS)...)
    return NamedTuple{keys}((sd_ci..., corr_ci...))
end

function _coevolution_delta_ci(lc, V, z, transform, inverse_transform)
    est = transform(lc)
    g = gradient(transform, lc)
    v = dot(g, V * g)
    se = (isfinite(v) && v > 0) ? sqrt(v) : Inf
    return (
        Float64(inverse_transform(est - z * se)), Float64(inverse_transform(est + z * se))
    )
end

function _coevolution_corr_z(Σ, i::Int, j::Int)
    ρ = Σ[i, j] / sqrt(Σ[i, i] * Σ[j, j])
    guard = sqrt(eps(Float64))
    return atanh(clamp(ρ, -one(ρ) + guard, one(ρ) - guard))
end

function _coevolution_rows(sd, correlation, ci)
    rowtype = NamedTuple{
        (:name, :type, :axis1, :axis2, :estimate, :lower, :upper),
        Tuple{Symbol,Symbol,Symbol,Symbol,Float64,Any,Any},
    }
    rows = rowtype[]
    for k in _COEV_SD_KEYS
        lo, hi = getproperty(ci, k)
        push!(
            rows,
            (
                name=k,
                type=:sd,
                axis1=k,
                axis2=k,
                estimate=getproperty(sd, k),
                lower=lo,
                upper=hi,
            ),
        )
    end
    for p in _COEV_CORR_PAIRS
        name, a1, a2, _, _ = p
        lo, hi = getproperty(ci, name)
        push!(
            rows,
            (
                name=name,
                type=:correlation,
                axis1=a1,
                axis2=a2,
                estimate=getproperty(correlation, name),
                lower=lo,
                upper=hi,
            ),
        )
    end
    return rows
end
