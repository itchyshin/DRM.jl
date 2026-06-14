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
    bridge_method = lowercase(strip(String(method)))
    is_biv = bundle isa BivariateDrmFormula
    # The univariate σ-phylo location-scale route precomputes its boundary-aware
    # profile CIs into the fit (it has no re-optimisable objective), so request them
    # at fit time for the profile method. The bivariate q=4 route has no such flag
    # (its drm method rejects `profile_ci`) — skip it there.
    (!is_biv && bridge_method == "profile") && (opts[:profile_ci] = true)
    tree_obj = tree === nothing ? nothing : _bridge_tree(tree)
    fit = _bridge_fit(bundle, fam, dat; tree = tree_obj, K = nothing,
                      A = nothing, coords = nothing, options = opts)

    # Bivariate q=4 phylogenetic fit: the uncertainty target is the four among-axis
    # SDs sqrt.(diag(Σ_a)), not a single SD row. The boundary makes the q4 profile
    # singular, so the route is the parametric bootstrap; return all four rows.
    if is_biv && fit.ranef isa NamedTuple && haskey(fit.ranef, :Sigma_a)
        return _bridge_bivariate_inference(fit, dat, bridge_method;
                                           B = B, level = level, seed = seed)
    end

    if bridge_method == "profile"
        # Profile ONLY the SD target the bridge returns (`_bridge_pick_sd_row`'s set),
        # not the full parameter vector — the bridge reports a single SD row, so
        # profiling the fixed effects too is wasted re-optimisation (#202 bridge perf).
        result = profile_result(fit; level = level, threads = threads,
                                parm = [:resd_sigma, :resd, :resd_mu])
        row = _bridge_pick_sd_row(result.ci)
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
        row = _bridge_pick_sd_row(result.summary)
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
    if haskey(options, :profile_ci)
        kwargs[:profile_ci] = Bool(options[:profile_ci])
    end
    return drm(bundle, fam; data = data, kwargs...)
end

# Pick the variance-component SD row from a profile/bootstrap result for the bridge: prefer the
# σ-phylo location-scale σ-axis SD (:resd_sigma), then the legacy phylo SD block (:resd), then
# the μ-axis SD (:resd_mu); fall back to the first row. (Routes the bridge inference to the SD
# that matters for the σ-phylo cell Ayumi needs.)
function _bridge_pick_sd_row(rows)
    for want in (:resd_sigma, :resd, :resd_mu)
        for row in rows
            row.param === want && return row
        end
    end
    isempty(rows) && throw(ArgumentError("drm_bridge_inference: no SD row in the result"))
    return first(rows)
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

# R model formulas write interactions with `:`, but Julia parses `:` as the
# RANGE operator, which has LOWER precedence than `+`. So `a + b + a:b` parses in
# Julia as `(a + b + a) : b` — mis-associating the `+` chain and, worse, pulling
# a trailing `phylo(1|g)` term inside a `FunctionTerm{Colon}` the engine can't
# read (Ayumi LS#2: `MethodError: |(::Int64, ::String)`). Julia's `&` has
# interaction-matching precedence (tighter than `+`), so rewrite `:` → `&` at the
# STRING level, before `Meta.parse`. A model-formula string never contains `::`.
function _bridge_translate_r_ops(part::AbstractString)
    occursin("::", part) && return part        # defensive: leave qualified names alone
    return replace(part, ':' => '&')
end

# R formula constructs `@formula` cannot evaluate as the R user intends: these
# bind to the wrong Julia object (`I` → `LinearAlgebra.I`) or are undefined
# (`poly`/`scale`/`factor`), so they crash with a raw Julia error; `^` (R
# crossing) would silently mis-model. Reject them with a clear message instead.
const _BRIDGE_REJECT_CALLS = Dict{Symbol,String}(
    :^ => "R crossing `(...)^k` is unsupported via engine=\"julia\"; expand it explicitly (e.g. `a + b + a:b`).",
    :I => "R `I(...)` is unsupported via engine=\"julia\"; precompute the column (e.g. add `x2 = x^2` to the data) and use it as a covariate.",
    :poly => "R `poly()` is unsupported via engine=\"julia\"; precompute the polynomial columns and pass them as covariates.",
    :scale => "R `scale()` is unsupported via engine=\"julia\"; precompute the standardized column and pass it as a covariate.",
    :factor => "R `factor()`/`as.factor()` is unsupported via engine=\"julia\"; make the column a factor before fitting so its contrasts match R.",
)

