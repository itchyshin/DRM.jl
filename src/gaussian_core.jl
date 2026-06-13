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
using Statistics: std, mean
using Random: default_rng
import StatsAPI: coef, vcov, nobs, fitted, residuals, predict, aic, bic, dof, deviance, dof_residual, StatisticalModel
import Tables

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
    estim_method::Symbol                   # :ML (default) or :REML — the estimator used
    reml_loglik::Float64                   # REML log-likelihood (NaN unless estim_method == :REML)
    ml_loglik::Float64                     # ML log-likelihood (always set; for cross-structure comparison)
end

# 11-arg outer constructor: formula + nll + nllgrad + ranef default to nothing;
# estim_method defaults to :ML and reml/ml loglik to NaN / the supplied loglik
# (the fitters use this; drm() attaches the formula via _withformula, the
# objective via _withnll, the BLUPs via _withranef, and REML metadata via _withreml).
DrmFit(family, blocks, coefnames, theta, vcov, loglik, nobs, converged, means, obs, scales) =
    DrmFit(family, blocks, coefnames, theta, vcov, loglik, nobs, converged, means, obs, scales,
           nothing, nothing, nothing, nothing, :ML, NaN, loglik)

_withformula(fit::DrmFit, f) = DrmFit(fit.family, fit.blocks, fit.coefnames, fit.theta,
    fit.vcov, fit.loglik, fit.nobs, fit.converged, fit.means, fit.obs, fit.scales, f, fit.nll, fit.nllgrad, fit.ranef,
    fit.estim_method, fit.reml_loglik, fit.ml_loglik)

# Attach the (negative) log-likelihood closure so profile intervals can re-optimise
# the nuisance parameters at each fixed value. nll(θ) must accept the full θ vector.
_withnll(fit::DrmFit, nll, nllgrad = nothing) = DrmFit(fit.family, fit.blocks, fit.coefnames, fit.theta,
    fit.vcov, fit.loglik, fit.nobs, fit.converged, fit.means, fit.obs, fit.scales, fit.formula, nll, nllgrad, fit.ranef,
    fit.estim_method, fit.reml_loglik, fit.ml_loglik)

# Attach per-group conditional random-effect estimates (BLUPs). `re` is a
# Dict{Symbol,...} keyed by grouping factor; see ranef(fit) for the public accessor.
_withranef(fit::DrmFit, re) = DrmFit(fit.family, fit.blocks, fit.coefnames, fit.theta,
    fit.vcov, fit.loglik, fit.nobs, fit.converged, fit.means, fit.obs, fit.scales, fit.formula, fit.nll, fit.nllgrad, re,
    fit.estim_method, fit.reml_loglik, fit.ml_loglik)

# Mark the fit as REML-estimated, recording both the REML and ML log-likelihoods.
# The public `loglik` slot is set to the REML value (with the documented
# cross-structure caveat); `ml_loglik` stays available for ML-style comparison.
_withreml(fit::DrmFit, reml_ll::Real, ml_ll::Real) = DrmFit(fit.family, fit.blocks, fit.coefnames, fit.theta,
    fit.vcov, Float64(reml_ll), fit.nobs, fit.converged, fit.means, fit.obs, fit.scales, fit.formula, fit.nll, fit.nllgrad, fit.ranef,
    :REML, Float64(reml_ll), Float64(ml_ll))

# Response-missing helpers. R's `NA_real_` may reach Julia as either `missing`
# or `NaN`, so the Gaussian response path treats both as absent observations.
function _is_response_missing(x)
    x === missing && return true
    x isa AbstractFloat && isnan(x) && return true
    return false
end

function _coerce_response_column(raw)
    y = Vector{Float64}(undef, length(raw))
    observed = Vector{Bool}(undef, length(raw))
    @inbounds for i in eachindex(raw)
        xi = raw[i]
        if _is_response_missing(xi)
            y[i] = NaN
            observed[i] = false
        else
            y[i] = Float64(xi)
            observed[i] = true
        end
    end
    return y, observed
end

_observed_response_mask(y) = .!isnan.(Vector{Float64}(y))

function _table_column(data, name::Symbol)
    if data isa NamedTuple
        return getproperty(data, name)
    elseif data isa AbstractDict
        haskey(data, name) && return data[name]
        s = String(name)
        haskey(data, s) && return data[s]
    end
    return getproperty(data, name)
end

function _replace_table_column(data, name::Symbol, replacement)
    cols = Tables.columntable(data)
    names = Tuple(Symbol(k) for k in keys(cols))
    vals = map(names) do k
        k === name ? replacement : getproperty(cols, k)
    end
    return NamedTuple{names}(Tuple(vals))
end

# Build a design matrix for one parameter's RHS. We reuse the response as a
# dummy LHS so the formula is valid for `schema`/`modelcols`, then keep only the
# predictor matrix. If the real response contains `missing` / `NaN`, the formula
# builder gets a numeric placeholder column while the returned `y` keeps `NaN`
# at unobserved response positions.
function _design(response::Symbol, rhs, data)
    raw_response = _table_column(data, response)
    y_response, observed = _coerce_response_column(raw_response)
    design_data = all(observed) ? data :
        _replace_table_column(data, response, ifelse.(observed, y_response, 0.0))
    ft = FormulaTerm(Term(response), rhs)
    # The 3-arg apply_schema with a StatisticalModel context adds R's implicit
    # intercept (so `y ~ x` means `y ~ 1 + x`, matching drmTMB); explicit
    # `1 + x` / `0 + x` are respected.
    ft = apply_schema(ft, schema(ft, design_data), StatisticalModel)
    _, X = modelcols(ft, design_data)
    Xm = X isa AbstractMatrix ? Matrix{Float64}(X) : reshape(Float64.(collect(X)), :, 1)
    return y_response, Xm, String.(vec(coefnames(ft.rhs)))
end

