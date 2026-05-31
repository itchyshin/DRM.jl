# inference.jl — Wald + profile-likelihood inference for fitted DRM models.
# Wald: estimate ± z·se from the observed information stored on the fit, on each
# parameter's working scale (log σ, atanh ρ12, log σ_b). Profile: invert the
# likelihood-ratio statistic — the endpoints where 2(ℓ̂ − ℓ_profile) = χ²₁(level),
# re-optimising the nuisance parameters at each fixed value. Mirrors drmTMB's
# `confint(..., method = "wald" | "profile")`.

using LinearAlgebra: diag
using Distributions: Normal, Chisq, quantile
import Optim
import Statistics
import StatsAPI: stderror, confint

"""
    stderror(fit) -> Vector{Float64}

Wald standard errors (√diag of the covariance), in the fit's coefficient order.
"""
stderror(fit::DrmFit) = sqrt.(diag(fit.vcov))

const _CIRow = NamedTuple{(:param, :coef, :estimate, :lower, :upper),
    Tuple{Symbol,String,Float64,Float64,Float64}}

"""
    confint(fit; level = 0.95, method = :wald)

Confidence intervals for every coefficient, as a vector of
`(param, coef, estimate, lower, upper)` rows on each parameter's working scale
(μ on the response scale; σ on `log σ`; ρ12 on `atanh ρ12`; random-effect SDs on
`log σ_b`).

- `method = :wald` (default) — estimate ± z·se from the stored covariance.
- `method = :profile` — profile-likelihood interval: the endpoints where
  `2(ℓ̂ − ℓ_profile) = χ²₁(level)`, re-optimising the nuisance parameters at each
  fixed value (asymmetric, and exact under the LR statistic where Wald is only
  quadratic-approximate). Works on any fitted Gaussian model.

Mirrors drmTMB's `confint(fit, method = "wald" | "profile")`.
"""
function confint(fit::DrmFit; level::Real = 0.95, method::Symbol = :wald)
    method === :wald && return _wald_ci(fit, level)
    method === :profile && return _profile_ci(fit, level)
    throw(ArgumentError("confint: method must be :wald or :profile (got :$method)"))
end

function _wald_ci(fit::DrmFit, level::Real)
    se = stderror(fit)
    z = quantile(Normal(), 1 - (1 - level) / 2)
    rows = _CIRow[]
    for ((p, r), (_, nms)) in zip(fit.blocks, fit.coefnames)
        for (j, idx) in enumerate(r)
            est = fit.theta[idx]
            s = se[idx]
            push!(rows, (param = p, coef = nms[j], estimate = est, lower = est - z * s, upper = est + z * s))
        end
    end
    return rows
end

# Profiled objective: minimise nll over every component except k, with θ[k] = v.
# Warm-started at the joint MLE; ForwardDiff through the stored objective.
function _profiled_nll(nll, θ̂::Vector{Float64}, k::Int, v::Real)
    p = length(θ̂)
    idx = [i for i in 1:p if i != k]
    isempty(idx) && return nll([float(v)])
    function obj(u)
        θ = Vector{eltype(u)}(undef, p)
        θ[k] = convert(eltype(u), v)
        @inbounds for (t, i) in enumerate(idx)
            θ[i] = u[t]
        end
        return nll(θ)
    end
    res = Optim.optimize(obj, θ̂[idx], Optim.LBFGS(); autodiff = :forward)
    return Optim.minimum(res)
end

# Endpoint in working coordinate where the profiled nll rises by `half` above the
# minimum, searching from θ̂[k] in direction dir ∈ {-1,+1}. The profiled nll is
# minimised at θ̂[k] and increases monotonically away from it, so h(t) below is
# increasing in t ≥ 0 with h(0) = -half < 0 — a clean 1-D bracket + bisection.
function _profile_endpoint(nll, θ̂, k, nllhat, half, s, dir)
    target = nllhat + half
    h(t) = _profiled_nll(nll, θ̂, k, θ̂[k] + dir * t) - target
    tlo = 0.0; thi = s; hval = h(thi); iters = 0
    while hval < 0 && iters < 40
        tlo = thi; thi *= 1.6; hval = h(thi); iters += 1
    end
    hval < 0 && return dir < 0 ? -Inf : Inf        # profile never crosses → unbounded
    for _ in 1:60
        tm = (tlo + thi) / 2
        h(tm) < 0 ? (tlo = tm) : (thi = tm)
        thi - tlo < 1e-7 && break
    end
    return θ̂[k] + dir * (tlo + thi) / 2
end

function _profile_ci(fit::DrmFit, level::Real)
    fit.nll === nothing &&
        throw(ArgumentError("profile intervals require the fitted objective; this model was not built with one"))
    nll = fit.nll
    θ̂ = copy(fit.theta)
    nllhat = nll(θ̂)
    half = quantile(Chisq(1), level) / 2           # nll rises by χ²₁/2 at each endpoint
    se = stderror(fit)
    rows = _CIRow[]
    for ((pp, r), (_, nms)) in zip(fit.blocks, fit.coefnames)
        for (j, k) in enumerate(r)
            est = θ̂[k]
            s = (isfinite(se[k]) && se[k] > 0) ? se[k] : max(abs(est), 1.0)
            lo = _profile_endpoint(nll, θ̂, k, nllhat, half, s, -1)
            hi = _profile_endpoint(nll, θ̂, k, nllhat, half, s, +1)
            push!(rows, (param = pp, coef = nms[j], estimate = est, lower = lo, upper = hi))
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
