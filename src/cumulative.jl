# cumulative.jl — Cumulative-logit ordinal regression. Ordered categorical
# response y ∈ {1,…,K}; Pr(y ≤ k) = logistic(θ_k − η) with ordered cutpoints
# θ_1 < … < θ_{K-1} and a single linear predictor η. The location intercept is
# dropped (a free intercept and free cutpoints are not jointly identifiable), so
# the `mu` formula contributes slopes only. No `sigma`. The cutpoints are kept
# ordered by the increment parameterisation θ_1 = δ_1, θ_k = θ_{k-1} + exp(δ_k).
# Mirrors drmTMB's `cumulative_logit`. Fixed effects, ML, plus an ordinary
# random intercept `(1 | g)` or independent random slope `(0 + x | g)` on `mu`
# (#563 S8) via 32-node Gauss–Hermite quadrature — the same scheme as the
# Poisson/Gamma/Tweedie `(1 | g)` routes (src/poisson.jl, src/gamma.jl,
# src/tweedie.jl). Correlated slopes `(1 + x | g)`, crossed/multiple random
# effects, structured (phylo/relmat/animal/spatial) markers, and random-effect
# scale formulas are refused, matching drmTMB 0.7.0's own
# `validate_cumulative_logit_mu_random_terms()` scope for the first two; the
# structured refusal here is a DRM.jl scope decision for this slice, not a
# drmTMB parity gap — drmTMB 0.7.0 does support an unlabelled, intercept-only
# `phylo(1 | species)` structured `mu` effect for `cumulative_logit()`
# (`validate_ordinal_phylo_mu_structured_term()`), which is left for a
# separate slice.

"""
    CumulativeLogit()

Cumulative-logit (proportional-odds) ordinal family. The response is an ordered
category coded `1, 2, …, K`. `Pr(y ≤ k) = logistic(θ_k − η)` with ordered
cutpoints `θ_1 < … < θ_{K-1}`; the single linear predictor `η` comes from the
`mu` formula **with its intercept dropped** (cutpoints absorb it). No scale
parameter. `coef(fit, :mu)` are the slopes; `coef(fit, :cutpoints)` are the raw
increment parameters (`θ_1 = δ_1`, `θ_k = θ_{k-1} + exp(δ_k)`). `fitted` returns
the expected ordered-category score `Σ_k k·Pr(y=k)`. Mirrors `drmTMB`'s
`cumulative_logit`. An ordinary random intercept `(1 | g)` or an independent
random slope `(0 + x | g)` on `mu` integrates the group-level term out by
32-node Gauss–Hermite quadrature; `coef(fit, :resd)` is the log random-effect
SD. Correlated slopes `(1 + x | g)`, crossed/multiple random effects, and
structured markers are not implemented in this slice.

```julia
fit = drm(bf(y ~ x), CumulativeLogit(); data = dat)          # y coded 1..K
fit_re = drm(bf(y ~ x + (1 | g)), CumulativeLogit(); data = dat)
fit_slope = drm(bf(y ~ x + (0 + x | g)), CumulativeLogit(); data = dat)
```
"""
struct CumulativeLogit end

# Ordered cutpoints from the free increment parameters: θ_1 = δ_1,
# θ_k = θ_{k-1} + exp(δ_k) for k ≥ 2. Shared by the fixed-effect and
# random-effect fitters below.
function _cumulative_cuts(δ)
    nc = length(δ)
    cuts = similar(δ)
    cuts[1] = δ[1]
    for k in 2:nc
        cuts[k] = cuts[k-1] + exp(δ[k])
    end
    return cuts
end

# Per-observation cumulative-logit log-likelihood log P(y=k | η, cuts).
@inline function _cumulative_loglik(k::Int, η, cuts, K::Int, nc::Int)
    if k == 1
        return _log_logistic(cuts[1] - η)                    # P(y=1) = F(θ_1−η)
    elseif k == K
        return _log_logistic(η - cuts[nc])                   # P(y=K) = 1−F(θ_{K-1}−η)
    else
        P = _logistic(cuts[k] - η) - _logistic(cuts[k-1] - η)
        return log(P)
    end