"""
    drm(formula::DrmFormula, family; data) -> DrmFit

Fit a distributional regression model by maximum likelihood. A formula bundle
has one linear predictor per distributional parameter:

```julia
fit = drm(bf(y ~ x1, sigma ~ x1), Gaussian(); data = dat)
```

Univariate Gaussian fits support fixed effects plus the structured-effect
markers documented under [`phylo`](@ref), [`spatial`](@ref), [`animal`](@ref),
[`relmat`](@ref), and [`meta_V`](@ref).

## `algorithm` — solver selection

`algorithm` (default `:auto`) chooses how the model is fit:

- `:auto` (default) — uses the all-node sparse L-BFGS route for the
  Gaussian phylogenetic-mean cell: a single `phylo(1 | g)` structured mean
  random effect (with `tree = …`) and a **constant** residual scale
  (`sigma ~ 1`, no random effect on `sigma`). Other Gaussian cells keep their
  cell-specific default fitters.
- `:gls`, `:lbfgs` — legacy dense leaf-covariance fitters for the Gaussian
  phylogenetic-mean cell and aliases for the usual default fitters elsewhere.
- `:em` — force the all-node sparse conjugate-EM route for the Gaussian
  phylogenetic-mean cell. It reaches the same MLE as the dense GLS fit (same β,
  residual σ, and marginal logLik) via closed-form E/M steps with exact O(p)
  Takahashi traces. Any other model cell raises a clear `ArgumentError`.
  The EM path has **no coefficient vcov** (the M-steps are closed-form), so
  `vcov(fit)` is filled with `NaN`s. Refit with `:gls` for dense-fit Wald
  inference. `re_sd(fit)` reports the EM's Brownian phylo SD `σ_phy` (a
  different scale from the GLS fit's correlation-matrix `σ_s`).
- `:sparse` — force the verified sparse structured-Gaussian route where one is
  implemented, including the two-structured `phylo + animal/relmat` sparse path.
- `:sparse_lbfgs` — force the default all-node sparse L-BFGS route for the same
  Gaussian phylogenetic-mean cell. It profiles the mean fixed effects by sparse
  GLS at each variance trial, optimises the residual and phylogenetic SDs on the
  log scale with exact Takahashi trace gradients, attaches a sparse
  full-objective closure and gradient for profile intervals, and stores the
  cheap fixed-effect covariance block. Variance-component uncertainty should
  use profile or bootstrap intervals in this first slice.

```julia
fit = drm(bf(y ~ x + phylo(1 | sp), sigma ~ 1), Gaussian();
          data = dat, tree = tree)
```

Bivariate Gaussian fits use [`BivariateDrmFormula`](@ref); with no structured
marker they fit the residual `rho12` model, and with shared `phylo(1 | group)`
markers on `mu1`, `mu2`, `sigma1`, and `sigma2` they route to the verified q=4
phylogenetic engine.
"""
function drm(f::DrmFormula, fam::Gaussian; data, K = nothing, A = nothing, tree = nothing, coords = nothing, g_tol::Real = 1e-8, algorithm::Symbol = :auto, method::Symbol = :ML, profile_ci::Bool = false)
    algorithm in (:auto, :gls, :lbfgs, :em, :sparse, :sparse_lbfgs) ||
        throw(ArgumentError("drm: `algorithm` must be one of :auto, :gls, :lbfgs, :em, :sparse, :sparse_lbfgs (got :$algorithm)"))
    method in (:ML, :REML) ||
        throw(ArgumentError("drm: `method` must be :ML (default) or :REML (got :$method)"))
    rhs = Dict(f.forms)
    fixed_mu, re, metav, structured = _split_ranef(rhs[:mu])   # (1|g), meta_V(v), relmat/animal/phylo/spatial(1|g)
    fixed_sigma, sigma_re, _, structured_sigma = _split_ranef(rhs[:sigma])  # (1|g)→GHQ; structured_sigma = phylo(1|g) on σ
    y, Xμ, nmμ = _design(f.response, fixed_mu, data)
    _, Xσ, nmσ = _design(f.response, fixed_sigma, data)
    response_observed = _observed_response_mask(y)
    has_missing_response = !all(response_observed)
    all_structured = _collect_structured(rhs[:mu])
    # σ-phylo location-scale (B0–B2): a structured phylo marker on `sigma` routes to
    # the Gaussian location-scale Laplace engine (separate / coupled / asymmetric
    # blocks + boundary-aware profile CIs). The 4th `_split_ranef` value used to be
    # dropped, silently fitting `sigma ~ phylo(1|g)` as `sigma ~ 1` — the silent-drop
    # bug Ayumi found (issue #2). Now it errors-or-fits the real σ-phylo structure.
    if structured_sigma !== nothing
        sigma_kind, sigma_grp = structured_sigma
        if sigma_kind !== :phylo
            throw(ArgumentError("drm (Gaussian): `$(sigma_kind)(1 | $(sigma_grp))` on `sigma` is " *
                "not yet supported in the univariate route — only `phylo(1 | g)` is wired for B1. " *
                "Use `relmat`/`animal`/`spatial` on the MEAN axis, or file an issue."))
        end
        tree === nothing && error("phylo(1 | $(sigma_grp)) on sigma needs `tree = …`")
        phy = tree isa AbstractString ? augmented_phy(tree) : tree
        labels_sigma = getproperty(data, sigma_grp)
        Q_sigma, gidx_sigma, G_sigma = _locscale_phylo_setup(phy, labels_sigma)

        # Missing-response handling for the σ-phylo route (Ayumi #2): drop missing/NaN-response
        # rows (observed-rows fit, like glmmTMB's na.action default) while KEEPING the full tree
        # (Q_sigma/G_sigma) so the σ-phylo latent structure is retained — a species whose every
        # row is missing simply stays in the prior with no likelihood term. This is the cell Ayumi
        # needs: σ-phylo (REML or ML) with missing responses. (Missing PREDICTORS remain a
        # listwise / future-FIML concern — `drm_listwise` drops them; modelling them is later.)
        if has_missing_response
            n_obs = count(response_observed)
            n_obs > size(Xμ, 2) ||
                error("drm (Gaussian σ-phylo): only $(n_obs) observed responses — too few to fit. " *
                      "Use `drm_listwise` or supply more complete responses.")
            @warn "drm: $(length(response_observed) - n_obs) of $(length(response_observed)) rows have a " *
                  "missing/NaN response and were dropped (σ-phylo observed-rows fit; the tree is kept in " *
                  "full). Use `drm_listwise` to preprocess explicitly to silence this."
            y          = y[response_observed]
            Xμ         = Xμ[response_observed, :]
            Xσ         = Xσ[response_observed, :]
            gidx_sigma = gidx_sigma[response_observed]
        end

        # method = :REML integrates β_μ out of the Laplace marginal (Patterson–Thompson
        # restricted likelihood). This branch returns BEFORE the generic :REML validator
        # below, so capture it here and thread it to the engine. (REML across the phylo
        # RE structure is not comparable across mean structures — the aic/bic/lrtest guard
        # keys off estim_method; ML stays the default.)
        reml = method === :REML

        # Both-phylo path: mean also carries phylo on the SAME grouping.
        if structured !== nothing
            mu_kind, mu_grp = structured
            mu_kind === :phylo ||
                error("drm (Gaussian): σ-phylo with a non-phylo structured mean RE is not yet supported")
            mu_grp === sigma_grp ||
                error("drm (Gaussian): σ-phylo and μ-phylo must share the same grouping factor " *
                      "(got :$(mu_grp) vs :$(sigma_grp)); cross-grouping σ-phylo is planned for a later slice")
            # `structured` only captures the FIRST structured mean marker; guard against a
            # SECOND being silently dropped (e.g. mu ~ phylo(1|g) + animal(1|g) with σ-phylo).
            length(all_structured) == 1 ||
                error("drm (Gaussian): the both-phylo σ-phylo route supports a single structured " *
                      "mean component, got $(length(all_structured)). A second structured mean RE " *
                      "alongside σ-phylo is not yet supported.")
            (isempty(re) && isempty(sigma_re) && metav === nothing) ||
                error("drm (Gaussian): the both-phylo location-scale route requires no additional " *
                      "random effects beyond the phylo structured intercept on each axis")
            fit = _fit_gaussian_locscale_phylo(fam, y, Xμ, Xσ, gidx_sigma, G_sigma, Q_sigma,
                                               nmμ, nmσ, String(sigma_grp);
                                               coupled = false, asymmetric = false,
                                               se = true, profile_ci = profile_ci,
                                               reml = reml, g_tol = g_tol)
            return _withformula(fit, f)
        end

        # Asymmetric path: σ-phylo only, mean is fixed-effects.
        (isempty(re) && isempty(sigma_re) && metav === nothing) ||
            error("drm (Gaussian): the asymmetric σ-phylo route requires no additional " *
                  "random effects on the mean axis")
        fit = _fit_gaussian_locscale_phylo(fam, y, Xμ, Xσ, gidx_sigma, G_sigma, Q_sigma,
                                           nmμ, nmσ, String(sigma_grp);
                                           coupled = false, asymmetric = true,
                                           se = true, profile_ci = profile_ci,
                                           reml = reml, g_tol = g_tol)
        return _withformula(fit, f)
    end
    if method === :REML
        # REML (opt-in, experimental) is implemented only for the fixed-effect
        # univariate Gaussian location–scale cell in this slice (the standard
        # Patterson–Thompson correction for β_μ). Random-effect / structured /
        # meta cells and the bivariate q=4 path are gated by their own REML work
        # (report/reml-wiring-design.md, slice 1 / #187); reject them clearly.
        (isempty(re) && isempty(sigma_re) && structured === nothing && metav === nothing &&
         length(_collect_structured(rhs[:mu])) == 0) ||
            throw(ArgumentError("drm: method = :REML is currently implemented only for the " *
                "fixed-effect Gaussian location–scale model (no random effects, no structured " *
                "/ phylo / meta terms). Use method = :ML (the default) for those models."))
    end
    if algorithm in (:em, :sparse_lbfgs)
        # The all-node sparse routes fit only the supported cell: a single
        # structured (phylo) mean random effect with a constant residual scale.
        # Reject anything else with a clear, specific error.
        (structured !== nothing && structured[1] === :phylo) ||
            throw(ArgumentError("drm: algorithm = :$algorithm is implemented only for the Gaussian " *
                "phylogenetic-mean cell — a single `phylo(1 | g)` structured mean random " *
                "effect with a tree. Use algorithm = :auto for any other structure."))
        (isempty(sigma_re) && size(Xσ, 2) == 1) ||
            throw(ArgumentError("drm: algorithm = :$algorithm requires a CONSTANT residual scale " *
                "(`sigma ~ 1` and no random effect on sigma)."))
        isempty(re) && metav === nothing ||
            throw(ArgumentError("drm: algorithm = :$algorithm supports exactly one structured mean " *
                "random effect (no additional `(1 | g)` / meta_V terms)."))
    end
    if has_missing_response
        (isempty(re) && isempty(sigma_re) && structured === nothing && metav === nothing &&
         length(all_structured) == 0) ||
            throw(ArgumentError("drm: missing Gaussian responses are currently supported for " *
                "fixed-effect univariate location-scale models. Structured, random-effect, " *
                "and meta-analysis response-missing support need their own likelihood slice."))
    end
    if !isempty(sigma_re)                                      # random effect on log σ
        (isempty(re) && structured === nothing && metav === nothing) ||
            error("a random effect on `sigma` must be the only random structure (the mean must be fixed effects)")
        (length(sigma_re) == 1 && _re_kind(sigma_re[1][1])[1] === :intercept) ||
            error("`sigma` random effects support a single random intercept `(1 | g)`")
        sgrp = sigma_re[1][2]
        gidx, G = _group_index(getproperty(data, sgrp))
        return _withformula(_fit_sigma_ranef_gaussian(fam, y, Xμ, Xσ, gidx, G, nmμ, nmσ, sgrp, g_tol), f)
    end
    # Two structured components in one fit (e.g. phylo(1|species) + relmat(1|id)):
    # a separate variance component each, latent field = their sum. Dense first cut.
    if length(all_structured) >= 2
        length(all_structured) == 2 ||
            error("at most two structured components are supported in one Gaussian fit " *
                  "(got $(length(all_structured)): $(all_structured))")
        isempty(re) && isempty(sigma_re) && metav === nothing ||
            error("two structured components must be the only random structure on the mean, " *
                  "with a fixed-effect `sigma`")
        (kind1, grp1), (kind2, grp2) = all_structured
        grp1 === grp2 && error("the two structured components must use different grouping factors")
        gidx1, G1 = _group_index(getproperty(data, grp1))
        gidx2, G2 = _group_index(getproperty(data, grp2))
        # Opt-in sparse O(p) path (#225/#232): augmented-latent + sparse Cholesky +
        # Takahashi-selected-inverse gradient. Same model, same MLE; default
        # (:auto) stays on the verified dense path.
        if algorithm === :sparse
            # END-TO-END sparse: a phylo component feeds the ROOT-CONDITIONED
            # augmented tree precision DIRECTLY (no dense Ck inversion) — true O(p)
            # (#232). A relmat/animal component still resolves its dense relatedness
            # K and uses Qk = K⁻¹ (the matrix is the user-supplied input). The
            # residual scale honours `sigma ~ x` (D → diag).
            comp1 = _sparse_struct_comp(kind1, grp1, G1, gidx1; K = K, A = A, tree = tree)
            comp2 = _sparse_struct_comp(kind2, grp2, G2, gidx2; K = K, A = A, tree = tree)
            return _withformula(_fit_two_structured_gaussian_sparse_spec(fam, y, Xμ, Xσ,
                comp1, comp2, nmμ, nmσ, g_tol), f)
        end
        C1 = _resolve_structured_matrix(kind1, grp1, G1; K = K, A = A, tree = tree, coords = coords)
        C2 = _resolve_structured_matrix(kind2, grp2, G2; K = K, A = A, tree = tree, coords = coords)
        return _withformula(_fit_two_structured_gaussian(fam, y, Xμ, gidx1, G1, C1,
            gidx2, G2, C2, nmμ, grp1, grp2, g_tol), f)
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
            use_sparse_phylo = algorithm in (:auto, :em, :sparse, :sparse_lbfgs) &&
                isempty(re) && metav === nothing &&
                isempty(sigma_re) && size(Xσ, 2) == 1
            if use_sparse_phylo
                phy = tree isa AbstractString ? augmented_phy(tree) : tree
                algorithm in (:auto, :sparse_lbfgs) && return _withformula(
                    _fit_structured_gaussian_sparse_lbfgs(fam, y, Xμ, Xσ, gidx, G, phy, nmμ, nmσ, grp, g_tol), f)
                return _withformula(
                    _fit_structured_gaussian_em(fam, y, Xμ, Xσ, gidx, G, phy, nmμ, nmσ, grp, g_tol), f)
            end
            _phylo_correlation(tree)
        end
        size(Kmat) == (G, G) || error("structured matrix must be $(G)×$(G) (the number of `$grp` levels)")
        return _withformula(_fit_structured_gaussian(fam, y, Xμ, Xσ, gidx, G, Kmat, nmμ, nmσ, grp, g_tol), f)
    end
    if metav !== nothing
        vv = Float64.(getproperty(data, metav))    # known sampling variances
        return _withformula(_fit_meta_gaussian(fam, y, Xμ, Xσ, vv, nmμ, nmσ, g_tol), f)
    end
    if isempty(re)
        if has_missing_response
            return _withformula(_fit_fixed_gaussian_missing_response(
                fam, y, Xμ, Xσ, nmμ, nmσ, g_tol, method), f)
        end
        if method === :REML
            return _withformula(_fit_fixed_gaussian_reml(fam, y, Xμ, Xσ, nmμ, nmσ, g_tol), f)
        end
        return _withformula(_fit_fixed_gaussian(fam, y, Xμ, Xσ, nmμ, nmσ, g_tol), f)
    end
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

