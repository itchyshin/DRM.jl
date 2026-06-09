# bridge.jl — primitive R-facing boundary for `drmTMB(..., engine = "julia")`.
#
# The public R glue lives in the drmTMB repository. This file keeps the Julia
# side deliberately boring for JuliaCall: strings, column tables, plain arrays,
# and dictionaries cross the boundary; DRM.jl objects stay on the Julia side.

const _BRIDGE_BIVARIATE_KEYS = Set((:mu1, :mu2, :sigma1, :sigma2, :rho12))
const _BRIDGE_TREE_CACHE = Dict{UInt64,Tuple{String,Any}}()
const _BRIDGE_TREE_CACHE_MAX = 4

"""
    drm_bridge(; formula, family, data, tree = nothing, K = nothing,
               A = nothing, coords = nothing, options = Dict())

Fit a DRM.jl model through a marshalling-friendly boundary for R callers.
`formula` may be a semicolon-separated string such as
`"y ~ x; sigma ~ x"` or a dictionary / named tuple whose values are formula
strings. `family` is a string such as `"gaussian"`, `"student"`, `"nbinom2"`,
or `"biv_gaussian"`. `data` is a column table, dictionary, or named tuple.

The return value is a `Dict{String,Any}` made of primitive R-reconstructable
pieces: named coefficients, covariance matrix, likelihood summaries, fitted
values, residuals, scales, and residual correlations when present.
"""
function drm_bridge(; formula, family::AbstractString, data, tree = nothing,
        K = nothing, A = nothing, coords = nothing, options = Dict{String,Any}())
    dat = _bridge_data(data)
    bundle = _bridge_formula(formula, family)
    fam = _bridge_family(family)
    opts = _bridge_options(options)
    fit = _bridge_fit(bundle, fam, dat; tree = tree, K = K, A = A,
                      coords = coords, options = opts)
    return _bridge_flatten(fit; family = String(family))
end

"""
    drm_bridge_inference(; formula, family, data, tree = nothing,
                         options = Dict(), method = "profile",
                         level = 0.95, B = 199, seed = nothing,
                         threads = false)

Run a narrow inference primitive for the R bridge. This first slice is limited
to the Gaussian phylogenetic SD block (`param = :resd`), because the R side
needs explicit response-scale transforms and parity checks before exposing
broader Julia inference results.
"""
function drm_bridge_inference(; formula, family::AbstractString, data,
        tree = nothing, options = Dict{String,Any}(), method::AbstractString = "profile",
        level::Real = 0.95, B::Integer = 199, seed = nothing,
        threads::Bool = false)
    dat = _bridge_data(data)
    bundle = _bridge_formula(formula, family)
    fam = _bridge_family(family)
    opts = _bridge_options(options)
    tree_obj = tree === nothing ? nothing : _bridge_tree(tree)
    fit = _bridge_fit(bundle, fam, dat; tree = tree_obj, K = nothing,
                      A = nothing, coords = nothing, options = opts)

    bridge_method = lowercase(strip(String(method)))
    if bridge_method == "profile"
        result = profile_result(fit; level = level, threads = threads, parm = :resd)
        row = _bridge_first_param_row(result.ci, :resd)
        return _bridge_inference_flatten(
            row;
            method = "profile",
            status = "profile",
            attempted = result.attempted,
            used = result.used,
            failed = result.failed,
            elapsed = result.elapsed,
            threaded = result.threaded,
            worker_threads = result.worker_threads,
            julia_threads = result.julia_threads,
            blas_threads = result.blas_threads,
            message = "profile_result completed",
        )
    elseif bridge_method == "bootstrap"
        rng = seed === nothing ? Random.default_rng() :
              Random.MersenneTwister(Int(seed))
        result = bootstrap_result(
            fit; data = dat, B = Int(B), level = level, rng = rng,
            tree = tree_obj, threads = threads, failures = :skip,
            check_converged = false,
            algorithm = Symbol(get(opts, :algorithm, :auto)),
            g_tol = Float64(get(opts, :g_tol, 1e-8)),
        )
        row = _bridge_first_param_row(result.summary, :resd)
        return _bridge_inference_flatten(
            row;
            method = "bootstrap",
            status = result.used >= 2 ? "bootstrap" : "bootstrap_unavailable",
            attempted = result.attempted,
            used = result.used,
            failed = result.failed,
            elapsed = result.elapsed,
            threaded = result.threaded,
            worker_threads = result.worker_threads,
            julia_threads = result.julia_threads,
            blas_threads = result.blas_threads,
            message = "$(result.used)/$(result.attempted) successful refits",
        )
    end
    throw(ArgumentError("drm_bridge_inference: unsupported method `$method`"))
