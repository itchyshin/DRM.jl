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
    _, re, mv, st = _split_ranef(rhs[:mu])
    (isempty(re) && mv === nothing && st === nothing) ||
        error("Poisson() currently supports fixed effects only")
    y, Xμ, nmμ = _design(f.response, rhs[:mu], data)
    all(yi -> yi ≥ 0 && isinteger(yi), y) ||
        error("Poisson() requires non-negative integer counts as the response")
    return _withformula(_fit_poisson(fam, y, Xμ, nmμ, g_tol), f)
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