function _with_full_fixed_gaussian_rows(fit::DrmFit, y_full, Xμ_full, Xσ_full)
    rμ = _block_range(fit, :mu)
    rσ = _block_range(fit, :sigma)
    means = Dict(:mu => Xμ_full * fit.theta[rμ])
    obs = Dict(:mu => Vector{Float64}(y_full))
    scales = Dict(:sigma => exp.(Xσ_full * fit.theta[rσ]))
    return DrmFit(
        fit.family, fit.blocks, fit.coefnames, fit.theta, fit.vcov,
        fit.loglik, fit.nobs, fit.converged, means, obs, scales,
        fit.formula, fit.nll, fit.nllgrad, fit.ranef,
        fit.estim_method, fit.reml_loglik, fit.ml_loglik,
    )
end

function _fit_fixed_gaussian_missing_response(fam::Gaussian, y, Xμ, Xσ, nmμ, nmσ, g_tol, method::Symbol)
    observed = _observed_response_mask(y)
    n_observed = count(observed)
    n_observed > 0 ||
        throw(ArgumentError("drm: at least one Gaussian response must be observed"))
    n_observed >= size(Xμ, 2) ||
        throw(ArgumentError("drm: observed Gaussian responses are fewer than the mean coefficients"))

    # Drop missing/NaN-response rows (observed-rows fit), matching glmmTMB's default
    # na.action — but WARN so it is never silent (the #258 contract; mirrors the
    # non-Gaussian _fit_observed_response_rows wrapper).
    @warn "drm: $(length(observed) - n_observed) of $(length(observed)) rows have a missing/NaN " *
          "response and were dropped (observed-rows fit, like glmmTMB's default na.action). " *
          "Use `drm_listwise` to preprocess explicitly, or supply complete responses, to silence this."

    y_obs = Vector{Float64}(y[observed])
    Xμ_obs = Matrix{Float64}(Xμ[observed, :])
    Xσ_obs = Matrix{Float64}(Xσ[observed, :])
    fit_obs = method === :REML ?
        _fit_fixed_gaussian_reml(fam, y_obs, Xμ_obs, Xσ_obs, nmμ, nmσ, g_tol) :
        _fit_fixed_gaussian(fam, y_obs, Xμ_obs, Xσ_obs, nmμ, nmσ, g_tol)
    return _with_full_fixed_gaussian_rows(fit_obs, y, Xμ, Xσ)