end

function _bridge_fit(bundle, fam, data; tree, K, A, coords, options)
    kwargs = Dict{Symbol,Any}()
    tree !== nothing && (kwargs[:tree] = _bridge_tree(tree))
    K !== nothing && (kwargs[:K] = K)
    A !== nothing && (kwargs[:A] = A)
    coords !== nothing && (kwargs[:coords] = coords)
    if haskey(options, :g_tol)
        kwargs[:g_tol] = Float64(options[:g_tol])
    end
    if haskey(options, :algorithm)
        kwargs[:algorithm] = Symbol(options[:algorithm])
    end
    if haskey(options, :method)
        kwargs[:method] = Symbol(options[:method])
    end
    if haskey(options, :se)
        kwargs[:se] = Bool(options[:se])
    end
    return drm(bundle, fam; data = data, kwargs...)
end

function _bridge_tree(tree)
    tree isa AbstractString || return tree
    key = hash(String(tree))
    cached = get(_BRIDGE_TREE_CACHE, key, nothing)
    if cached !== nothing && cached[1] == tree
        return cached[2]
    end
    parsed = augmented_phy(tree)
    if length(_BRIDGE_TREE_CACHE) >= _BRIDGE_TREE_CACHE_MAX
        empty!(_BRIDGE_TREE_CACHE)
    end
    _BRIDGE_TREE_CACHE[key] = (String(tree), parsed)
    return parsed
end

function _bridge_options(options)
    options === nothing && return Dict{Symbol,Any}()
    if options isa NamedTuple
        return Dict{Symbol,Any}(Symbol(k) => v for (k, v) in pairs(options))
    elseif options isa AbstractDict
        return Dict{Symbol,Any}(Symbol(String(k)) => v for (k, v) in pairs(options))
    end
    throw(ArgumentError("drm_bridge: `options` must be a dictionary or named tuple"))
end

function _bridge_data(data)
    if data isa NamedTuple
        return NamedTuple(Symbol(k) => _bridge_column(v) for (k, v) in pairs(data))
    elseif data isa AbstractDict
        return NamedTuple(Symbol(String(k)) => _bridge_column(v) for (k, v) in pairs(data))
    end
    return data
end

_bridge_column(v::AbstractVector) = collect(v)
_bridge_column(v) = v

function _bridge_family(family::AbstractString)
    fam = lowercase(strip(String(family)))
    fam in ("gaussian", "normal") && return Gaussian()
    fam in ("biv_gaussian", "gaussian_bivariate", "bivariate_gaussian") && return Gaussian()
    fam in ("student", "student_t", "student-t") && return Student()
    fam == "poisson" && return Poisson()
    fam in ("nbinom2", "negbinomial2", "negative_binomial_2") && return NegBinomial2()
    fam in ("truncated_nbinom2", "truncated_negbinomial2") && return TruncatedNegBinomial2()
    fam == "beta" && return Beta()
    fam in ("beta_binomial", "betabinomial") && return BetaBinomial()
    fam == "binomial" && return Binomial()
    fam == "gamma" && return Gamma()
    fam == "lognormal" && return LogNormal()
    fam in ("zero_one_beta", "zeroonebeta") && return ZeroOneBeta()
    fam == "tweedie" && return Tweedie()
    fam in ("cumulative_logit", "ordinal") && return CumulativeLogit()
    throw(ArgumentError("drm_bridge: unsupported family `$family`"))
end

function _bridge_formula(formula, family::AbstractString)
    parts = _bridge_formula_parts(formula)
    parsed = map(_bridge_parse_formula_part, parts)
    any(isnothing, parsed) &&
        throw(ArgumentError("drm_bridge: could not parse formula specification"))

    keyed = Dict{Symbol,Any}()
    positional = Any[]
    for item in parsed
        key, form = item
        if key === nothing
            push!(positional, form)
        else
            keyed[key] = form
        end
    end

    if any(k -> k in _BRIDGE_BIVARIATE_KEYS, keys(keyed))
        (isempty(positional) && haskey(keyed, :mu1) && haskey(keyed, :mu2)) ||
            throw(ArgumentError("drm_bridge: bivariate formulas need keyed `mu1` and `mu2` entries"))
        return bf(; mu1 = keyed[:mu1],
                    mu2 = keyed[:mu2],
                    sigma1 = get(keyed, :sigma1, nothing),
                    sigma2 = get(keyed, :sigma2, nothing),
                    rho12 = get(keyed, :rho12, nothing))
    end

    if !isempty(keyed)
        isempty(positional) ||
            throw(ArgumentError("drm_bridge: do not mix keyed and positional univariate formulas"))
        haskey(keyed, :mu) ||
            throw(ArgumentError("drm_bridge: keyed univariate formulas need a `mu` entry"))
        ordered = Any[keyed[:mu]]
        for p in (:sigma, :nu, :zi, :hu, :zoi, :coi)
            haskey(keyed, p) && push!(ordered, keyed[p])
        end
        return bf(ordered...)
    end
    isempty(positional) &&
        throw(ArgumentError("drm_bridge: at least one formula is required"))
    return bf(positional...)
