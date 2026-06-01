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
using Random: default_rng
import StatsAPI: coef, vcov, nobs, fitted, residuals, predict, aic, bic, dof, StatisticalModel

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
    response2::Any   # second response column (failures), for `cbind(s, f)` beta-binomial; else nothing
end

# 2-arg convenience: single-column response (the common case).
DrmFormula(response::Symbol, forms::Vector{Pair{Symbol,Any}}) = DrmFormula(response, forms, nothing)

"""
    bf(response_formula, dpar_formulas...)
    drm_formula(response_formula, dpar_formulas...)

Bundle one formula per distributional parameter, exactly as drmTMB. The first
formula `y ~ …` sets the response and the `μ` predictor; each later formula
`param ~ …` (e.g. `sigma ~ …`) sets that parameter's predictor. `sigma` defaults
to `~ 1` when omitted.
"""
function bf(mu::FormulaTerm, dpars::FormulaTerm...)
    lhs = mu.lhs
    if lhs isa FunctionTerm && lhs.f === cbind        # cbind(successes, failures) ~ …
        response = lhs.args[1].sym; response2 = lhs.args[2].sym
    else
        response = lhs.sym; response2 = nothing
    end
    forms = Pair{Symbol,Any}[:mu => mu.rhs]
    for f in dpars
        push!(forms, f.lhs.sym => f.rhs)
    end
    any(p -> first(p) === :sigma, forms) || push!(forms, :sigma => ConstantTerm(1))
    return DrmFormula(response, forms, response2)
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
    means::Dict{Symbol,Vector{Float64}}   # fitted mean per mean-parameter
    obs::Dict{Symbol,Vector{Float64}}      # observed response per mean-parameter
    scales::Dict{Symbol,Vector{Float64}}   # residual scale(s) for simulation
    formula::Any                           # the DrmFormula / BivariateDrmFormula (for predict)
    nll::Any                               # objective θ ↦ nll(θ) (for profile intervals)
end

# 11-arg outer constructor: formula + nll default to nothing (the fitters use
# this; drm() attaches the formula via _withformula, the objective via _withnll).
DrmFit(family, blocks, coefnames, theta, vcov, loglik, nobs, converged, means, obs, scales) =
    DrmFit(family, blocks, coefnames, theta, vcov, loglik, nobs, converged, means, obs, scales, nothing, nothing)

_withformula(fit::DrmFit, f) = DrmFit(fit.family, fit.blocks, fit.coefnames, fit.theta,
    fit.vcov, fit.loglik, fit.nobs, fit.converged, fit.means, fit.obs, fit.scales, f, fit.nll)

