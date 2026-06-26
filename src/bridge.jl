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
    drm_bridge_q2_phylo(; Y, X, species, tree, options = Dict())

Private diagnostic boundary for the restricted q2 phylogenetic coevolution
point export. This intentionally bypasses the public formula bridge because the
general-q coevolution model is diagonal-residual Gaussian evidence, not the full
bivariate `rho12` q2 route. The return payload is the same primitive dictionary
shape consumed by the row-contract tests.
"""
function drm_bridge_q2_phylo(; Y, X, species, tree, options = Dict{String,Any}())
    y = Matrix{Float64}(Y)
    x = Matrix{Float64}(X)
    sp = Int.(vec(species))
    size(y, 2) == 2 ||
        throw(ArgumentError("drm_bridge_q2_phylo: `Y` must have exactly two columns"))
    size(x, 1) == size(y, 1) ||
        throw(ArgumentError("drm_bridge_q2_phylo: `X` and `Y` must have the same number of rows"))
    length(sp) == size(y, 1) ||
        throw(ArgumentError("drm_bridge_q2_phylo: `species` length must match the number of rows in `Y`"))
    phy = _bridge_tree(tree)
    all(1 .<= sp .<= phy.n_leaves) ||
        throw(ArgumentError("drm_bridge_q2_phylo: `species` must contain 1-based tip indices"))
    opts = _bridge_options(options)
    prob, Q_cond = make_coevo_problem(phy, y, x; species = sp)
    fit = fit_coevolution(
        prob,
        Q_cond;
        iterations = Int(get(opts, :iterations, 180)),
        g_tol = Float64(get(opts, :g_tol, 1e-4)),
        fd_h = Float64(get(opts, :fd_h, 1e-6)),
    )
    return _bridge_q2_point_export(fit; family = "biv_gaussian",
                                   structured_type = "phylo")
end

"""
    drm_bridge_q2_known_precision(; Y, X, group, Q,
                                  structured_type = "relmat",
                                  precision_source = nothing,
                                  options = Dict())

