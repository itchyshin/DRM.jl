# joint_missing_frontend.jl — narrow formula admission for one or two missing predictors.
#
# The numerical likelihood lives in joint_missing_predictor.jl.  This file only
# turns a validated, native StatsModels formula into that prepared representation.

"""
    mi(x)

Marker for exactly one additive predictor whose missing values are modelled by
the joint missing-predictor frontend. It is valid only inside `@formula`; direct
evaluation is an error.
"""
mi(args...) = throw(ArgumentError("`mi()` is a formula marker; use it only inside `@formula(...)`"))

"""Validated controls for the joint missing-predictor formula admission."""
struct JointMissingControl
    response::Symbol
    predictor::Symbol
end

function _joint_control_value(value, name::AbstractString, allowed::Tuple)
    value isa Symbol || value isa AbstractString ||
        throw(ArgumentError("miss_control: `$name` must be one of $(join(string.(allowed), ", "))"))
    result = Symbol(value)
    result in allowed ||
        throw(ArgumentError("miss_control: `$name` must be one of $(join(string.(allowed), ", ")) (got `$value`)"))
    return result
end

"""
    miss_control(; response = "fail", predictor = "fail")

Declare missing-data handling for the joint frontend. Its currently verified
admission requires `predictor = "model"` and, when responses are missing,
`response = "include"`; the defaults
fail rather than silently changing a conventional `drm()` fit.
"""
function miss_control(; response = "fail", predictor = "fail")
    return JointMissingControl(
        _joint_control_value(response, "response", (:fail, :include)),
        _joint_control_value(predictor, "predictor", (:fail, :model)),
    )
end

"""Formula and family for the one predictor distribution in a joint fit."""
struct JointImputeModel{F}
    formula::FormulaTerm
    family::F
end

"""
    impute_model(formula; family = Gaussian())

Wrap a predictor model when its distribution is not the default Gaussian.
The bounded frontend currently admits Gaussian and Bernoulli (`Binomial()`) x.
"""
function impute_model(formula::FormulaTerm; family = Gaussian())
    family isa Gaussian || family isa Binomial ||
        throw(ArgumentError("impute_model: `family` must be Gaussian() or Binomial()"))
    return JointImputeModel(formula, family)
end

"""User-facing wrapper around the prepared exact joint fit."""
struct JointDrmFit
    prepared::PreparedJointFit
    formula::DrmFormula
    variable::Symbol
end

"""
    JointTwoDrmFit

Formula-facing wrapper for the prepared two-independent-Gaussian-predictor
kernel. Raw coefficients and `vcov` preserve the kernel order
`beta, b1, b2, delta, alpha1, logtau1, alpha2, logtau2`; natural predictor
SDs are exposed only through `coef(fit, :sigma_mi_<variable>)`.
"""
struct JointTwoDrmFit
    prepared::PreparedTwoJointGaussianFit
    formula::DrmFormula
    variables::NTuple{2,Symbol}
end

_joint_frontend_terms(rhs) = rhs isa Tuple ? collect(rhs) : Any[rhs]

function _joint_mi_count(term)
    if term isa Tuple || term isa AbstractVector
        return sum(_joint_mi_count, term)
    elseif term isa FunctionTerm
        return (term.f === mi ? 1 : 0) + sum(_joint_mi_count, term.args)
    elseif hasproperty(term, :terms)
        return sum(_joint_mi_count, getproperty(term, :terms))
    elseif hasproperty(term, :args)
        return sum(_joint_mi_count, getproperty(term, :args))
    end
    return 0
end

_joint_contains_mi(term) = _joint_mi_count(term) > 0

"""Whether any formula axis contains the `mi()` marker."""
_has_joint_mi(f::DrmFormula) = any(_joint_contains_mi(pair.second) for pair in f.forms)
_has_joint_mi(f::FormulaTerm) = _joint_contains_mi(f.rhs)

function _joint_term_symbols(term)
    if term isa Term
        return Symbol[term.sym]
    elseif term isa FunctionTerm
        return reduce(vcat, (_joint_term_symbols(arg) for arg in term.args); init = Symbol[])
    elseif hasproperty(term, :terms)
        return reduce(vcat, (_joint_term_symbols(arg) for arg in getproperty(term, :terms)); init = Symbol[])
    elseif hasproperty(term, :args)
        return reduce(vcat, (_joint_term_symbols(arg) for arg in getproperty(term, :args)); init = Symbol[])
    end
    return Symbol[]