# Attach the (negative) log-likelihood closure so profile intervals can re-optimise
# the nuisance parameters at each fixed value. nll(θ) must accept the full θ vector.
_withnll(fit::DrmFit, nll) = DrmFit(fit.family, fit.blocks, fit.coefnames, fit.theta,
    fit.vcov, fit.loglik, fit.nobs, fit.converged, fit.means, fit.obs, fit.scales, fit.formula, nll)

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
function drm(f::DrmFormula, fam::Gaussian; data, K = nothing, A = nothing, tree = nothing, coords = nothing, g_tol::Real = 1e-8)
    rhs = Dict(f.forms)
    fixed_mu, re, metav, structured = _split_ranef(rhs[:mu])   # (1|g), meta_V(v), relmat/animal/phylo/spatial(1|g)
    fixed_sigma, sigma_re, _, _ = _split_ranef(rhs[:sigma])    # (1|g) on the scale → GHQ marginal
    y, Xμ, nmμ = _design(f.response, fixed_mu, data)
    _, Xσ, nmσ = _design(f.response, fixed_sigma, data)
    if !isempty(sigma_re)                                      # random effect on log σ
        (isempty(re) && structured === nothing && metav === nothing) ||
            error("a random effect on `sigma` must be the only random structure (the mean must be fixed effects)")
        (length(sigma_re) == 1 && _re_kind(sigma_re[1][1])[1] === :intercept) ||
            error("`sigma` random effects support a single random intercept `(1 | g)`")
        sgrp = sigma_re[1][2]
        gidx, G = _group_index(getproperty(data, sgrp))
        return _withformula(_fit_sigma_ranef_gaussian(fam, y, Xμ, Xσ, gidx, G, nmμ, nmσ, sgrp, g_tol), f)
    end
    if structured !== nothing
        kind, grp = structured
        gidx, G = _group_index(getproperty(data, grp))
        if kind === :spatial
            coords === nothing && error("spatial(1 | $grp) needs `coords = …`")
            cmat = Matrix{Float64}(coords)
            size(cmat, 1) == G || error("coords must have $G rows (one per `$grp` level)")
            return _withformula(_fit_spatial_gaussian(fam, y, Xμ, Xσ, gidx, G, cmat, nmμ, nmσ, grp, g_tol), f)
        end
        Kmat = if kind === :relmat
            K === nothing && error("relmat(1 | $grp) needs `K = …`")
            Matrix{Float64}(K)
        elseif kind === :animal
            A === nothing && error("animal(1 | $grp) needs the relatedness matrix `A = …`")
            Matrix{Float64}(A)
        else  # :phylo
            tree === nothing && error("phylo(1 | $grp) needs `tree = …`")
            _phylo_correlation(tree)
        end
        size(Kmat) == (G, G) || error("structured matrix must be $(G)×$(G) (the number of `$grp` levels)")
        return _withformula(_fit_structured_gaussian(fam, y, Xμ, Xσ, gidx, G, Kmat, nmμ, nmσ, grp, g_tol), f)
    end
    if metav !== nothing
        vv = Float64.(getproperty(data, metav))    # known sampling variances
        return _withformula(_fit_meta_gaussian(fam, y, Xμ, Xσ, vv, nmμ, nmσ, g_tol), f)
    end
    isempty(re) && return _withformula(_fit_fixed_gaussian(fam, y, Xμ, Xσ, nmμ, nmσ, g_tol), f)
    re_kinds = [_re_kind(rl) for (rl, _) in re]
    if length(re) == 1 && re_kinds[1][1] === :corr           # (1 + x | g)
        (_, grp) = re[1]; (_, var) = re_kinds[1]
        gidx, G = _group_index(getproperty(data, grp))
        xs = Float64.(getproperty(data, var))
        return _withformula(_fit_correlated_ranef_gaussian(fam, y, Xμ, Xσ, gidx, G, xs, nmμ, nmσ, grp, g_tol), f)
    end
    any(k -> k[1] === :corr, re_kinds) &&
        error("a correlated `(1 + x | g)` block must be the only random-effect term")
    if length(re) == 1                                        # single scalar component
        (_, grp) = re[1]; (kind, var) = re_kinds[1]
        gidx, G = _group_index(getproperty(data, grp))
        w = kind === :intercept ? ones(length(y)) : Float64.(getproperty(data, var))
        return _withformula(_fit_ranef_gaussian(fam, y, Xμ, Xσ, gidx, G, w, nmμ, nmσ, grp, g_tol), f)
    end
    comps = map(zip(re, re_kinds)) do ((_, grp), (kind, var))  # multiple scalar components
        w = kind === :intercept ? ones(length(y)) : Float64.(getproperty(data, var))
        gidx, Gk = _group_index(getproperty(data, grp))
        (w, gidx, Gk, String(grp))
    end
    return _withformula(_fit_multi_ranef_gaussian(fam, y, Xμ, Xσ, comps, nmμ, nmσ, g_tol), f)
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
    means = Dict(:mu => Xμ * θ̂[1:pμ])
    obs = Dict(:mu => Vector{Float64}(y))
    scales = Dict(:sigma => exp.(Xσ * θ̂[(pμ+1):(pμ+pσ)]))
    return _withnll(DrmFit(fam, blocks, names, θ̂, V, -nll(θ̂), n, Optim.converged(res), means, obs, scales), nll)
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
    fitted(fit)

Fitted mean(s). Univariate / random-effect models return the μ vector (the
population/marginal mean `Xβ̂`); bivariate models return `Dict(:mu1=>…, :mu2=>…)`.
"""
fitted(fit::DrmFit) = haskey(fit.means, :mu) ? fit.means[:mu] : fit.means

"""
    residuals(fit)

Response residuals (observed − fitted mean), matching [`fitted`](@ref)'s shape.
"""
function residuals(fit::DrmFit)
    haskey(fit.means, :mu) && return fit.obs[:mu] .- fit.means[:mu]
    return Dict(k => fit.obs[k] .- fit.means[k] for k in keys(fit.means))
end

"""
    predict(fit, newdata) -> Vector or Dict

