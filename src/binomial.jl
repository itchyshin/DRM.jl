# binomial.jl — plain Binomial / Bernoulli family: the classic logistic
# regression / logistic GLMM. Logit link on the mean success probability μ; no
# dispersion parameter (mean-only, like Poisson — see BetaBinomial for the
# overdispersed version). Two response forms: `cbind(successes, failures) ~ x`
# (trials = successes + failures, exactly as drmTMB) or a plain 0/1 Bernoulli
# vector. Fixed effects and a random intercept `(1 | g)` on the mean (logistic
# GLMM). `Distributions.Binomial` is used qualified — DRM exports its own
# `Binomial` family.

import Distributions

"""
    Binomial()

Binomial response family — successes out of known trials (logistic regression).
Logit link on the mean success probability `μ`; no scale/dispersion parameter
(mean-only, like [`Poisson`](@ref)). Accepts either a two-column response via
[`cbind`](@ref) (`trials = successes + failures`) or a plain `0/1` Bernoulli
vector. Likelihood `Binomial(n, μ)` with `μ = logistic(η)`. Mirrors `drmTMB`'s
`binomial` family. A random intercept `(1 | g)` on the mean fits a logistic
GLMM; crossed intercepts such as `(1 | g) + (1 | h)` use the sparse-Laplace
engine, as does `phylo(1 | species)` when `tree = ...` is supplied.

!!! note
    `DRM.Binomial` shadows `Distributions.Binomial`; if you need the
    distribution too (e.g. to simulate), qualify it as `Distributions.Binomial`.

```julia
fit = drm(bf(cbind(successes, failures) ~ x), Binomial(); data = dat)   # logistic regression
fit = drm(bf(y ~ x + (1 | g)), Binomial(); data = dat)                  # 0/1 logistic GLMM
fit = drm(bf(cbind(successes, failures) ~ x + (1 | g) + (1 | h)), Binomial(); data = dat)
fit = drm(bf(cbind(successes, failures) ~ x + phylo(1 | species)), Binomial(); data = dat, tree = phy)
fitted(fit)        # fitted success probabilities μ̂ = logistic(Xβ̂)
```
"""
struct Binomial end

function drm(f::DrmFormula, fam::Binomial; data, tree = nothing, g_tol::Real = 1e-8)
    rhs = Dict(f.forms)
    fixed_mu, re, mv, st = _split_ranef(rhs[:mu])
    for (pname, r) in f.forms          # Binomial is mean-only — reject any other parameter formula
        pname === :mu && continue
        pname === :sigma || error("Binomial() is mean-only; no sigma/dispersion parameter")
        r === ConstantTerm(1) ||
            error("Binomial() is mean-only; no sigma/dispersion parameter")
    end
    if f.response2 === nothing                            # plain 0/1 Bernoulli vector
        s = Float64.(getproperty(data, f.response))
        all(yi -> yi == 0 || yi == 1, s) ||
            error("Binomial() with a single-column response requires a 0/1 (Bernoulli) vector; use cbind(successes, failures) for trial counts")
        ntr = ones(length(s))
    else                                                  # cbind(successes, failures): n = s + f
        s = Float64.(getproperty(data, f.response))       # successes
        fl = Float64.(getproperty(data, f.response2))     # failures
        (all(si -> si ≥ 0 && isinteger(si), s) && all(fi -> fi ≥ 0 && isinteger(fi), fl)) ||
            error("Binomial() requires non-negative integer successes and failures")
        ntr = s .+ fl                                     # trials
    end
    y, Xμ, nmμ = _design(f.response, fixed_mu, data)      # successes column is a dummy LHS
    phy = _nongaussian_phylo_structure("Binomial()", st, re, mv, data, tree)
    if phy !== nothing
        return _withformula(
            _fit_binomial_phylo_laplace(fam, s, ntr, Xμ, phy.gidx, phy.G, phy.K,
                                        nmμ, phy.label, g_tol),
            f
        )
    end
    if !isempty(re)                                       # random intercept (1|g) → GHQ/Laplace marginal
        if length(re) > 1
            all(_re_kind(r[1])[1] === :intercept for r in re) ||
                error("Binomial() supports multiple random effects only as crossed/nested intercepts, e.g. `(1 | g) + (1 | h)`")
            comps = map(re) do r
                grp = r[2]; gidx, G = _group_index(getproperty(data, grp))
                (ones(length(s)), gidx, G, String(grp))
            end
            return _withformula(_fit_binomial_crossed_laplace(fam, s, ntr, Xμ, comps, nmμ, g_tol), f)
        end
        (rk, var) = _re_kind(re[1][1]); grp = re[1][2]; gidx, G = _group_index(getproperty(data, grp))
        rk === :intercept ||
            error("Binomial() supports `(1 | g)` on the mean")
        return _withformula(_fit_binomial_ranef(fam, s, ntr, Xμ, gidx, G, nmμ, grp, g_tol), f)
    end
    return _withformula(_fit_binomial(fam, s, ntr, Xμ, nmμ, g_tol), f)
