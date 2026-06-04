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
import StatsAPI: coef, vcov, nobs, fitted, residuals, predict, aic, bic, dof, deviance, dof_residual, StatisticalModel

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

# Distributional parameters the univariate front end accepts as a *secondary*
# formula LHS. The mean μ comes from the response formula, so it is not listed
# here; the two-response parameters live in the keyword form. Whether a given
# family actually uses a parameter (e.g. Gaussian has no `nu`) is a separate,
# family-level question handled in `drm`.
const _UNIVARIATE_DPARS = (:sigma, :nu, :zi, :hu, :zoi, :coi)

# Parameters valid only through the bivariate keyword form
# `bf(mu1 = …, mu2 = …, sigma1 = …, sigma2 = …, rho12 = …)`.
const _BIVARIATE_DPARS = (:mu1, :mu2, :sigma1, :sigma2, :rho12)

# Validate one secondary formula's parameter name, mirroring the reserved syntax
# drmTMB rejects (with parallel intent). `seen` accumulates accepted names so a
# parameter given twice is caught as a duplicate.
function _check_dpar_name!(seen::Set{Symbol}, name::Symbol)
    if name === :mu
        throw(ArgumentError("bf: the mean μ is set by the response formula (the first " *
            "argument) — pass the μ predictor there, not a separate `mu ~ …`."))
    elseif name === :tau
        throw(ArgumentError("bf: the scale parameter is named `sigma`, never `tau` — " *
            "write `sigma ~ …`."))
    elseif name in _BIVARIATE_DPARS
        throw(ArgumentError("bf: `$name` is a bivariate (two-response) parameter; use the " *
            "keyword form `bf(mu1 = …, mu2 = …, sigma1 = …, sigma2 = …, rho12 = …)`."))
    elseif !(name in _UNIVARIATE_DPARS)
        throw(ArgumentError("bf: unknown distributional parameter `$name`. Valid secondary " *
            "parameters are " * join(_UNIVARIATE_DPARS, ", ") * "."))
    elseif name in seen
        throw(ArgumentError("bf: duplicate formula for `$name` — give one formula per " *
            "distributional parameter."))
    end
    push!(seen, name)
    return name
end

"""
    bf(response_formula, dpar_formulas...)
    drm_formula(response_formula, dpar_formulas...)

Bundle one formula per distributional parameter, exactly as drmTMB. The first
formula `y ~ …` sets the response and the `μ` predictor; each later formula
`param ~ …` (e.g. `sigma ~ …`) sets that parameter's predictor. `sigma` defaults
to `~ 1` when omitted.

The secondary parameter on each formula's left-hand side must be one of
`$(join(_UNIVARIATE_DPARS, ", "))`. Mirroring drmTMB, `bf` rejects reserved /
mis-typed syntax with a clear error: `tau` (the scale is `sigma`), `mu` as a
separate formula (μ comes from the response), the two-response parameters
`mu1/mu2/sigma1/sigma2/rho12` in this positional form (use the keyword form),
unknown parameter names, and a parameter given more than once.
"""
function bf(mu::FormulaTerm, dpars::FormulaTerm...)
    lhs = mu.lhs
    if lhs isa FunctionTerm && lhs.f === cbind        # cbind(successes, failures) ~ …
        response = lhs.args[1].sym; response2 = lhs.args[2].sym
    else
        response = lhs.sym; response2 = nothing
    end
    forms = Pair{Symbol,Any}[:mu => mu.rhs]
    seen = Set{Symbol}()
    for f in dpars
        f.lhs isa Term || throw(ArgumentError("bf: each distributional-parameter formula " *
            "must read `param ~ …` with a parameter name on the left (got `$(f.lhs)`)."))
        name = _check_dpar_name!(seen, f.lhs.sym)
        push!(forms, name => f.rhs)
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
    nllgrad::Any                           # optional gradient callback (g, θ) -> g
    ranef::Any                             # per-group conditional RE estimates (BLUPs); nothing if no RE
