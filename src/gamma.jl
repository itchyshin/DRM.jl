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
Crossed random intercepts on the mean, such as `(1 | g) + (1 | h)`, use the
sparse-Laplace engine when `sigma ~ 1`. A phylogenetic random intercept on the
mean, `phylo(1 | species)`, also uses the sparse-Laplace engine.

!!! note
    `DRM.Gamma` shadows `Distributions.Gamma`; qualify the latter if you need it.

```julia
fit = drm(bf(y ~ x, sigma ~ 1), Gamma(); data = dat)
fit = drm(bf(y ~ x + (1 | g) + (1 | h), sigma ~ 1), Gamma(); data = dat)
fit_phy = drm(bf(@formula(y ~ x + phylo(1 | species)), @formula(sigma ~ 1)),
              Gamma(); data = dat, tree = tr, se = false)
exp(-2 * coef(fit, :sigma)[1])     # estimated shape α
```
"""
struct Gamma end

function drm(f::DrmFormula, fam::Gamma; data, tree = nothing, g_tol::Real = 1e-8,
             se::Bool = true)
    rhs = Dict(f.forms)
    # Location–scale: a coupled `(1 | tag | group)` shared by the mean and sigma
    # formulas → one 2×2 group-level covariance fit by the augmented-state engine.
    lc = _ls_coupled_re(rhs[:mu], get(rhs, :sigma, ConstantTerm(1)))
    lc === nothing ||
        return _withformula(_fit_locscale_frontend(Val(:gamma), fam, f, rhs, lc, data;
                                                    g_tol = g_tol, se = se), f)
    fixed_mu, re, mv, st = _split_ranef(rhs[:mu])
    mv === nothing ||
        error("Gamma() does not support meta_V markers")
    for (pname, r) in f.forms          # only the mean may carry a random effect
        pname === :mu && continue
        _, re2, mv2, st2 = _split_ranef(r)
        (isempty(re2) && mv2 === nothing && st2 === nothing) ||
            error("Gamma(): only the mean formula may carry a random effect")
    end
    y, Xμ, nmμ = _design(f.response, fixed_mu, data)
    _, Xσ, nmσ = _design(f.response, get(rhs, :sigma, ConstantTerm(1)), data)
    all(yi -> yi > 0, y) || error("Gamma() requires strictly positive responses")
    if st !== nothing
        isempty(re) ||
            error("Gamma() phylo structured effects cannot be combined with ordinary random effects yet")
        # `sigma ~ 1` keeps the scalar-dispersion spine; a covariate `sigma`
        # formula routes to the per-observation log-dispersion path (#164).
        kind, grp = st
        kind === :phylo ||
            error("Gamma() currently supports only phylo(1 | group) among structured markers")
        tree === nothing && error("phylo(1 | $grp) needs `tree = ...`")
        labels = getproperty(data, grp)
        return _withformula(_fit_gamma_phylo_laplace(fam, y, Xμ, Xσ, labels, tree, nmμ, nmσ, grp, g_tol; se = se), f)
    end
    if !isempty(re)                    # random effect on the log mean → GHQ/Laplace
        if length(re) > 1
            all(_re_kind(r[1])[1] === :intercept for r in re) ||
                error("Gamma() supports multiple random effects only as crossed/nested intercepts, e.g. `(1 | g) + (1 | h)`")
            comps = map(re) do r
                grp = r[2]; gidx, G = _group_index(getproperty(data, grp))
                (ones(length(y)), gidx, G, String(grp))
            end
            return _withformula(_fit_gamma_crossed_laplace(fam, y, Xμ, Xσ, comps, nmμ, nmσ, g_tol), f)
        end
        (rk, var) = _re_kind(re[1][1]); grp = re[1][2]
        gidx, G = _group_index(getproperty(data, grp))
        if rk === :intercept           # (1 | g) → 1-D Gauss–Hermite
            return _withformula(_fit_gamma_ranef(fam, y, Xμ, Xσ, gidx, G, nmμ, nmσ, grp, g_tol), f)
        elseif rk === :corr            # (1 + x | g) → correlated 2-D Gauss–Hermite
            return _withformula(_fit_gamma_corr_ranef(fam, y, Xμ, Xσ, Float64.(getproperty(data, var)), gidx, G, nmμ, nmσ, grp, g_tol), f)
        else
            error("Gamma() supports `(1 | g)` or `(1 + x | g)` on the mean")
        end
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
    scales = Dict(:sigma => exp.(Xσ * θ̂[(pμ+1):(pμ+pσ)]))
    return _withnll(DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n, Optim.converged(res), means, obs, scales), nll)
end

# Gamma GLMM with a CORRELATED random intercept+slope (1 + x | g) on the log mean.
# Per group (b0,b1) ~ N(0, Σ_re), Σ_re = L Lᵀ with L = [l11 0; cc l22] (log-Cholesky
# parameters a, b, cc; l11=exp(a), l22=exp(b)). The Gamma marginal has no closed form,
# so the 2-D group integral is taken by K×K Gauss–Hermite quadrature: substituting
# (b0,b1) = √2 L z turns the prior integral into Σⱼₖ wⱼwₖ·(group likelihood at node j,k).
# Shape α = 1/σ² is a fixed effect. θ = [β_μ; β_σ; a, b, cc]. O(n_g·K²) per group.
function _fit_gamma_corr_ranef(fam::Gamma, y, Xμ, Xσ, xs, gidx, G, nmμ, nmσ, grp, g_tol)
    n = length(y); pμ, pσ = size(Xμ, 2), size(Xσ, 2)
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
                    μ = exp(clamp(η0[i] + b0 + b1 * xs[i], -30.0, 30.0)); α = exp(-2 * ησ[i])
                    gll += Distributions.logpdf(Distributions.Gamma(α, μ / α), y[i])
                end
                terms[t] = gll
            end
            mx = maximum(terms)
            s -= (-lπ + mx + log(sum(exp.(terms .- mx))))
        end
        return s
    end
    ȳ = sum(y) / n; v = sum(abs2, y .- ȳ) / max(n - 1, 1)
    α0 = max(ȳ^2 / max(v, eps()), 0.5)
    θ0 = zeros(pμ + pσ + 3)
    θ0[1] = log(ȳ + eps()); θ0[pμ+1] = -0.5 * log(α0)
    θ0[pμ+pσ+1] = log(0.4); θ0[pμ+pσ+2] = log(0.4); θ0[pμ+pσ+3] = 0.0
    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Optim.minimizer(res); V = inv(ForwardDiff.hessian(nll, θ̂))
    blocks = [:mu => 1:pμ, :sigma => (pμ+1):(pμ+pσ), :recov => (pμ+pσ+1):(pμ+pσ+3)]
    names = [:mu => nmμ, :sigma => nmσ, :recov => ["$(grp):L11", "$(grp):L22", "$(grp):L21"]]
    means = Dict(:mu => exp.(Xμ * θ̂[1:pμ])); obs = Dict(:mu => Vector{Float64}(y))
    scales = Dict(:sigma => exp.(Xσ * θ̂[(pμ+1):(pμ+pσ)]))
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
    scales = Dict(:sigma => exp.(Xσ * θ̂[(pμ+1):(pμ+pσ)]))
    return _withnll(DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n, Optim.converged(res), means, obs, scales), nll)
end
