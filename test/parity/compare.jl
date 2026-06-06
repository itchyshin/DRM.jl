# compare.jl — pure numerical-parity comparison contract (no file I/O).
#
# This file is the heart of Workflow G (issue #17, deferred .jl code): it turns a
# DRM.jl fit and a drmTMB reference (`ParityExpected`) into a pass/fail verdict
# with human-readable failure strings. It is deliberately I/O-free so it can be
# unit-tested in full without any fixtures on disk — `loadfixture.jl` owns the
# TOML/CSV parsing.
#
# IMPORTANT (honesty / license): this code does NOT itself contain or imply any
# drmTMB parity claim. It only *compares* a DRM.jl fit to whatever expected
# numbers it is handed. Real drmTMB `expected.toml` fixtures are generated
# out-of-band by a maintainer with local R + drmTMB (see GENERATING.md); the
# always-on smoke test feeds it a DRM.jl self-consistency expected instead.

"""
    ParityExpected

A drmTMB (or self-consistency) reference for one parity case. All fields are
plain numbers/strings parsed from `expected.toml` (see `loadfixture.jl`) — no
DRM.jl objects — so this struct is the stable comparison contract.

Fields:
- `family::String` — family tag, e.g. `"gaussian"`.
- `coef::Dict{String,Float64}` — point estimates keyed by flat name
  `"<param>_<coefname>"`, e.g. `"mu_(Intercept)"`, `"sigma_x"`.
- `loglik::Float64` — reference maximised log-likelihood.
- `aic::Float64` — reference AIC (`-2·loglik + 2·df`).
- `df::Int` — number of estimated parameters.
- `n::Int` — number of observations.
- `vcov_order::Union{Nothing,Vector{String}}` — flat names giving the row/column
  order of `vcov` (nothing when no vcov is supplied).
- `vcov::Union{Nothing,Matrix{Float64}}` — reference covariance matrix in
  `vcov_order` order (nothing when not supplied).
- `tol::Dict{String,Float64}` — per-case tolerance overrides (`[tol]` block); any
  of `rtol_coef`, `atol_coef`, `rtol_vcov`, `atol_vcov`, `atol_loglik`,
  `atol_aic`.
"""
struct ParityExpected
    family::String
    coef::Dict{String,Float64}
    loglik::Float64
    aic::Float64
    df::Int
    n::Int
    vcov_order::Union{Nothing,Vector{String}}
    vcov::Union{Nothing,Matrix{Float64}}
    tol::Dict{String,Float64}
    # Optional group-level (location–scale) covariance reference: the grouping
    # factor name + any of "sd_mu", "sd_sigma", "cor" (in DRM.jl's convention —
    # the generator applies the drmTMB→DRM.jl reparameterisation, see GENERATING.md).
    ranef_group::Union{Nothing,String}
    ranef::Dict{String,Float64}
end

# Convenience constructor: vcov, ranef + tol default to nothing/empty.
function ParityExpected(; family::AbstractString, coef::AbstractDict, loglik::Real,
        aic::Real, df::Integer, n::Integer,
        vcov_order = nothing, vcov = nothing, tol = Dict{String,Float64}(),
        ranef_group = nothing, ranef = Dict{String,Float64}())
    ParityExpected(String(family),
        Dict{String,Float64}(String(k) => Float64(v) for (k, v) in coef),
        Float64(loglik), Float64(aic), Int(df), Int(n),
        vcov_order === nothing ? nothing : Vector{String}(String.(vcov_order)),
        vcov === nothing ? nothing : Matrix{Float64}(vcov),
        Dict{String,Float64}(String(k) => Float64(v) for (k, v) in tol),
        ranef_group === nothing ? nothing : String(ranef_group),
        Dict{String,Float64}(String(k) => Float64(v) for (k, v) in ranef))
end