end

# 11-arg outer constructor: formula + nll + nllgrad + ranef default to nothing
# (the fitters use this; drm() attaches the formula via _withformula, the
# objective via _withnll, and the BLUPs via _withranef).
DrmFit(family, blocks, coefnames, theta, vcov, loglik, nobs, converged, means, obs, scales) =
    DrmFit(family, blocks, coefnames, theta, vcov, loglik, nobs, converged, means, obs, scales, nothing, nothing, nothing, nothing)

_withformula(fit::DrmFit, f) = DrmFit(fit.family, fit.blocks, fit.coefnames, fit.theta,
    fit.vcov, fit.loglik, fit.nobs, fit.converged, fit.means, fit.obs, fit.scales, f, fit.nll, fit.nllgrad, fit.ranef)

# Attach the (negative) log-likelihood closure so profile intervals can re-optimise
# the nuisance parameters at each fixed value. nll(θ) must accept the full θ vector.
_withnll(fit::DrmFit, nll, nllgrad = nothing) = DrmFit(fit.family, fit.blocks, fit.coefnames, fit.theta,
    fit.vcov, fit.loglik, fit.nobs, fit.converged, fit.means, fit.obs, fit.scales, fit.formula, nll, nllgrad, fit.ranef)

# Attach per-group conditional random-effect estimates (BLUPs). `re` is a
# Dict{Symbol,...} keyed by grouping factor; see ranef(fit) for the public accessor.
_withranef(fit::DrmFit, re) = DrmFit(fit.family, fit.blocks, fit.coefnames, fit.theta,
    fit.vcov, fit.loglik, fit.nobs, fit.converged, fit.means, fit.obs, fit.scales, fit.formula, fit.nll, fit.nllgrad, re)

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
"""
    coef(fit::DrmFit)

Estimated coefficients, all parameter blocks concatenated (`coef(fit, :mu)` returns
one block). Extends `StatsAPI.coef`.
"""
coef(fit::DrmFit) = fit.theta
function coef(fit::DrmFit, param::Symbol)
    for (p, r) in fit.blocks
        p === param && return fit.theta[r]
    end
    throw(ArgumentError("no parameter $param in fit (have $(first.(fit.blocks)))"))
end
"""
    vcov(fit::DrmFit)

Variance–covariance matrix of the estimated coefficients. Extends `StatsAPI.vcov`.
"""
vcov(fit::DrmFit) = fit.vcov
"""
    nobs(fit::DrmFit)

Number of observations. Extends `StatsAPI.nobs`.
"""
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
    sigma(fit)

Fitted scale / dispersion. Returns the per-observation fitted scale(s) computed
at the MLE — drmTMB's `sigma()`.

- Univariate location–scale with a single scale (`:sigma`): the `σ_i` vector
  (`exp.(Xσ·β̂_σ)` on the response scale; for meta-analysis `√(vᵢ + τ²)`).
- Bivariate co-scale: `Dict(:sigma1 => …, :sigma2 => …)`.
- Families with no separately fitted scale stored (e.g. Poisson, whose variance
  is fixed by the mean): returns an empty `Dict` — there is no free dispersion.

For the population-level scale *coefficients* (on the working/log scale) use
`coef(fit, :sigma)` instead.
"""
function sigma(fit::DrmFit)
    ks = sort!(collect(keys(fit.scales)))
    isempty(ks) && return Dict{Symbol,Vector{Float64}}()
    (length(ks) == 1 && ks[1] === :sigma) && return fit.scales[:sigma]
    return fit.scales
end

"""
    corpairs(fit)

Fitted between-response residual correlation(s) — drmTMB's `corpairs()`. For a
bivariate co-scale model this is the per-observation `ρ12 = tanh(Xρ·β̂_ρ)`
(constant when `rho12 ~ 1`, varying when `rho12 ~ x`). Univariate models have no
between-response correlation and return an empty `Dict`.