end

_joint_frontend_missing(value) = ismissing(value) || (value isa AbstractFloat && isnan(value))

function _joint_require_complete_rhs(rhs, data, label::AbstractString)
    for name in unique(reduce(vcat, (_joint_term_symbols(t) for t in _joint_frontend_terms(rhs)); init = Symbol[]))
        values = _table_column(data, name)
        any(_joint_frontend_missing, values) &&
            throw(ArgumentError("joint missing-predictor frontend: `$name` has missing values in $label; only the marked predictor and response may be incomplete"))
    end
    return nothing
end

function _joint_require_exogenous(rhs, response::Symbol, predictor::Symbol, label::AbstractString)
    for term in _joint_frontend_terms(rhs), name in _joint_term_symbols(term)
        name in (response, predictor) && throw(ArgumentError(
            "joint missing-predictor frontend: $label must use exogenous covariates; `$name` is a modelled response or predictor"))
    end
    return nothing
end

function _joint_require_exogenous(rhs, response::Symbol, predictors::NTuple{2,Symbol}, label::AbstractString)
    for term in _joint_frontend_terms(rhs), name in _joint_term_symbols(term)
        (name === response || name in predictors) && throw(ArgumentError(
            "joint missing-predictor frontend: $label must use exogenous covariates; `$name` is a modelled response or predictor"))
    end
    return nothing
end

function _joint_validate_fixed_term(term, label::AbstractString)
    if term isa FunctionTerm
        forbidden = term.f === mi || term.f === (|) || term.f === meta_V ||
            term.f === phylo || term.f === relmat || term.f === animal || term.f === spatial ||
            nameof(term.f) === :offset
        forbidden && throw(ArgumentError("joint missing-predictor frontend: $label cannot contain mi(), offset(), random effects, structured effects, or meta_V()"))
        foreach(arg -> _joint_validate_fixed_term(arg, label), term.args)
    elseif hasproperty(term, :terms)
        foreach(arg -> _joint_validate_fixed_term(arg, label), getproperty(term, :terms))
    elseif !(term isa Term || term isa ConstantTerm)
        throw(ArgumentError("joint missing-predictor frontend: $label contains an unsupported formula term"))
    end
    return nothing
end

function _joint_validate_fixed_rhs(rhs, label::AbstractString)
    foreach(term -> _joint_validate_fixed_term(term, label), _joint_frontend_terms(rhs))
    return nothing
end

function _joint_mean_parts(rhs)
    terms = _joint_frontend_terms(rhs)
    total = sum(_joint_mi_count, terms)
    total == 1 || throw(ArgumentError("joint missing-predictor frontend: mean formula needs exactly one bare additive `mi(x)` term (found $total)"))
    marked = Any[]
    fixed = Any[]
    for term in terms
        if term isa FunctionTerm && term.f === mi
            length(term.args) == 1 && term.args[1] isa Term ||
                throw(ArgumentError("joint missing-predictor frontend: `mi()` must have one bare predictor name, e.g. `mi(x)`"))
            push!(marked, term)
        elseif _joint_contains_mi(term)
            throw(ArgumentError("joint missing-predictor frontend: `mi(x)` must be a bare additive term; nested or interacted markers are not implemented"))
        else
            _joint_validate_fixed_term(term, "mean formula")
            push!(fixed, term)
        end
    end
    length(marked) == 1 || throw(ArgumentError("joint missing-predictor frontend: multiple `mi()` terms are not implemented"))
    # StatsModels supplies an implicit intercept for `y ~ mi(x)`. Retain it
    # explicitly after removing the marker; `0 + mi(x)` remains zero-width and
    # is refused after design construction below.
    fixed_rhs = isempty(fixed) ? ConstantTerm(1) : length(fixed) == 1 ? fixed[1] : Tuple(fixed)
    return marked[1].args[1].sym, fixed_rhs
end