end

function _formula_response_observed_mask(f::DrmFormula, data)
    _, observed1 = _coerce_response_column(_table_column(data, f.response))
    f.response2 === nothing && return observed1
    _, observed2 = _coerce_response_column(_table_column(data, f.response2))
    length(observed1) == length(observed2) ||
        throw(ArgumentError("drm: the two response columns have different lengths"))
    return observed1 .& observed2
end

function _subset_table_rows(data, rows)
    cols = Tables.columntable(data)
    names = Tuple(Symbol(k) for k in keys(cols))
    vals = map(names) do k
        col = getproperty(cols, k)
        collect(col)[rows]
    end
    return NamedTuple{names}(Tuple(vals))
end

function _fit_observed_response_rows(fitfun::Function, f::DrmFormula, data)
    observed = _formula_response_observed_mask(f, data)
    all(observed) && return nothing
    count(observed) > 0 ||
        throw(ArgumentError("drm: at least one response row must be observed"))
    # Missing/NaN RESPONSE rows are dropped (observed-rows fit), matching glmmTMB's
    # default `na.action`. Warn so it is never SILENT (reconciles #241 auto-handling
    # with #258's "not silently fit" contract). Predictor missingness still errors.
    ndrop = count(!, observed)
    @warn "drm: $(ndrop) of $(length(observed)) rows have a missing/NaN response and were " *
          "dropped (observed-rows fit, like glmmTMB's default na.action). Use `drm_listwise` " *
          "to preprocess explicitly, or supply complete responses, to silence this."
    fit_observed = fitfun(_subset_table_rows(data, observed))
    return _with_full_response_rows(fit_observed, f, data)
end

function _full_response_obs(f::DrmFormula, data)
    y, observed1 = _coerce_response_column(_table_column(data, f.response))
    f.response2 === nothing && return Dict(:mu => y)
    y2, observed2 = _coerce_response_column(_table_column(data, f.response2))
    ntr = y .+ y2
    prop = y ./ ntr
    prop[.!(observed1 .& observed2)] .= NaN
    return Dict(:mu => prop)
end

function _full_trials(f::DrmFormula, data)
    y, observed1 = _coerce_response_column(_table_column(data, f.response))
    f.response2 === nothing && return ones(length(y))
    y2, observed2 = _coerce_response_column(_table_column(data, f.response2))
    ntr = y .+ y2
    ntr[.!(observed1 .& observed2)] .= NaN
    return ntr
end

function _cumulative_full_components(fit::DrmFit, data)
    f = fit.formula
    forms = Dict(f.forms)
    fixed_mu, _, _, _ = _split_ranef(forms[:mu])
    nrows = length(_table_column(data, f.response))
    ndr = _replace_table_column(data, f.response, zeros(nrows))
    _, Xμ, nmμ = _design(f.response, fixed_mu, ndr)
    ic = findfirst(==("(Intercept)"), nmμ)
    if ic !== nothing
        keep = setdiff(1:length(nmμ), ic)
        Xμ = Xμ[:, keep]
    end
    β = coef(fit, :mu)
    δ = coef(fit, :cutpoints)
    nc = length(δ)
    K = nc + 1
    cuts = similar(δ)
    cuts[1] = δ[1]
    for k in 2:nc
        cuts[k] = cuts[k - 1] + exp(δ[k])
    end
    η = length(β) == 0 ? zeros(nrows) : Xμ * β
    score = Vector{Float64}(undef, nrows)
    for i in 1:nrows
        sc = 0.0
        for k in 1:K
            pk = k == 1 ? _logistic(cuts[1] - η[i]) :
                 k == K ? 1 - _logistic(cuts[nc] - η[i]) :
                 _logistic(cuts[k] - η[i]) - _logistic(cuts[k - 1] - η[i])
            sc += k * pk
        end
        score[i] = sc
    end
    return score, η, Float64.(cuts)
end

