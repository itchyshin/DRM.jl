# poisson.jl — Poisson family for count responses. Log link on the mean
# (λ = exp(Xμβ)); no dispersion parameter (see the negative-binomial family for
# overdispersed counts). Fixed effects, maximum likelihood. Mirrors drmTMB's
# `poisson`. The log-pmf is written out explicitly (y·log λ − λ − log y!) so the
# fit needs no `Distributions.Poisson` — that name is left to Distributions.

"""
    Poisson()

Poisson response family for counts: log link on the mean `μ` (so `μ` coefficients
act on `log λ`). No scale parameter. Mirrors `drmTMB`'s `poisson` family.

!!! note
    `DRM.Poisson` shadows `Distributions.Poisson`; if you need the distribution
    too (e.g. to simulate), qualify it as `Distributions.Poisson`.

```julia
fit = drm(bf(y ~ x), Poisson(); data = dat)
fitted(fit)        # fitted counts λ = exp(Xβ̂), on the response scale
```
"""
struct Poisson end

_logfactorial(k::Integer) = sum(log, 2:k; init = 0.0)   # log k!  (0 for k = 0, 1)

function drm(f::DrmFormula, fam::Poisson; data, g_tol::Real = 1e-8)
    rhs = Dict(f.forms)
    fixed_mu, re, mv, st = _split_ranef(rhs[:mu])
    (mv === nothing && st === nothing) ||
        error("Poisson() does not support meta_V / structured markers")
    y, Xμ, nmμ = _design(f.response, fixed_mu, data)
    all(yi -> yi ≥ 0 && isinteger(yi), y) ||
        error("Poisson() requires non-negative integer counts as the response")
    if !isempty(re)                                       # random intercept (1|g) → GHQ marginal
        (haskey(rhs, :zi) || haskey(rhs, :hu)) &&
            error("Poisson() random effects cannot be combined with `zi`/`hu` yet")
        if length(re) > 1                                 # (1|g)+(1|h)+… crossed/multiple intercepts → sparse Laplace
            all(_re_kind(r[1])[1] === :intercept for r in re) ||
                error("Poisson() supports multiple random effects only as crossed/nested intercepts, e.g. `(1 | g) + (1 | h)`")
            comps = map(re) do r
                grp = r[2]; gidx, G = _group_index(getproperty(data, grp))
                (ones(length(y)), gidx, G, String(grp))
            end
            return _withformula(_fit_poisson_crossed_laplace(fam, y, Xμ, comps, nmμ, g_tol), f)
        end
        (rk, var) = _re_kind(re[1][1]); grp = re[1][2]; gidx, G = _group_index(getproperty(data, grp))
        if rk === :intercept                              # (1 | g) → 1-D GHQ
            return _withformula(_fit_poisson_ranef(fam, y, Xμ, gidx, G, nmμ, grp, g_tol), f)
        elseif rk === :corr                               # (1 + x | g) → 2-D GHQ
            xs = Float64.(getproperty(data, var))
            return _withformula(_fit_poisson_corr_ranef(fam, y, Xμ, xs, gidx, G, nmμ, grp, g_tol), f)
        else
            error("Poisson() supports `(1 | g)` or `(1 + x | g)` random effects on the mean")
        end
    end
    haskey(rhs, :zi) && haskey(rhs, :hu) &&
        error("`zi` and `hu` cannot both be specified (zero-inflation vs hurdle)")
    if haskey(rhs, :zi)                                   # zero-inflated Poisson
        _, Xzi, nmzi = _design(f.response, rhs[:zi], data)
        return _withformula(_fit_poisson_zi(fam, y, Xμ, Xzi, nmμ, nmzi, g_tol), f)
    end
    if haskey(rhs, :hu)                                   # hurdle Poisson
        _, Xhu, nmhu = _design(f.response, rhs[:hu], data)
        return _withformula(_fit_poisson_hu(fam, y, Xμ, Xhu, nmμ, nmhu, g_tol), f)
    end
    return _withformula(_fit_poisson(fam, y, Xμ, nmμ, g_tol), f)
end