function _joint_two_mean_parts(rhs)
    terms = _joint_frontend_terms(rhs)
    total = sum(_joint_mi_count, terms)
    total == 2 || throw(ArgumentError("joint missing-predictor frontend: two-predictor mean formula needs exactly two bare additive `mi(x)` terms (found $total)"))
    variables = Symbol[]
    fixed = Any[]
    for term in terms
        if term isa FunctionTerm && term.f === mi
            length(term.args) == 1 && term.args[1] isa Term ||
                throw(ArgumentError("joint missing-predictor frontend: `mi()` must have one bare predictor name, e.g. `mi(x)`"))
            push!(variables, term.args[1].sym)
        elseif _joint_contains_mi(term)
            throw(ArgumentError("joint missing-predictor frontend: `mi(x)` must be a bare additive term; nested or interacted markers are not implemented"))
        else
            _joint_validate_fixed_term(term, "mean formula")
            push!(fixed, term)
        end
    end
    length(unique(variables)) == 2 ||
        throw(ArgumentError("joint missing-predictor frontend: the two `mi()` terms must mark distinct predictors"))
    fixed_rhs = isempty(fixed) ? ConstantTerm(1) : length(fixed) == 1 ? fixed[1] : Tuple(fixed)
    return (variables[1], variables[2]), fixed_rhs
end

function _joint_impute_spec(impute, variable::Symbol)
    impute isa NamedTuple ||
        throw(ArgumentError("joint missing-predictor frontend: `impute` must be a one-entry named tuple, e.g. `(x = @formula(x ~ z),)`"))
    names = Tuple(keys(impute))
    names == (variable,) ||
        throw(ArgumentError("joint missing-predictor frontend: `impute` must contain exactly the marked predictor `$variable`"))
    spec = getproperty(impute, variable)
    spec = spec isa FormulaTerm ? impute_model(spec) : spec
    spec isa JointImputeModel ||
        throw(ArgumentError("joint missing-predictor frontend: `$variable` must map to `@formula($variable ~ ...)` or `impute_model(...)`"))
    spec.formula.lhs isa Term && spec.formula.lhs.sym === variable ||
        throw(ArgumentError("joint missing-predictor frontend: imputation formula lhs must be `$variable`"))
    return spec
end

function _joint_two_impute_specs(impute, variables::NTuple{2,Symbol})
    impute isa NamedTuple ||
        throw(ArgumentError("joint missing-predictor frontend: `impute` must be a two-entry named tuple for the marked predictors"))
    names = Tuple(keys(impute))
    length(names) == 2 && Set(names) == Set(variables) ||
        throw(ArgumentError("joint missing-predictor frontend: `impute` must contain exactly `$(variables[1])` and `$(variables[2])`"))
    specs = ntuple(2) do j
        variable = variables[j]
        spec = getproperty(impute, variable)
        spec = spec isa FormulaTerm ? impute_model(spec) : spec
        spec isa JointImputeModel ||
            throw(ArgumentError("joint missing-predictor frontend: `$variable` must map to `@formula($variable ~ ...)` or `impute_model(...)`"))
        spec.formula.lhs isa Term && spec.formula.lhs.sym === variable ||
            throw(ArgumentError("joint missing-predictor frontend: imputation formula lhs must be `$variable`"))
        spec.family isa Gaussian ||
            throw(ArgumentError("joint missing-predictor frontend: two-predictor admission requires Gaussian() for both predictor models"))
        spec
    end
    return specs
end

function _joint_missing_vector(values)
    return Union{Missing,Float64}[value isa AbstractFloat && isnan(value) ? missing : Float64(value) for value in values]
end

function _joint_refuse_nondefault(method, algorithm, K, A, tree, coords, profile_ci, phylo_coupled, penalty, sparse)
    method === :ML || throw(ArgumentError("joint missing-predictor frontend: only `method = :ML` is implemented; REML is not available"))
    algorithm === :auto || throw(ArgumentError("joint missing-predictor frontend: `algorithm` is not forwarded; the verified prepared route uses LBFGS"))
    K === nothing && A === nothing && tree === nothing && coords === nothing &&
        !profile_ci && !phylo_coupled && penalty === nothing && sparse === nothing ||
        throw(ArgumentError("joint missing-predictor frontend: random/structured, profile, penalty, and sparse options are not implemented for this formula admission"))
    return nothing
end