end

function _bridge_formula_parts(formula)
    if formula isa AbstractString
        return filter(!isempty, strip.(split(String(formula), ';')))
    elseif formula isa NamedTuple
        return ["$(String(k)) = $(v)" for (k, v) in pairs(formula)]
    elseif formula isa AbstractDict
        return ["$(String(k)) = $(v)" for (k, v) in pairs(formula)]
    elseif formula isa AbstractVector
        return String.(formula)
    end
    throw(ArgumentError("drm_bridge: `formula` must be a string, vector of strings, dictionary, or named tuple"))
end

function _bridge_parse_formula_part(part::AbstractString)
    expr = Meta.parse(part)
    if expr isa Expr && expr.head === :(=)
        length(expr.args) == 2 || return nothing
        key = expr.args[1]
        key isa Symbol || return nothing
        form = _bridge_formula_from_expr(expr.args[2])
        form === nothing && return nothing
        return key => form
    end
    form = _bridge_formula_from_expr(expr)
    form === nothing && return nothing
    return nothing => form
end

function _bridge_formula_from_expr(expr)
    (expr isa Expr && expr.head === :call && expr.args[1] === :~) || return nothing
    return eval(Expr(:macrocall, Symbol("@formula"), LineNumberNode(0), expr))
end

function _bridge_flatten(fit; family::AbstractString)
    cnames, cvals = _bridge_coef_vector(fit)
    V = Matrix{Float64}(vcov(fit))
    return Dict{String,Any}(
        "family" => String(family),
        "coef_names" => cnames,
        "coefficients" => cvals,
        "coef" => Dict(cnames .=> cvals),
        "vcov" => V,
        "vcov_names" => cnames,
        "loglik" => loglik(fit),
        "aic" => aic(fit),
        "bic" => bic(fit),
        "df" => dof(fit),
        "nobs" => nobs(fit),
        "converged" => is_converged(fit),
        "fitted" => _bridge_plain(fitted(fit)),
        "residuals" => _bridge_plain(residuals(fit)),
        "sigma" => _bridge_plain(sigma(fit)),
        "corpairs" => _bridge_plain(corpairs(fit)),
    )
end

function _bridge_coef_vector(fit)
    θ = coef(fit)
    namemap = Dict(p => ns for (p, ns) in fit.coefnames)
    names = String[]
    vals = Float64[]
    for (param, r) in fit.blocks
        haskey(namemap, param) || continue
        pnames = namemap[param]
        length(pnames) == length(r) ||
            error("drm_bridge: coefficient-name mismatch for `$param`")
        for (nm, idx) in zip(pnames, r)
            push!(names, "$(param)_$(nm)")
            push!(vals, θ[idx])
        end
    end
    return names, vals
end

_bridge_plain(x::AbstractVector) = collect(x)
_bridge_plain(x::AbstractMatrix) = Matrix(x)
function _bridge_plain(x::AbstractDict)
    return Dict(String(k) => _bridge_plain(v) for (k, v) in pairs(x))
end
_bridge_plain(x) = x

function _bridge_first_param_row(rows, param::Symbol)
    for row in rows
        row.param === param && return row
    end
    throw(ArgumentError("drm_bridge_inference: result has no `$param` row"))
end

function _bridge_inference_flatten(row; method::AbstractString,
        status::AbstractString, attempted::Integer, used::Integer,
        failed::Integer, elapsed::Real, threaded::Bool,
        worker_threads::Integer, julia_threads::Integer,
        blas_threads::Integer, message::AbstractString)
    return Dict{String,Any}(
        "method" => String(method),
        "param" => String(row.param),
        "coef" => String(row.coef),
        "estimate" => row.estimate,
        "lower" => row.lower,
        "upper" => row.upper,
        "status" => String(status),
        "message" => String(message),
        "attempted" => Int(attempted),
        "used" => Int(used),
        "failed" => Int(failed),
        "elapsed" => Float64(elapsed),
        "threaded" => Bool(threaded),
        "worker_threads" => Int(worker_threads),
        "julia_threads" => Int(julia_threads),
        "blas_threads" => Int(blas_threads),
    )
end