end

function _fit_binomial(fam::Binomial, s, ntr, Xμ, nmμ, g_tol)
    n = length(s); pμ = size(Xμ, 2)
    sint = round.(Int, s); nint = round.(Int, ntr)
    function nll(θ)
        ημ = clamp.(Xμ * θ, -15.0, 15.0)                  # μ = logistic(η) ∈ (0,1)
        v = zero(eltype(θ))
        @inbounds for i in 1:n
            μ = _logistic(ημ[i])
            v -= Distributions.logpdf(Distributions.Binomial(nint[i], μ), sint[i])
        end
        return v
    end
    p̄ = clamp(sum(s) / max(sum(ntr), 1), 1e-3, 1 - 1e-3)   # overall success rate
    θ0 = zeros(pμ); θ0[1] = log(p̄ / (1 - p̄))               # logit p̄
    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Optim.minimizer(res); V = inv(ForwardDiff.hessian(nll, θ̂))
    blocks = [:mu => 1:pμ]; names = [:mu => nmμ]
    means = Dict(:mu => _logistic.(Xμ * θ̂))                # fitted success probability
    obs = Dict(:mu => s ./ ntr)                            # observed proportion (for residuals)
    scales = Dict(:trials => Float64.(nint))
    return _withnll(DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n, Optim.converged(res), means, obs, scales), nll)
end

# Binomial logistic GLMM with a random intercept (1|g) on the logit mean.
# b_g ~ N(0,σ_b²) is integrated out per group by 32-node Gauss–Hermite
# quadrature (b = √2 σ_b z), the same scheme as the Poisson/Beta GLMMs.
# O(n·K) per evaluation, fully differentiable. θ = [β_μ; log σ_b].
function _fit_binomial_ranef(fam::Binomial, s, ntr, Xμ, gidx, G, nmμ, grp, g_tol)
    n = length(s); pμ = size(Xμ, 2)
    sint = round.(Int, s); nint = round.(Int, ntr)
    members = [Int[] for _ in 1:G]
    for i in 1:n
        push!(members[gidx[i]], i)
    end
    z, w = _gauss_hermite(32); logw = log.(w); K = length(z); rt2 = sqrt(2.0); lπ = log(π)
    function nll(θ)
        βμ = θ[1:pμ]; σb = exp(θ[pμ+1])
        η0 = Xμ * βμ
        s_ = zero(eltype(θ))
        for idx in members
            isempty(idx) && continue
            terms = Vector{eltype(θ)}(undef, K)
            for k in 1:K
                δ = rt2 * σb * z[k]; gll = logw[k]
                for i in idx
                    μ = _logistic(clamp(η0[i] + δ, -15.0, 15.0))
                    gll += Distributions.logpdf(Distributions.Binomial(nint[i], μ), sint[i])
                end
                terms[k] = gll
            end
            mx = maximum(terms)
            s_ -= (-0.5 * lπ + mx + log(sum(exp.(terms .- mx))))
        end
        return s_
    end
    p̄ = clamp(sum(s) / max(sum(ntr), 1), 1e-3, 1 - 1e-3)
    θ0 = zeros(pμ + 1)
    θ0[1] = log(p̄ / (1 - p̄)); θ0[pμ+1] = log(0.5)
    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Optim.minimizer(res); V = inv(ForwardDiff.hessian(nll, θ̂))
    blocks = [:mu => 1:pμ, :resd => (pμ+1):(pμ+1)]
    names = [:mu => nmμ, :resd => [String(grp)]]
    means = Dict(:mu => _logistic.(Xμ * θ̂[1:pμ])); obs = Dict(:mu => s ./ ntr)   # population μ (b=0)
    scales = Dict(:trials => Float64.(nint))
    return _withnll(DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n, Optim.converged(res), means, obs, scales), nll)
end