function _full_means_and_scales(fit::DrmFit, data)
    if fit.family isa CumulativeLogit
        score, η, cuts = _cumulative_full_components(fit, data)
        return Dict(:mu => score), Dict(:ordinal_eta => η, :ordinal_cuts => cuts)
    end

    if fit.family isa ZeroOneBeta
        params = predict_parameters(fit, data; type = :link)
        βmu = _logistic.(clamp.(params[:mu], -30.0, 30.0))
        zoi = _logistic.(clamp.(params[:zoi], -30.0, 30.0))
        coi = _logistic.(clamp.(params[:coi], -30.0, 30.0))
        scales = Dict(
            :beta_mu => βmu,
            :sigma => exp.(params[:sigma]),
            :zoi => zoi,
            :coi => coi,
        )
        return Dict(:mu => (1 .- zoi) .* βmu .+ zoi .* coi), scales
    end

    params = predict_parameters(fit, data)
    means = Dict(:mu => params[:mu])

    scales = Dict{Symbol,Vector{Float64}}()
    for (p, value) in params
        p === :mu && continue
        scales[p] = value
    end
    if fit.family isa Binomial || fit.family isa BetaBinomial
        scales[:trials] = _full_trials(fit.formula, data)
    end
    return means, scales
end

function _with_full_response_rows(fit::DrmFit, f::DrmFormula, data)
    means, scales = _full_means_and_scales(fit, data)
    obs = _full_response_obs(f, data)
    return DrmFit(
        fit.family, fit.blocks, fit.coefnames, fit.theta, fit.vcov,
        fit.loglik, fit.nobs, fit.converged, means, obs, scales,
        fit.formula, fit.nll, fit.nllgrad, fit.ranef,
        fit.estim_method, fit.reml_loglik, fit.ml_loglik,
    )
end