For random-effect (within-group) correlations, see [`vc`](@ref).
"""
function corpairs(fit::DrmFit)
    haskey(fit.scales, :rho12) && return fit.scales[:rho12]
    return Dict{Symbol,Vector{Float64}}()
end

"""
    predict(fit, newdata; type = :response) -> Vector or Dict

Population-level prediction on `newdata` (a NamedTuple / column table), random /
structured effects integrated out. `type = :response` (default) returns the
response-scale mean — the family inverse link applied to `Xβ̂` (`exp` for
Poisson/Gamma, `logistic` for Beta/Binomial, identity for Gaussian); `type = :link`
returns `Xβ̂`. In-sample, `predict(fit, data) ≈ fitted(fit)`. Univariate returns a
vector; bivariate returns `Dict(:mu1 => …, :mu2 => …)`.
"""
function predict(fit::DrmFit, newdata; type::Symbol = :response)
    f = fit.formula
    f === nothing && error("predict: this fit did not retain its formula")
    nd = NamedTuple(pairs(newdata))
    nrows = length(first(values(nd)))
    if f isa DrmFormula
        fixed_mu, _, _, _ = _split_ranef(Dict(f.forms)[:mu])
        ndr = merge(nd, NamedTuple{(f.response,)}((zeros(nrows),)))
        _, Xnew, _ = _design(f.response, fixed_mu, ndr)
        type in (:response, :link) || error("predict: `type` must be :response or :link")
        η = Xnew * coef(fit, :mu)
        return type === :link ? η : _mean_response(fit.family, η)
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

# Inverse mean-link per family: maps the linear predictor Xβ to the response
# scale (matching `fitted`). Identity for Gaussian/Student; exp for log-link
# families; logistic for logit-link families; linear predictor otherwise.
function _mean_response(fam, η)
    if fam isa Poisson || fam isa NegBinomial2 || fam isa TruncatedNegBinomial2 ||
       fam isa Gamma || fam isa LogNormal || fam isa Tweedie
        return exp.(clamp.(η, -30.0, 30.0))
    elseif fam isa Beta || fam isa Binomial || fam isa BetaBinomial
        return _logistic.(clamp.(η, -30.0, 30.0))
    else
        return η
    end
end

# Inverse link for one distributional parameter, mapping its linear predictor
# Xβ to the response scale exactly as the fitters store it in `fit.scales` /
# `fit.means`. The mapping lives here so `predict_parameters(:response)`
# reproduces the in-sample fitted parameters. Sources reused:
#   :mu    → `_mean_response(fam, η)` (identity/exp/logistic; gaussian_core.jl)
#   :sigma → exp.(η)                  (e.g. gaussian_core.jl `_fit_fixed_gaussian`)
#   :nu    → exp.(η) for Student (student.jl), `_logit12.(η)` for Tweedie (tweedie.jl)
#   :zi    → `_logistic.(η)`          (poisson.jl / negbinomial.jl)
#   :hu    → `_logistic.(η)`          (poisson.jl / negbinomial.jl)
#   :zoi   → `_logistic.(η)`          (zeroonebeta.jl)
#   :coi   → `_logistic.(η)`          (zeroonebeta.jl)
# Bivariate Gaussian (gaussian_bivariate.jl `drm(::BivariateDrmFormula, …)`):
#   :mu1, :mu2     → `_mean_response(fam, η)` (identity for Gaussian)
#   :sigma1, :sigma2 → exp.(η)
#   :rho12         → tanh.(η)         (plain tanh / atanh link; no clamp/scale)
function _param_response(fam, p::Symbol, η)
    if p === :mu || p === :mu1 || p === :mu2
        return _mean_response(fam, η)
    elseif p === :sigma || p === :sigma1 || p === :sigma2
        return exp.(η)
    elseif p === :rho12
        return tanh.(η)
    elseif p === :nu
        return fam isa Tweedie ? _logit12.(η) : exp.(η)
    elseif p === :zi || p === :hu || p === :zoi || p === :coi
        return _logistic.(η)
    else
        throw(ArgumentError("predict_parameters: no inverse link known for parameter `$p`"))
    end
end

"""
    predict_parameters(fit, newdata; type = :response) -> Dict{Symbol,Vector{Float64}}