# Poisson count GLMM with a random intercept (1|g) on log λ. b_g ~ N(0,σ_b²) is
# integrated out per group by K-node Gauss–Hermite quadrature (b = √2 σ_b z), the
# same scheme as the Gaussian σ-RE. O(n·K) per evaluation, fully differentiable.
function _fit_poisson_ranef(fam::Poisson, y, Xμ, gidx, G, nmμ, grp, g_tol)
    n = length(y); pμ = size(Xμ, 2)
    members = [Int[] for _ in 1:G]
    for i in 1:n
        push!(members[gidx[i]], i)
    end
    lf = [_logfactorial(round(Int, yi)) for yi in y]
    z, w = _gauss_hermite(32); logw = log.(w); K = length(z); rt2 = sqrt(2.0); lπ = log(π)
    function nll(θ)
        βμ = θ[1:pμ]; σb = exp(θ[pμ+1])
        η0 = Xμ * βμ
        s = zero(eltype(θ))
        for idx in members
            isempty(idx) && continue
            terms = Vector{eltype(θ)}(undef, K)
            for k in 1:K
                δ = rt2 * σb * z[k]
                gll = logw[k]
                for i in idx
                    η = η0[i] + δ
                    gll += y[i] * η - exp(η) - lf[i]      # log Poisson(y_i; e^η)
                end
                terms[k] = gll
            end
            mx = maximum(terms)
            s -= (-0.5 * lπ + mx + log(sum(exp.(terms .- mx))))
        end
        return s
    end
    θ0 = zeros(pμ + 1)
    θ0[1] = log(sum(y) / n + eps())
    θ0[pμ+1] = log(0.5)
    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Optim.minimizer(res); V = inv(ForwardDiff.hessian(nll, θ̂))
    blocks = [:mu => 1:pμ, :resd => (pμ+1):(pμ+1)]
    names = [:mu => nmμ, :resd => [String(grp)]]
    means = Dict(:mu => exp.(Xμ * θ̂[1:pμ])); obs = Dict(:mu => Vector{Float64}(y))   # population λ (b=0)
    scales = Dict{Symbol,Vector{Float64}}()
    return _withnll(DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n, Optim.converged(res), means, obs, scales), nll)
end

# Poisson count GLMM with a correlated random intercept+slope (1 + x | g) on log λ.
# Per group (b0,b1) ~ N(0, Σ); because groups are disjoint the 2-D integral
# factorises, so it is done by a 2-D Gauss–Hermite tensor grid (K² nodes). Σ is the
# log-Cholesky parameterisation L = [exp(a) 0; cc exp(b)] (the `vc` convention), so
# vc(fit) reconstructs Σ = L Lᵀ. O(G·K²·group) per eval, fully differentiable.
function _fit_poisson_corr_ranef(fam::Poisson, y, Xμ, xs, gidx, G, nmμ, grp, g_tol)
    n = length(y); pμ = size(Xμ, 2)
    members = [Int[] for _ in 1:G]
    for i in 1:n
        push!(members[gidx[i]], i)
    end
    lf = [_logfactorial(round(Int, yi)) for yi in y]
    z1, w1 = _gauss_hermite(12); lw = log.(w1); K = length(z1); rt2 = sqrt(2.0); lπ = log(π)
    function nll(θ)
        βμ = θ[1:pμ]; a = θ[pμ+1]; b = θ[pμ+2]; cc = θ[pμ+3]
        l11 = exp(a); l22 = exp(b); η0 = Xμ * βμ
        s = zero(eltype(θ))
        for idx in members
            isempty(idx) && continue
            terms = Vector{eltype(θ)}(undef, K * K)
            t = 0
            for j in 1:K, k in 1:K
                t += 1
                b0 = rt2 * l11 * z1[j]; b1 = rt2 * (cc * z1[j] + l22 * z1[k])   # √2 L z
                gll = lw[j] + lw[k]
                for i in idx
                    η = clamp(η0[i] + b0 + b1 * xs[i], -30.0, 30.0)
                    gll += y[i] * η - exp(η) - lf[i]
                end
                terms[t] = gll
            end
            mx = maximum(terms)
            s -= (-lπ + mx + log(sum(exp.(terms .- mx))))      # 2-D: -0.5·2·logπ = -logπ
        end
        return s
    end
    θ0 = zeros(pμ + 3)
    θ0[1] = log(sum(y) / n + eps())
    θ0[pμ+1] = log(0.4); θ0[pμ+2] = log(0.4); θ0[pμ+3] = 0.0
    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Optim.minimizer(res); V = inv(ForwardDiff.hessian(nll, θ̂))
    blocks = [:mu => 1:pμ, :recov => (pμ+1):(pμ+3)]
    names = [:mu => nmμ, :recov => ["$(grp):L11", "$(grp):L22", "$(grp):L21"]]
    means = Dict(:mu => exp.(Xμ * θ̂[1:pμ])); obs = Dict(:mu => Vector{Float64}(y))
    scales = Dict{Symbol,Vector{Float64}}()
    return _withnll(DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n, Optim.converged(res), means, obs, scales), nll)
end

# log-logistic helpers (stable): log π and log(1-π) for π = logistic(η).
_log_logistic(η) = -log1p(exp(-η))
_log1m_logistic(η) = -log1p(exp(η))
# log(exp(a) + exp(b)), numerically stable.
_logaddexp(a, b) = (m = max(a, b); m + log1p(exp(-abs(a - b))))
# log(1 - exp(x)) for x ≤ 0, numerically stable (hurdle zero-truncation term).
_log1mexp(x) = x < -log(2) ? log1p(-exp(x)) : log(-expm1(x))