end

# Expected ordered-category score Σ_k k·P(y=k|η,cuts), the `fitted()` value.
function _cumulative_score(η̂, cuts_hat, K)
    n = length(η̂); nc = K - 1
    score = Vector{Float64}(undef, n)
    for i in 1:n
        sc = 0.0
        for k in 1:K
            Pk = k == 1 ? _logistic(cuts_hat[1] - η̂[i]) :
                 k == K ? 1 - _logistic(cuts_hat[nc] - η̂[i]) :
                 _logistic(cuts_hat[k] - η̂[i]) - _logistic(cuts_hat[k-1] - η̂[i])
            sc += k * Pk
        end
        score[i] = sc
    end
    return score
end

# Initial cutpoint increments from empirical cumulative category proportions.
function _cumulative_cut_init(y, K, n)
    nc = K - 1
    cnt = [count(==(k), y) for k in 1:K]
    cum = clamp.(cumsum(cnt)[1:nc] ./ n, 1e-3, 1 - 1e-3)
    θc0 = log.(cum ./ (1 .- cum))
    δ0 = zeros(nc)
    δ0[1] = θc0[1]
    for k in 2:nc
        δ0[k] = log(max(θc0[k] - θc0[k-1], 1e-2))
    end
    return δ0
end

function drm(f::DrmFormula, fam::CumulativeLogit; data, g_tol::Real = 1e-8)
    missing_fit = _fit_observed_response_rows(f, data) do data_observed
        drm(f, fam; data = data_observed, g_tol = g_tol)
    end
    missing_fit !== nothing && return missing_fit

    _lss_only_gaussian_guard(f, fam)   # #544: refuse, never silently drop, sd() parts
    rhs = Dict(f.forms)
    fixed_mu, re, mv, st = _split_ranef(rhs[:mu])
    mv === nothing ||
        error("CumulativeLogit() does not support meta_V markers")
    st === nothing ||
        error("CumulativeLogit() structured (phylo/relmat/animal/spatial) `mu` random " *
              "effects are not implemented in this slice; use an ordinary `(1 | g)` " *
              "random intercept or `(0 + x | g)` random slope instead")
    y, Xμ, nmμ = _design(f.response, fixed_mu, data)
    ic = findfirst(==("(Intercept)"), nmμ)               # drop the location intercept
    if ic !== nothing
        keep = setdiff(1:length(nmμ), ic)
        Xμ = Xμ[:, keep]; nmμ = nmμ[keep]
    end
    (all(yi -> yi >= 1 && isinteger(yi), y) && maximum(y) >= 2) ||
        error("CumulativeLogit() requires ordered integer categories coded 1, 2, …, K (K ≥ 2)")
    K = round(Int, maximum(y))
    yi = round.(Int, y)
    if !isempty(re)                    # random intercept/slope on mu → GHQ marginal (#563 S8)
        length(re) == 1 ||
            error("CumulativeLogit() supports only a single `(1 | g)` random intercept or " *
                  "`(0 + x | g)` random slope on `mu`; crossed/multiple random effects are " *
                  "not implemented in this slice")
        (rk, var) = _re_kind(re[1][1]); grp = re[1][2]
        gidx, G = _group_index(getproperty(data, grp))
        if rk === :intercept
            return _withformula(_fit_cumulative_ranef(fam, yi, Xμ, K, gidx, G, nmμ, grp, g_tol), f)
        elseif rk === :slope
            xs = Float64.(getproperty(data, var))
            return _withformula(
                _fit_cumulative_slope_ranef(fam, yi, Xμ, K, xs, gidx, G, nmμ, grp, g_tol), f)
        else
            error("CumulativeLogit() supports only an ordinary `(1 | g)` random intercept " *
                  "or an independent `(0 + x | g)` random slope on `mu`; correlated random " *
                  "slopes `(1 + x | g)` are not implemented (matches drmTMB 0.7.0: " *
                  "\"Only independent cumulative_logit() mu random intercepts and slopes " *
                  "are implemented in this slice\")")
        end
    end
    return _withformula(_fit_cumulative(fam, yi, Xμ, K, nmμ, g_tol), f)
