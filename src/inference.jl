# inference.jl — Wald inference for fitted DRM models. Standard errors come from
# the observed information (the covariance stored on the fit); Wald intervals are
# estimate ± z·se on each parameter's working scale (log σ, atanh ρ12, log σ_b).
# Mirrors drmTMB's default `confint(..., method = "wald")`.

using LinearAlgebra: diag
using Distributions: Normal, quantile
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