# Zero-inflated Poisson: P(0) = π + (1-π)e^{-λ}, P(k>0) = (1-π)·Poisson(k; λ),
# with π = logistic(Xziᵀβ) (logit link) and λ = exp(Xμᵀβ).
function _fit_poisson_zi(fam::Poisson, y, Xμ, Xzi, nmμ, nmzi, g_tol)
    n = length(y); pμ, pz = size(Xμ, 2), size(Xzi, 2)
    lf = [_logfactorial(round(Int, yi)) for yi in y]
    iszero_y = y .== 0
    function nll(θ)
        βμ = θ[1:pμ]; βz = θ[pμ+1:pμ+pz]
        ημ = clamp.(Xμ * βμ, -30.0, 30.0); ηz = clamp.(Xzi * βz, -30.0, 30.0)
        s = zero(eltype(θ))
        @inbounds for i in 1:n
            λ = exp(ημ[i]); lπ = _log_logistic(ηz[i]); l1mπ = _log1m_logistic(ηz[i])
            if iszero_y[i]
                s -= _logaddexp(lπ, l1mπ - λ)              # log(π + (1-π)e^{-λ})
            else
                s -= l1mπ + (y[i] * ημ[i] - λ - lf[i])
            end
        end
        return s
    end
    pos = y[y.>0]
    θ0 = zeros(pμ + pz)
    θ0[1] = log((isempty(pos) ? sum(y) / n : sum(pos) / length(pos)) + eps())   # λ from non-zeros
    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Optim.minimizer(res); V = inv(ForwardDiff.hessian(nll, θ̂))
    blocks = [:mu => 1:pμ, :zi => (pμ+1):(pμ+pz)]
    names = [:mu => nmμ, :zi => nmzi]
    means = Dict(:mu => exp.(Xμ * θ̂[1:pμ])); obs = Dict(:mu => Vector{Float64}(y))
    scales = Dict{Symbol,Vector{Float64}}()
    return _withnll(DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n, Optim.converged(res), means, obs, scales), nll)
end

# Hurdle Poisson: P(0) = π, P(k>0) = (1-π)·Poisson(k; λ)/(1-e^{-λ}) [zero-truncated],
# with π = logistic(Xhuᵀβ) the hurdle (zero) probability and λ = exp(Xμᵀβ). All
# zeros are structural; the positive part is the zero-truncated Poisson.
function _fit_poisson_hu(fam::Poisson, y, Xμ, Xhu, nmμ, nmhu, g_tol)
    n = length(y); pμ, ph = size(Xμ, 2), size(Xhu, 2)
    lf = [_logfactorial(round(Int, yi)) for yi in y]
    iszero_y = y .== 0
    function nll(θ)
        βμ = θ[1:pμ]; βh = θ[pμ+1:pμ+ph]
        ημ = clamp.(Xμ * βμ, -30.0, 30.0); ηh = clamp.(Xhu * βh, -30.0, 30.0)
        s = zero(eltype(θ))
        @inbounds for i in 1:n
            lπ = _log_logistic(ηh[i]); l1mπ = _log1m_logistic(ηh[i])
            if iszero_y[i]
                s -= lπ                                        # log π
            else
                λ = exp(ημ[i])
                lpos = y[i] * ημ[i] - λ - lf[i]                # log Poisson(k; λ)
                s -= l1mπ + lpos - _log1mexp(-λ)               # − log(1 − e^{-λ})
            end
        end
        return s
    end
    pos = y[y.>0]
    θ0 = zeros(pμ + ph)
    θ0[1] = log((isempty(pos) ? sum(y) / n : sum(pos) / length(pos)) + eps())   # λ from non-zeros
    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Optim.minimizer(res); V = inv(ForwardDiff.hessian(nll, θ̂))
    blocks = [:mu => 1:pμ, :hu => (pμ+1):(pμ+ph)]
    names = [:mu => nmμ, :hu => nmhu]
    means = Dict(:mu => exp.(Xμ * θ̂[1:pμ])); obs = Dict(:mu => Vector{Float64}(y))
    scales = Dict{Symbol,Vector{Float64}}()
    return _withnll(DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n, Optim.converged(res), means, obs, scales), nll)
end

function _fit_poisson(fam::Poisson, y, Xμ, nmμ, g_tol)
    n = length(y); pμ = size(Xμ, 2)
    lf = [_logfactorial(round(Int, yi)) for yi in y]    # constant log y! offset
    function nll(θ)
        ημ = Xμ * θ                                     # log λ
        s = zero(eltype(θ))
        @inbounds for i in 1:n
            s -= y[i] * ημ[i] - exp(ημ[i]) - lf[i]
        end
        return s
    end
    θ0 = zeros(pμ); θ0[1] = log(sum(y) / n + eps())
    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Optim.minimizer(res); V = inv(ForwardDiff.hessian(nll, θ̂))
    blocks = [:mu => 1:pμ]; names = [:mu => nmμ]
    means = Dict(:mu => exp.(Xμ * θ̂)); obs = Dict(:mu => Vector{Float64}(y))   # response-scale λ
    scales = Dict{Symbol,Vector{Float64}}()
    return _withnll(DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n, Optim.converged(res), means, obs, scales), nll)
end