# ---------------------------------------------------------------------------
# REML for the fixed-effect Gaussian location–scale model (issue #11, slice 2).
#
# Standard restricted maximum likelihood (Patterson & Thompson 1971; Harville
# 1974) for the heteroscedastic linear model
#
#     y_i ~ N(Xμ_i β_μ, σ_i²),   log σ_i = Xσ_i β_σ.
#
# REML profiles out the mean fixed effects β_μ jointly with the scale, and adds
# the −½ logdet(Xμ' Σ⁻¹ Xμ) restriction term to the profile log-likelihood. With
# W = diag(σ_i⁻²) the profiled β̂_μ(β_σ) is the weighted-least-squares estimate
# solving (Xμ' W Xμ) β̂_μ = Xμ' W y, and the restricted log-likelihood is
#
#     ℓ_R(β_σ) = ℓ_P(β̂_μ(β_σ), β_σ) − ½ logdet(Xμ' W Xμ) + (pμ/2) log(2π),
#
# i.e. the same data fit as ML but with the residual scale corrected for the pμ
# degrees of freedom spent estimating β_μ. The defining consequence is that the
# REML residual variance is LARGER (less downward-biased) than the ML one — the
# classic n vs (n − pμ) divisor in the homoscedastic special case.
#
# HONEST LIMITS (ship these — see report/reml-wiring-design.md):
#   * Scope: fixed-effect univariate Gaussian location–scale ONLY (no random
#     effects, no structured/phylo/meta terms, not the bivariate q=4 path — those
#     are gated by slice 1 / #187). REML is OPT-IN and EXPERIMENTAL.
#   * The correction inflates the SCALE estimate; it does not change β̂_μ at the
#     optimum (β̂_μ is the same WLS estimate ML would give at the REML β_σ).
#   * REML log-likelihoods are NOT comparable across different MEAN structures
#     (the error-contrast basis differs) — model selection must stay on ML. The
#     aic/bic/lrtest guard enforces this.
"""
    _fit_fixed_gaussian_reml(fam, y, Xμ, Xσ, nmμ, nmσ, g_tol) -> DrmFit

REML fit of the fixed-effect Gaussian location–scale model. Profiles out β_μ by
weighted least squares and optimises the restricted log-likelihood over β_σ; β̂_μ
is recovered as the final WLS estimate. The returned `DrmFit` carries
`estim_method = :REML`, `reml_loglik`, and `ml_loglik` (the plain ML log-lik at
the REML parameters, for reference). Internal — reached via `drm(...; method = :REML)`.
"""
function _fit_fixed_gaussian_reml(fam::Gaussian, y, Xμ, Xσ, nmμ, nmσ, g_tol)
    n = length(y)
    pμ, pσ = size(Xμ, 2), size(Xσ, 2)
    const_2pi = 0.5 * n * log(2π)

    # Profiled β̂_μ(β_σ): weighted least squares with W = diag(exp(-2 ησ)).
    # Returns (β̂_μ, residuals, logdet(Xμ' W Xμ)) — all differentiable in β_σ.
    function profile_bmu(βσ)
        ησ = Xσ * βσ
        w = exp.(-2 .* ησ)                 # σ_i^{-2}
        XtW = Xμ' * (w .* Xμ)              # pμ × pμ, Xμ' W Xμ
        XtWy = Xμ' * (w .* y)
        βμ = XtW \ XtWy
        r = y .- Xμ * βμ
        return βμ, r, ησ, logdet(XtW)
    end

    # Restricted NEGATIVE log-likelihood over β_σ alone (β_μ profiled out).
    function nll_reml(βσ)
        _, r, ησ, ld = profile_bmu(βσ)
        s = zero(eltype(βσ))
        @inbounds for i in 1:n
            s += ησ[i] + 0.5 * r[i] * r[i] * exp(-2 * ησ[i])
        end
        # ℓ_R = -s - const_2pi - 0.5*ld + 0.5*pμ*log(2π);  nll = -ℓ_R.
        return s + const_2pi + 0.5 * ld - 0.5 * pμ * log(2π)
    end

    # Warm-start β_σ from the homoscedastic residual scale (intercept), zeros else.
    βσ0 = zeros(pσ)
    βμ_ols = Xμ \ y
    βσ0[1] = log(std(y - Xμ * βμ_ols) + eps())
    res = Optim.optimize(nll_reml, βσ0, Optim.LBFGS(), Optim.Options(g_tol = g_tol); autodiff = :forward)
    βσ̂ = Optim.minimizer(res)
    βμ̂, r̂, ησ̂, _ = profile_bmu(βσ̂)
    θ̂ = vcat(βμ̂, βσ̂)

    # vcov: for the mean block, the REML/WLS covariance (Xμ' W Xμ)^{-1}; for the
    # scale block, the inverse Fisher information of the restricted objective.
    # We assemble a block-diagonal vcov (mean ⟂ scale at the optimum for Gaussian
    # location–scale), reusing the WLS information for β_μ and the FD Hessian of
    # the restricted objective for β_σ.
    w = exp.(-2 .* ησ̂)
    Vμ = inv(Symmetric(Xμ' * (w .* Xμ)))
    Hσ = ForwardDiff.hessian(nll_reml, βσ̂)
    Vσ = inv(Symmetric(Hσ))
    V = zeros(pμ + pσ, pμ + pσ)
    V[1:pμ, 1:pμ] .= Vμ
    V[(pμ+1):(pμ+pσ), (pμ+1):(pμ+pσ)] .= Vσ

    # Both log-likelihoods at the REML estimate.
    reml_ll = -nll_reml(βσ̂)
    # Plain ML log-lik at the SAME (β̂_μ, β̂_σ) — for reference / cross-structure use.
    ml_ll = let s = 0.0
        @inbounds for i in 1:n
            s += ησ̂[i] + 0.5 * r̂[i] * r̂[i] * exp(-2 * ησ̂[i])
        end
        -(s + const_2pi)
    end

    blocks = [:mu => 1:pμ, :sigma => (pμ+1):(pμ+pσ)]
    names = [:mu => nmμ, :sigma => nmσ]
    means = Dict(:mu => Xμ * βμ̂)
    obs = Dict(:mu => Vector{Float64}(y))
    scales = Dict(:sigma => exp.(ησ̂))
    # Reconstruct a full-θ ML objective closure for profile intervals (matches the
    # ML fitter's nll layout): the standard location–scale negative log-likelihood.
    function nll_full(θ)
        βμ = θ[1:pμ]; βσ = θ[pμ+1:pμ+pσ]
        ημ = Xμ * βμ; eσ = Xσ * βσ
        s = zero(eltype(θ))
        @inbounds for i in 1:n
            rr = y[i] - ημ[i]
            s += eσ[i] + 0.5 * rr * rr * exp(-2 * eσ[i])
        end
        return s + const_2pi
    end
    fit = DrmFit(fam, blocks, names, θ̂, V, reml_ll, n, Optim.converged(res), means, obs, scales)
    return _withreml(_withnll(fit, nll_full), reml_ll, ml_ll)
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
    residuals(fit; type = :response, rng = Random.default_rng())

Model residuals. `type` selects the kind:

- `:response` (default) — raw response residuals (observed − fitted mean),
  matching [`fitted`](@ref)'s shape. `residuals(fit)` is unchanged.
- `:quantile` — randomized quantile residuals (Dunn & Smyth; DHARMa /
  glmmTMB style). For observation `i` with fitted distribution `F_i`,
  `r_i = Φ⁻¹(u_i)` where `u_i` is the (randomized, for discrete families)
  probability-integral transform of `y_i`. Under a correct model the `r_i`
  are i.i.d. standard normal. Univariate only.

Quantile residuals are implemented for every DRM.jl response family except
Tweedie (no closed-form CDF in `Distributions.jl`):

- **continuous** (PIT `u_i = F(y_i)`, no RNG): Gaussian, Student-t, LogNormal,
  Gamma, Beta;
- **discrete, randomized** (`u_i = F(y_i−1) + (F(y_i) − F(y_i−1))·U`,
  `U ~ Uniform(0,1)` drawn from `rng`): Poisson, NegBinomial2,
  TruncatedNegBinomial2, Binomial, BetaBinomial, CumulativeLogit (ordinal);
- **atomic** (point-mass mixture; the mass is randomized across): ZeroOneBeta.

The per-family parameter → distribution map lives in `_conditional_dist`
(reused by future `simulate`/PIT checks). Tweedie throws an `ArgumentError`.
"""
function residuals(fit::DrmFit; type::Symbol = :response, rng = Random.default_rng())
    if type === :response
        haskey(fit.means, :mu) && return fit.obs[:mu] .- fit.means[:mu]
        return Dict(k => fit.obs[k] .- fit.means[k] for k in keys(fit.means))
    elseif type === :quantile
        return _quantile_residuals(fit, rng)
    else
        throw(ArgumentError("residuals: `type` must be :response or :quantile (got :$type)"))
    end
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
    predict(fit, newdata; type = :response, se = false) -> Vector / Dict / NamedTuple

Population-level prediction on `newdata` (a NamedTuple / column table), random /
structured effects integrated out. `type = :response` (default) returns the
response-scale mean — the family inverse link applied to `Xβ̂` (`exp` for
Poisson/Gamma, `logistic` for Beta/Binomial, identity for Gaussian); `type = :link`
returns `Xβ̂`. In-sample, `predict(fit, data) ≈ fitted(fit)`. Univariate returns a
vector; bivariate returns `Dict(:mu1 => …, :mu2 => …)`.

`se = false` (default) is the point prediction above. `se = true` adds
**delta-method standard errors** for the mean (glmmTMB/drmTMB `se.fit` parity):

- univariate → a `NamedTuple` `(; prediction, se)`;
- bivariate  → a `NamedTuple` `(; prediction::Dict, se::Dict)` keyed `:mu1, :mu2`.

The SE uses the μ-block of `vcov(fit)`: link scale `se_i = sqrt(xᵢ' Vμ xᵢ)`
(with `Vμ = vcov(fit)[r, r]`, `r` the `:mu` coef range from `fit.blocks`);
response scale multiplies by the inverse-link derivative `|dμ/dη|` at `η̂`
(identity → 1, exp → `exp(η)`, logistic → `μ(1−μ)`).
"""
function predict(fit::DrmFit, newdata; type::Symbol = :response, se::Bool = false)
    f = fit.formula
    f === nothing && error("predict: this fit did not retain its formula")
    type in (:response, :link) || error("predict: `type` must be :response or :link")
    nd = NamedTuple(pairs(newdata))
    nrows = length(first(values(nd)))
    V = se ? vcov(fit) : nothing
    if f isa DrmFormula
        fixed_mu, _, _, _ = _split_ranef(Dict(f.forms)[:mu])
        ndr = merge(nd, NamedTuple{(f.response,)}((zeros(nrows),)))
        _, Xnew, _ = _design(f.response, fixed_mu, ndr)
        η = Xnew * coef(fit, :mu)
        pred = type === :link ? η : _mean_response(fit.family, η)
        se || return pred
        r = _block_range(fit, :mu)
        se_vec = _delta_se(Xnew, view(V, r, r), η, type, fit.family, :mu)
        return (; prediction = pred, se = se_vec)
    else  # BivariateDrmFormula
        fm = Dict(f.forms)
        fixed1, _, _, _ = _split_ranef(fm[:mu1])
        fixed2, _, _, _ = _split_ranef(fm[:mu2])
        nd1 = merge(nd, NamedTuple{(f.response1,)}((zeros(nrows),)))
        nd2 = merge(nd, NamedTuple{(f.response2,)}((zeros(nrows),)))
        _, X1, _ = _design(f.response1, fixed1, nd1)
        _, X2, _ = _design(f.response2, fixed2, nd2)
        η1 = X1 * coef(fit, :mu1)
        η2 = X2 * coef(fit, :mu2)
        pred = type === :link ?
            Dict(:mu1 => η1, :mu2 => η2) :
            Dict(:mu1 => _mean_response(fit.family, η1),
                 :mu2 => _mean_response(fit.family, η2))
        se || return pred
        r1 = _block_range(fit, :mu1); r2 = _block_range(fit, :mu2)
        se_dict = Dict(
            :mu1 => _delta_se(X1, view(V, r1, r1), η1, type, fit.family, :mu1),
            :mu2 => _delta_se(X2, view(V, r2, r2), η2, type, fit.family, :mu2))
        return (; prediction = pred, se = se_dict)
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

# Inverse-link derivative dμ/dη at the linear predictor η for parameter `p`,
# mirroring `_param_response` link-by-link. Used by the delta method to map a
# link-scale standard error to the response scale:
#   se_response(η) = |dμ/dη| · se_link(η).
# Derivatives (g⁻¹ is the inverse link applied in `_param_response`):
#   identity → 1;  exp → exp(η);  logistic μ=σ(η) → μ(1−μ);  tanh ρ=tanh(η) → 1−ρ²;
#   Tweedie ν via `_logit12` (1 + sigmoid → range (1,2)) → sig·(1−sig) with sig=σ(η).
function _link_deriv(fam, p::Symbol, η)
    if p === :mu || p === :mu1 || p === :mu2
        if fam isa Poisson || fam isa NegBinomial2 || fam isa TruncatedNegBinomial2 ||
           fam isa Gamma || fam isa LogNormal || fam isa Tweedie
            return exp.(clamp.(η, -30.0, 30.0))               # log link
        elseif fam isa Beta || fam isa Binomial || fam isa BetaBinomial
            μ = _logistic.(clamp.(η, -30.0, 30.0))            # logit link
            return μ .* (1 .- μ)
        else
            return ones(length(η))                            # identity link
        end
    elseif p === :sigma || p === :sigma1 || p === :sigma2
        return exp.(η)                                        # log link
    elseif p === :rho12
        ρ = tanh.(η)                                          # atanh link
        return 1 .- ρ .^ 2
    elseif p === :nu
        if fam isa Tweedie
            s = _logistic.(η)                                 # _logit12 = 1 + σ(η)
            return s .* (1 .- s)
        else
            return exp.(η)                                    # log link
        end
    elseif p === :zi || p === :hu || p === :zoi || p === :coi
        μ = _logistic.(η)                                     # logit link
        return μ .* (1 .- μ)
    else
        throw(ArgumentError("predict: no inverse-link derivative known for parameter `$p`"))
    end
end

# Coefficient (vcov / theta) index range for one distributional parameter block,
# read straight off `fit.blocks` (Vector{Pair{Symbol,UnitRange}}).
_block_range(fit::DrmFit, p::Symbol) = begin
    for (q, r) in fit.blocks
        q === p && return r
    end
    throw(ArgumentError("no parameter $p in fit (have $(first.(fit.blocks)))"))
end

# Delta-method standard errors for one parameter from its design rows `Xp`, the
# corresponding vcov sub-block `Vp`, and (for the response scale) the inverse-link
# derivative at η̂. Link-scale: se_i = sqrt(xᵢ' Vp xᵢ). Response-scale multiplies
# by |dμ/dη| at η̂_i. Centralised so the point value and its SE stay consistent.
function _delta_se(Xp::AbstractMatrix, Vp::AbstractMatrix, η::AbstractVector,
                   type::Symbol, fam, p::Symbol)
    se_link = [sqrt(max(0.0, dot(view(Xp, i, :), Vp, view(Xp, i, :)))) for i in 1:size(Xp, 1)]
    type === :link && return se_link
    return abs.(_link_deriv(fam, p, η)) .* se_link
end

"""
    predict_parameters(fit, newdata; type = :response, se = false)
        -> Dict{Symbol,Vector{Float64}}  (se = false)
        -> Dict{Symbol,NamedTuple}        (se = true)

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

`se = false` (default) returns `Dict{Symbol,Vector{Float64}}` of point values.
`se = true` returns `Dict{Symbol,NamedTuple}` with `p => (; value, se)` per
parameter: each `se` is the **delta-method** standard error using that parameter's
own coef range `r_p` from `fit.blocks` (`V_p = vcov(fit)[r_p, r_p]`), the response
scale multiplying by that parameter's inverse-link derivative at `η̂` (`:sigma`→`exp`,
`:rho12`→`1−ρ²`, etc.). `value` matches the `se = false` point prediction.

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
function predict_parameters(fit::DrmFit, newdata; type::Symbol = :response,
                            se::Bool = false)
    f = fit.formula
    f === nothing && error("predict_parameters: this fit did not retain its formula")
    type in (:response, :link) || error("predict_parameters: `type` must be :response or :link")
    forms = Dict(f.forms)
    nd = NamedTuple(pairs(newdata))
    nrows = length(first(values(nd)))
    V = se ? vcov(fit) : nothing
    # A real LHS to dummy into `_design` for each parameter's RHS. The univariate
    # form has one response; the bivariate form has two (use response1 for the
    # σ/ρ placeholder RHS, exactly as the bivariate fitter does). The per-parameter
    # response symbol is chosen inline in the loop below (a conditional inner
    # function is not reliably bound in local scope).
    bivar = !(f isa DrmFormula)
    ndr = bivar ?
        merge(nd, NamedTuple{(f.response1, f.response2)}((zeros(nrows), zeros(nrows)))) :
        merge(nd, NamedTuple{(f.response,)}((zeros(nrows),)))
    out = se ? Dict{Symbol,NamedTuple}() : Dict{Symbol,Vector{Float64}}()
    for (p, r) in fit.blocks
        haskey(forms, p) || continue          # skip RE-SD / cutpoint blocks (:resd, :recov, :cutpoints, …)
        resp = bivar ? (p === :mu2 ? f.response2 : f.response1) : f.response
        fixed_p, _, _, _ = _split_ranef(forms[p])
        _, Xp, _ = _design(resp, fixed_p, ndr)
        ηp = Xp * coef(fit, p)
        val = type === :link ? ηp : _param_response(fit.family, p, ηp)
        if se
            se_p = _delta_se(Xp, view(V, r, r), ηp, type, fit.family, p)
            out[p] = (; value = val, se = se_p)
        else
            out[p] = val
        end
    end
    return out
end

"""
    prediction_grid(reference::NamedTuple; n::Int = 50, kwargs...) -> NamedTuple

Build a `newdata` column table for [`predict`](@ref) / [`predict_parameters`](@ref)
by sweeping one or more predictors over supplied value ranges (their **Cartesian
product**) while holding every *other* predictor fixed at a reference value.

Pure data — no fitted model is needed, so it is trivially testable and composes
directly with `predict_parameters(fit, prediction_grid(...))`.

# Arguments
- `reference::NamedTuple`: the predictor columns to hold constant. Each held
  value is reduced to a scalar by this rule:
  * if `reference[col]` is an `AbstractArray` of numbers → its `mean`;
  * if `reference[col]` is any other `AbstractArray` → its `first` element;
  * otherwise → the value itself (already a scalar).
  Held columns are broadcast to the product length.
- `n::Int = 50`: reserved for future default-range generation; currently unused
  (every swept predictor supplies its own explicit values via `kwargs`).
- `kwargs...`: each `predictor = values` gives a vector/range of values to sweep
  for that predictor. The output rows enumerate the full Cartesian product of the
  swept predictors. A swept predictor named in `reference` overrides (replaces)
  the held value.

# Returns
A `NamedTuple` of equal-length column vectors. With no swept predictors the grid
has a single row at the reference; with one swept predictor it is just that range
(others held); with several, the full Cartesian product.

The swept columns appear first (in `kwargs` order), then the remaining held
columns (in `reference` order).

# Example
```julia
g = prediction_grid((; x = randn(100)), x = range(-2, 2; length = 25))
length(g.x) == 25                       # a 25-row sweep over x

# Two swept predictors → Cartesian product (5 × 3 = 15 rows), z held at its mean:
g2 = prediction_grid((; x = [0.0], z = [1.0, 2.0, 3.0]), x = -2:1.0:2)
length(g2.x) == 5
all(==(2.0), g2.z)                       # z held at mean([1,2,3])

# Composes with a fit:
preds = predict_parameters(fit, g)       # Dict(:mu => …, :sigma => …) of length 25
```
"""
function prediction_grid(reference::NamedTuple; n::Int = 50, kwargs...)
    swept = NamedTuple(kwargs)
    swept_keys = keys(swept)

    # Reduce each held reference column to a scalar; skip any that are swept
    # (the swept values override the reference).
    held_pairs = Pair{Symbol,Any}[]
    for k in keys(reference)
        k in swept_keys && continue
        push!(held_pairs, k => _reference_scalar(reference[k]))
    end

    # Collect the swept value vectors (in kwarg order) and form the Cartesian
    # product. `Iterators.product` varies the FIRST argument fastest.
    swept_vals = [collect(swept[k]) for k in swept_keys]
    combos = isempty(swept_vals) ? [()] : vec(collect(Iterators.product(swept_vals...)))
    nrows = length(combos)

    cols = Pair{Symbol,Vector}[]
    for (i, k) in enumerate(swept_keys)
        push!(cols, k => [combo[i] for combo in combos])
    end
    for (k, v) in held_pairs
        push!(cols, k => fill(v, nrows))
    end
    return (; cols...)
end

# Reduce a held reference column to the scalar used across the grid: the mean of
# a numeric array, the first element of any other array, or the value itself.
_reference_scalar(v::AbstractArray{<:Number}) = mean(v)
_reference_scalar(v::AbstractArray) = first(v)
_reference_scalar(v) = v

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
    simulate(fit; nsim = 1, rng = default_rng())

Draw parametric (residual-level) replicate response(s) from the fitted model —
the building block of a parametric bootstrap and posterior-predictive checks.
Each draw uses the fitted per-observation mean μ̂ and the fitted dispersion /
scale parameters for the family; for random-effect models the draw is
conditional on the random effects being zero (population level).

Return value (univariate / random-effect / meta models):
- `nsim == 1` → a length-`nobs` response `Vector` (back-compatible).
- `nsim  > 1` → a `nobs × nsim` `Matrix`, one independent replicate per column.

Bivariate Gaussian models return `Dict(:mu1=>…, :mu2=>…)` for `nsim == 1`, or a
length-`nsim` `Vector` of such `Dict`s for `nsim > 1` (a matrix of paired
responses is not well defined).

Supported families: Gaussian (univariate & bivariate), Student-t, Poisson
(+ zero-inflated / hurdle), NegBinomial2 (+ zero-inflated / hurdle / truncated),
Beta, BetaBinomial, Binomial, Gamma, LogNormal, ZeroOneBeta, Tweedie, and
CumulativeLogit.

# Example
```julia
fit = drm(bf(@formula(y ~ x), @formula(sigma ~ x)), Gaussian(); data)
y1  = simulate(fit)               # Vector, length nobs
Y   = simulate(fit; nsim = 100)   # nobs × 100 Matrix
```
"""
function simulate(fit::DrmFit; nsim::Integer = 1, rng = default_rng())
    nsim >= 1 || throw(ArgumentError("simulate requires nsim >= 1, got $nsim"))
    nsim == 1 && return _simulate_once(fit, rng)
    first_draw = _simulate_once(fit, rng)
    if first_draw isa AbstractVector       # univariate: stack columns into a Matrix
        out = Matrix{eltype(first_draw)}(undef, length(first_draw), nsim)
        out[:, 1] = first_draw
        for s in 2:nsim
            out[:, s] = _simulate_once(fit, rng)
        end
        return out
    else                                   # bivariate Dict: collect replicates
        reps = Vector{typeof(first_draw)}(undef, nsim)
        reps[1] = first_draw
        for s in 2:nsim
            reps[s] = _simulate_once(fit, rng)
        end
        return reps
    end
end

# One residual-level replicate (the per-draw kernel). Returns a response Vector
# for univariate / RE / meta fits, or a Dict(:mu1, :mu2) for bivariate Gaussian.
function _simulate_once(fit::DrmFit, rng)
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

For a **REML** fit (`drm(...; method = :REML)`) this returns the **restricted**
log-likelihood (`reml_loglik(fit)`). REML log-likelihoods are **not comparable
across different fixed-effect (mean) structures** — the error-contrast basis
differs — so do not use them for model selection across mean structures; the
`aic`/`bic`/`lrtest` guard enforces this. Use [`ml_loglik`](@ref) (the plain ML
log-likelihood at the REML estimate) when an ML-comparable value is needed.
"""
loglik(fit::DrmFit) = fit.loglik

"""
    estimation_method(fit) -> Symbol

The estimator used to fit the model: `:ML` (default) or `:REML`
(`drm(...; method = :REML)`).
"""
estimation_method(fit::DrmFit) = fit.estim_method

"""
    reml_loglik(fit) -> Float64

The restricted (REML) log-likelihood. Returns `NaN` for an ML fit (REML was not
used). See [`loglik`](@ref) for the cross-structure-comparison caveat.
"""
reml_loglik(fit::DrmFit) = fit.reml_loglik

"""
    ml_loglik(fit) -> Float64

The plain (unrestricted) maximum-likelihood log-likelihood. For an ML fit this
equals [`loglik`](@ref); for a REML fit it is the ML log-likelihood evaluated at
the REML parameter estimate — the value to use when an ML-comparable log-likelihood
is needed (e.g. across different mean structures).
"""
ml_loglik(fit::DrmFit) = fit.ml_loglik

"""
    dof(fit) -> Int

Degrees of freedom — the number of estimated parameters (length of θ).
"""
dof(fit::DrmFit) = length(fit.theta)

# REML model-selection guard (issue #11): AIC/BIC built on a REML log-likelihood
# are only meaningful when comparing models with the SAME fixed-effect (mean)
# structure (REML compares variance structure, not mean structure). We cannot see
# the other model from a single-fit accessor, so we warn once that the value is
# only valid for variance-only comparisons. `lrtest`/`anova` (which see both fits)
# enforce the stronger, comparison-aware guard.
function _reml_infocrit_warn(fit::DrmFit, which::AbstractString)
    fit.estim_method === :REML && @warn(
        "$which on a REML fit: REML log-likelihoods are only comparable across models with " *
        "the SAME fixed-effect (mean) structure (variance-only differences). For model " *
        "selection across mean structures, refit with method = :ML.", maxlog = 1)
    return nothing
end

"""
    aic(fit) -> Float64

Akaike information criterion, `-2·loglik + 2·dof`. Lower is better; compares
models fit by **ML** (not REML) on the same data.

On a **REML** fit this uses the restricted log-likelihood and is only valid for
comparing models that differ in **variance structure only** (same mean structure);
a one-time warning is emitted. Use ML for cross-mean-structure selection.
"""
function aic(fit::DrmFit)
    _reml_infocrit_warn(fit, "aic")
    return -2 * fit.loglik + 2 * length(fit.theta)
end

"""
    bic(fit) -> Float64

Bayesian (Schwarz) information criterion, `-2·loglik + dof·log(nobs)`.

On a **REML** fit this carries the same variance-only-comparison caveat as
[`aic`](@ref) and emits a one-time warning.
"""
function bic(fit::DrmFit)
    _reml_infocrit_warn(fit, "bic")
    return -2 * fit.loglik + length(fit.theta) * log(fit.nobs)
end

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