Private diagnostic boundary for a restricted q2 known-precision provider payload.
This consumes `Q` as a precision matrix directly through
`make_coevo_problem_from_precision`; it does not invert or relabel `Q` as a
covariance matrix, and it does not imply formula, slope, REML, or interval
support. Provider identity is deliberately narrow: `structured_type = "relmat"`
records `precision_source = "Q"`, while `structured_type = "animal"` records
`precision_source = "Ainv"`.
"""
function drm_bridge_q2_known_precision(; Y, X, group, Q,
        structured_type = "relmat", precision_source = nothing,
        options = Dict{String,Any}())
    y = Matrix{Float64}(Y)
    x = Matrix{Float64}(X)
    g = Int.(vec(group))
    qmat = Matrix{Float64}(Q)
    st, source = _bridge_q2_known_precision_provider(structured_type,
                                                     precision_source)
    size(y, 2) == 2 ||
        throw(ArgumentError("drm_bridge_q2_known_precision: `Y` must have exactly two columns"))
    size(x, 1) == size(y, 1) ||
        throw(ArgumentError("drm_bridge_q2_known_precision: `X` and `Y` must have the same number of rows"))
    length(g) == size(y, 1) ||
        throw(ArgumentError("drm_bridge_q2_known_precision: `group` length must match the number of rows in `Y`"))
    opts = _bridge_options(options)
    prob, Q_cond = make_coevo_problem_from_precision(qmat, y, x; group = g)
    fit = fit_coevolution_q2_residual(
        prob,
        Q_cond;
        iterations = Int(get(opts, :iterations, 180)),
        g_tol = Float64(get(opts, :g_tol, 1e-4)),
        fd_h = Float64(get(opts, :fd_h, 1e-6)),
    )
    out = _bridge_q2_point_export(
        fit;
        family = "biv_gaussian",
        structured_type = st,
    )
    out["input_scale"] = "precision"
    out["precision_source"] = source
    out["precision_matrix"] = qmat
    out["claim_boundary"] = join((
        "Direct q2 $st known-precision point export only for complete-response",
        "exact-Gaussian ML fixtures; `$source` is consumed as a precision",
        "matrix without implicit precision-to-covariance conversion. No",
        "R-via-Julia formula support, structured slope support, broad q2",
        "bridge support, q2 REML, q4, AI-REML, interval reliability, or",
        "interval coverage is promoted.",
    ), " ")
    return out
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
    if haskey(options, :phylo_coupled)
        kwargs[:phylo_coupled] = Bool(options[:phylo_coupled])
    end
    if _bridge_is_bivariate_phylo_q4(bundle, fam, tree) && !haskey(options, :q4_vcov)
        # The bridge's q4 uncertainty route is profile/bootstrap over among-axis
        # SDs. Avoid the auxiliary finite-difference Wald covariance by default:
        # it is expensive at large q4 phylogenetic fits and can fail after a
        # usable fit has been found.
        kwargs[:q4_vcov] = false
    end
    if haskey(options, :q4_g_tol)
        kwargs[:q4_g_tol] = Float64(options[:q4_g_tol])
    end
    if haskey(options, :q4_iterations)
        kwargs[:q4_iterations] = Int(options[:q4_iterations])
    end
    if haskey(options, :q4_n_newton)
        kwargs[:q4_n_newton] = Int(options[:q4_n_newton])
    end
    if haskey(options, :q4_vcov)
        kwargs[:q4_vcov] = Bool(options[:q4_vcov])
    end
    return drm(bundle, fam; data = data, kwargs...)
end

function _bridge_is_bivariate_phylo_q4(bundle, fam, tree)
    return bundle isa BivariateDrmFormula && fam isa Gaussian && tree !== nothing
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
    out = Dict{String,Any}(
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
    q4_point_export = _bridge_q4_point_export(fit; family = family)
    if !isempty(q4_point_export)
        out["q4_point_export"] = q4_point_export
    end
    q2_point_export = _bridge_q2_point_export(fit; family = family)
    if !isempty(q2_point_export)
        out["q2_point_export"] = q2_point_export
    end
    return out
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

function _bridge_q4_point_export(fit; family::AbstractString)
    if !(fit.ranef isa NamedTuple) || !haskey(fit.ranef, :Sigma_a)
        return Dict{String,Any}()
    end
    Σ = Matrix{Float64}(fit.ranef.Sigma_a)
    size(Σ) == (4, 4) || return Dict{String,Any}()
    axes = haskey(fit.ranef, :axes) ? Tuple(fit.ranef.axes) :
        (:mu1, :mu2, :sigma1, :sigma2)
    length(axes) == 4 || return Dict{String,Any}()
    d = sqrt.(max.(diag(Σ), 0.0))
    R = Σ ./ (d * d')
    return Dict{String,Any}(
        "target" => "gaussian_q4_phylo",
        "dimension" => "q4",
        "family" => String(family),
        "estimator" => String(fit.estim_method),
        "axes" => String[String(axis) for axis in axes],
        "sigma_a_source" => "fit.ranef.Sigma_a",
        "sigma_a" => Σ,
        "sd" => Dict{String,Float64}(
            String(axes[i]) => Float64(d[i]) for i in eachindex(axes)
        ),
        "correlation" => R,
        "claim_boundary" => "Direct q4 point export only; no R-via-Julia q4 bridge parity, q4 REML, AI-REML, interval reliability, or interval coverage is promoted.",
    )
end

function _bridge_q2_point_export(fit; family::AbstractString = "biv_gaussian",
                                 structured_type::AbstractString = "phylo")
    export_type = fit isa DrmFit &&
                  fit.ranef isa NamedTuple &&
                  haskey(fit.ranef, :structured_type) ?
                  String(fit.ranef.structured_type) : String(structured_type)
    if fit isa DrmFit &&
       fit.ranef isa NamedTuple &&
       haskey(fit.ranef, :Sigma_a) &&
       size(fit.ranef.Sigma_a) == (2, 2)
        Σ = Matrix{Float64}(fit.ranef.Sigma_a)
        d = sqrt.(max.(diag(Σ), 0.0))
        R = Σ ./ (d * d')
        axes = haskey(fit.ranef, :axes) ? Tuple(fit.ranef.axes) : (:mu1, :mu2)
        residual_sd = Dict{String,Float64}(
            "mu1" => Float64(first(fit.scales[:sigma1])),
            "mu2" => Float64(first(fit.scales[:sigma2])),
        )
        boundary = "Direct q2 $(export_type) residual-correlation point export only for complete-response exact-Gaussian ML fixtures; R-via-Julia support is limited to route-specific q2 fixtures; no broad q2 bridge support, q2 REML, q4, AI-REML, interval reliability, or interval coverage is promoted."
        return Dict{String,Any}(
            "target" => "gaussian_q2_mu1_mu2_$(export_type)_residual_correlation",
            "dimension" => "q2",
            "family" => String(family),
            "structured_type" => export_type,
            "estimator" => String(fit.estim_method),
            "axes" => String[String(axis) for axis in axes],
            "sigma_a_source" => "fit.ranef.Sigma_a",
            "sigma_a" => Σ,
            "sd" => Dict{String,Float64}(
                String(axes[i]) => Float64(d[i]) for i in eachindex(axes)
            ),
            "correlation" => R,
            "residual_sd" => residual_sd,
            "residual_correlation" => Float64(first(fit.scales[:rho12])),
            "loglik" => Float64(loglik(fit)),
            "converged" => Bool(is_converged(fit)),
            "claim_boundary" => boundary,
        )
    end
    if !(fit isa NamedTuple) || !haskey(fit, :Λ)
        return Dict{String,Any}()
    end
    Σ = Matrix{Float64}(fit.Λ)
    size(Σ) == (2, 2) || return Dict{String,Any}()
    d = sqrt.(max.(diag(Σ), 0.0))
    R = Σ ./ (d * d')
    has_residual_correlation = haskey(fit, :residual_cov) && haskey(fit, :rho12)
    target_suffix = has_residual_correlation ?
        "residual_correlation" : "restricted_diagonal_residual"
    source = has_residual_correlation ?
        "fit_coevolution_q2_residual.Λ" : "fit_coevolution.Λ"
    boundary = has_residual_correlation ?
        "Direct q2 $(export_type) residual-correlation point export only for known-matrix complete-response exact-Gaussian ML fixtures; R-via-Julia support is limited to route-specific q2 fixtures; no broad q2 bridge support, q2 REML, q4, AI-REML, interval reliability, or interval coverage is promoted." :
        "Direct q2 $(export_type) restricted point export only for a diagonal-residual coevolution fixture; no R-via-Julia q2 bridge support, full q2 residual-correlation route, q2 REML, q4, interval reliability, or interval coverage is promoted."
    out = Dict{String,Any}(
        "target" => "gaussian_q2_mu1_mu2_$(export_type)_$(target_suffix)",
        "dimension" => "q2",
        "family" => String(family),
        "structured_type" => export_type,
        "estimator" => "ML",
        "axes" => ["mu1", "mu2"],
        "sigma_a_source" => source,
        "sigma_a" => Σ,
        "sd" => Dict{String,Float64}(
            "mu1" => Float64(d[1]),
            "mu2" => Float64(d[2]),
        ),
        "correlation" => R,
        "converged" => haskey(fit, :converged) ? Bool(fit.converged) : false,
        "claim_boundary" => boundary,
    )
    if haskey(fit, :σ_res)
        out["residual_sd"] = Dict{String,Float64}(
            "mu1" => Float64(fit.σ_res[1]),
            "mu2" => Float64(fit.σ_res[2]),
        )
    end
    if has_residual_correlation
        out["residual_correlation"] = Float64(fit.rho12)
    end
    if haskey(fit, :loglik)
        out["loglik"] = Float64(fit.loglik)
    end
    return out
end

_bridge_plain(x::AbstractVector) = collect(x)
_bridge_plain(x::AbstractMatrix) = Matrix(x)
function _bridge_plain(x::AbstractDict)
    return Dict(String(k) => _bridge_plain(v) for (k, v) in pairs(x))
end
_bridge_plain(x) = x

const _BRIDGE_Q2_DIRECT_STRUCTURED_TYPES = ("phylo", "spatial", "animal", "relmat")
const _BRIDGE_Q2_KNOWN_PRECISION_PROVIDERS = (
    (structured_type = "animal", precision_source = "Ainv"),
    (structured_type = "relmat", precision_source = "Q"),
)
const _BRIDGE_Q2_DIRECT_COEFFICIENT_ORDER = (
    "mu1:(Intercept)",
    "mu1:x",
    "mu2:(Intercept)",
    "mu2:x",
    "sd_mu1:structured(group)",
    "sd_mu2:structured(group)",
    "cor_mu1_mu2:structured(group)",
)

function _bridge_q2_known_precision_provider(structured_type, precision_source)
    st = lowercase(strip(String(structured_type)))
    expected_sources = Dict(
        "animal" => "Ainv",
        "relmat" => "Q",
    )
    haskey(expected_sources, st) ||
        throw(ArgumentError(
            "drm_bridge_q2_known_precision: `structured_type` must be `animal` or `relmat`",
        ))
    source = precision_source === nothing ? expected_sources[st] :
             String(precision_source)
    source == expected_sources[st] ||
        throw(ArgumentError(
            "drm_bridge_q2_known_precision: `precision_source` for `$st` must be `$(expected_sources[st])`",
        ))
    return st, source
end

function _bridge_q2_direct_export_schema()
    return (
        :target,
        :structured_type,
        :dimension,
        :route,
        :estimator,
        :coefficient_order,
        :direct_status,
        :bridge_status,
        :unavailable_reason,
        :claim_boundary,
        :next_gate,
    )
end

function _bridge_q2_known_precision_schema()
    return (
        :target,
        :structured_type,
        :dimension,
        :route,
        :estimator,
        :input_scale,
        :precision_source,
        :direct_status,
        :bridge_status,
        :claim_boundary,
        :next_gate,
    )
end

function _bridge_q2_direct_export_status()
    coefficient_order = join(_BRIDGE_Q2_DIRECT_COEFFICIENT_ORDER, ";")
    return Tuple(
        begin
            direct_status = structured_type == "phylo" ?
                "available_residual_correlation_point_export" :
                structured_type in ("animal", "relmat") ?
                    "available_known_covariance_residual_correlation_point_export" :
                    "available_fixed_covariance_residual_correlation_fixture"
            bridge_status = "experimental"
            unavailable_reason = if structured_type == "phylo"
                "Same-target q2 phylo residual-correlation direct export and narrow R-via-Julia bridge parity fixture exist for complete-response exact-Gaussian ML."
            elseif structured_type == "spatial"
                "Direct q2 spatial evidence and the R-via-Julia bridge are limited to a fixed-covariance fixture; the range-estimating spatial route remains unsupported."
            else
                "Direct q2 $(structured_type) residual-correlation export and narrow R-via-Julia bridge parity fixture exist for known-covariance exact-Gaussian ML."
            end
            claim_boundary = if structured_type == "phylo"
                "Direct q2 phylo residual-correlation point export is fixture evidence only; R-via-Julia bridge support is narrow fixture support; no broad q2 bridge support, q2 REML, q4, AI-REML, interval reliability, or interval coverage is promoted."
            elseif structured_type == "spatial"
                "Direct q2 spatial fixed-covariance fixture evidence is not a range-estimating spatial route; R-via-Julia bridge support is narrow fixture support; no broad q2 bridge support, q2 REML, q4, AI-REML, interval reliability, or interval coverage is promoted."
            else
                "Direct q2 $(structured_type) known-covariance residual-correlation point export is fixture evidence only; R-via-Julia bridge support is narrow fixture support; no broad q2 bridge support, q2 REML, q4, AI-REML, interval reliability, or interval coverage is promoted."
            end
            next_gate = structured_type == "spatial" ?
                "Keep aggregate q2 acceptance scoped to fixed-covariance spatial fixtures; range-estimating spatial remains outside this bridge." :
                "Keep aggregate q2 acceptance scoped to complete-response exact-Gaussian ML fixtures before widening to q2 REML, q4, or interval claims."
            (
            target = "gaussian_q2_mu1_mu2_$structured_type",
            structured_type = structured_type,
            dimension = "q2",
            route = "direct_drmjl",
            estimator = "ML",
            coefficient_order = coefficient_order,
            direct_status = direct_status,
            bridge_status = bridge_status,
            unavailable_reason = unavailable_reason,
            claim_boundary = claim_boundary,
            next_gate = next_gate,
            )
        end
        for structured_type in _BRIDGE_Q2_DIRECT_STRUCTURED_TYPES
    )
end

function _bridge_q2_known_precision_status()
    return Tuple(
        begin
            st = spec.structured_type
            source = spec.precision_source
            claim_boundary = join((
                "Direct q2 $st known-precision point export is private",
                "complete-response exact-Gaussian ML fixture evidence only;",
                "`$source` is consumed as a precision matrix without implicit",
                "precision-to-covariance conversion. No R-via-Julia formula",
                "support, structured slope support, broad q2 bridge support,",
                "q2 REML, q4, AI-REML, interval reliability, or interval",
                "coverage is promoted.",
            ), " ")
            next_gate = join((
                "Use only as a Julia-side precision payload target until",
                "formula routing, structured slope support, and row-specific",
                "R-via-Julia parity evidence exist.",
            ), " ")
            (
            target = "gaussian_q2_mu1_mu2_$(st)_known_precision",
            structured_type = st,
            dimension = "q2",
            route = "direct_drmjl_private",
            estimator = "ML",
            input_scale = "precision",
            precision_source = source,
            direct_status = "available_known_precision_residual_correlation_point_export",
            bridge_status = "private_diagnostic",
            claim_boundary = claim_boundary,
            next_gate = next_gate,
            )
        end
        for spec in _BRIDGE_Q2_KNOWN_PRECISION_PROVIDERS
    )
end

function _bridge_q2_validate_direct_export_status(rows)
    schema = _bridge_q2_direct_export_schema()
    expected_targets = Set(
        "gaussian_q2_mu1_mu2_$structured_type"
        for structured_type in _BRIDGE_Q2_DIRECT_STRUCTURED_TYPES
    )
    expected_order = join(_BRIDGE_Q2_DIRECT_COEFFICIENT_ORDER, ";")
    errors = String[]
    seen = Set{String}()
    for (i, row) in enumerate(rows)
        propertynames(row) == schema ||
            push!(errors, "row $i schema does not match q2 direct export schema")
        target = String(getproperty(row, :target))
        push!(seen, target)
        target in expected_targets ||
            push!(errors, "row $i target is not registered: $target")
        getproperty(row, :dimension) == "q2" ||
            push!(errors, "row $i dimension must be q2")
        getproperty(row, :route) == "direct_drmjl" ||
            push!(errors, "row $i route must be direct_drmjl")
        getproperty(row, :estimator) == "ML" ||
            push!(errors, "row $i estimator must be ML")
        getproperty(row, :coefficient_order) == expected_order ||
            push!(errors, "row $i coefficient order does not match the q2 contract")
        if getproperty(row, :structured_type) == "phylo"
            getproperty(row, :direct_status) == "available_residual_correlation_point_export" ||
                push!(errors, "row $i phylo direct_status must record the residual-correlation point export")
        elseif getproperty(row, :structured_type) == "spatial"
            getproperty(row, :direct_status) == "available_fixed_covariance_residual_correlation_fixture" ||
                push!(errors, "row $i spatial direct_status must record the fixed-covariance fixture boundary")
            occursin("not a range-estimating spatial route", getproperty(row, :claim_boundary)) ||
                push!(errors, "row $i spatial claim boundary must reject range-estimating route support")
        else
            getproperty(row, :direct_status) == "available_known_covariance_residual_correlation_point_export" ||
                push!(errors, "row $i direct_status must record known-covariance residual-correlation point export")
            occursin("known-covariance", getproperty(row, :claim_boundary)) ||
                push!(errors, "row $i claim boundary must name known-covariance fixture evidence")
        end
        getproperty(row, :bridge_status) == "experimental" ||
            push!(errors, "row $i bridge_status must remain experimental")
        occursin("no broad q2 bridge support", getproperty(row, :claim_boundary)) ||
            push!(errors, "row $i claim boundary must reject broad q2 bridge support")
    end
    missing = setdiff(expected_targets, seen)
    isempty(missing) ||
        push!(errors, "missing q2 direct targets: $(join(sort(collect(missing)), ","))")
    return (
        ok = isempty(errors),
        errors = Tuple(errors),
        n_rows = length(rows),
        schema = schema,
    )
end

function _bridge_q2_validate_known_precision_status(rows)
    schema = _bridge_q2_known_precision_schema()
    expected = Dict(
        spec.structured_type => spec.precision_source
        for spec in _BRIDGE_Q2_KNOWN_PRECISION_PROVIDERS
    )
    expected_targets = Set(
        "gaussian_q2_mu1_mu2_$(st)_known_precision"
        for st in keys(expected)
    )
    errors = String[]
    seen = Set{String}()
    for (i, row) in enumerate(rows)
        propertynames(row) == schema ||
            push!(errors, "row $i schema does not match q2 known-precision schema")
        target = String(getproperty(row, :target))
        push!(seen, target)
        target in expected_targets ||
            push!(errors, "row $i target is not registered: $target")
        st = String(getproperty(row, :structured_type))
        haskey(expected, st) ||
            push!(errors, "row $i structured_type is not a known-precision provider")
        getproperty(row, :dimension) == "q2" ||
            push!(errors, "row $i dimension must be q2")
        getproperty(row, :route) == "direct_drmjl_private" ||
            push!(errors, "row $i route must be direct_drmjl_private")
        getproperty(row, :estimator) == "ML" ||
            push!(errors, "row $i estimator must be ML")
        getproperty(row, :input_scale) == "precision" ||
            push!(errors, "row $i input_scale must be precision")
        if haskey(expected, st)
            getproperty(row, :precision_source) == expected[st] ||
                push!(errors, "row $i precision_source does not match $st")
        end
        getproperty(row, :direct_status) == "available_known_precision_residual_correlation_point_export" ||
            push!(errors, "row $i direct_status must record known-precision residual-correlation point export")
        getproperty(row, :bridge_status) == "private_diagnostic" ||
            push!(errors, "row $i bridge_status must remain private_diagnostic")
        occursin("No R-via-Julia formula support", getproperty(row, :claim_boundary)) ||
            push!(errors, "row $i claim boundary must reject formula support")
        occursin("structured slope support", getproperty(row, :claim_boundary)) ||
            push!(errors, "row $i claim boundary must reject structured slope support")
        occursin("broad q2 bridge support", getproperty(row, :claim_boundary)) ||
            push!(errors, "row $i claim boundary must reject broad q2 bridge support")
    end
    missing = setdiff(expected_targets, seen)
    isempty(missing) ||
        push!(errors, "missing q2 known-precision targets: $(join(sort(collect(missing)), ","))")
    return (
        ok = isempty(errors),
        errors = Tuple(errors),
        n_rows = length(rows),
        schema = schema,
    )
end

const _BRIDGE_Q4_DIRECT_AXES = ("mu1", "mu2", "sigma1", "sigma2")

function _bridge_q4_direct_export_schema()
    return (
        :target,
        :axis,
        :dimension,
        :route,
        :estimator,
        :direct_sd_target,
        :sigma_a_source,
        :direct_status,
        :bridge_status,
        :inference_status,
        :claim_boundary,
        :next_gate,
    )
end

function _bridge_q4_direct_export_status()
    return Tuple(
        (
            target = "gaussian_q4_phylo_sd_$axis",
            axis = axis,
            dimension = "q4",
            route = "direct_drmjl",
            estimator = "ML",
            direct_sd_target = "sd_$axis",
            sigma_a_source = "fit.ranef.Sigma_a",
            direct_status = "available_point_target",
            bridge_status = "experimental",
            inference_status = "point_target_only",
            claim_boundary = "Direct q4 export is a status contract for point SD targets only; no R-via-Julia q4 bridge parity, q4 REML, AI-REML, interval reliability, or interval coverage is promoted.",
            next_gate = "Compare same-target native R/TMB, direct DRM.jl, and R-via-Julia q4 point outputs before bridge parity.",
        )
        for axis in _BRIDGE_Q4_DIRECT_AXES
    )
end

function _bridge_q4_validate_direct_export_status(rows)
    schema = _bridge_q4_direct_export_schema()
    expected_targets = Set("gaussian_q4_phylo_sd_$axis" for axis in _BRIDGE_Q4_DIRECT_AXES)
    expected_sd_targets = Dict(axis => "sd_$axis" for axis in _BRIDGE_Q4_DIRECT_AXES)
    errors = String[]
    seen = Set{String}()
    for (i, row) in enumerate(rows)
        propertynames(row) == schema ||
            push!(errors, "row $i schema does not match q4 direct export schema")
        target = String(getproperty(row, :target))
        axis = String(getproperty(row, :axis))
        push!(seen, target)
        target in expected_targets ||
            push!(errors, "row $i target is not registered: $target")
        haskey(expected_sd_targets, axis) ||
            push!(errors, "row $i axis is not registered: $axis")
        getproperty(row, :dimension) == "q4" ||
            push!(errors, "row $i dimension must be q4")
        getproperty(row, :route) == "direct_drmjl" ||
            push!(errors, "row $i route must be direct_drmjl")
        getproperty(row, :estimator) == "ML" ||
            push!(errors, "row $i estimator must be ML")
        getproperty(row, :direct_sd_target) == get(expected_sd_targets, axis, "") ||
            push!(errors, "row $i direct_sd_target does not match axis")
        getproperty(row, :sigma_a_source) == "fit.ranef.Sigma_a" ||
            push!(errors, "row $i sigma_a_source must be fit.ranef.Sigma_a")
        getproperty(row, :direct_status) == "available_point_target" ||
            push!(errors, "row $i direct_status must be available_point_target")
        getproperty(row, :bridge_status) == "experimental" ||
            push!(errors, "row $i bridge_status must remain experimental")
        getproperty(row, :inference_status) == "point_target_only" ||
            push!(errors, "row $i inference_status must remain point_target_only")
        occursin("no R-via-Julia q4 bridge parity", getproperty(row, :claim_boundary)) ||
            push!(errors, "row $i claim boundary must reject bridge parity")
        occursin("interval coverage", getproperty(row, :claim_boundary)) ||
            push!(errors, "row $i claim boundary must reject interval coverage")
    end
    missing = setdiff(expected_targets, seen)
    isempty(missing) ||
        push!(errors, "missing q4 direct targets: $(join(sort(collect(missing)), ","))")
    return (
        ok = isempty(errors),
        errors = Tuple(errors),
        n_rows = length(rows),
        schema = schema,
    )
end

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

# Bivariate q=4 inference for the bridge: confidence intervals for the among-axis SDs
# (sd_mu1, sd_mu2, sd_sigma1, sd_sigma2) — these are boundary variance components, so the
# right tools are profile (default) and bootstrap, NOT Wald:
#   method = "profile"   -> profile_sigma_a  (hessian-free profile-likelihood CIs; a
#                           collapsed axis returns lower = 0, the honest no-signal interval)
#   method = "bootstrap" -> bootstrap_sigma_a (parametric percentile CIs + correlations)
#   method = "wald"      -> unavailable (the among-axis boundary Hessian is singular)
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
    elseif method == "profile"
        # PROFILE-likelihood CIs for the among-axis SDs — hessian-free, so valid exactly
        # where the boundary Hessian is singular (a collapsed axis returns lower = 0).
        # `fit` already carries the profile-ready stash (re.prob / re.Sigma_a / re.Q_cond
        # from gaussian_bivariate.jl), so no re-fit is needed.
        elapsed = @elapsed result = profile_sigma_a(fit; level = level)
        rows = result.summary
        return _bridge_inference_flatten_multi_profile(
            rows;
            method = "profile",
            status = "profile",
            attempted = length(rows), used = length(rows), failed = 0,
            elapsed = elapsed,
            message = "profile_sigma_a (hessian-free profile-likelihood CIs)")
    elseif method == "wald"
        throw(ArgumentError("drm_bridge_inference: `wald` CIs are not available for the " *
            "bivariate q=4 phylogenetic fit's among-axis SDs (boundary variance components — " *
            "the Hessian is singular at a collapsed axis); use method = \"profile\" (default) " *
            "or method = \"bootstrap\""))
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

# Profile rows carry (param, coef, estimate, lower, upper, deviance_floor, bounded) — NO
# std_error (a likelihood-ratio interval, not a Wald one), and `upper` may be Inf on a
# flat/collapsed axis. Emit std_error => NaN and carry the honest `bounded` flag so the R
# data.frame keeps the same columns as the bootstrap path.
function _bridge_inference_flatten_multi_profile(rows; method::AbstractString,
        status::AbstractString, attempted::Integer, used::Integer,
        failed::Integer, elapsed::Real, message::AbstractString)
    return Dict{String,Any}(
        "method" => String(method),
        "multi" => true,
        "param" => String[String(r.param) for r in rows],
        "coef" => String[String(r.coef) for r in rows],
        "estimate" => Float64[Float64(r.estimate) for r in rows],
        "std_error" => Float64[NaN for _ in rows],
        "lower" => Float64[Float64(r.lower) for r in rows],
        "upper" => Float64[Float64(r.upper) for r in rows],
        "bounded" => Bool[Bool(r.bounded) for r in rows],
        "status" => String(status),
        "message" => String(message),
        "attempted" => Int(attempted),
        "used" => Int(used),
        "failed" => Int(failed),
        "elapsed" => Float64(elapsed),
    )
end
