# gaussian_core.jl — public formula front end + univariate Gaussian
# location–scale fitter (fixed effects, maximum likelihood). The drmTMB homepage
# model: a formula for the mean μ and a formula for the (log) scale σ.
#
# Public-verb decision (resolves issue #18): the Julia fit verb is `drm(...)`;
# the formula bundle is `bf(...)` (alias `drm_formula(...)`), mirroring
# brms / drmTMB. Each formula's left-hand side names its distributional
# parameter — `y ~ …` sets the response + μ predictor, `sigma ~ …` sets log σ.

using StatsModels: @formula, FormulaTerm, Term, ConstantTerm, FunctionTerm,
    schema, apply_schema, modelcols, coefnames
using Statistics: std
import StatsAPI: coef, vcov, nobs, StatisticalModel

"""
    Gaussian()

Gaussian response family: identity link on the mean `μ`, log link on the scale
`σ` (so `σ` coefficients act on `log σ`). Mirrors `drmTMB::gaussian()`.
"""
struct Gaussian end

"""
    DrmFormula

A bundle of one linear-predictor formula per distributional parameter, built by
[`bf`](@ref). `response` is the response column; `forms` is ordered
`:mu => rhs, :sigma => rhs, …`.
"""
struct DrmFormula
    response::Symbol
    forms::Vector{Pair{Symbol,Any}}
end

"""
    bf(response_formula, dpar_formulas...)
    drm_formula(response_formula, dpar_formulas...)

Bundle one formula per distributional parameter, exactly as drmTMB. The first
formula `y ~ …` sets the response and the `μ` predictor; each later formula
`param ~ …` (e.g. `sigma ~ …`) sets that parameter's predictor. `sigma` defaults
to `~ 1` when omitted.
"""
function bf(mu::FormulaTerm, dpars::FormulaTerm...)
    response = mu.lhs.sym
    forms = Pair{Symbol,Any}[:mu => mu.rhs]
    for f in dpars
        push!(forms, f.lhs.sym => f.rhs)
    end
    any(p -> first(p) === :sigma, forms) || push!(forms, :sigma => ConstantTerm(1))
    return DrmFormula(response, forms)
end
const drm_formula = bf

"""
    DrmFit

A fitted distributional regression model. Accessors: [`coef`](@ref),
`coef(fit, :mu)`, [`vcov`](@ref), [`loglik`](@ref), [`nobs`](@ref),
[`fixef`](@ref).
"""
struct DrmFit{F}
    family::F
    blocks::Vector{Pair{Symbol,UnitRange{Int}}}
    coefnames::Vector{Pair{Symbol,Vector{String}}}
    theta::Vector{Float64}
    vcov::Matrix{Float64}
    loglik::Float64
    nobs::Int
    converged::Bool
end

# Build a design matrix for one parameter's RHS. We reuse the (real) response as
# a dummy LHS so the formula is always valid for `schema`/`modelcols`, then keep
# only the predictor matrix.
function _design(response::Symbol, rhs, data)
    ft = FormulaTerm(Term(response), rhs)
    # The 3-arg apply_schema with a StatisticalModel context adds R's implicit
    # intercept (so `y ~ x` means `y ~ 1 + x`, matching drmTMB); explicit
    # `1 + x` / `0 + x` are respected.
    ft = apply_schema(ft, schema(ft, data), StatisticalModel)
    y, X = modelcols(ft, data)
    Xm = X isa AbstractMatrix ? Matrix{Float64}(X) : reshape(Float64.(collect(X)), :, 1)
    return Float64.(y), Xm, String.(vec(coefnames(ft.rhs)))
end

