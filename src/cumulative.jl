# cumulative.jl — Cumulative-logit ordinal regression. Ordered categorical
# response y ∈ {1,…,K}; Pr(y ≤ k) = logistic(θ_k − η) with ordered cutpoints
# θ_1 < … < θ_{K-1} and a single linear predictor η. The location intercept is
# dropped (a free intercept and free cutpoints are not jointly identifiable), so
# the `mu` formula contributes slopes only. No `sigma`. The cutpoints are kept
# ordered by the increment parameterisation θ_1 = δ_1, θ_k = θ_{k-1} + exp(δ_k).
# Mirrors drmTMB's `cumulative_logit`. Fixed effects, ML.

"""
    CumulativeLogit()

Cumulative-logit (proportional-odds) ordinal family. The response is an ordered
category coded `1, 2, …, K`. `Pr(y ≤ k) = logistic(θ_k − η)` with ordered
cutpoints `θ_1 < … < θ_{K-1}`; the single linear predictor `η` comes from the
`mu` formula **with its intercept dropped** (cutpoints absorb it). No scale
parameter. `coef(fit, :mu)` are the slopes; `coef(fit, :cutpoints)` are the raw
increment parameters (`θ_1 = δ_1`, `θ_k = θ_{k-1} + exp(δ_k)`). `fitted` returns
the expected ordered-category score `Σ_k k·Pr(y=k)`. Mirrors `drmTMB`'s
`cumulative_logit`.

```julia
fit = drm(bf(y ~ x), CumulativeLogit(); data = dat)   # y coded 1..K
```
"""
struct CumulativeLogit end

function drm(f::DrmFormula, fam::CumulativeLogit; data, g_tol::Real = 1e-8)
    rhs = Dict(f.forms)
    _, re, mv, st = _split_ranef(rhs[:mu])
    (isempty(re) && mv === nothing && st === nothing) ||
        error("CumulativeLogit() currently supports fixed effects only")
    y, Xμ, nmμ = _design(f.response, rhs[:mu], data)
    ic = findfirst(==("(Intercept)"), nmμ)               # drop the location intercept
    if ic !== nothing
        keep = setdiff(1:length(nmμ), ic)
        Xμ = Xμ[:, keep]; nmμ = nmμ[keep]
    end
    (all(yi -> yi >= 1 && isinteger(yi), y) && maximum(y) >= 2) ||
        error("CumulativeLogit() requires ordered integer categories coded 1, 2, …, K (K ≥ 2)")
    K = round(Int, maximum(y))
    return _withformula(_fit_cumulative(fam, round.(Int, y), Xμ, K, nmμ, g_tol), f)
end

function _fit_cumulative(fam::CumulativeLogit, y::Vector{Int}, Xμ, K, nmμ, g_tol)
    n = length(y); pμ = size(Xμ, 2); nc = K - 1
    function nll(θ)
        β = θ[1:pμ]; δ = θ[pμ+1:pμ+nc]
        cuts = similar(δ); cuts[1] = δ[1]                # θ_1
        for k in 2:nc
            cuts[k] = cuts[k-1] + exp(δ[k])              # ordered: + positive increment
        end
        η = pμ == 0 ? zeros(eltype(θ), n) : Xμ * β
        s = zero(eltype(θ))
        @inbounds for i in 1:n
            k = y[i]
            if k == 1
                s -= _log_logistic(cuts[1] - η[i])               # P(y=1) = F(θ_1−η)
            elseif k == K
                s -= _log_logistic(η[i] - cuts[nc])              # P(y=K) = 1−F(θ_{K-1}−η)
            else
                P = _logistic(cuts[k] - η[i]) - _logistic(cuts[k-1] - η[i])
                s -= log(P)
            end
        end
        return s
    end
    # init: empirical cumulative category proportions → logit cutpoints
    cnt = [count(==(k), y) for k in 1:K]
    cum = clamp.(cumsum(cnt)[1:nc] ./ n, 1e-3, 1 - 1e-3)
    θc0 = log.(cum ./ (1 .- cum))
    θ0 = zeros(pμ + nc)
    θ0[pμ+1] = θc0[1]
    for k in 2:nc
        θ0[pμ+k] = log(max(θc0[k] - θc0[k-1], 1e-2))
    end
    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Optim.minimizer(res); V = inv(ForwardDiff.hessian(nll, θ̂))
    blocks = [:mu => 1:pμ, :cutpoints => (pμ+1):(pμ+nc)]
    names = [:mu => nmμ, :cutpoints => ["theta$k" for k in 1:nc]]
    # fitted = expected category score Σ_k k·P(y=k)
    β̂ = θ̂[1:pμ]; δ̂ = θ̂[pμ+1:pμ+nc]
    cuts = similar(δ̂); cuts[1] = δ̂[1]
    for k in 2:nc; cuts[k] = cuts[k-1] + exp(δ̂[k]); end
    η̂ = pμ == 0 ? zeros(n) : Xμ * β̂
    score = Vector{Float64}(undef, n)
    for i in 1:n
        sc = 0.0
        for k in 1:K
            Pk = k == 1 ? _logistic(cuts[1] - η̂[i]) :
                 k == K ? 1 - _logistic(cuts[nc] - η̂[i]) :
                 _logistic(cuts[k] - η̂[i]) - _logistic(cuts[k-1] - η̂[i])
            sc += k * Pk
        end
        score[i] = sc
    end
    means = Dict(:mu => score); obs = Dict(:mu => Float64.(y))
    scales = Dict(:ordinal_eta => η̂, :ordinal_cuts => Float64.(cuts))
    return _withnll(DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n, Optim.converged(res), means, obs, scales), nll)
end