function _fit_two_joint_formula(f::DrmFormula, data;
                                impute,
                                missing,
                                g_tol::Real,
                                method::Symbol,
                                algorithm::Symbol,
                                K,
                                A,
                                tree,
                                coords,
                                profile_ci::Bool,
                                phylo_coupled::Bool,
                                penalty,
                                sparse)
    f.response2 === nothing || throw(ArgumentError("joint missing-predictor frontend: bivariate responses are not implemented"))
    _joint_refuse_nondefault(method, algorithm, K, A, tree, coords, profile_ci, phylo_coupled, penalty, sparse)
    missing isa JointMissingControl ||
        throw(ArgumentError("joint missing-predictor frontend: `missing` must be created with miss_control(...)"))
    missing.response in (:fail, :include) ||
        throw(ArgumentError("joint missing-predictor frontend: response control must be :fail or :include"))
    missing.predictor === :model ||
        throw(ArgumentError("joint missing-predictor frontend: use `missing = miss_control(predictor = \"model\")`"))
    isfinite(g_tol) && g_tol > 0 || throw(ArgumentError("joint missing-predictor frontend: `g_tol` must be finite and positive"))

    rhs = Dict(f.forms)
    Set(keys(rhs)) == Set((:mu, :sigma)) ||
        throw(ArgumentError("joint missing-predictor frontend: only `mu` and `sigma` formulas are implemented"))
    variables, fixed_mu = _joint_two_mean_parts(rhs[:mu])
    f.response in variables && throw(ArgumentError(
        "joint missing-predictor frontend: response and modelled predictors must be different variables"))
    _joint_contains_mi(rhs[:sigma]) &&
        throw(ArgumentError("joint missing-predictor frontend: `mi()` is valid on the mean formula only, not `sigma`"))
    _joint_require_exogenous(fixed_mu, f.response, variables, "the mean design")
    _joint_require_exogenous(rhs[:sigma], f.response, variables, "the sigma design")
    _joint_validate_fixed_rhs(rhs[:sigma], "sigma formula")
    _joint_require_complete_rhs(fixed_mu, data, "the mean design")
    _joint_require_complete_rhs(rhs[:sigma], data, "the sigma design")

    specs = _joint_two_impute_specs(impute, variables)
    for j in 1:2
        rhsj = specs[j].formula.rhs
        _joint_require_exogenous(rhsj, f.response, variables, "predictor design for `$(variables[j])`")
        _joint_validate_fixed_rhs(rhsj, "predictor model for `$(variables[j])`")
        _joint_require_complete_rhs(rhsj, data, "predictor design for `$(variables[j])`")
    end

    y, Xmu, mu_names = _design(f.response, fixed_mu, data)
    missing.response === :fail && any(isnan, y) &&
        throw(ArgumentError("joint missing-predictor frontend: response has missing values; use `miss_control(response = \"include\", predictor = \"model\")`"))
    _, Xsigma, sigma_names = _design(f.response, rhs[:sigma], data)
    x1, Xpredictor1, predictor_names1 = _design(variables[1], specs[1].formula.rhs, data)
    x2, Xpredictor2, predictor_names2 = _design(variables[2], specs[2].formula.rhs, data)
    size(Xmu, 2) > 0 ||
        throw(ArgumentError("joint missing-predictor frontend: removing the two `mi()` terms leaves a zero-width mean design, which the prepared engine does not support"))
    n = length(y)
    length(x1) == n && length(x2) == n && size(Xmu, 1) == n && size(Xsigma, 1) == n &&
        size(Xpredictor1, 1) == n && size(Xpredictor2, 1) == n ||
        throw(ArgumentError("joint missing-predictor frontend: response and design rows must agree"))
    x = hcat(_joint_missing_vector(x1), _joint_missing_vector(x2))
    prepared = prepared_joint_model(_joint_missing_vector(y), x, Xmu, Xsigma,
                                    (Xpredictor1, Xpredictor2);
                                    predictor = :gaussian, predictor_variables = variables,
                                    mu_names = mu_names, sigma_names = sigma_names,
                                    predictor_names = (predictor_names1, predictor_names2),
                                    original_row = collect(1:n))
    return JointTwoDrmFit(fit_prepared_joint(prepared; g_tol = g_tol), f, variables)
end

