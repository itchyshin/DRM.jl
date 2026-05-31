# lognormal.jl — LogNormal family for strictly-positive responses whose log is
# Gaussian. The mean formula μ is the mean of log y (identity link on the log
# scale); σ (log link) is the SD of log y. The log-density is the Gaussian
# log-density of log y plus the −log y change-of-variables Jacobian, so the fit
# reuses the Gaussian location–scale objective on log y. Fixed effects + random
# intercept/slope on μ, ML. Mirrors drmTMB's `lognormal`. `Distributions.Normal`
# is used qualified inside the GHQ random-effect paths.

import Distributions

"""
    LogNormal()

LogNormal response family for positive continuous data: the mean formula `μ` is
the **mean of `log y`** (identity link on the log scale), and `σ` (log link) is
the **SD of `log y`**. The response-scale median is `exp(μ)`. Mirrors `drmTMB`'s
`lognormal` family.

!!! note
    `DRM.LogNormal` shadows `Distributions.LogNormal`; qualify the latter if needed.

A random intercept `(1 | g)` or a correlated random intercept+slope `(1 + x | g)`
may be placed on the log-mean `μ`; the group effect is integrated out by
Gauss–Hermite quadrature (`re_sd(fit)[:g]` / `vc(fit)[:g]`).

```julia
fit = drm(bf(y ~ x, sigma ~ 1), LogNormal(); data = dat)
coef(fit, :mu)                 # on the log scale
exp(coef(fit, :sigma)[1])      # SD of log y
```
"""
struct LogNormal end

function drm(f::DrmFormula, fam::LogNormal; data, g_tol::Real = 1e-8)
    rhs = Dict(f.forms)
    fixed_mu, re, mv, st = _split_ranef(rhs[:mu])
    (mv === nothing && st === nothing) ||
        error("LogNormal() does not support meta_V / structured markers")
    for (pname, r) in f.forms          # only the mean may carry a random effect
        pname === :mu && continue
        _, re2, mv2, st2 = _split_ranef(r)
        (isempty(re2) && mv2 === nothing && st2 === nothing) ||
            error("LogNormal(): only the mean formula may carry a random effect")
    end
    y, Xμ, nmμ = _design(f.response, fixed_mu, data)
    _, Xσ, nmσ = _design(f.response, get(rhs, :sigma, ConstantTerm(1)), data)
    all(yi -> yi > 0, y) || error("LogNormal() requires strictly positive responses")
    if !isempty(re)                    # random effect on the log-mean μ → GHQ
        length(re) == 1 ||
            error("LogNormal() supports a single random-effect term on the mean")
        (rk, var) = _re_kind(re[1][1]); grp = re[1][2]
        gidx, G = _group_index(getproperty(data, grp))
        if rk === :intercept           # (1 | g) → 1-D Gauss–Hermite
            return _withformula(_fit_lognormal_ranef(fam, y, Xμ, Xσ, gidx, G, nmμ, nmσ, grp, g_tol), f)
        elseif rk === :corr            # (1 + x | g) → correlated 2-D Gauss–Hermite
            return _withformula(_fit_lognormal_corr_ranef(fam, y, Xμ, Xσ, Float64.(getproperty(data, var)), gidx, G, nmμ, nmσ, grp, g_tol), f)
        else
            error("LogNormal() supports `(1 | g)` or `(1 + x | g)` on the mean")
        end
    end
    return _withformula(_fit_lognormal(fam, y, Xμ, Xσ, nmμ, nmσ, g_tol), f)
end

# LogNormal GLMM with a random intercept (1|g) on the log-mean μ (the mean of
# log y). b_g ~ N(0,σ_b²) integrated out per group by 32-node Gauss–Hermite
# quadrature; σ = SD of log y (log link) is a fixed effect. Same scheme as the
# Gamma random intercept, with the per-observation contribution the Gaussian
# log-density of log y. (A closed-form Gaussian-LMM marginal on log y exists; GHQ
# is used here for consistency with the other non-Gaussian families.) The constant
# −Σ log y change-of-variables Jacobian is added to the reported loglik so it
# matches the fixed fitter's convention.
function _fit_lognormal_ranef(fam::LogNormal, y, Xμ, Xσ, gidx, G, nmμ, nmσ, grp, g_tol)
    n = length(y); pμ, pσ = size(Xμ, 2), size(Xσ, 2)
    ly = log.(y); sumlogy = sum(ly)                  # Σ log y = the Jacobian offset
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
                    μ = clamp(η0[i] + δ, -30.0, 30.0); σ = exp(ησ[i])
                    gll += Distributions.logpdf(Distributions.Normal(μ, σ), ly[i])
                end
                terms[k] = gll
            end
            mx = maximum(terms)
            s -= (-0.5 * lπ + mx + log(sum(exp.(terms .- mx))))
        end
        return s + sumlogy                            # + Σ log y so loglik carries the Jacobian
    end
    βμ0 = Xμ \ ly
    θ0 = zeros(pμ + pσ + 1)
    θ0[1:pμ] .= βμ0
    θ0[pμ+1] = log(std(ly - Xμ * βμ0) + eps()); θ0[pμ+pσ+1] = log(0.5)
    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Optim.minimizer(res); V = inv(ForwardDiff.hessian(nll, θ̂))
    blocks = [:mu => 1:pμ, :sigma => (pμ+1):(pμ+pσ), :resd => (pμ+pσ+1):(pμ+pσ+1)]
    names = [:mu => nmμ, :sigma => nmσ, :resd => [String(grp)]]
    means = Dict(:mu => exp.(Xμ * θ̂[1:pμ])); obs = Dict(:mu => Vector{Float64}(y))
    scales = Dict{Symbol,Vector{Float64}}()
    return _withnll(DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n, Optim.converged(res), means, obs, scales), nll)