Population-level mean prediction on `newdata` (a NamedTuple / column table):
`Xβ̂` with random / structured effects integrated out. Univariate models return
a vector; bivariate models return `Dict(:mu1 => …, :mu2 => …)`. Predictors must
be present in `newdata` (continuous; categorical levels must match training).
"""
function predict(fit::DrmFit, newdata)
    f = fit.formula
    f === nothing && error("predict: this fit did not retain its formula")
    nd = NamedTuple(pairs(newdata))
    nrows = length(first(values(nd)))
    if f isa DrmFormula
        fixed_mu, _, _, _ = _split_ranef(Dict(f.forms)[:mu])
        ndr = merge(nd, NamedTuple{(f.response,)}((zeros(nrows),)))
        _, Xnew, _ = _design(f.response, fixed_mu, ndr)
        return Xnew * coef(fit, :mu)
    else  # BivariateDrmFormula
        fm = Dict(f.forms)
        fixed1, _, _, _ = _split_ranef(fm[:mu1])
        fixed2, _, _, _ = _split_ranef(fm[:mu2])
        nd1 = merge(nd, NamedTuple{(f.response1,)}((zeros(nrows),)))
        nd2 = merge(nd, NamedTuple{(f.response2,)}((zeros(nrows),)))
        _, X1, _ = _design(f.response1, fixed1, nd1)
        _, X2, _ = _design(f.response2, fixed2, nd2)
        return Dict(:mu1 => X1 * coef(fit, :mu1), :mu2 => X2 * coef(fit, :mu2))
    end
end

"""
    simulate(fit; rng = default_rng())

Draw one parametric (residual-level) replicate from the fitted model — the
building block of a parametric bootstrap. Univariate / random-effect / meta
models return a response vector; bivariate models return `Dict(:mu1=>…, :mu2=>…)`.
For random-effect models the draw is conditional on the random effects being
zero (population level).
"""
function simulate(fit::DrmFit; rng = default_rng())
    n = fit.nobs
    if haskey(fit.scales, :sigma)                       # univariate / RE / meta
        return fit.means[:mu] .+ fit.scales[:sigma] .* randn(rng, n)
    elseif haskey(fit.scales, :sigma1)                  # bivariate
        μ1, μ2 = fit.means[:mu1], fit.means[:mu2]
        σ1, σ2, ρ = fit.scales[:sigma1], fit.scales[:sigma2], fit.scales[:rho12]
        z1 = randn(rng, n); z2 = randn(rng, n)
        return Dict(:mu1 => μ1 .+ σ1 .* z1,
                    :mu2 => μ2 .+ σ2 .* (ρ .* z1 .+ sqrt.(1 .- ρ .^ 2) .* z2))
    end
    # Non-Gaussian families: draw from the fitted distribution. μ is on the
    # response scale (fit.means[:mu]); dispersion is read from the constant
    # `sigma` block (modelled dispersion `sigma ~ x` is not reconstructable here).
    μ = fit.means[:mu]; fam = fit.family
    if fam isa Poisson
        return Float64[rand(rng, Distributions.Poisson(max(m, 0.0))) for m in μ]
    elseif fam isa NegBinomial2
        θ = exp(_sigma_scalar(fit))
        return Float64[rand(rng, Distributions.NegativeBinomial(θ, θ / (θ + m))) for m in μ]
    elseif fam isa Beta
        φ = exp(-2 * _sigma_scalar(fit))
        return Float64[rand(rng, Distributions.Beta(m * φ, (1 - m) * φ)) for m in μ]
    elseif fam isa Gamma
        a = exp(-2 * _sigma_scalar(fit))
        return Float64[rand(rng, Distributions.Gamma(a, m / a)) for m in μ]
    end
    error("simulate: not yet supported for $(typeof(fam)) — implemented for " *
          "Gaussian, Poisson, NegBinomial2, Beta, Gamma (constant dispersion).")
end

# Constant-dispersion `sigma` coefficient (link scale). Errors on modelled
# dispersion `sigma ~ x`, which simulate cannot reconstruct from the stored fit.
function _sigma_scalar(fit::DrmFit)
    for (p, r) in fit.blocks
        p === :sigma || continue
        length(r) == 1 || error("simulate: modelled dispersion (sigma ~ x) not yet supported")
        return fit.theta[r[1]]
    end
    error("simulate: this fit has no sigma block")
end

"""
    loglik(fit) -> Float64

Maximised log-likelihood of the fitted model.
"""
loglik(fit::DrmFit) = fit.loglik

"""
    dof(fit) -> Int

Degrees of freedom — the number of estimated parameters (length of θ).
"""
dof(fit::DrmFit) = length(fit.theta)

"""
    aic(fit) -> Float64

Akaike information criterion, `-2·loglik + 2·dof`. Lower is better; compares
models fit by **ML** (not REML) on the same data.
"""
aic(fit::DrmFit) = -2 * fit.loglik + 2 * length(fit.theta)

"""
    bic(fit) -> Float64

Bayesian (Schwarz) information criterion, `-2·loglik + dof·log(nobs)`.
"""
bic(fit::DrmFit) = -2 * fit.loglik + length(fit.theta) * log(fit.nobs)

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