end

function _fit_cumulative(fam::CumulativeLogit, y::Vector{Int}, Xμ, K, nmμ, g_tol)
    n = length(y); pμ = size(Xμ, 2); nc = K - 1
    function nll(θ)
        β = θ[1:pμ]; δ = θ[pμ+1:pμ+nc]
        cuts = _cumulative_cuts(δ)
        η = pμ == 0 ? zeros(eltype(θ), n) : Xμ * β
        s = zero(eltype(θ))
        @inbounds for i in 1:n
            s -= _cumulative_loglik(y[i], η[i], cuts, K, nc)
        end
        return s
    end
    θ0 = zeros(pμ + nc)
    θ0[(pμ+1):(pμ+nc)] = _cumulative_cut_init(y, K, n)
    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Optim.minimizer(res); V = _vcov_from_hessian(ForwardDiff.hessian(nll, θ̂))
    blocks = [:mu => 1:pμ, :cutpoints => (pμ+1):(pμ+nc)]
    names = [:mu => nmμ, :cutpoints => ["theta$k" for k in 1:nc]]
    # fitted = expected category score Σ_k k·P(y=k)
    β̂ = θ̂[1:pμ]; δ̂ = θ̂[pμ+1:pμ+nc]
    # `cuts_hat`, NOT `cuts` (#549 class): the nll closure above also assigns
    # `cuts`, and sharing the name here would make it one boxed variable shared
    # with a closure that threaded profile CIs call concurrently.
    cuts_hat = _cumulative_cuts(δ̂)
    η̂ = pμ == 0 ? zeros(n) : Xμ * β̂
    score = _cumulative_score(η̂, cuts_hat, K)
    means = Dict(:mu => score); obs = Dict(:mu => Float64.(y))
    scales = Dict(:ordinal_eta => η̂, :ordinal_cuts => Float64.(cuts_hat))
    return _withiterations(
        _withnll(DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n, Optim.converged(res), means, obs, scales), nll),
        Optim.iterations(res))
end

# Cumulative-logit ordinal GLMM with a random intercept (1|g) on the latent
# linear predictor η. b_g ~ N(0,σ_b²) integrated out per group by 32-node
# Gauss–Hermite quadrature (b = √2 σ_b z) — the same scheme as the
# Poisson/Gamma/Tweedie `(1 | g)` routes (src/poisson.jl `_fit_poisson_ranef`,
# src/gamma.jl `_fit_gamma_ranef`, src/tweedie.jl `_fit_tweedie_ranef`).
# Cutpoints stay ordinary fixed effects (shared across groups). #563 S8.
function _fit_cumulative_ranef(fam::CumulativeLogit, y::Vector{Int}, Xμ, K, gidx, G, nmμ, grp, g_tol)
    n = length(y); pμ = size(Xμ, 2); nc = K - 1
    members = [Int[] for _ in 1:G]
    for i in 1:n
        push!(members[gidx[i]], i)
    end
    z, w = _gauss_hermite(32); logw = log.(w); Kq = length(z); rt2 = sqrt(2.0); lπ = log(π)
    function nll(θ)
        β = θ[1:pμ]; δ = θ[pμ+1:pμ+nc]; σb = exp(θ[pμ+nc+1])
        cuts = _cumulative_cuts(δ)
        η0 = pμ == 0 ? zeros(eltype(θ), n) : Xμ * β
        s = zero(eltype(θ))
        for idx in members
            isempty(idx) && continue
            terms = Vector{eltype(θ)}(undef, Kq)
            for k in 1:Kq
                b = rt2 * σb * z[k]; gll = logw[k]
                for i in idx
                    gll += _cumulative_loglik(y[i], η0[i] + b, cuts, K, nc)
                end
                terms[k] = gll
            end
            mx = maximum(terms)
            s -= (-0.5 * lπ + mx + log(sum(exp.(terms .- mx))))
        end
        return s
    end
    θ0 = zeros(pμ + nc + 1)
    θ0[(pμ+1):(pμ+nc)] = _cumulative_cut_init(y, K, n)
    θ0[pμ+nc+1] = log(0.5)             # σ_b
    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Optim.minimizer(res); V = _vcov_from_hessian(ForwardDiff.hessian(nll, θ̂))
    blocks = [:mu => 1:pμ, :cutpoints => (pμ+1):(pμ+nc), :resd => (pμ+nc+1):(pμ+nc+1)]
    names = [:mu => nmμ, :cutpoints => ["theta$k" for k in 1:nc], :resd => [String(grp)]]
    β̂ = θ̂[1:pμ]; cuts_hat = _cumulative_cuts(θ̂[pμ+1:pμ+nc])
    η̂ = pμ == 0 ? zeros(n) : Xμ * β̂     # population (b=0) linear predictor
    score = _cumulative_score(η̂, cuts_hat, K)
    means = Dict(:mu => score); obs = Dict(:mu => Float64.(y))
    scales = Dict(:ordinal_eta => η̂, :ordinal_cuts => Float64.(cuts_hat))
    return _withiterations(
        _withnll(DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n, Optim.converged(res), means, obs, scales), nll),
        Optim.iterations(res))
