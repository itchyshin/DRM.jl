# betabinomial.jl — Beta-binomial family: successes out of known trials, with
# extra-binomial overdispersion. Two-column response `cbind(successes, failures)`
# (trials = successes + failures), exactly as drmTMB. Logit link on the mean
# success probability μ; the `sigma` slot is σ with precision φ = 1/σ² (same
# mapping as Beta) — likelihood BetaBinomial(n, μφ, (1-μ)φ). `Distributions.
# BetaBinomial` is used qualified — DRM exports its own `BetaBinomial` family.

import Distributions

"""
    cbind(successes, failures)

Formula marker for a two-column count response, e.g.
`bf(cbind(successes, failures) ~ x, sigma ~ z)` with [`BetaBinomial`](@ref).
Trials are `successes + failures`. Mirrors drmTMB's `cbind(...)` response.
Only inspected structurally on a formula left-hand side.
"""
cbind(a, b) = hcat(a, b)

"""
    BetaBinomial()

Beta-binomial response family — successes out of known trials with
extra-binomial overdispersion. Logit link on the mean success probability `μ`;
the `sigma` slot carries `σ` with precision `φ = 1/σ²` (so `coef(fit, :sigma)`
is `log σ`). Likelihood `BetaBinomial(n, μφ, (1-μ)φ)`. Requires a two-column
response via [`cbind`](@ref). Mirrors `drmTMB`'s `beta_binomial`.

```julia
fit = drm(bf(cbind(successes, failures) ~ x, sigma ~ 1), BetaBinomial(); data = dat)
```
"""
struct BetaBinomial end

function drm(f::DrmFormula, fam::BetaBinomial; data, g_tol::Real = 1e-8)
    f.response2 === nothing &&
        error("BetaBinomial() needs a two-column response: bf(cbind(successes, failures) ~ …)")
    rhs = Dict(f.forms)
    for (_, r) in f.forms
        _, re, mv, st = _split_ranef(r)
        (isempty(re) && mv === nothing && st === nothing) ||
            error("BetaBinomial() currently supports fixed effects only")
    end
    s = Float64.(getproperty(data, f.response))          # successes
    fl = Float64.(getproperty(data, f.response2))        # failures
    (all(si -> si ≥ 0 && isinteger(si), s) && all(fi -> fi ≥ 0 && isinteger(fi), fl)) ||
        error("BetaBinomial() requires non-negative integer successes and failures")
    ntr = s .+ fl                                        # trials
    _, Xμ, nmμ = _design(f.response, rhs[:mu], data)     # successes column is a dummy LHS
    _, Xσ, nmσ = _design(f.response, get(rhs, :sigma, ConstantTerm(1)), data)
    return _withformula(_fit_betabinomial(fam, s, ntr, Xμ, Xσ, nmμ, nmσ, g_tol), f)
end

function _fit_betabinomial(fam::BetaBinomial, s, ntr, Xμ, Xσ, nmμ, nmσ, g_tol)
    n = length(s); pμ, pσ = size(Xμ, 2), size(Xσ, 2)
    sint = round.(Int, s); nint = round.(Int, ntr)
    function nll(θ)
        βμ = θ[1:pμ]; βσ = θ[pμ+1:pμ+pσ]
        ημ = clamp.(Xμ * βμ, -30.0, 30.0)        # μ ∈ (0,1) strictly
        ησ = clamp.(Xσ * βσ, -15.0, 15.0)        # φ = exp(-2ησ) > 0 finite
        v = zero(eltype(θ))
        @inbounds for i in 1:n
            μ = _logistic(ημ[i]); φ = exp(-2 * ησ[i])
            v -= Distributions.logpdf(Distributions.BetaBinomial(nint[i], μ * φ, (1 - μ) * φ), sint[i])
        end
        return v
    end
    p̄ = clamp(sum(s) / max(sum(ntr), 1), 1e-3, 1 - 1e-3)   # overall success rate
    θ0 = zeros(pμ + pσ)
    θ0[1] = log(p̄ / (1 - p̄))                                # logit p̄
    θ0[pμ+1] = -0.5 * log(10.0)                             # moderate precision init (φ ≈ 10)
    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Optim.minimizer(res); V = inv(ForwardDiff.hessian(nll, θ̂))
    blocks = [:mu => 1:pμ, :sigma => (pμ+1):(pμ+pσ)]
    names = [:mu => nmμ, :sigma => nmσ]
    means = Dict(:mu => _logistic.(Xμ * θ̂[1:pμ]))           # fitted mean success probability
    obs = Dict(:mu => s ./ ntr)                             # observed proportion (for residuals)
    scales = Dict{Symbol,Vector{Float64}}()
    return _withnll(DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n, Optim.converged(res), means, obs, scales), nll)
end