"""
    _fit_joint_formula(f, data; impute, missing, ...)

Build a prepared exact joint model from one Gaussian response formula containing
one or two bare additive `mi(x)` mean terms. This deliberately partial frontend
admits fixed Gaussian ML responses with complete remaining covariates. The
one-predictor route permits Gaussian or Bernoulli predictor models; the
two-predictor route requires two independent Gaussian predictor models. It
neither drops rows nor fills modelled predictors before fitting.
"""
function _fit_joint_formula(f::DrmFormula, data;
                            impute = nothing,
                            missing = miss_control(),
                            g_tol::Real = 1e-8,
                            method::Symbol = :ML,
                            algorithm::Symbol = :auto,
                            K = nothing,
                            A = nothing,
                            tree = nothing,
                            coords = nothing,
                            profile_ci::Bool = false,
                            phylo_coupled::Bool = false,
                            penalty = nothing,
                            sparse = nothing)
    rhs_for_route = Dict(f.forms)
    if haskey(rhs_for_route, :mu) && _joint_mi_count(rhs_for_route[:mu]) == 2
        return _fit_two_joint_formula(f, data; impute = impute, missing = missing,
            g_tol = g_tol, method = method, algorithm = algorithm, K = K, A = A,
            tree = tree, coords = coords, profile_ci = profile_ci,
            phylo_coupled = phylo_coupled, penalty = penalty, sparse = sparse)
    end
    f.response2 === nothing || throw(ArgumentError("joint missing-predictor frontend: bivariate responses are not implemented"))
    _joint_refuse_nondefault(method, algorithm, K, A, tree, coords, profile_ci, phylo_coupled, penalty, sparse)
    missing isa JointMissingControl ||
        throw(ArgumentError("joint missing-predictor frontend: `missing` must be created with miss_control(...)"))
    missing.response in (:fail, :include) ||
        throw(ArgumentError("joint missing-predictor frontend: response control must be :fail or :include"))
    missing.predictor === :model ||
        throw(ArgumentError("joint missing-predictor frontend: use `missing = miss_control(predictor = \"model\")`"))
    isfinite(g_tol) && g_tol > 0 || throw(ArgumentError("joint missing-predictor frontend: `g_tol` must be finite and positive"))

    rhs = Dict(f.forms)
    Set(keys(rhs)) == Set((:mu, :sigma)) ||
        throw(ArgumentError("joint missing-predictor frontend: only `mu` and `sigma` formulas are implemented"))
    variable, fixed_mu = _joint_mean_parts(rhs[:mu])
    variable !== f.response || throw(ArgumentError(
        "joint missing-predictor frontend: response and modelled predictor must be different variables"))
    _joint_require_exogenous(fixed_mu, f.response, variable, "the mean design")
    _joint_require_exogenous(rhs[:sigma], f.response, variable, "the sigma design")
    _joint_contains_mi(rhs[:sigma]) &&
        throw(ArgumentError("joint missing-predictor frontend: `mi()` is valid on the mean formula only, not `sigma`"))
    _joint_validate_fixed_rhs(rhs[:sigma], "sigma formula")
    _joint_require_complete_rhs(fixed_mu, data, "the mean design")
    _joint_require_complete_rhs(rhs[:sigma], data, "the sigma design")

    spec = _joint_impute_spec(impute, variable)
    _joint_require_exogenous(spec.formula.rhs, f.response, variable, "the predictor design")
    _joint_validate_fixed_rhs(spec.formula.rhs, "the predictor model")
    _joint_require_complete_rhs(spec.formula.rhs, data, "the predictor design")
    predictor = spec.family isa Gaussian ? :gaussian : spec.family isa Binomial ? :bernoulli :
        throw(ArgumentError("joint missing-predictor frontend: predictor family must be Gaussian() or Binomial()"))

    y, Xmu, mu_names = _design(f.response, fixed_mu, data)
    missing.response === :fail && any(isnan, y) &&
        throw(ArgumentError("joint missing-predictor frontend: response has missing values; use `miss_control(response = \"include\", predictor = \"model\")`"))
    _, Xsigma, sigma_names = _design(f.response, rhs[:sigma], data)
    x, Xpredictor, predictor_names = _design(variable, spec.formula.rhs, data)
    size(Xmu, 2) > 0 ||
        throw(ArgumentError("joint missing-predictor frontend: `0 + mi($variable)` leaves a zero-width mean design, which the prepared engine does not support"))
    n = length(y)
    length(x) == n && size(Xmu, 1) == n && size(Xsigma, 1) == n && size(Xpredictor, 1) == n ||
        throw(ArgumentError("joint missing-predictor frontend: response and design rows must agree"))
    prepared = prepared_joint_model(_joint_missing_vector(y), _joint_missing_vector(x), Xmu, Xsigma, Xpredictor;
                                    predictor = predictor, mu_names = mu_names, sigma_names = sigma_names,
                                    predictor_names = predictor_names, original_row = collect(1:n))
    return JointDrmFit(fit_prepared_joint(prepared; g_tol = g_tol), f, variable)
