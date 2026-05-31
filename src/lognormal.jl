# lognormal.jl — LogNormal family for strictly-positive responses whose log is
# Gaussian. The mean formula μ is the mean of log y (identity link on the log
# scale); σ (log link) is the SD of log y. The log-density is the Gaussian
# log-density of log y plus the −log y change-of-variables Jacobian, so the fit
# reuses the Gaussian location–scale objective on log y. Fixed effects, ML.
# Mirrors drmTMB's `lognormal`. No `Distributions` needed.

"""
    LogNormal()

LogNormal response family for positive continuous data: the mean formula `μ` is
the **mean of `log y`** (identity link on the log scale), and `σ` (log link) is
the **SD of `log y`**. The response-scale median is `exp(μ)`. Mirrors `drmTMB`'s
`lognormal` family.

!!! note
    `DRM.LogNormal` shadows `Distributions.LogNormal`; qualify the latter if needed.

```julia
fit = drm(bf(y ~ x, sigma ~ 1), LogNormal(); data = dat)
coef(fit, :mu)                 # on the log scale
exp(coef(fit, :sigma)[1])      # SD of log y
```
"""
struct LogNormal end

function drm(f::DrmFormula, fam::LogNormal; data, g_tol::Real = 1e-8)
    rhs = Dict(f.forms)
    for (_, r) in f.forms
        _, re, mv, st = _split_ranef(r)
        (isempty(re) && mv === nothing && st === nothing) ||
            error("LogNormal() currently supports fixed effects only")
    end
    y, Xμ, nmμ = _design(f.response, rhs[:mu], data)
    _, Xσ, nmσ = _design(f.response, get(rhs, :sigma, ConstantTerm(1)), data)
    all(yi -> yi > 0, y) || error("LogNormal() requires strictly positive responses")
    return _withformula(_fit_lognormal(fam, y, Xμ, Xσ, nmμ, nmσ, g_tol), f)
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