"""
    drm_coef_named(fit) -> Dict{String,Float64}

Flatten a DRM.jl fit's coefficients into the fixture's flat naming
`"<param>_<coefname>"`. This is the bridge between DRM.jl's block layout
(`fit.blocks :: Vector{Pair{Symbol,UnitRange}}` + `fit.coefnames ::
Vector{Pair{Symbol,Vector{String}}}`) and the flat, order-independent name keys
in `expected.toml`.

For each block `param => range`, we look up the matching coefficient-name vector
in `fit.coefnames`, then zip those names with the `coef(fit)` slice for that
range, emitting `"\$(param)_\$(name)" => estimate`. So a Gaussian location–scale
fit with `mu ~ 1 + x`, `sigma ~ 1 + x` yields keys
`"mu_(Intercept)"`, `"mu_x"`, `"sigma_(Intercept)"`, `"sigma_x"`.
"""
function drm_coef_named(fit)::Dict{String,Float64}
    θ = coef(fit)
    namemap = Dict(p => ns for (p, ns) in fit.coefnames)
    out = Dict{String,Float64}()
    for (param, r) in fit.blocks
        haskey(namemap, param) || continue   # blocks without named coefs (rare) are skipped
        names = namemap[param]
        slice = θ[r]
        length(names) == length(slice) || error(
            "drm_coef_named: name/coef length mismatch for `$param` " *
            "($(length(names)) names vs $(length(slice)) coefs)")
        for (nm, est) in zip(names, slice)
            out["$(param)_$(nm)"] = est
        end
    end
    return out
end

# Resolve an effective tolerance: per-case override (`[tol]`) wins over default.
_tol(exp::ParityExpected, key::AbstractString, default::Float64) =
    get(exp.tol, String(key), default)

# Scalar within-tolerance check (relative OR absolute), mirroring `isapprox`.
_within(a, b, rtol, atol) = abs(a - b) <= max(atol, rtol * max(abs(a), abs(b)))