end

"""All raw fitted coefficients in the prepared-engine order."""
coef(fit::JointDrmFit) = coef(fit.prepared.fit)

"""
    coef(fit::JointDrmFit, parameter)

`:mi_<variable>` maps to the internal predictor-model block. For a Gaussian predictor, `:sigma_mi_<variable>` returns
the natural predictor SD, while `:logsd_mi_<variable>` returns its raw
log-covariance coordinate.
"""
function coef(fit::JointDrmFit, parameter::Symbol)
    mi_name = Symbol(:mi_, fit.variable)
    raw_sd_name = Symbol(:logsd_mi_, fit.variable)
    natural_sd_name = Symbol(:sigma_mi_, fit.variable)
    if parameter === mi_name
        return coef(fit.prepared.fit, :mi_x)
    elseif parameter === raw_sd_name
        return coef(fit.prepared.fit, :logsd_mi_x)
    elseif parameter === natural_sd_name
        fit.prepared.prepared.predictor === :gaussian ||
            throw(ArgumentError("joint missing-predictor frontend: Bernoulli `$((fit.variable))` has no predictor SD"))
        return exp.(coef(fit.prepared.fit, :logsd_mi_x))
    end
    return coef(fit.prepared.fit, parameter)
end

vcov(fit::JointDrmFit) = vcov(fit.prepared.fit)
loglik(fit::JointDrmFit) = loglik(fit.prepared.fit)
nobs(fit::JointDrmFit) = nobs(fit.prepared.fit)
is_converged(fit::JointDrmFit) = is_converged(fit.prepared.fit)
niterations(fit::JointDrmFit) = niterations(fit.prepared.fit)
family(::JointDrmFit) = Gaussian()

"""Conditional imputation for the marker variable in a formula-based joint fit."""
function imputed(fit::JointDrmFit; variable = nothing, rows = :missing, se::Bool = true)
    requested = variable isa AbstractString ? Symbol(variable) : variable
    requested === nothing || requested isa Symbol ||
        throw(ArgumentError("joint missing-predictor frontend: `variable` must be a Symbol, String, or nothing"))
    requested === nothing || requested === fit.variable ||
        throw(ArgumentError("joint missing-predictor frontend: this fit models `$(fit.variable)`, not `$variable`"))
    return _imputed_joint(fit.prepared, fit.variable; rows = rows, se = se)
end

"""All raw fitted coefficients in the two-predictor prepared-engine order."""
coef(fit::JointTwoDrmFit) = coef(fit.prepared.fit)

function coef(fit::JointTwoDrmFit, parameter::Symbol)
    for variable in fit.variables
        mi_name = Symbol(:mi_, variable)
        raw_sd_name = Symbol(:logsd_mi_, variable)
        natural_sd_name = Symbol(:sigma_mi_, variable)
        if parameter === mi_name || parameter === raw_sd_name
            return coef(fit.prepared.fit, parameter)
        elseif parameter === natural_sd_name
            return exp.(coef(fit.prepared.fit, raw_sd_name))
        end
    end
    return coef(fit.prepared.fit, parameter)
end

# Keep the covariance on raw coordinates. In particular, logtau coordinates
# are not delta-transformed merely because `coef(..., :sigma_mi_*)` is natural.
vcov(fit::JointTwoDrmFit) = vcov(fit.prepared.fit)
loglik(fit::JointTwoDrmFit) = loglik(fit.prepared.fit)
nobs(fit::JointTwoDrmFit) = nobs(fit.prepared.fit)
is_converged(fit::JointTwoDrmFit) = is_converged(fit.prepared.fit)
niterations(fit::JointTwoDrmFit) = niterations(fit.prepared.fit)
family(::JointTwoDrmFit) = Gaussian()

"""Conditional imputation for one explicitly selected two-predictor marker variable."""
function imputed(fit::JointTwoDrmFit; variable = nothing, rows = :missing, se::Bool = true)
    requested = variable isa AbstractString ? Symbol(variable) : variable
    requested isa Symbol ||
        throw(ArgumentError("joint missing-predictor frontend: two-predictor fits require `variable`"))
    requested in fit.variables ||
        throw(ArgumentError("joint missing-predictor frontend: this fit models `$(fit.variables[1])` and `$(fit.variables[2])`, not `$variable`"))
    return imputed(fit.prepared; variable = requested, rows = rows, se = se)
end
