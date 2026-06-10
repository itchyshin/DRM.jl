# zeroonebeta.jl — Zero-one-inflated beta family for responses on the CLOSED
# interval [0,1] (proportions that can be exactly 0 or 1). A three-part mixture
# (drmTMB's `zero_one_beta`): with probability `zoi` the value is a boundary
# (P(1|boundary) = `coi`); otherwise a Beta(μ, φ) on (0,1).
#
#   P(y=0)        = zoi·(1-coi)
#   P(y=1)        = zoi·coi
#   f(y∈(0,1))    = (1-zoi)·Beta(y; μφ, (1-μ)φ)
#
# Parameters: mu (logit) / sigma (log, φ=1/σ²) / zoi (logit) / coi (logit). Fixed
# effects, ML. `Distributions.Beta` is used qualified.

import Distributions

"""
    ZeroOneBeta()

Zero-one-inflated beta family for proportions on the closed interval `[0,1]`
(values may be exactly 0 or 1). Parameters: `mu` (logit; beta mean on the
interior), `sigma` (log; precision `φ = 1/σ²`), `zoi` (logit; probability the
value is a boundary 0/1), `coi` (logit; probability of 1 given a boundary).
Mirrors `drmTMB`'s `zero_one_beta`. `fitted` returns the unconditional mean
`(1-zoi)·μ + zoi·coi`.

```julia
fit = drm(bf(y ~ x, sigma ~ 1, zoi ~ 1, coi ~ 1), ZeroOneBeta(); data = dat)
```
"""
struct ZeroOneBeta end

function drm(f::DrmFormula, fam::ZeroOneBeta; data, g_tol::Real = 1e-8)
    missing_fit = _fit_observed_response_rows(f, data) do data_observed
        drm(f, fam; data = data_observed, g_tol = g_tol)
    end
    missing_fit !== nothing && return missing_fit

    rhs = Dict(f.forms)
    for (_, r) in f.forms
        _, re, mv, st = _split_ranef(r)
        (isempty(re) && mv === nothing && st === nothing) ||
            error("ZeroOneBeta() currently supports fixed effects only")
    end
    y, Xμ, nmμ = _design(f.response, rhs[:mu], data)
    _, Xσ, nmσ = _design(f.response, get(rhs, :sigma, ConstantTerm(1)), data)
    _, Xz, nmz = _design(f.response, get(rhs, :zoi, ConstantTerm(1)), data)
    _, Xc, nmc = _design(f.response, get(rhs, :coi, ConstantTerm(1)), data)
    all(yi -> 0 <= yi <= 1, y) ||
        error("ZeroOneBeta() requires responses in the closed interval [0, 1]")
    return _withformula(_fit_zeroonebeta(fam, y, Xμ, Xσ, Xz, Xc, nmμ, nmσ, nmz, nmc, g_tol), f)
end

function _fit_zeroonebeta(fam::ZeroOneBeta, y, Xμ, Xσ, Xz, Xc, nmμ, nmσ, nmz, nmc, g_tol)
    n = length(y)
    pμ, pσ, pz, pc = size(Xμ, 2), size(Xσ, 2), size(Xz, 2), size(Xc, 2)
    i1 = pμ + pσ; i2 = i1 + pz; i3 = i2 + pc
    function nll(θ)
        βμ = θ[1:pμ]; βσ = θ[pμ+1:i1]; βz = θ[i1+1:i2]; βc = θ[i2+1:i3]
        ημ = clamp.(Xμ * βμ, -30.0, 30.0); ησ = clamp.(Xσ * βσ, -15.0, 15.0)
        ηz = clamp.(Xz * βz, -30.0, 30.0); ηc = clamp.(Xc * βc, -30.0, 30.0)
        s = zero(eltype(θ))
        @inbounds for i in 1:n
            lzoi = _log_logistic(ηz[i]); l1mzoi = _log1m_logistic(ηz[i])
            if y[i] == 0
                s -= lzoi + _log1m_logistic(ηc[i])      # log zoi + log(1-coi)
            elseif y[i] == 1
                s -= lzoi + _log_logistic(ηc[i])        # log zoi + log coi
            else
                μ = _logistic(ημ[i]); φ = exp(-2 * ησ[i])
                s -= l1mzoi + Distributions.logpdf(Distributions.Beta(μ * φ, (1 - μ) * φ), y[i])
            end
        end
        return s
    end
    # initialisations from the empirical mixture
    isb = (y .== 0) .| (y .== 1)
    cont = y[.!isb]; p̄ = isempty(cont) ? 0.5 : clamp(sum(cont) / length(cont), 1e-3, 1 - 1e-3)
    fb = clamp(sum(isb) / n, 1e-3, 1 - 1e-3)
    nb = sum(isb); co0 = nb == 0 ? 0.5 : clamp(sum(y .== 1) / nb, 1e-3, 1 - 1e-3)
    θ0 = zeros(i3)
    θ0[1] = log(p̄ / (1 - p̄))                 # logit μ
    θ0[pμ+1] = -0.5 * log(10.0)               # σ (φ ≈ 10)
    θ0[i1+1] = log(fb / (1 - fb))             # logit zoi
    θ0[i2+1] = log(co0 / (1 - co0))           # logit coi
    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Optim.minimizer(res); V = inv(ForwardDiff.hessian(nll, θ̂))
    blocks = [:mu => 1:pμ, :sigma => (pμ+1):i1, :zoi => (i1+1):i2, :coi => (i2+1):i3]
    names = [:mu => nmμ, :sigma => nmσ, :zoi => nmz, :coi => nmc]
    μ̂ = _logistic.(Xμ * θ̂[1:pμ])
    zoî = _logistic.(Xz * θ̂[(i1+1):i2]); coî = _logistic.(Xc * θ̂[(i2+1):i3])
    means = Dict(:mu => (1 .- zoî) .* μ̂ .+ zoî .* coî)   # unconditional mean (drmTMB fitted)
    obs = Dict(:mu => Vector{Float64}(y))
    scales = Dict(:beta_mu => μ̂,
                  :sigma => exp.(Xσ * θ̂[(pμ+1):i1]),
                  :zoi => zoî,
                  :coi => coî)
    return _withnll(DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n, Optim.converged(res), means, obs, scales), nll)
end