"""
    compare_fit(fit, expected::ParityExpected;
                rtol_coef=1e-4, atol_coef=1e-6,
                rtol_vcov=1e-3, atol_vcov=1e-8, atol_loglik=1e-4) -> (passed, failures)

Compare a DRM.jl `fit` against a `ParityExpected` reference under the README's
tolerance table. Returns a NamedTuple `(passed::Bool, failures::Vector{String})`
— it NEVER throws on a numerical mismatch; instead it accumulates a
human-readable line per failure of the form
`"<case quantity>: drmTMB=… DRM.jl=… |Δ|=… > tol"`.

Checks, in order:
1. metadata — `n` and `df` must match the fit.
2. coef — every expected coef name must exist in `drm_coef_named(fit)` and be
   within (`rtol_coef`, `atol_coef`). A missing name is itself a failure.
3. loglik — scalar, within `atol_loglik`.
4. aic — scalar (derived `-2·loglik + 2·df`), within `atol_loglik` by default
   (override with `[tol] atol_aic`).
5. vcov — if `expected.vcov` is supplied, reorder the fit's `vcov(fit)` to
   `expected.vcov_order` (using `drm_coef_named`'s ordering of the fit) and
   compare element-wise within (`rtol_vcov`, `atol_vcov`).

Per-case overrides from the fixture's `[tol]` block take precedence over the
keyword defaults (keys: `rtol_coef`, `atol_coef`, `rtol_vcov`, `atol_loglik`,
`atol_vcov`, `atol_aic`).
"""
function compare_fit(fit, expected::ParityExpected;
        rtol_coef::Real = 1e-4, atol_coef::Real = 1e-6,
        rtol_vcov::Real = 1e-3, atol_vcov::Real = 1e-8,
        atol_loglik::Real = 1e-4)

    failures = String[]

    rc = _tol(expected, "rtol_coef", Float64(rtol_coef))
    ac = _tol(expected, "atol_coef", Float64(atol_coef))
    rv = _tol(expected, "rtol_vcov", Float64(rtol_vcov))
    av = _tol(expected, "atol_vcov", Float64(atol_vcov))
    al = _tol(expected, "atol_loglik", Float64(atol_loglik))
    aa = _tol(expected, "atol_aic", al)

    got = drm_coef_named(fit)

    # 1. metadata.
    nfit = nobs(fit)
    nfit == expected.n ||
        push!(failures, "nobs: drmTMB=$(expected.n) DRM.jl=$(nfit)")
    dfit = dof(fit)
    dfit == expected.df ||
        push!(failures, "df: drmTMB=$(expected.df) DRM.jl=$(dfit)")

    # 2. coefficients — name-matched.
    for name in sort!(collect(keys(expected.coef)))
        want = expected.coef[name]
        if !haskey(got, name)
            push!(failures, "coef[$name]: expected name absent from DRM.jl fit " *
                "(have: $(join(sort!(collect(keys(got))), ", ")))")
            continue
        end
        have = got[name]
        if !_within(want, have, rc, ac)
            push!(failures, "coef[$name]: drmTMB=$(want) DRM.jl=$(have) " *
                "|Δ|=$(abs(want - have)) > (rtol=$(rc), atol=$(ac))")
        end
    end

    # 3. loglik.
    llh = loglik(fit)
    if !_within(expected.loglik, llh, 0.0, al)
        push!(failures, "loglik: drmTMB=$(expected.loglik) DRM.jl=$(llh) " *
            "|Δ|=$(abs(expected.loglik - llh)) > atol=$(al)")
    end

    # 4. aic (derived from loglik + df).
    aic_fit = -2 * llh + 2 * dof(fit)
    if !_within(expected.aic, aic_fit, 0.0, aa)
        push!(failures, "aic: drmTMB=$(expected.aic) DRM.jl=$(aic_fit) " *
            "|Δ|=$(abs(expected.aic - aic_fit)) > atol=$(aa)")
    end

    # 5. vcov (optional) — reorder fit's vcov to the expected name order.
    if expected.vcov !== nothing && expected.vcov_order !== nothing
        order = expected.vcov_order
        # Build the fit's flat-name → vcov-index map by walking blocks in order
        # (vcov rows/cols follow θ's ordering, same as drm_coef_named).
        fitnames = String[]
        namemap = Dict(p => ns for (p, ns) in fit.coefnames)
        for (param, r) in fit.blocks
            haskey(namemap, param) || continue
            for nm in namemap[param]
                push!(fitnames, "$(param)_$(nm)")
            end
        end
        idx = Dict(nm => i for (i, nm) in enumerate(fitnames))
        Vfit = vcov(fit)
        missing_names = [nm for nm in order if !haskey(idx, nm)]
        if !isempty(missing_names)
            push!(failures, "vcov: expected order names absent from DRM.jl fit: " *
                join(missing_names, ", "))
        else
            perm = [idx[nm] for nm in order]
            Vp = Vfit[perm, perm]
            k = length(order)
            if size(expected.vcov) != (k, k)
                push!(failures, "vcov: expected matrix is $(size(expected.vcov)) " *
                    "but order has $k names")
            else
                for i in 1:k, j in 1:k
                    want = expected.vcov[i, j]
                    have = Vp[i, j]
                    if !_within(want, have, rv, av)
                        push!(failures, "vcov[$(order[i]),$(order[j])]: " *
                            "drmTMB=$(want) DRM.jl=$(have) " *
                            "|Δ|=$(abs(want - have)) > (rtol=$(rv), atol=$(av))")
                    end
                end
            end
        end
    end

    # 6. group-level covariance (optional) — drmTMB VarCorr (reparam'd to DRM.jl
    # convention by the generator) vs DRM.jl's `vc(fit)` for the location–scale Λ.
    if expected.ranef_group !== nothing
        rr = _tol(expected, "rtol_ranef", 1e-3)
        ar = _tol(expected, "atol_ranef", 1e-6)
        V = vc(fit)
        gkey = Symbol(expected.ranef_group)
        if !haskey(V, gkey)
            push!(failures, "ranef[$(expected.ranef_group)]: group absent from DRM.jl fit " *
                "(have: $(join(string.(keys(V)), ", ")))")
        else
            Σ = V[gkey]
            sd_mu = sqrt(Σ[1, 1]); sd_sigma = sqrt(Σ[2, 2])
            cor = Σ[1, 2] / (sd_mu * sd_sigma)
            got_re = Dict("sd_mu" => sd_mu, "sd_sigma" => sd_sigma, "cor" => cor)
            for key in sort!(collect(keys(expected.ranef)))
                want = expected.ranef[key]
                if !haskey(got_re, key)
                    push!(failures, "ranef[$key]: unknown key (expected one of sd_mu, sd_sigma, cor)")
                    continue
                end
                have = got_re[key]
                if !_within(want, have, rr, ar)
                    push!(failures, "ranef[$key]: drmTMB=$(want) DRM.jl=$(have) " *
                        "|Δ|=$(abs(want - have)) > (rtol=$(rr), atol=$(ar))")
                end
            end
        end
    end

    return (passed = isempty(failures), failures = failures)
end