Population-level prediction of **every** distributional parameter at `newdata`
(a NamedTuple / column table), random / structured effects integrated out
(exactly like [`predict`](@ref)). The returned `Dict` has one entry per
distributional parameter the model carries — always `:mu` and (when the family
uses it) `:sigma`, plus any family extras present (`:nu`, `:zi`, `:hu`, `:zoi`,
`:coi`).

`type = :response` (default) applies each parameter's inverse link, so in-sample
it reproduces [`marginal_parameters`](@ref) (i.e. `fit.means[:mu]`,
`fit.scales[...]`). `type = :link` returns the linear predictor `Xβ̂` per
parameter (the working scale).

For a univariate fit the parameters are `:mu`, (`:sigma`) plus family extras; for
a bivariate fit they are `:mu1, :mu2, :sigma1, :sigma2, :rho12` (each from its own
fixed-effects RHS, with the σ links `exp` and the ρ12 link `tanh`).

# Example
```julia
x = randn(200)
y = 0.5 .- 0.8 .* x .+ exp.(-0.3 .+ 0.4 .* x) .* randn(200)
data = (; y, x)
fit = drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1 + x)), Gaussian(); data)

p = predict_parameters(fit, data)              # Dict(:mu => …, :sigma => …)
p[:mu]    ≈ fit.means[:mu]                      # in-sample reproduction
p[:sigma] ≈ fit.scales[:sigma]

predict_parameters(fit, data; type = :link)[:mu]   # == Xβ̂ (predict link scale)
```
"""
function predict_parameters(fit::DrmFit, newdata; type::Symbol = :response)
    f = fit.formula
    f === nothing && error("predict_parameters: this fit did not retain its formula")
    type in (:response, :link) || error("predict_parameters: `type` must be :response or :link")
    forms = Dict(f.forms)
    nd = NamedTuple(pairs(newdata))
    nrows = length(first(values(nd)))
    # A real LHS to dummy into `_design` for each parameter's RHS. The univariate
    # form has one response; the bivariate form has two (use response1 for the
    # σ/ρ placeholder RHS, exactly as the bivariate fitter does). The per-parameter
    # response symbol is chosen inline in the loop below (a conditional inner
    # function is not reliably bound in local scope).
    bivar = !(f isa DrmFormula)
    ndr = bivar ?
        merge(nd, NamedTuple{(f.response1, f.response2)}((zeros(nrows), zeros(nrows)))) :
        merge(nd, NamedTuple{(f.response,)}((zeros(nrows),)))
    out = Dict{Symbol,Vector{Float64}}()
    for (p, _) in fit.blocks
        haskey(forms, p) || continue          # skip RE-SD / cutpoint blocks (:resd, :recov, :cutpoints, …)
        resp = bivar ? (p === :mu2 ? f.response2 : f.response1) : f.response
        fixed_p, _, _, _ = _split_ranef(forms[p])
        _, Xp, _ = _design(resp, fixed_p, ndr)
        ηp = Xp * coef(fit, p)
        out[p] = type === :link ? ηp : _param_response(fit.family, p, ηp)
    end
    return out
end

"""
    marginal_parameters(fit) -> Dict{Symbol,Vector{Float64}}

In-sample fitted per-observation distributional parameters, read straight from
the stored fit — a cheap accessor with no recomputation. Returns the mean(s) from
`fit.means` (`:mu`, or `:mu1`/`:mu2` for a bivariate fit) and every per-observation
scale / correlation parameter from `fit.scales` (e.g. `:sigma`, `:nu`, `:zi`,
`:hu`, `:zoi`, `:coi`; `:sigma1`/`:sigma2`/`:rho12` for a bivariate fit).

In-sample these equal `predict_parameters(fit, data)` (response scale).

