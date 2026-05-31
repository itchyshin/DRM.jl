# inference.jl — Wald inference for fitted DRM models. Standard errors come from
# the observed information (the covariance stored on the fit); Wald intervals are
# estimate ± z·se on each parameter's working scale (log σ, atanh ρ12, log σ_b).
# Mirrors drmTMB's default `confint(..., method = "wald")`.

using LinearAlgebra: diag
using Distributions: Normal, quantile
import Statistics
import StatsAPI: stderror, confint

"""
    stderror(fit) -> Vector{Float64}

Wald standard errors (√diag of the covariance), in the fit's coefficient order.
"""
stderror(fit::DrmFit) = sqrt.(diag(fit.vcov))

"""
    confint(fit; level = 0.95)

Wald confidence intervals for every coefficient, returned as a vector of
`(param, coef, estimate, lower, upper)` rows. Intervals are on each parameter's
working scale (μ on the response scale; σ on `log σ`; ρ12 on `atanh ρ12`;
random-effect SDs on `log σ_b`).
"""
function confint(fit::DrmFit; level::Real = 0.95)
    se = stderror(fit)
    z = quantile(Normal(), 1 - (1 - level) / 2)
    rows = NamedTuple{(:param, :coef, :estimate, :lower, :upper),
        Tuple{Symbol,String,Float64,Float64,Float64}}[]
    for ((p, r), (_, nms)) in zip(fit.blocks, fit.coefnames)
        for (j, idx) in enumerate(r)
            est = fit.theta[idx]
            s = se[idx]
            push!(rows, (param = p, coef = nms[j], estimate = est, lower = est - z * s, upper = est + z * s))
        end
    end
    return rows
end

"""
    bootstrap_ci(formula, family; data, B = 300, level = 0.95, rng = default_rng(), K =, A =, tree =)

Parametric bootstrap confidence intervals: fit the model, then `simulate` `B`
replicate responses, refit each, and take percentile intervals per coefficient.
Univariate-response models (fixed / random-effect / meta / structured). Same row
shape as [`confint`](@ref). Pass through the structured-matrix keywords (`K` /
`A` / `tree`) exactly as to [`drm`](@ref).
"""
function bootstrap_ci(formula::DrmFormula, family::Gaussian; data, B::Int = 300,
        level::Real = 0.95, rng = default_rng(), K = nothing, A = nothing, tree = nothing)
    fit0 = drm(formula, family; data, K, A, tree)
    response = formula.response
    est = coef(fit0)
    p = length(est)
    draws = Matrix{Float64}(undef, B, p)
    for b in 1:B
        ysim = simulate(fit0; rng)
        datab = merge(data, NamedTuple{(response,)}((ysim,)))
        draws[b, :] = coef(drm(formula, family; data = datab, K, A, tree))
    end
    α = (1 - level) / 2
    rows = NamedTuple{(:param, :coef, :estimate, :lower, :upper),
        Tuple{Symbol,String,Float64,Float64,Float64}}[]
    col = 1
    for ((pp, r), (_, nms)) in zip(fit0.blocks, fit0.coefnames)
        for (j, _) in enumerate(r)
            v = @view draws[:, col]
            push!(rows, (param = pp, coef = nms[j], estimate = est[col],
                lower = Statistics.quantile(v, α), upper = Statistics.quantile(v, 1 - α)))
            col += 1
        end
    end
    return rows
end
