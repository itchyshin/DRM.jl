# student.jl — Student-t family: robust location–scale–shape regression.
# A formula per parameter: μ (location, identity), σ (scale, log link), ν
# (degrees of freedom, log link → ν > 0). The density is the location-scale t:
# logpdf = logpdf(TDist(ν), (y-μ)/σ) − log σ. Heavy tails downweight outliers;
# ν → ∞ recovers Gaussian. Fixed effects, maximum likelihood. Mirrors drmTMB's
# `student` family. Random/structured/meta terms are a later slice.

using Distributions: TDist, logpdf

"""
    Student()

Student-t response family: identity link on the location `μ`, log link on the
scale `σ`, and log link on the degrees of freedom `ν` (so `ν` coefficients act
on `log ν`). Robust sibling of [`Gaussian`](@ref) — heavy tails downweight
outliers, and `ν → ∞` tends to Gaussian. Mirrors `drmTMB`'s `student` family.

```julia
fit = drm(bf(y ~ x, sigma ~ 1, nu ~ 1), Student(); data = dat)
exp(coef(fit, :nu)[1])      # estimated degrees of freedom
```
"""
struct Student end

function drm(f::DrmFormula, fam::Student; data, g_tol::Real = 1e-8)
    rhs = Dict(f.forms)
    for (_, r) in f.forms      # fixed-effects-only this slice
        _, re, mv, st = _split_ranef(r)
        (isempty(re) && mv === nothing && st === nothing) ||
            error("Student() currently supports fixed effects only (no random / structured / meta terms)")
    end
    y, Xμ, nmμ = _design(f.response, rhs[:mu], data)
    _, Xσ, nmσ = _design(f.response, get(rhs, :sigma, ConstantTerm(1)), data)
    _, Xν, nmν = _design(f.response, get(rhs, :nu, ConstantTerm(1)), data)
    return _withformula(_fit_student(fam, y, Xμ, Xσ, Xν, nmμ, nmσ, nmν, g_tol), f)
end

function _fit_student(fam::Student, y, Xμ, Xσ, Xν, nmμ, nmσ, nmν, g_tol)
    n = length(y)
    pμ, pσ, pν = size(Xμ, 2), size(Xσ, 2), size(Xν, 2)
    function nll(θ)
        βμ = θ[1:pμ]; βσ = θ[pμ+1:pμ+pσ]; βν = θ[pμ+pσ+1:pμ+pσ+pν]
        ημ = Xμ * βμ; ησ = Xσ * βσ; ην = Xν * βν
        s = zero(eltype(θ))
        @inbounds for i in 1:n
            ν = exp(ην[i]); z = (y[i] - ημ[i]) * exp(-ησ[i])
            s -= logpdf(TDist(ν), z) - ησ[i]       # − log σ Jacobian
        end
        return s
    end
    βμ0 = Xμ \ y
    θ0 = zeros(pμ + pσ + pν)
    θ0[1:pμ] .= βμ0
    θ0[pμ+1] = log(std(y - Xμ * βμ0) + eps())       # σ init
    θ0[pμ+pσ+1] = log(10.0)                          # ν init (mildly heavy-tailed)
    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Optim.minimizer(res); V = inv(ForwardDiff.hessian(nll, θ̂))
    blocks = [:mu => 1:pμ, :sigma => (pμ+1):(pμ+pσ), :nu => (pμ+pσ+1):(pμ+pσ+pν)]
    names = [:mu => nmμ, :sigma => nmσ, :nu => nmν]
    means = Dict(:mu => Xμ * θ̂[1:pμ]); obs = Dict(:mu => Vector{Float64}(y))
    scales = Dict(:sigma => exp.(Xσ * θ̂[(pμ+1):(pμ+pσ)]))
    return _withnll(DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n, Optim.converged(res), means, obs, scales), nll)
end
