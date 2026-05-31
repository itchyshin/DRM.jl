# gamma.jl — Gamma family for strictly-positive continuous responses (durations,
# sizes, concentrations). Log link on the mean μ; the `sigma` slot carries σ =
# the coefficient of variation, mapped to the shape α = 1/σ² (so var = μ²σ² and
# coef(:sigma) is log σ). Likelihood Gamma(α, μ/α) (shape–scale, mean μ). Fixed
# effects, ML. `Distributions.Gamma` is used qualified — DRM exports its own
# `Gamma` family.

import Distributions

"""
    Gamma()

Gamma response family for positive continuous data: log link on the mean `μ`, and
the `sigma` slot carries `σ` = the coefficient of variation, mapped to the shape
`α = 1/σ²` (`coef(fit, :sigma)` is `log σ`; recover the shape as `exp(-2·log σ)`).
Likelihood `Gamma(α, μ/α)`; variance `μ²σ²`. Mirrors `drmTMB`'s `Gamma` family.

!!! note
    `DRM.Gamma` shadows `Distributions.Gamma`; qualify the latter if you need it.

```julia
fit = drm(bf(y ~ x, sigma ~ 1), Gamma(); data = dat)
exp(-2 * coef(fit, :sigma)[1])     # estimated shape α
```
"""
struct Gamma end

function drm(f::DrmFormula, fam::Gamma; data, g_tol::Real = 1e-8)
    rhs = Dict(f.forms)
    fixed_mu, re, mv, st = _split_ranef(rhs[:mu])
    (mv === nothing && st === nothing) ||
        error("Gamma() does not support meta_V / structured markers")
    for (pname, r) in f.forms          # only the mean may carry a random effect
        pname === :mu && continue
        _, re2, mv2, st2 = _split_ranef(r)
        (isempty(re2) && mv2 === nothing && st2 === nothing) ||
            error("Gamma(): only the mean formula may carry a random effect")
    end
    y, Xμ, nmμ = _design(f.response, fixed_mu, data)
    _, Xσ, nmσ = _design(f.response, get(rhs, :sigma, ConstantTerm(1)), data)
    all(yi -> yi > 0, y) || error("Gamma() requires strictly positive responses")
    if !isempty(re)                    # random intercept on the log mean → GHQ
        (length(re) == 1 && _re_kind(re[1][1])[1] === :intercept) ||
            error("Gamma() supports a single random intercept `(1 | g)` on the mean")
        grp = re[1][2]; gidx, G = _group_index(getproperty(data, grp))
        return _withformula(_fit_gamma_ranef(fam, y, Xμ, Xσ, gidx, G, nmμ, nmσ, grp, g_tol), f)
    end
    return _withformula(_fit_gamma(fam, y, Xμ, Xσ, nmμ, nmσ, g_tol), f)
end

# Gamma GLMM with a random intercept (1|g) on the log mean. b_g ~ N(0,σ_b²)
# integrated out per group by 32-node Gauss–Hermite quadrature; shape α = 1/σ²
# is a fixed effect. Same scheme as the count GLMMs.
function _fit_gamma_ranef(fam::Gamma, y, Xμ, Xσ, gidx, G, nmμ, nmσ, grp, g_tol)
    n = length(y); pμ, pσ = size(Xμ, 2), size(Xσ, 2)
    members = [Int[] for _ in 1:G]
    for i in 1:n
        push!(members[gidx[i]], i)
    end
    z, w = _gauss_hermite(32); logw = log.(w); K = length(z); rt2 = sqrt(2.0); lπ = log(π)
    function nll(θ)
        βμ = θ[1:pμ]; βσ = θ[pμ+1:pμ+pσ]; σb = exp(θ[pμ+pσ+1])
        η0 = Xμ * βμ; ησ = clamp.(Xσ * βσ, -15.0, 15.0)
        s = zero(eltype(θ))
        for idx in members
            isempty(idx) && continue
            terms = Vector{eltype(θ)}(undef, K)
            for k in 1:K
                δ = rt2 * σb * z[k]; gll = logw[k]
                for i in idx
                    μ = exp(clamp(η0[i] + δ, -30.0, 30.0)); α = exp(-2 * ησ[i])
                    gll += Distributions.logpdf(Distributions.Gamma(α, μ / α), y[i])
                end
                terms[k] = gll
            end
            mx = maximum(terms)
            s -= (-0.5 * lπ + mx + log(sum(exp.(terms .- mx))))
        end
        return s
    end
    ȳ = sum(y) / n; v = sum(abs2, y .- ȳ) / max(n - 1, 1)
    α0 = max(ȳ^2 / max(v, eps()), 0.5)
    θ0 = zeros(pμ + pσ + 1)
    θ0[1] = log(ȳ + eps()); θ0[pμ+1] = -0.5 * log(α0); θ0[pμ+pσ+1] = log(0.5)
    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Optim.minimizer(res); V = inv(ForwardDiff.hessian(nll, θ̂))
    blocks = [:mu => 1:pμ, :sigma => (pμ+1):(pμ+pσ), :resd => (pμ+pσ+1):(pμ+pσ+1)]
    names = [:mu => nmμ, :sigma => nmσ, :resd => [String(grp)]]
    means = Dict(:mu => exp.(Xμ * θ̂[1:pμ])); obs = Dict(:mu => Vector{Float64}(y))
    scales = Dict{Symbol,Vector{Float64}}()
    return _withnll(DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n, Optim.converged(res), means, obs, scales), nll)
end

function _fit_gamma(fam::Gamma, y, Xμ, Xσ, nmμ, nmσ, g_tol)
    n = length(y); pμ, pσ = size(Xμ, 2), size(Xσ, 2)
    function nll(θ)
        βμ = θ[1:pμ]; βσ = θ[pμ+1:pμ+pσ]
        ημ = clamp.(Xμ * βμ, -30.0, 30.0)        # μ > 0 finite
        ησ = clamp.(Xσ * βσ, -15.0, 15.0)        # α = exp(-2ησ) > 0 finite
        s = zero(eltype(θ))
        @inbounds for i in 1:n
            μ = exp(ημ[i]); α = exp(-2 * ησ[i])  # shape = 1/σ²
            s -= Distributions.logpdf(Distributions.Gamma(α, μ / α), y[i])
        end
        return s
    end
    ȳ = sum(y) / n; v = sum(abs2, y .- ȳ) / max(n - 1, 1)
    α0 = max(ȳ^2 / max(v, eps()), 0.5)            # method-of-moments shape
    θ0 = zeros(pμ + pσ)
    θ0[1] = log(ȳ + eps())                        # log mean
    θ0[pμ+1] = -0.5 * log(α0)                      # σ = 1/√α ⇒ log σ = -½ log α
    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Optim.minimizer(res); V = inv(ForwardDiff.hessian(nll, θ̂))
    blocks = [:mu => 1:pμ, :sigma => (pμ+1):(pμ+pσ)]
    names = [:mu => nmμ, :sigma => nmσ]
    means = Dict(:mu => exp.(Xμ * θ̂[1:pμ])); obs = Dict(:mu => Vector{Float64}(y))  # response-scale μ̂
    scales = Dict{Symbol,Vector{Float64}}()
    return _withnll(DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n, Optim.converged(res), means, obs, scales), nll)
end
