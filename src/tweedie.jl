# tweedie.jl — Tweedie family (compound Poisson–Gamma, 1 < p < 2): semicontinuous
# responses with a point mass at 0 and a continuous positive part (biomass,
# rainfall, total insurance loss). Log link on the mean μ; `sigma` is the
# √dispersion (φ = σ²); `nu` is the power p on a logit-(1,2) link
# (p = 1 + logistic(η)). Var(y) = φ·μ^p. The density has no closed form — it is
# evaluated by the Dunn–Smyth compound Poisson–Gamma series. Mirrors drmTMB's
# `tweedie`. Fixed effects, ML.

using SpecialFunctions: loggamma

# log Σ_n W_n for the positive part: W_n = λⁿ y^{-nα} γ^{nα} / (n! Γ(-nα)), the
# compound Poisson–Gamma mixture (N ~ Poisson(λ); sum of N Gamma(-α, γ) jumps).
# The dominant n and the summation window are chosen in Float64 (detached, so the
# window doesn't break differentiability), then the window is summed in the
# parameter's number type so ForwardDiff differentiates through `loggamma(-nα)`.
function _tweedie_logW(y, λ, α, γ)
    z = log(λ) - α * log(y) + α * log(γ)
    zv = ForwardDiff.value(z); αv = ForwardDiff.value(α)
    logWn(nn) = nn * zv - loggamma(nn + 1.0) - loggamma(-nn * αv)
    nmax = 1; best = logWn(1.0)
    for nn in 2:400
        l = logWn(float(nn))
        l > best && (best = l; nmax = nn)
        (l < best - 45 && nn > nmax) && break
    end
    jl = max(1, nmax - 30); jh = nmax + 30
    terms = [j * z - loggamma(j + 1.0) - loggamma(-j * α) for j in jl:jh]
    m = maximum(terms)
    return m + log(sum(exp(t - m) for t in terms))
end

# Tweedie log-density at one point (1 < p < 2, y ≥ 0, μ,φ > 0).
function _logpdf_tweedie(y, μ, φ, p)
    λ = μ^(2 - p) / (φ * (2 - p))
    y == 0 && return -λ
    α = (2 - p) / (1 - p); γ = φ * (p - 1) * μ^(p - 1)
    return -λ - y / γ - log(y) + _tweedie_logW(y, λ, α, γ)
end

"""
    Tweedie()

Tweedie response family (compound Poisson–Gamma, power `1 < p < 2`) for
semicontinuous data — an exact-zero mass plus a positive continuous part. Log
link on the mean `μ`; `sigma` is the √dispersion (so `φ = σ²`, `coef(fit, :sigma)`
is `log σ`); `nu` is the power `p` on a logit-`(1,2)` link
(`p = 1 + logistic(coef(fit, :nu))`). `Var(y) = φ·μ^p`. Density via the Dunn–Smyth
series. Mirrors `drmTMB`'s `tweedie`.

```julia
fit = drm(bf(y ~ x, sigma ~ 1, nu ~ 1), Tweedie(); data = dat)
exp(2 * coef(fit, :sigma)[1])               # dispersion φ
1 + 1 / (1 + exp(-coef(fit, :nu)[1]))       # power p ∈ (1,2)
```
"""
struct Tweedie end

_logit12(η) = 1 + 1 / (1 + exp(-η))            # (1,2) link for the power p

function drm(f::DrmFormula, fam::Tweedie; data, g_tol::Real = 1e-8)
    missing_fit = _fit_observed_response_rows(f, data) do data_observed
        drm(f, fam; data = data_observed, g_tol = g_tol)
    end
    missing_fit !== nothing && return missing_fit

    rhs = Dict(f.forms)
    for (_, r) in f.forms
        _, re, mv, st = _split_ranef(r)
        (isempty(re) && mv === nothing && st === nothing) ||
            error("Tweedie() currently supports fixed effects only")
    end
    y, Xμ, nmμ = _design(f.response, rhs[:mu], data)
    _, Xσ, nmσ = _design(f.response, get(rhs, :sigma, ConstantTerm(1)), data)
    _, Xν, nmν = _design(f.response, get(rhs, :nu, ConstantTerm(1)), data)
    all(yi -> yi >= 0, y) || error("Tweedie() requires non-negative responses (zeros allowed)")
    return _withformula(_fit_tweedie(fam, y, Xμ, Xσ, Xν, nmμ, nmσ, nmν, g_tol), f)
end

function _fit_tweedie(fam::Tweedie, y, Xμ, Xσ, Xν, nmμ, nmσ, nmν, g_tol)
    n = length(y); pμ, pσ, pν = size(Xμ, 2), size(Xσ, 2), size(Xν, 2)
    i1 = pμ + pσ; i2 = i1 + pν
    function nll(θ)
        βμ = θ[1:pμ]; βσ = θ[pμ+1:i1]; βν = θ[i1+1:i2]
        ημ = clamp.(Xμ * βμ, -30.0, 30.0); ησ = clamp.(Xσ * βσ, -15.0, 15.0)
        ην = clamp.(Xν * βν, -12.0, 12.0)        # keep p strictly inside (1,2) — avoids the boundary singularities
        s = zero(eltype(θ))
        @inbounds for i in 1:n
            μ = exp(ημ[i]); φ = exp(2 * ησ[i]); p = _logit12(ην[i])   # φ = σ²
            s -= _logpdf_tweedie(y[i], μ, φ, p)
        end
        return s
    end
    ȳ = sum(y) / n
    θ0 = zeros(i2)
    θ0[1] = log(ȳ + eps())            # log mean
    θ0[pμ+1] = 0.0                     # σ = 1 (φ = 1)
    θ0[i1+1] = 0.0                     # p = 1.5
    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Optim.minimizer(res); V = inv(ForwardDiff.hessian(nll, θ̂))
    blocks = [:mu => 1:pμ, :sigma => (pμ+1):i1, :nu => (i1+1):i2]
    names = [:mu => nmμ, :sigma => nmσ, :nu => nmν]
    means = Dict(:mu => exp.(Xμ * θ̂[1:pμ])); obs = Dict(:mu => Vector{Float64}(y))   # response-scale μ̂
    scales = Dict(:sigma => exp.(Xσ * θ̂[(pμ+1):i1]),
                  :nu => _logit12.(Xν * θ̂[(i1+1):i2]))
    return _withnll(DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n, Optim.converged(res), means, obs, scales), nll)
end
