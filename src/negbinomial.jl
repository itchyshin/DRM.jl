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
Crossed random intercepts on the mean, such as `(1 | g) + (1 | h)`, use the
sparse-Laplace engine when `sigma ~ 1`. A phylogenetic random intercept on the
mean, `phylo(1 | species)`, also uses the sparse-Laplace engine; here a covariate
dispersion formula `sigma ~ x` is supported (a per-observation log-size; #164),
while the crossed-intercept route still requires `sigma ~ 1`.

```julia
fit = drm(bf(y ~ x, sigma ~ 1), NegBinomial2(); data = dat)
fit = drm(bf(y ~ x + (1 | g) + (1 | h), sigma ~ 1), NegBinomial2(); data = dat)
fit_phy = drm(bf(@formula(y ~ x + phylo(1 | species)), @formula(sigma ~ 1)),
              NegBinomial2(); data = dat, tree = tr, se = false)
fit_disp = drm(bf(@formula(y ~ x + phylo(1 | species)), @formula(sigma ~ x)),
               NegBinomial2(); data = dat, tree = tr, se = false)  # log-size ~ x
exp(coef(fit, :sigma)[1])     # estimated dispersion θ (size)
```
"""
struct NegBinomial2 end

function drm(f::DrmFormula, fam::NegBinomial2; data, tree = nothing, g_tol::Real = 1e-8,
             se::Bool = true)
    missing_fit = _fit_observed_response_rows(f, data) do data_observed
        drm(f, fam; data = data_observed, tree = tree, g_tol = g_tol, se = se)
    end
    missing_fit !== nothing && return missing_fit

    rhs = Dict(f.forms)
    # Location–scale: a coupled `(1 | tag | group)` shared by the mean and sigma
    # formulas → one 2×2 group-level covariance fit by the augmented-state engine.
    lc = _ls_coupled_re(rhs[:mu], get(rhs, :sigma, ConstantTerm(1)))
    lc === nothing ||
        return _withformula(_fit_locscale_frontend(Val(:nb2), fam, f, rhs, lc, data;
                                                    g_tol = g_tol, se = se), f)
    fixed_mu, re, mv, st = _split_ranef(rhs[:mu])
    mv === nothing ||
        error("NegBinomial2() does not support meta_V markers")
    for (pname, r) in f.forms          # only the mean may carry a random effect
        pname === :mu && continue
        _, re2, mv2, st2 = _split_ranef(r)
        (isempty(re2) && mv2 === nothing && st2 === nothing) ||
            error("NegBinomial2(): only the mean formula may carry a random effect")
    end
    y, Xμ, nmμ = _design(f.response, fixed_mu, data)
    _, Xσ, nmσ = _design(f.response, get(rhs, :sigma, ConstantTerm(1)), data)
    all(yi -> yi ≥ 0 && isinteger(yi), y) ||
        error("NegBinomial2() requires non-negative integer counts as the response")
    if st !== nothing
        isempty(re) ||
            error("NegBinomial2() phylo structured effects cannot be combined with ordinary random effects yet")
        (haskey(rhs, :zi) || haskey(rhs, :hu)) &&
            error("NegBinomial2() phylo structured effects cannot be combined with `zi`/`hu` yet")
        # `sigma ~ 1` keeps the scalar-dispersion spine; a covariate `sigma`
        # formula routes to the per-observation log-dispersion path (#164).
        kind, grp = st
        kind === :phylo ||
            error("NegBinomial2() currently supports only phylo(1 | group) among structured markers")
        tree === nothing && error("phylo(1 | $grp) needs `tree = …`")
        labels = getproperty(data, grp)
        return _withformula(_fit_nb2_phylo_laplace(fam, y, Xμ, Xσ, labels, tree, nmμ, nmσ, grp, g_tol; se = se), f)
    end
    if !isempty(re)                                       # random effect on the mean → GHQ/Laplace
        (haskey(rhs, :zi) || haskey(rhs, :hu)) &&
            error("NegBinomial2() random effects cannot be combined with `zi`/`hu` yet")
        if length(re) > 1
            all(_re_kind(r[1])[1] === :intercept for r in re) ||
                error("NegBinomial2() supports multiple random effects only as crossed/nested intercepts, e.g. `(1 | g) + (1 | h)`")
            comps = map(re) do r
                grp = r[2]; gidx, G = _group_index(getproperty(data, grp))
                (ones(length(y)), gidx, G, String(grp))
            end
            return _withformula(_fit_nb2_crossed_laplace(fam, y, Xμ, Xσ, comps, nmμ, nmσ, g_tol; se = se), f)
        end
        (rk, var) = _re_kind(re[1][1]); grp = re[1][2]
        gidx, G = _group_index(getproperty(data, grp))
        if rk === :intercept                              # (1 | g) → 1-D GHQ
            return _withformula(_fit_negbin2_ranef(fam, y, Xμ, Xσ, gidx, G, nmμ, nmσ, grp, g_tol), f)
        elseif rk === :corr                               # (1 + x | g) → 2-D GHQ
            return _withformula(_fit_negbin2_corr_ranef(fam, y, Xμ, Xσ, Float64.(getproperty(data, var)), gidx, G, nmμ, nmσ, grp, g_tol), f)
        else
            error("NegBinomial2() supports (1|g) or (1+x|g) on the mean")
        end
    end
    haskey(rhs, :zi) && haskey(rhs, :hu) &&
        error("`zi` and `hu` cannot both be specified (zero-inflation vs hurdle)")
    if haskey(rhs, :zi)                                   # zero-inflated NB (ZINB)
        _, Xzi, nmzi = _design(f.response, rhs[:zi], data)
        return _withformula(_fit_negbin2_zi(fam, y, Xμ, Xσ, Xzi, nmμ, nmσ, nmzi, g_tol), f)
    end
    if haskey(rhs, :hu)                                   # hurdle NB
        _, Xhu, nmhu = _design(f.response, rhs[:hu], data)
        return _withformula(_fit_negbin2_hu(fam, y, Xμ, Xσ, Xhu, nmμ, nmσ, nmhu, g_tol), f)
    end
    return _withformula(_fit_negbin2(fam, y, Xμ, Xσ, nmμ, nmσ, g_tol), f)
end

# NB2 count GLMM with a random intercept (1|g) on log μ. b_g ~ N(0,σ_b²) is
# integrated out per group by 32-node Gauss–Hermite quadrature; the dispersion θ
# (the `sigma` slot) is a fixed effect. Same scheme as the Poisson GLMM.
function _fit_negbin2_ranef(fam::NegBinomial2, y, Xμ, Xσ, gidx, G, nmμ, nmσ, grp, g_tol)
    n = length(y); pμ, pσ = size(Xμ, 2), size(Xσ, 2)
    members = [Int[] for _ in 1:G]
    for i in 1:n
        push!(members[gidx[i]], i)
    end
    yint = round.(Int, y)
    z, w = _gauss_hermite(32); logw = log.(w); K = length(z); rt2 = sqrt(2.0); lπ = log(π)
    function nll(θ)
        βμ = θ[1:pμ]; βσ = θ[pμ+1:pμ+pσ]; σb = exp(θ[pμ+pσ+1])
        η0 = Xμ * βμ; ησ = clamp.(Xσ * βσ, -20.0, 20.0)
        s = zero(eltype(θ))
        for idx in members
            isempty(idx) && continue
            terms = Vector{eltype(θ)}(undef, K)
            for k in 1:K
                δ = rt2 * σb * z[k]
                gll = logw[k]
                for i in idx
                    μ = exp(clamp(η0[i] + δ, -20.0, 20.0)); r = exp(ησ[i]); p = r / (r + μ)
                    gll += logpdf(NegativeBinomial(r, p), yint[i])
                end
                terms[k] = gll
            end
            mx = maximum(terms)
            s -= (-0.5 * lπ + mx + log(sum(exp.(terms .- mx))))
        end
        return s
    end
    m = sum(y) / n; v = sum(abs2, y .- m) / max(n - 1, 1)
    θ0 = zeros(pμ + pσ + 1)
    θ0[1] = log(m + eps())
    θ0[pμ+1] = log(max(m^2 / max(v - m, 0.1 * m + eps()), 0.5))
    θ0[pμ+pσ+1] = log(0.5)
    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Optim.minimizer(res); V = inv(ForwardDiff.hessian(nll, θ̂))
    blocks = [:mu => 1:pμ, :sigma => (pμ+1):(pμ+pσ), :resd => (pμ+pσ+1):(pμ+pσ+1)]
    names = [:mu => nmμ, :sigma => nmσ, :resd => [String(grp)]]
    means = Dict(:mu => exp.(Xμ * θ̂[1:pμ])); obs = Dict(:mu => Vector{Float64}(y))   # population μ (b=0)
    scales = Dict(:sigma => exp.(Xσ * θ̂[(pμ+1):(pμ+pσ)]))
    return _withnll(DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n, Optim.converged(res), means, obs, scales), nll)
end

# NB2 count GLMM with a CORRELATED random intercept+slope (1 + x | g) on log μ:
# per group (b0,b1) ~ N(0, Σ_re), Σ_re a 2×2 covariance (log-Cholesky a, b, c).
# Unlike the Gaussian case there is no closed-form marginal (b enters μ through
# exp), so the 2-D prior integral is done by tensor-product Gauss–Hermite: with
# (b0,b1) = √2 L (z_j, z_k) the prior turns into Σ_{j,k} w_j w_k·(likelihood at
# that node). O(G·K²·m̄) per eval, fully differentiable. Mirrors the Poisson /
# NB2 random-intercept route extended to two dimensions; the `recov` block and
# names follow the Gaussian correlated fit so `vc(fit)` reconstructs Σ.
function _fit_negbin2_corr_ranef(fam::NegBinomial2, y, Xμ, Xσ, xs, gidx, G, nmμ, nmσ, grp, g_tol)
    n = length(y); pμ, pσ = size(Xμ, 2), size(Xσ, 2)
    members = [Int[] for _ in 1:G]
    for i in 1:n
        push!(members[gidx[i]], i)
    end
    yint = round.(Int, y)
    z1, w1 = _gauss_hermite(12); lw = log.(w1); K = length(z1); rt2 = sqrt(2.0); lπ = log(π)
    function nll(θ)
        βμ = θ[1:pμ]; βσ = θ[pμ+1:pμ+pσ]
        a = θ[pμ+pσ+1]; b = θ[pμ+pσ+2]; cc = θ[pμ+pσ+3]
        l11 = exp(a); l22 = exp(b)                 # L = [l11 0; cc l22], Σ_re = L Lᵀ
        η0 = Xμ * βμ; ησ = clamp.(Xσ * βσ, -20.0, 20.0)
        s = zero(eltype(θ))
        for idx in members
            isempty(idx) && continue
            terms = Vector{eltype(θ)}(undef, K * K); t = 0
            for j in 1:K, k in 1:K
                t += 1
                b0 = rt2 * l11 * z1[j]; b1 = rt2 * (cc * z1[j] + l22 * z1[k])   # √2 L z
                gll = lw[j] + lw[k]
                for i in idx
                    μ = exp(clamp(η0[i] + b0 + b1 * xs[i], -20.0, 20.0)); r = exp(ησ[i]); p = r / (r + μ)
                    gll += logpdf(NegativeBinomial(r, p), yint[i])
                end
                terms[t] = gll
            end
            mx = maximum(terms)
            s -= (-lπ + mx + log(sum(exp.(terms .- mx))))   # 2-D Gaussian factor: −log π
        end
        return s
    end
    m = sum(y) / n; v = sum(abs2, y .- m) / max(n - 1, 1)
    θ0 = zeros(pμ + pσ + 3)
    θ0[1] = log(m + eps())
    θ0[pμ+1] = log(max(m^2 / max(v - m, 0.1 * m + eps()), 0.5))   # MoM dispersion init (as in _fit_negbin2_ranef)
    θ0[pμ+pσ+1] = log(0.4); θ0[pμ+pσ+2] = log(0.4); θ0[pμ+pσ+3] = 0.0
    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Optim.minimizer(res); V = inv(ForwardDiff.hessian(nll, θ̂))
    blocks = [:mu => 1:pμ, :sigma => (pμ+1):(pμ+pσ), :recov => (pμ+pσ+1):(pμ+pσ+3)]
    names = [:mu => nmμ, :sigma => nmσ, :recov => ["$(grp):L11", "$(grp):L22", "$(grp):L21"]]
    means = Dict(:mu => exp.(Xμ * θ̂[1:pμ])); obs = Dict(:mu => Vector{Float64}(y))   # population μ (b=0)
    scales = Dict(:sigma => exp.(Xσ * θ̂[(pμ+1):(pμ+pσ)]))
    return _withnll(DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n, Optim.converged(res), means, obs, scales), nll)
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
    scales = Dict(:sigma => exp.(Xσ * θ̂[(pμ+1):(pμ+pσ)]),
                  :zi => _logistic.(Xzi * θ̂[(pμ+pσ+1):(pμ+pσ+pz)]))
    return _withnll(DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n, Optim.converged(res), means, obs, scales), nll)
end

# Hurdle NB2: P(0) = π, P(k>0) = (1-π)·NB(k)/(1-NB(0)) [zero-truncated], with
# π = logistic(Xhuᵀβ) the hurdle (zero) probability. Uses `_log1mexp` (poisson.jl).
function _fit_negbin2_hu(fam::NegBinomial2, y, Xμ, Xσ, Xhu, nmμ, nmσ, nmhu, g_tol)
    n = length(y); pμ, pσ, ph = size(Xμ, 2), size(Xσ, 2), size(Xhu, 2)
    yint = round.(Int, y); iszero_y = y .== 0
    function nll(θ)
        βμ = θ[1:pμ]; βσ = θ[pμ+1:pμ+pσ]; βh = θ[pμ+pσ+1:pμ+pσ+ph]
        ημ = clamp.(Xμ * βμ, -20.0, 20.0); ησ = clamp.(Xσ * βσ, -20.0, 20.0)
        ηh = clamp.(Xhu * βh, -30.0, 30.0)
        s = zero(eltype(θ))
        @inbounds for i in 1:n
            lπ = _log_logistic(ηh[i]); l1mπ = _log1m_logistic(ηh[i])
            if iszero_y[i]
                s -= lπ
            else
                μ = exp(ημ[i]); r = exp(ησ[i]); p = r / (r + μ)
                d = NegativeBinomial(r, p)
                s -= l1mπ + logpdf(d, yint[i]) - _log1mexp(logpdf(d, 0))
            end
        end
        return s
    end
    pos = y[y.>0]; m = isempty(pos) ? sum(y) / n : sum(pos) / length(pos)
    v = sum(abs2, y .- sum(y) / n) / max(n - 1, 1)
    θ0 = zeros(pμ + pσ + ph)
    θ0[1] = log(m + eps())
    θ0[pμ+1] = log(max(m^2 / max(v - m, 0.1 * m + eps()), 0.5))
    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Optim.minimizer(res); V = inv(ForwardDiff.hessian(nll, θ̂))
    blocks = [:mu => 1:pμ, :sigma => (pμ+1):(pμ+pσ), :hu => (pμ+pσ+1):(pμ+pσ+ph)]
    names = [:mu => nmμ, :sigma => nmσ, :hu => nmhu]
    means = Dict(:mu => exp.(Xμ * θ̂[1:pμ])); obs = Dict(:mu => Vector{Float64}(y))
    scales = Dict(:sigma => exp.(Xσ * θ̂[(pμ+1):(pμ+pσ)]),
                  :hu => _logistic.(Xhu * θ̂[(pμ+pσ+1):(pμ+pσ+ph)]))
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
    scales = Dict(:sigma => exp.(Xσ * θ̂[(pμ+1):(pμ+pσ)]))
    return _withnll(DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n, Optim.converged(res), means, obs, scales), nll)
end

"""
    TruncatedNegBinomial2()

Zero-truncated negative-binomial (NB2) family for strictly-positive counts (≥ 1)
— litter sizes, group sizes given presence. Same parameterisation as
[`NegBinomial2`](@ref) (log-link mean `μ`, dispersion `θ` in the `sigma` slot)
but conditioned on `y ≥ 1`: `P(k) = NB(k) / (1 − NB(0))`. Mirrors `drmTMB`'s
`truncated_nbinom2`.

```julia
fit = drm(bf(y ~ x, sigma ~ 1), TruncatedNegBinomial2(); data = dat)
```
"""
struct TruncatedNegBinomial2 end

function drm(f::DrmFormula, fam::TruncatedNegBinomial2; data, g_tol::Real = 1e-8)
    missing_fit = _fit_observed_response_rows(f, data) do data_observed
        drm(f, fam; data = data_observed, g_tol = g_tol)
    end
    missing_fit !== nothing && return missing_fit

    rhs = Dict(f.forms)
    for (_, r) in f.forms
        _, re, mv, st = _split_ranef(r)
        (isempty(re) && mv === nothing && st === nothing) ||
            error("TruncatedNegBinomial2() currently supports fixed effects only")
    end
    y, Xμ, nmμ = _design(f.response, rhs[:mu], data)
    _, Xσ, nmσ = _design(f.response, get(rhs, :sigma, ConstantTerm(1)), data)
    all(yi -> yi ≥ 1 && isinteger(yi), y) ||
        error("TruncatedNegBinomial2() requires positive integer counts (≥ 1) as the response")
    return _withformula(_fit_truncated_negbin2(fam, y, Xμ, Xσ, nmμ, nmσ, g_tol), f)
end

function _fit_truncated_negbin2(fam::TruncatedNegBinomial2, y, Xμ, Xσ, nmμ, nmσ, g_tol)
    n = length(y); pμ, pσ = size(Xμ, 2), size(Xσ, 2)
    yint = round.(Int, y)
    function nll(θ)
        βμ = θ[1:pμ]; βσ = θ[pμ+1:pμ+pσ]
        ημ = clamp.(Xμ * βμ, -20.0, 20.0); ησ = clamp.(Xσ * βσ, -20.0, 20.0)
        s = zero(eltype(θ))
        @inbounds for i in 1:n
            μ = exp(ημ[i]); r = exp(ησ[i]); p = r / (r + μ)
            d = NegativeBinomial(r, p)
            s -= logpdf(d, yint[i]) - _log1mexp(logpdf(d, 0))   # divide out P(0): zero-truncated
        end
        return s
    end
    m = sum(y) / n; v = sum(abs2, y .- m) / max(n - 1, 1)
    θ0 = zeros(pμ + pσ)
    θ0[1] = log(m + eps())
    θ0[pμ+1] = log(max(m^2 / max(v - m, 0.1 * m + eps()), 0.5))
    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Optim.minimizer(res); V = inv(ForwardDiff.hessian(nll, θ̂))
    blocks = [:mu => 1:pμ, :sigma => (pμ+1):(pμ+pσ)]
    names = [:mu => nmμ, :sigma => nmσ]
    means = Dict(:mu => exp.(Xμ * θ̂[1:pμ])); obs = Dict(:mu => Vector{Float64}(y))  # untruncated NB mean μ̂
    scales = Dict(:sigma => exp.(Xσ * θ̂[(pμ+1):(pμ+pσ)]))
    return _withnll(DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n, Optim.converged(res), means, obs, scales), nll)
end
