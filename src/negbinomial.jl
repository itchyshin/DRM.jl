# negbinomial.jl — Negative-binomial (NB2) family for overdispersed counts.
# Log link on the mean μ and on the dispersion/size θ (carried in the `sigma`
# slot, matching the project convention that `sigma` is the family's secondary
# parameter). Variance = μ + μ²/θ, so θ → ∞ recovers Poisson. The likelihood is
# Distributions' NegativeBinomial(θ, p) with p = θ/(θ+μ) — verified
# ForwardDiff-safe. Fixed effects, ML. Mirrors drmTMB's `nbinom2`.

using Distributions: NegativeBinomial, logpdf

"""
    NegBinomial2()

Negative-binomial (NB2) family for overdispersed counts: log link on the mean
`μ`, and log link on the dispersion/size `θ` (the `sigma` formula slot, so
`coef(fit, :sigma)` is `log θ`). Var = `μ + μ²/θ`; as `θ → ∞` it tends to
[`Poisson`](@ref). Mirrors `drmTMB`'s `nbinom2` family.

```julia
fit = drm(bf(y ~ x, sigma ~ 1), NegBinomial2(); data = dat)
exp(coef(fit, :sigma)[1])     # estimated dispersion θ (size)
```
"""
struct NegBinomial2 end

function drm(f::DrmFormula, fam::NegBinomial2; data, g_tol::Real = 1e-8)
    rhs = Dict(f.forms)
    for (_, r) in f.forms
        _, re, mv, st = _split_ranef(r)
        (isempty(re) && mv === nothing && st === nothing) ||
            error("NegBinomial2() currently supports fixed effects only")
    end
    y, Xμ, nmμ = _design(f.response, rhs[:mu], data)
    _, Xσ, nmσ = _design(f.response, get(rhs, :sigma, ConstantTerm(1)), data)
    all(yi -> yi ≥ 0 && isinteger(yi), y) ||
        error("NegBinomial2() requires non-negative integer counts as the response")
    if haskey(rhs, :zi)                                   # zero-inflated NB (ZINB)
        _, Xzi, nmzi = _design(f.response, rhs[:zi], data)
        return _withformula(_fit_negbin2_zi(fam, y, Xμ, Xσ, Xzi, nmμ, nmσ, nmzi, g_tol), f)
    end
    return _withformula(_fit_negbin2(fam, y, Xμ, Xσ, nmμ, nmσ, g_tol), f)
end

# Zero-inflated NB2: P(0) = π + (1-π)·NB(0), P(k>0) = (1-π)·NB(k), with
# π = logistic(Xziᵀβ). Reuses the log-logistic / logaddexp helpers (poisson.jl).
function _fit_negbin2_zi(fam::NegBinomial2, y, Xμ, Xσ, Xzi, nmμ, nmσ, nmzi, g_tol)
    n = length(y); pμ, pσ, pz = size(Xμ, 2), size(Xσ, 2), size(Xzi, 2)
    yint = round.(Int, y); iszero_y = y .== 0
    function nll(θ)
        βμ = θ[1:pμ]; βσ = θ[pμ+1:pμ+pσ]; βz = θ[pμ+pσ+1:pμ+pσ+pz]
        ημ = clamp.(Xμ * βμ, -20.0, 20.0); ησ = clamp.(Xσ * βσ, -20.0, 20.0)
        ηz = clamp.(Xzi * βz, -30.0, 30.0)
        s = zero(eltype(θ))
        @inbounds for i in 1:n
            μ = exp(ημ[i]); r = exp(ησ[i]); p = r / (r + μ)
            lπ = _log_logistic(ηz[i]); l1mπ = _log1m_logistic(ηz[i])
            nb = logpdf(NegativeBinomial(r, p), yint[i])
            if iszero_y[i]
                s -= _logaddexp(lπ, l1mπ + nb)             # log(π + (1-π)·NB(0))
            else
                s -= l1mπ + nb
            end
        end
        return s
    end
    pos = y[y.>0]; m = isempty(pos) ? sum(y) / n : sum(pos) / length(pos)
    v = sum(abs2, y .- sum(y) / n) / max(n - 1, 1)
    θ0 = zeros(pμ + pσ + pz)
    θ0[1] = log(m + eps())
    θ0[pμ+1] = log(max(m^2 / max(v - m, 0.1 * m + eps()), 0.5))
    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Optim.minimizer(res); V = inv(ForwardDiff.hessian(nll, θ̂))
    blocks = [:mu => 1:pμ, :sigma => (pμ+1):(pμ+pσ), :zi => (pμ+pσ+1):(pμ+pσ+pz)]
    names = [:mu => nmμ, :sigma => nmσ, :zi => nmzi]
    means = Dict(:mu => exp.(Xμ * θ̂[1:pμ])); obs = Dict(:mu => Vector{Float64}(y))
    scales = Dict{Symbol,Vector{Float64}}()
    return _withnll(DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n, Optim.converged(res), means, obs, scales), nll)
end

function _fit_negbin2(fam::NegBinomial2, y, Xμ, Xσ, nmμ, nmσ, g_tol)
    n = length(y); pμ, pσ = size(Xμ, 2), size(Xσ, 2)
    yint = round.(Int, y)
    function nll(θ)
        βμ = θ[1:pμ]; βσ = θ[pμ+1:pμ+pσ]
        ημ = clamp.(Xμ * βμ, -20.0, 20.0)        # bound predictors so p ∈ (0,1) strictly
        ησ = clamp.(Xσ * βσ, -20.0, 20.0)        # (NegativeBinomial rejects p ≤ 0 / size ≤ 0)
        s = zero(eltype(θ))
        @inbounds for i in 1:n
            μ = exp(ημ[i]); r = exp(ησ[i]); p = r / (r + μ)   # r = θ (size)
            s -= logpdf(NegativeBinomial(r, p), yint[i])
        end
        return s
    end
    m = sum(y) / n; v = sum(abs2, y .- m) / max(n - 1, 1)
    θ0 = zeros(pμ + pσ)
    θ0[1] = log(m + eps())                                  # log-mean intercept
    θ0[pμ+1] = log(max(m^2 / max(v - m, 0.1 * m + eps()), 0.5))  # MoM dispersion init
    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Optim.minimizer(res); V = inv(ForwardDiff.hessian(nll, θ̂))
    blocks = [:mu => 1:pμ, :sigma => (pμ+1):(pμ+pσ)]
    names = [:mu => nmμ, :sigma => nmσ]
    means = Dict(:mu => exp.(Xμ * θ̂[1:pμ])); obs = Dict(:mu => Vector{Float64}(y))  # response-scale μ̂
    scales = Dict{Symbol,Vector{Float64}}()
    return _withnll(DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n, Optim.converged(res), means, obs, scales), nll)
end