# Example
```julia
fit = drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1 + x)), Gaussian(); data)
m = marginal_parameters(fit)
m[:mu]    == fit.means[:mu]
m[:sigma] == fit.scales[:sigma]
```
"""
function marginal_parameters(fit::DrmFit)
    out = Dict{Symbol,Vector{Float64}}()
    for (p, _) in fit.blocks
        if haskey(fit.means, p)        # mean parameter(s): :mu (univariate) / :mu1,:mu2 (bivariate)
            out[p] = fit.means[p]
        elseif haskey(fit.scales, p)   # scale / correlation parameters: :sigma(1/2), :rho12, family extras
            out[p] = fit.scales[p]
        end
    end
    return out
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
    fam = fit.family
    if fam isa Gaussian && haskey(fit.scales, :sigma1)   # bivariate Gaussian
        μ1, μ2 = fit.means[:mu1], fit.means[:mu2]
        σ1, σ2, ρ = fit.scales[:sigma1], fit.scales[:sigma2], fit.scales[:rho12]
        z1 = randn(rng, n); z2 = randn(rng, n)
        return Dict(:mu1 => μ1 .+ σ1 .* z1,
                    :mu2 => μ2 .+ σ2 .* (ρ .* z1 .+ sqrt.(1 .- ρ .^ 2) .* z2))
    elseif fam isa Gaussian && haskey(fit.scales, :sigma) # univariate / RE / meta
        return fit.means[:mu] .+ fit.scales[:sigma] .* randn(rng, n)
    end
    # Non-Gaussian families: draw from the fitted distribution. μ is on the
    # response scale (fit.means[:mu]); per-row auxiliary parameters are stored in
    # `fit.scales` by the family fitters.
    μ = fit.means[:mu]
    if fam isa Poisson
        if haskey(fit.scales, :zi)
            zi = fit.scales[:zi]
            return Float64[rand(rng) < zi[i] ? 0 : rand(rng, Distributions.Poisson(max(μ[i], 0.0))) for i in 1:n]
        elseif haskey(fit.scales, :hu)
            hu = fit.scales[:hu]
            return Float64[rand(rng) < hu[i] ? 0 : _rand_positive_poisson(rng, max(μ[i], eps())) for i in 1:n]
        end
        return Float64[rand(rng, Distributions.Poisson(max(m, 0.0))) for m in μ]
    elseif fam isa NegBinomial2
        θ = _scale_vector(fit, :sigma)
        if haskey(fit.scales, :zi)
            zi = fit.scales[:zi]
            return Float64[rand(rng) < zi[i] ? 0 : rand(rng, Distributions.NegativeBinomial(θ[i], θ[i] / (θ[i] + μ[i]))) for i in 1:n]
        elseif haskey(fit.scales, :hu)
            hu = fit.scales[:hu]
            return Float64[rand(rng) < hu[i] ? 0 : _rand_positive_negbin(rng, θ[i], θ[i] / (θ[i] + μ[i])) for i in 1:n]
        end
        return Float64[rand(rng, Distributions.NegativeBinomial(θ[i], θ[i] / (θ[i] + μ[i]))) for i in 1:n]
    elseif fam isa TruncatedNegBinomial2
        θ = _scale_vector(fit, :sigma)
        return Float64[_rand_positive_negbin(rng, θ[i], θ[i] / (θ[i] + μ[i])) for i in 1:n]
    elseif fam isa Beta
        σ = _scale_vector(fit, :sigma); φ = @. 1 / (σ * σ)
        return Float64[rand(rng, Distributions.Beta(clamp(μ[i], eps(), 1 - eps()) * φ[i], (1 - clamp(μ[i], eps(), 1 - eps())) * φ[i])) for i in 1:n]
    elseif fam isa BetaBinomial
        σ = _scale_vector(fit, :sigma); φ = @. 1 / (σ * σ)
        ntr = round.(Int, _scale_vector(fit, :trials))
        return Float64[rand(rng, Distributions.BetaBinomial(ntr[i], clamp(μ[i], eps(), 1 - eps()) * φ[i], (1 - clamp(μ[i], eps(), 1 - eps())) * φ[i])) for i in 1:n]
    elseif fam isa Binomial
        ntr = round.(Int, _scale_vector(fit, :trials))
        return Float64[rand(rng, Distributions.Binomial(ntr[i], clamp(μ[i], eps(), 1 - eps()))) for i in 1:n]
    elseif fam isa Gamma
        σ = _scale_vector(fit, :sigma); a = @. 1 / (σ * σ)
        return Float64[rand(rng, Distributions.Gamma(a[i], μ[i] / a[i])) for i in 1:n]
    elseif fam isa LogNormal
        σ = _scale_vector(fit, :sigma)
        return Float64[exp(log(max(μ[i], eps())) + σ[i] * randn(rng)) for i in 1:n]
    elseif fam isa Student
        σ = _scale_vector(fit, :sigma)
        ν = _scale_vector(fit, :nu)
        return Float64[μ[i] + σ[i] * rand(rng, Distributions.TDist(ν[i])) for i in 1:n]
    elseif fam isa ZeroOneBeta
        μb = _scale_vector(fit, :beta_mu)
        σ = _scale_vector(fit, :sigma); φ = @. 1 / (σ * σ)
        zoi = _scale_vector(fit, :zoi); coi = _scale_vector(fit, :coi)
        return Float64[_rand_zeroonebeta(rng, μb[i], φ[i], zoi[i], coi[i]) for i in 1:n]
    elseif fam isa Tweedie
        σ = _scale_vector(fit, :sigma)
        p = _scale_vector(fit, :nu)
        return Float64[_rand_tweedie(rng, μ[i], σ[i]^2, p[i]) for i in 1:n]
    elseif fam isa CumulativeLogit
        η = _scale_vector(fit, :ordinal_eta)
        cuts = _scale_vector(fit, :ordinal_cuts)
        return Float64[_rand_cumulative_logit(rng, η[i], cuts) for i in 1:n]
    end
    error("simulate: not yet supported for $(typeof(fam)).")
end

function _scale_vector(fit::DrmFit, key::Symbol)
    haskey(fit.scales, key) || error("simulate: fitted $(typeof(fit.family)) object does not carry `$key`; refit with current DRM.jl")
    return fit.scales[key]
end

function _rand_positive_poisson(rng, λ)
    for _ in 1:10_000
        y = rand(rng, Distributions.Poisson(λ))
        y > 0 && return y
    end
    return 1
end

function _rand_positive_negbin(rng, r, p)
    for _ in 1:10_000
        y = rand(rng, Distributions.NegativeBinomial(r, p))
        y > 0 && return y
    end
    return 1
end

function _rand_zeroonebeta(rng, μ, φ, zoi, coi)
    u = rand(rng)
    if u < zoi
        return rand(rng) < coi ? 1.0 : 0.0
    end
    m = clamp(μ, eps(), 1 - eps())
    return rand(rng, Distributions.Beta(m * φ, (1 - m) * φ))
end

function _rand_tweedie(rng, μ, φ, p)
    λ = μ^(2 - p) / (φ * (2 - p))
    γ = φ * (p - 1) * μ^(p - 1)
    sh = (2 - p) / (p - 1)
    N = rand(rng, Distributions.Poisson(λ))
    return N == 0 ? 0.0 : rand(rng, Distributions.Gamma(N * sh, γ))
end

function _rand_cumulative_logit(rng, η, cuts)
    K = length(cuts) + 1
    u = rand(rng)
    acc = 0.0
    for k in 1:K
        pk = k == 1 ? _logistic(cuts[1] - η) :
             k == K ? 1 - _logistic(cuts[end] - η) :
             _logistic(cuts[k] - η) - _logistic(cuts[k-1] - η)
        acc += max(pk, 0.0)
        u <= acc && return k
    end
    return K
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