"""
    drm(formula::DrmFormula, family; data) -> DrmFit

Fit a distributional regression model by maximum likelihood. Currently supports
the univariate `Gaussian()` location–scale model with fixed effects:

```julia
fit = drm(bf(y ~ x1, sigma ~ x1), Gaussian(); data = dat)
```
"""
function drm(f::DrmFormula, fam::Gaussian; data, g_tol::Real = 1e-8)
    rhs = Dict(f.forms)
    fixed_mu, re = _split_ranef(rhs[:mu])          # peel off (1 | g) terms
    y, Xμ, nmμ = _design(f.response, fixed_mu, data)
    _, Xσ, nmσ = _design(f.response, rhs[:sigma], data)
    isempty(re) && return _fit_fixed_gaussian(fam, y, Xμ, Xσ, nmμ, nmσ, g_tol)
    length(re) == 1 ||
        error("DRM.jl (current slice) supports a single random-intercept term `(1 | g)`")
    _, grp = re[1]
    gidx, G = _group_index(getproperty(data, grp))
    return _fit_ranef_gaussian(fam, y, Xμ, Xσ, gidx, G, nmμ, nmσ, grp, g_tol)
end

# univariate Gaussian location–scale, fixed effects only (closed form, ML)
function _fit_fixed_gaussian(fam::Gaussian, y, Xμ, Xσ, nmμ, nmσ, g_tol)
    n = length(y)
    pμ, pσ = size(Xμ, 2), size(Xσ, 2)
    function nll(θ)
        βμ = θ[1:pμ]; βσ = θ[pμ+1:pμ+pσ]
        ημ = Xμ * βμ; ησ = Xσ * βσ                 # log σ
        s = zero(eltype(θ))
        @inbounds for i in 1:n
            r = y[i] - ημ[i]
            s += ησ[i] + 0.5 * r * r * exp(-2 * ησ[i])
        end
        return s + 0.5 * n * log(2π)
    end
    βμ0 = Xμ \ y
    θ0 = zeros(pμ + pσ)
    θ0[1:pμ] .= βμ0
    θ0[pμ+1] = log(std(y - Xμ * βμ0) + eps())
    res = Optim.optimize(nll, θ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :forward)
    θ̂ = Optim.minimizer(res)
    V = inv(ForwardDiff.hessian(nll, θ̂))
    blocks = [:mu => 1:pμ, :sigma => (pμ+1):(pμ+pσ)]
    names = [:mu => nmμ, :sigma => nmσ]
    return DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n, Optim.converged(res))
end

# ---- accessors -----------------------------------------------------------
coef(fit::DrmFit) = fit.theta
function coef(fit::DrmFit, param::Symbol)
    for (p, r) in fit.blocks
        p === param && return fit.theta[r]
    end
    throw(ArgumentError("no parameter $param in fit (have $(first.(fit.blocks)))"))
end
vcov(fit::DrmFit) = fit.vcov
nobs(fit::DrmFit) = fit.nobs

"""
    loglik(fit) -> Float64

Maximised log-likelihood of the fitted model.
"""
loglik(fit::DrmFit) = fit.loglik

"""
    re_sd(fit) -> Dict{Symbol,Float64}

Estimated random-effect (random-intercept) standard deviations, keyed by
grouping factor.
"""
function re_sd(fit::DrmFit)
    d = Dict{Symbol,Float64}()
    for (p, r) in fit.blocks
        p === :resd || continue
        nms = first(cn[2] for cn in fit.coefnames if cn[1] === :resd)
        for (j, nm) in enumerate(nms)
            d[Symbol(nm)] = exp(fit.theta[r[j]])
        end
    end
    return d
end

"""
    fixef(fit) -> Vector{Pair}

Fixed-effect coefficients per distributional parameter, with their names.
"""
fixef(fit::DrmFit) =
    [p => (names = ns, estimate = coef(fit, p)) for ((p, _), (_, ns)) in zip(fit.blocks, fit.coefnames)]

function Base.show(io::IO, fit::DrmFit)
    print(io, "DrmFit (Gaussian location–scale, ", fit.nobs, " obs, ",
        fit.converged ? "converged" : "NOT converged",
        "; logLik = ", round(fit.loglik, digits = 2), ")")
    for (p, _) in fit.blocks
        print(io, "\n  ", p, ": ", join(string.(round.(coef(fit, p), digits = 3)), ", "))
    end
end