end

# LogNormal GLMM with a CORRELATED random intercept+slope (1 + x | g) on the
# log-mean μ. Per group (b0,b1) ~ N(0, Σ_re), Σ_re = L Lᵀ with L = [l11 0; cc l22]
# (log-Cholesky parameters a, b, cc; l11=exp(a), l22=exp(b)). The 2-D group integral
# is taken by K×K Gauss–Hermite quadrature: substituting (b0,b1) = √2 L z turns the
# prior integral into Σⱼₖ wⱼwₖ·(group likelihood at node j,k). σ = SD of log y is a
# fixed effect. θ = [β_μ; β_σ; a, b, cc]. O(n_g·K²) per group. The constant −Σ log y
# Jacobian is added to the reported loglik to match the fixed fitter's convention.
function _fit_lognormal_corr_ranef(fam::LogNormal, y, Xμ, Xσ, xs, gidx, G, nmμ, nmσ, grp, g_tol)
    n = length(y); pμ, pσ = size(Xμ, 2), size(Xσ, 2)
    ly = log.(y); sumlogy = sum(ly)                  # Σ log y = the Jacobian offset
    members = [Int[] for _ in 1:G]
    for i in 1:n
        push!(members[gidx[i]], i)
    end
    z1, w1 = _gauss_hermite(12); lw = log.(w1); K = length(z1); rt2 = sqrt(2.0); lπ = log(π)
    function nll(θ)
        βμ = θ[1:pμ]; βσ = θ[pμ+1:pμ+pσ]
        l11 = exp(θ[pμ+pσ+1]); l22 = exp(θ[pμ+pσ+2]); cc = θ[pμ+pσ+3]
        η0 = Xμ * βμ; ησ = clamp.(Xσ * βσ, -15.0, 15.0)
        s = zero(eltype(θ))
        for idx in members
            isempty(idx) && continue
            terms = Vector{eltype(θ)}(undef, K * K); t = 0
            for j in 1:K, k in 1:K
                t += 1
                b0 = rt2 * l11 * z1[j]; b1 = rt2 * (cc * z1[j] + l22 * z1[k])
                gll = lw[j] + lw[k]
                for i in idx
                    μ = clamp(η0[i] + b0 + b1 * xs[i], -30.0, 30.0); σ = exp(ησ[i])
                    gll += Distributions.logpdf(Distributions.Normal(μ, σ), ly[i])
                end
                terms[t] = gll
            end
            mx = maximum(terms)
            s -= (-lπ + mx + log(sum(exp.(terms .- mx))))
        end
        return s + sumlogy                            # + Σ log y so loglik carries the Jacobian
    end
    βμ0 = Xμ \ ly
    θ0 = zeros(pμ + pσ + 3)
    θ0[1:pμ] .= βμ0
    θ0[pμ+1] = log(std(ly - Xμ * βμ0) + eps())
    θ0[pμ+pσ+1] = log(0.4); θ0[pμ+pσ+2] = log(0.4); θ0[pμ+pσ+3] = 0.0
    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Optim.minimizer(res); V = inv(ForwardDiff.hessian(nll, θ̂))
    blocks = [:mu => 1:pμ, :sigma => (pμ+1):(pμ+pσ), :recov => (pμ+pσ+1):(pμ+pσ+3)]
    names = [:mu => nmμ, :sigma => nmσ, :recov => ["$(grp):L11", "$(grp):L22", "$(grp):L21"]]
    means = Dict(:mu => exp.(Xμ * θ̂[1:pμ])); obs = Dict(:mu => Vector{Float64}(y))
    scales = Dict{Symbol,Vector{Float64}}()
    return _withnll(DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n, Optim.converged(res), means, obs, scales), nll)
end

function _fit_lognormal(fam::LogNormal, y, Xμ, Xσ, nmμ, nmσ, g_tol)
    n = length(y); pμ, pσ = size(Xμ, 2), size(Xσ, 2)
    ly = log.(y); sumlogy = sum(ly)                  # Σ log y = the Jacobian offset
    function nll(θ)
        βμ = θ[1:pμ]; βσ = θ[pμ+1:pμ+pσ]
        ημ = Xμ * βμ; ησ = Xσ * βσ                   # ησ = log σ
        s = zero(eltype(θ))
        @inbounds for i in 1:n
            r = ly[i] - ημ[i]
            s += ησ[i] + 0.5 * r * r * exp(-2 * ησ[i])
        end
        return s + 0.5 * n * log(2π) + sumlogy        # Gaussian-on-log-y nll + Σ log y
    end
    βμ0 = Xμ \ ly
    θ0 = zeros(pμ + pσ)
    θ0[1:pμ] .= βμ0
    θ0[pμ+1] = log(std(ly - Xμ * βμ0) + eps())
    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Optim.minimizer(res); V = inv(ForwardDiff.hessian(nll, θ̂))
    blocks = [:mu => 1:pμ, :sigma => (pμ+1):(pμ+pσ)]
    names = [:mu => nmμ, :sigma => nmσ]
    means = Dict(:mu => exp.(Xμ * θ̂[1:pμ])); obs = Dict(:mu => Vector{Float64}(y))  # response-scale median
    scales = Dict{Symbol,Vector{Float64}}()
    return _withnll(DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n, Optim.converged(res), means, obs, scales), nll)
end