end

# Cumulative-logit ordinal GLMM with an INDEPENDENT random slope (0+x|g) on
# the latent linear predictor η. b_g ~ N(0,σ_b²) integrated out per group by
# 32-node Gauss–Hermite quadrature; the group term enters as b_g·x_i rather
# than b_g. Same scheme as src/tweedie.jl `_fit_tweedie_slope_ranef`. #563 S8.
function _fit_cumulative_slope_ranef(fam::CumulativeLogit, y::Vector{Int}, Xμ, K, xs, gidx, G, nmμ, grp, g_tol)
    n = length(y); pμ = size(Xμ, 2); nc = K - 1
    members = [Int[] for _ in 1:G]
    for i in 1:n
        push!(members[gidx[i]], i)
    end
    z, w = _gauss_hermite(32); logw = log.(w); Kq = length(z); rt2 = sqrt(2.0); lπ = log(π)
    function nll(θ)
        β = θ[1:pμ]; δ = θ[pμ+1:pμ+nc]; σb = exp(θ[pμ+nc+1])
        cuts = _cumulative_cuts(δ)
        η0 = pμ == 0 ? zeros(eltype(θ), n) : Xμ * β
        s = zero(eltype(θ))
        for idx in members
            isempty(idx) && continue
            terms = Vector{eltype(θ)}(undef, Kq)
            for k in 1:Kq
                b = rt2 * σb * z[k]; gll = logw[k]
                for i in idx
                    gll += _cumulative_loglik(y[i], η0[i] + b * xs[i], cuts, K, nc)
                end
                terms[k] = gll
            end
            mx = maximum(terms)
            s -= (-0.5 * lπ + mx + log(sum(exp.(terms .- mx))))
        end
        return s
    end
    θ0 = zeros(pμ + nc + 1)
    θ0[(pμ+1):(pμ+nc)] = _cumulative_cut_init(y, K, n)
    θ0[pμ+nc+1] = log(0.5)             # σ_b
    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Optim.minimizer(res); V = _vcov_from_hessian(ForwardDiff.hessian(nll, θ̂))
    blocks = [:mu => 1:pμ, :cutpoints => (pμ+1):(pμ+nc), :resd => (pμ+nc+1):(pμ+nc+1)]
    names = [:mu => nmμ, :cutpoints => ["theta$k" for k in 1:nc], :resd => [String(grp)]]
    β̂ = θ̂[1:pμ]; cuts_hat = _cumulative_cuts(θ̂[pμ+1:pμ+nc])
    η̂ = pμ == 0 ? zeros(n) : Xμ * β̂     # population (b=0) linear predictor
    score = _cumulative_score(η̂, cuts_hat, K)
    means = Dict(:mu => score); obs = Dict(:mu => Float64.(y))
    scales = Dict(:ordinal_eta => η̂, :ordinal_cuts => Float64.(cuts_hat))
    return _withiterations(
        _withnll(DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n, Optim.converged(res), means, obs, scales), nll),
        Optim.iterations(res))
end