# Translate / validate the parsed formula tree before `@formula`. `:` is already
# `&` (handled at the string level); here we translate R's `- 1`/`- 0` intercept
# control and reject the crash/silent-mismodel constructs above. Markers
# (phylo/relmat/animal/spatial/meta_V/cbind) and StatsModels transforms
# (log/exp/…) pass through unchanged.
_bridge_xlate(x) = x
function _bridge_xlate(e::Expr)
    e.head === :call || return e
    f = e.args[1]
    if f === :-
        if length(e.args) == 3 && e.args[3] === 1
            return Expr(:call, :+, 0, _bridge_xlate(e.args[2]))   # `… - 1` → drop intercept
        elseif length(e.args) == 3 && e.args[3] === 0
            return _bridge_xlate(e.args[2])                        # `… - 0` → keep intercept
        end
        throw(ArgumentError("drmTMB(engine=\"julia\"): R term removal with `-` is unsupported; list the terms you want explicitly."))
    elseif !(f isa Symbol)
        throw(ArgumentError("drmTMB(engine=\"julia\"): unsupported formula function `$(f)`; precompute it as a covariate column."))
    elseif haskey(_BRIDGE_REJECT_CALLS, f)
        throw(ArgumentError("drmTMB(engine=\"julia\"): " * _BRIDGE_REJECT_CALLS[f]))
    end
    # Recurse into EVERY remaining call's arguments (`~`, `+`, `&`, `*`, `log`,
    # `phylo`, …) so a rejected construct nested at ANY depth — e.g. `I()` under
    # `*` (`x1 * I(x1^2)`) or under `log()` — is still caught, not only when it
    # sits directly under `~`/`+`/`&`.
    return Expr(:call, f, (_bridge_xlate(a) for a in e.args[2:end])...)
end

function _bridge_parse_formula_part(part::AbstractString)
    expr = Meta.parse(_bridge_translate_r_ops(part))
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
    expr = _bridge_xlate(expr)
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

# Bivariate q=4 inference for the bridge: the parametric bootstrap of the among-
# axis SDs (sd_mu1, sd_mu2, sd_sigma1, sd_sigma2). Profile is unavailable here —
# the boundary Hessian is singular — so we direct profile requests to bootstrap.
function _bridge_bivariate_inference(fit, dat, method::AbstractString;
                                     B::Integer, level::Real, seed)
    if method == "bootstrap"
        rng = seed === nothing ? Random.default_rng() :
              Random.MersenneTwister(Int(seed))
        result = bootstrap_result(fit; data = dat, B = Int(B), level = level,
                                  rng = rng, failures = :warn, check_converged = false)
        return _bridge_inference_flatten_multi(
            result.summary;
            method = "bootstrap",
            status = result.used >= 2 ? "bootstrap" : "bootstrap_unavailable",
            attempted = result.attempted, used = result.used, failed = result.failed,
            elapsed = result.elapsed,
            message = "$(result.used)/$(result.attempted) successful refits")
    elseif method == "profile" || method == "wald"
        throw(ArgumentError("drm_bridge_inference: `$method` CIs are not available for the " *
            "bivariate q=4 phylogenetic fit (the among-axis boundary Hessian is singular); " *
            "use method = \"bootstrap\" for the among-axis SD confidence intervals"))
    end
    throw(ArgumentError("drm_bridge_inference: unsupported method `$method`"))
end

# Multi-row payload for the bivariate route: param/coef/estimate/std_error/lower/
# upper come back as equal-length vectors so the R side reads them as a data.frame.
function _bridge_inference_flatten_multi(rows; method::AbstractString,
        status::AbstractString, attempted::Integer, used::Integer,
        failed::Integer, elapsed::Real, message::AbstractString)
    return Dict{String,Any}(
        "method" => String(method),
        "multi" => true,
        "param" => String[String(r.param) for r in rows],
        "coef" => String[String(r.coef) for r in rows],
        "estimate" => Float64[Float64(r.estimate) for r in rows],
        "std_error" => Float64[Float64(r.std_error) for r in rows],
        "lower" => Float64[Float64(r.lower) for r in rows],
        "upper" => Float64[Float64(r.upper) for r in rows],
        "status" => String(status),
        "message" => String(message),
        "attempted" => Int(attempted),
        "used" => Int(used),
        "failed" => Int(failed),
        "elapsed" => Float64(elapsed),
    )
end
