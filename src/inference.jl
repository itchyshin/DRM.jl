# inference.jl — Wald + profile-likelihood inference for fitted DRM models.
# Wald: estimate ± z·se from the observed information stored on the fit, on each
# parameter's working scale (log σ, atanh ρ12, log σ_b). Profile: invert the
# likelihood-ratio statistic — the endpoints where 2(ℓ̂ − ℓ_profile) = χ²₁(level),
# re-optimising the nuisance parameters at each fixed value. Mirrors drmTMB's
# `confint(..., method = "wald" | "profile")`.

using LinearAlgebra: diag, isposdef, Symmetric, eigvals, BLAS
using Distributions: Normal, Chisq, quantile
using Optim: Optim
using Random: Random
using Statistics: Statistics
import StatsAPI: stderror, confint

"""
    stderror(fit) -> Vector{Float64}

Wald standard errors (√diag of the covariance), in the fit's coefficient order.

A coefficient's Wald SE is defined only where its estimated variance is finite
and positive. At a singular boundary the observed information is not
positive-definite, so the stored covariance carries a non-positive (or
non-finite) variance for the unidentified direction. Rather than return a silent
`NaN` there, that coefficient reports `Inf` — an undefined, infinitely wide
standard error — which propagates to an unbounded `(-Inf, Inf)` Wald interval.
[`check_drm`](@ref) flags the same situation via `vcov_posdef`; drmTMB returns
all-`NaN` from `sdreport` in this case.
"""
stderror(fit::DrmFit) = _boundary_se.(diag(fit.vcov))

# √v where the variance is identified (finite, positive); Inf otherwise. Keeps a
# non-PD boundary direction from poisoning the whole SE vector with NaN.
_boundary_se(v::Real) = (isfinite(v) && v > 0) ? sqrt(v) : Inf

const _CIRow = NamedTuple{
    (:param, :coef, :estimate, :lower, :upper),Tuple{Symbol,String,Float64,Float64,Float64}
}

const _BootstrapSummaryRow = NamedTuple{
    (:param, :coef, :estimate, :std_error, :lower, :upper),
    Tuple{Symbol,String,Float64,Float64,Float64,Float64},
}

const _BootstrapFailureRow = NamedTuple{
    (:replicate, :seed, :message),Tuple{Int,UInt,String}
}

const _ProfileStatsRow = NamedTuple{
    (
        :param,
        :coef,
        :evaluations,
        :gradient_evaluations,
        :bracket_expansions,
        :root_iterations,
        :lower_unbounded,
        :upper_unbounded,
        :nonmonotone,
        # DRM.jl#493: the refinement loop's `thi - tlo < 1e-8` bracket-collapse
        # exit was being treated identically to genuine convergence
        # (`abs(ht) < 1e-9`), which let a trapped, non-monotone profiled-nll
        # surface report a fabricated near-zero step as if it were a real
        # endpoint (measured: arm width 3.7e-09 vs a healthy ~0.2). These flag
        # that failure per arm, distinct from `unbounded` (a legitimate result:
        # the profile never crosses within the search range).
        :lower_endpoint_failed,
        :upper_endpoint_failed,
    ),
    Tuple{Symbol,String,Int,Int,Int,Int,Bool,Bool,Bool,Bool,Bool},
}

function _worker_threads(active::Bool, ntasks::Int)
    return active ? min(max(ntasks, 1), Threads.nthreads()) : 1
end
function _blas_oversubscribed(active::Bool)
    return active && Threads.nthreads() > 1 && BLAS.get_num_threads() > 1
end

"""
    confint(fit; level = 0.95, method = :wald, threads = false, parm = nothing)

Confidence intervals for every coefficient, as a vector of
`(param, coef, estimate, lower, upper)` rows on each parameter's working scale
(μ on the response scale; σ on `log σ`; ρ12 on `atanh ρ12`; random-effect SDs on
`log σ_b`).

- `method = :wald` (default) — estimate ± z·se from the stored covariance.
- `method = :profile` — profile-likelihood interval: the endpoints where
  `2(ℓ̂ − ℓ_profile) = χ²₁(level)`, re-optimising the nuisance parameters at each
  fixed value (asymmetric, and exact under the LR statistic where Wald is only
  quadratic-approximate). Works on any fitted Gaussian model, and on the
  non-Gaussian location–scale fit (`(1 | tag | group)` coupled RE), where it
  routes to a trust-region inner solve that is robust on the variance boundary —
  exactly where profile intervals are most needed and Wald is least trustworthy.
  The endpoint search uses warm-start continuation (each profiled solve starts
  from the previous point's optimum) and a guarded-Newton root-find driven by the
  envelope-theorem slope `∂nll/∂θ_k`, falling back to bisection — bracket-
  guaranteed correctness, far fewer inner re-optimisations than cold-started
  bisection. Endpoint validity assumes an accurate inner nuisance solve: the
  `:finite` autodiff path can leave the profiled NLL slightly non-monotone. When
  that is detected the bracket is reset to `[0, t]` and pure bisection is used so
  the FIRST (conservative) LR crossing is returned, and a `nonmonotone` flag is
  set on the profile stats row so callers can see the assumption was violated.
  Pass `threads = true` to profile coefficients in parallel when the fitted
  objective is thread-safe; if only one coefficient is profiled, its lower and
  upper endpoint searches are run in parallel instead. (Threading is not yet used
  for the location–scale route, which profiles serially.)
- `parm = :resd` or `parm = [:mu, :resd]` — restrict intervals to one or more
  parameter blocks. This is especially useful for profiling random-effect SDs
  without also profiling fixed-effect coefficients.

Mirrors drmTMB's `confint(fit, method = "wald" | "profile")`.
"""
function confint(
    fit::DrmFit; level::Real=0.95, method::Symbol=:wald, threads::Bool=false, parm=nothing
)
    method === :wald && return _wald_ci(fit, level, parm)
    method === :profile && return profile_result(fit; level, threads, parm).ci
    throw(ArgumentError("confint: method must be :wald or :profile (got :$method)"))
end

# Build CI rows from the σ-phylo location-scale route's PRECOMPUTED boundary-aware profile CIs
# (fit.scales[:profile_ci_sd_mu] / [:profile_ci_sd_sigma], reported on the SD scale — an honest
# [0, x] at the variance boundary). Empty unless the fit was built with profile_ci=true. That
# route attaches no re-optimisable objective, so the generic profiler cannot recompute them; we
# surface the stored CIs instead. (Ayumi #2: σ-phylo SD boundary CI reachable from R.)
function _glsp_stored_profile_rows(fit::DrmFit)
    rows = _CIRow[]
    namemap = Dict(p => nms for (p, nms) in fit.coefnames)
    for (sdkey, param) in ((:profile_ci_sd_mu, :resd_mu), (:profile_ci_sd_sigma, :resd_sigma))
        (haskey(fit.scales, sdkey) && haskey(namemap, param)) || continue
        lo, hi = fit.scales[sdkey]
        est = exp(coef(fit, param)[1])                 # SD-scale point estimate
        push!(rows, (param=param, coef=namemap[param][1], estimate=Float64(est),
                     lower=Float64(lo), upper=Float64(hi)))
    end
    return rows
end

"""
    profile_result(fit; level = 0.95, threads = false, parm = nothing)

Auditable profile-likelihood confidence intervals. Returns a `NamedTuple` with:

- `ci` — the same rows returned by `confint(fit; method = :profile)`;
- `stats` — per-coefficient endpoint work counts;
- `attempted`, `used`, `failed` — coefficient counts;
- `threaded`, `worker_threads`, `julia_threads`, `blas_threads`,
  `blas_oversubscribed`, `elapsed` — CPU context and wall-clock timing;
- `autodiff` — profile nuisance-gradient backend (`:stored`, `:forward`, or
  `:finite`).

Set `threads = true` to parallelise independent profile coefficients. When only
one coefficient is profiled, the two endpoint arms are run in parallel instead.
"""
function profile_result(fit::DrmFit; level::Real=0.95, threads::Bool=false, parm=nothing)
    fit.nll isa LocScaleObjective && return _ls_profile_result(fit; level=level, parm=parm)
    if fit.nll isa LocOnlyObjective
        jobs = _profile_jobs(fit, parm)
        if !isempty(jobs) && all(job.param === :resd for job in jobs)
            return _loconly_profile_result(fit; level=level, threads=threads, jobs=jobs)
        end
    end
    # σ-phylo location-scale: surface the PRECOMPUTED boundary-aware SD-scale profile CIs
    # (the route has no re-optimisable objective). Present only when profile_ci=true was set.
    let stored = _glsp_stored_profile_rows(fit)
        if !isempty(stored)
            sel = filter(r -> _ci_coef_selected(r.param, r.coef, parm), stored)
            return (ci=sel, stats=_ProfileStatsRow[], attempted=length(sel), used=length(sel),
                    failed=0, threaded=false, worker_threads=1, julia_threads=Threads.nthreads(),
                    blas_threads=BLAS.get_num_threads(), blas_oversubscribed=false,
                    elapsed=0.0, autodiff=:stored, level=float(level))
        end
    end
    fit.nll === nothing && throw(
        ArgumentError(
            "profile intervals require the fitted objective; this model was not built with one " *
            "(σ-phylo location-scale: fit with profile_ci=true to get boundary-aware SD CIs)",
        ),
    )
    nll = fit.nll
    nllgrad = fit.nllgrad
    θ̂ = copy(fit.theta)
    nllhat = nll(θ̂)
    autodiff = _profile_autodiff_mode(nll, nllgrad, θ̂)
    half = quantile(Chisq(1), level) / 2
    se = stderror(fit)
    jobs = _profile_jobs(fit, parm)
    rows = Vector{_CIRow}(undef, length(jobs))
    stats = Vector{_ProfileStatsRow}(undef, length(jobs))
    threaded = threads && Threads.nthreads() > 1
    coefficient_threaded = threaded && length(jobs) > 1
    endpoint_threaded = threaded && length(jobs) == 1
    elapsed = @elapsed begin
        if coefficient_threaded
            Threads.@threads for i in eachindex(jobs)
                rows[i], stats[i] = _profile_row_result(
                    jobs[i], nll, nllgrad, θ̂, nllhat, half, se, autodiff
                )
            end
        else
            for i in eachindex(jobs)
                rows[i], stats[i] = _profile_row_result(
                    jobs[i],
                    nll,
                    nllgrad,
                    θ̂,
                    nllhat,
                    half,
                    se,
                    autodiff;
                    endpoint_threads=endpoint_threaded,
                )
            end
        end
    end
    # DRM.jl#493: a coefficient counts as `failed` when either arm's endpoint
    # search hit the bracket-collapse exit without genuine convergence (the row
    # is still returned, with ±Inf on the failed side — see `_profile_endpoint_result`).
    failed = count(s -> s.lower_endpoint_failed || s.upper_endpoint_failed, stats)
    return (
        ci=rows,
        stats=stats,
        attempted=length(jobs),
        used=length(rows),
        failed=failed,
        threaded=threaded,
        worker_threads=_worker_threads(threaded, endpoint_threaded ? 2 : length(jobs)),
        julia_threads=Threads.nthreads(),
        blas_threads=BLAS.get_num_threads(),
        blas_oversubscribed=_blas_oversubscribed(threaded),
        elapsed=elapsed,
        autodiff=autodiff,
        level=float(level),
    )
end

# `parm` selection. Two granularities, because a block can be expensive:
#
#   nothing                      every coefficient
#   :mu                          every coefficient in the :mu block
#   [:mu, :sigma]                every coefficient in those blocks
#   :phylocov => "L44"           ONE coefficient           (#495)
#   [:phylocov => "L44", ...]    several named coefficients (#495)
#   [:mu, :phylocov => "L44"]    mixed block and coefficient selectors
#
# The per-coefficient form exists because profiling is priced per coefficient and
# some blocks are large: `:phylocov` on the q4 route is TEN entries, so a
# diagnostic that only needs three (a calibrated control, an over-coverer and an
# under-coverer) previously had to pay for all ten or none. Block-level callers
# are unaffected -- every pre-existing `parm` value means exactly what it did.
_ci_block_of(sel) = sel isa Pair ? first(sel) : sel

function _ci_param_selected(param::Symbol, parm)
    parm === nothing && return true
    parm isa Symbol && return param === parm
    parm isa Pair && return param === first(parm)
    if parm isa AbstractVector
        return any(sel -> param === _ci_block_of(sel), parm)
    end
    throw(ArgumentError(
        "confint: parm must be nothing, a Symbol, a `:block => \"coef\"` Pair, " *
        "or a Vector of those",
    ))
end

# A `parm` that names a coefficient which does not exist must THROW, not quietly
# return zero rows. A silent empty result from a typo is indistinguishable from a
# legitimate "nothing selected", and this codebase has repeatedly been bitten by
# measurements taken through apparatus that was not actually connected.
function _ci_validate_parm(fit::DrmFit, parm)
    parm === nothing && return nothing
    sels = parm isa AbstractVector ? collect(parm) : [parm]
    known = Set{Tuple{Symbol,String}}()
    blocks = Set{Symbol}()
    for ((p, _), (_, nms)) in zip(fit.blocks, fit.coefnames)
        push!(blocks, p)
        for nm in nms
            push!(known, (p, String(nm)))
        end
    end
    # A bare block Symbol naming a block this fit does not have is NOT an error:
    # callers legitimately pass a SUPERSET of block names covering several model
    # shapes (e.g. [:mu, :sigma, :resd, :resd_sigma]) and expect absent blocks to
    # be skipped. Rejecting that would break existing callers for no benefit.
    #
    # A Pair is different -- it names one specific coefficient -- but only when
    # its block is actually present. Absent block => same superset logic, skip it.
    # So the check fires exactly where a typo is the only plausible explanation:
    # the block exists, and the coefficient in it does not.
    for sel in sels
        sel isa Pair || continue
        blk = first(sel)
        blk in blocks || continue
        if !((blk, String(last(sel))) in known)
            avail = sort([c for (b, c) in known if b === blk])
            throw(ArgumentError(
                "confint: no coefficient `$(last(sel))` in block `:$(blk)`. " *
                "Available in that block: $(avail).",
            ))
        end
    end
    return nothing
end

# Full selection: block AND coefficient name. A bare block selector admits every
# coefficient in it, so this reduces to `_ci_param_selected` unless a Pair names
# the coefficient explicitly.
function _ci_coef_selected(param::Symbol, coef::AbstractString, parm)
    parm === nothing && return true
    parm isa Symbol && return param === parm
    parm isa Pair && return param === first(parm) && String(last(parm)) == String(coef)
    if parm isa AbstractVector
        return any(parm) do sel
            sel isa Pair ?
                (param === first(sel) && String(last(sel)) == String(coef)) :
                param === sel
        end
    end
    throw(ArgumentError(
        "confint: parm must be nothing, a Symbol, a `:block => \"coef\"` Pair, " *
        "or a Vector of those",
    ))
end

function _wald_ci(fit::DrmFit, level::Real, parm)
    _ci_validate_parm(fit, parm)
    se = stderror(fit)
    z = quantile(Normal(), 1 - (1 - level) / 2)
    rows = _CIRow[]
    for ((p, r), (_, nms)) in zip(fit.blocks, fit.coefnames)
        _ci_param_selected(p, parm) || continue
        for (j, idx) in enumerate(r)
            _ci_coef_selected(p, nms[j], parm) || continue
            est = fit.theta[idx]
            s = se[idx]
            push!(
                rows,
                (param=p, coef=nms[j], estimate=est, lower=est - z * s, upper=est + z * s),
            )
        end
    end
    return rows
end

function _profile_jobs(fit::DrmFit, parm)
    _ci_validate_parm(fit, parm)
    jobs = NamedTuple{(:param, :coef, :k),Tuple{Symbol,String,Int}}[]
    for ((pp, r), (_, nms)) in zip(fit.blocks, fit.coefnames)
        _ci_param_selected(pp, parm) || continue
        for (j, k) in enumerate(r)
            _ci_coef_selected(pp, nms[j], parm) || continue
            push!(jobs, (param=pp, coef=nms[j], k=k))
        end
    end
    return jobs
end

# Profile-likelihood CIs for the location–scale fit, routed to the robust
# trust-region profiler `_ls_profile_ci` (locscale_profile.jl). The DrmFit packs
# the covariance block in `:recov` order [logL11, logL22, L21] while the engine
# packs [logL11, L21, logL22]; the permutation below (an involution that swaps
# the last two covariance entries) maps a DrmFit coefficient index to the engine
# index the profiler expects, and the engine θ̂ back from the stored `theta`.
function _ls_profile_result(fit::DrmFit; level::Real=0.95, parm=nothing)
    obj = fit.nll::LocScaleObjective
    base = size(obj.Xμ, 2) + size(obj.Xψ, 2)
    perm = vcat(collect(1:base), [base + 1, base + 3, base + 2])  # involution
    θengine = fit.theta[perm]
    se = stderror(fit)                                    # DrmFit (recov) order
    jobs = _profile_jobs(fit, parm)
    rows = Vector{_CIRow}(undef, length(jobs))
    stats = Vector{_ProfileStatsRow}(undef, length(jobs))
    elapsed = @elapsed begin
        nmin = obj(θengine)                               # marginal NLL at θ̂ (once)
        for (i, job) in enumerate(jobs)
            s = se[job.k]
            se_arg = (isfinite(s) && s > 0) ? s : nothing
            ci = _ls_profile_ci(
                obj.kind,
                obj.y,
                obj.Xμ,
                obj.Xψ,
                obj.gidx,
                obj.G,
                obj.Q,
                θengine;
                idx=perm[job.k],
                level=level,
                nll_min=nmin,
                se=se_arg,
            )
            rows[i] = (
                param=job.param,
                coef=job.coef,
                estimate=fit.theta[job.k],
                lower=ci.lower,
                upper=ci.upper,
            )
            stats[i] = (
                param=job.param,
                coef=job.coef,
                evaluations=0,
                gradient_evaluations=0,
                bracket_expansions=0,
                root_iterations=0,
                lower_unbounded=!isfinite(ci.lower),
                upper_unbounded=!isfinite(ci.upper),
                nonmonotone=false,
                # `_ls_profile_ci` (locscale_profile.jl) is the robust trust-region
                # route, not the generic `_profile_endpoint_result` DRM.jl#493 fixes;
                # it has no analogous bracket-collapse failure mode.
                lower_endpoint_failed=false,
                upper_endpoint_failed=false,
            )
        end
    end
    return (
        ci=rows,
        stats=stats,
        attempted=length(jobs),
        used=length(rows),
        failed=0,
        threaded=false,
        worker_threads=1,
        julia_threads=Threads.nthreads(),
        blas_threads=BLAS.get_num_threads(),
        blas_oversubscribed=false,
        elapsed=elapsed,
        autodiff=:locscale,
        level=float(level),
    )
end

function _loconly_profile_result(
    fit::DrmFit; level::Real=0.95, threads::Bool=false, jobs=nothing
)
    obj = fit.nll::LocOnlyObjective
    θ̂ = copy(fit.theta)
    nllhat = _loconly_profile_fg(obj.prob, θ̂[obj.pμ + 1], θ̂[obj.pμ + 2])[1]
    half = quantile(Chisq(1), level) / 2
    jobs === nothing && (jobs = _profile_jobs(fit, :resd))
    rows = Vector{_CIRow}(undef, length(jobs))
    stats = Vector{_ProfileStatsRow}(undef, length(jobs))
    threaded = threads && Threads.nthreads() > 1
    endpoint_threaded = threaded && length(jobs) == 1
    elapsed = @elapsed begin
        if threaded && length(jobs) > 1
            Threads.@threads for i in eachindex(jobs)
                rows[i], stats[i] = _loconly_profile_row_result(
                    jobs[i], obj, θ̂, nllhat, half
                )
            end
        else
            for i in eachindex(jobs)
                rows[i], stats[i] = _loconly_profile_row_result(
                    jobs[i], obj, θ̂, nllhat, half; endpoint_threads=endpoint_threaded
                )
            end
        end
    end
    return (
        ci=rows,
        stats=stats,
        attempted=length(jobs),
        used=length(rows),
        failed=0,
        threaded=threaded,
        worker_threads=_worker_threads(threaded, endpoint_threaded ? 2 : length(jobs)),
        julia_threads=Threads.nthreads(),
        blas_threads=BLAS.get_num_threads(),
        blas_oversubscribed=_blas_oversubscribed(threaded),
        elapsed=elapsed,
        autodiff=:loconly,
        level=float(level),
    )
end

function _loconly_profile_row_result(
    job, obj::LocOnlyObjective, θ̂, nllhat, half; endpoint_threads::Bool=false
)
    k = job.k
    est = θ̂[k]
    lσ0 = θ̂[obj.pμ + 1]
    if endpoint_threads && Threads.nthreads() > 1
        left = Threads.@spawn _loconly_profile_endpoint_result(
            obj, lσ0, est, nllhat, half, -1.0
        )
        right = Threads.@spawn _loconly_profile_endpoint_result(
            obj, lσ0, est, nllhat, half, +1.0
        )
        lo, lstats = fetch(left)
        hi, rstats = fetch(right)
    else
        lo, lstats = _loconly_profile_endpoint_result(obj, lσ0, est, nllhat, half, -1.0)
        hi, rstats = _loconly_profile_endpoint_result(obj, lσ0, est, nllhat, half, +1.0)
    end
    row = (param=job.param, coef=job.coef, estimate=est, lower=lo, upper=hi)
    stats = (
        param=job.param,
        coef=job.coef,
        evaluations=lstats.evaluations + rstats.evaluations,
        gradient_evaluations=lstats.gradient_evaluations + rstats.gradient_evaluations,
        bracket_expansions=lstats.bracket_expansions + rstats.bracket_expansions,
        root_iterations=lstats.root_iterations + rstats.root_iterations,
        lower_unbounded=lstats.unbounded,
        upper_unbounded=rstats.unbounded,
        nonmonotone=lstats.nonmonotone || rstats.nonmonotone,
        # `_loconly_profile_endpoint_result` was not in scope for DRM.jl#493 (the
        # reported degenerate fit routes through the generic path, not here) and
        # is not instrumented for the same bracket-collapse failure; default false
        # rather than claim a check that was not made.
        lower_endpoint_failed=false,
        upper_endpoint_failed=false,
    )
    return row, stats
end

function _loconly_profile_endpoint_result(
    obj::LocOnlyObjective, lσ0::Real, estimate::Real, nllhat::Real, half::Real, dir::Real
)
    target = nllhat + half
    lσ_start = Float64(lσ0)
    evaluations = 0
    gradient_evaluations = 0

    function heval(t)
        f, lσ_opt, slope = _loconly_profiled_resd_nll(obj, lσ_start, estimate + dir * t)
        lσ_start = lσ_opt
        evaluations += 1
        gradient_evaluations += 1
        return (f - target, dir * slope)
    end

    tlo = 0.0
    thi = 0.1
    hhi, _ = heval(thi)
    hprev = hhi
    nonmonotone = false
    iters = 0
    while isfinite(hhi) && hhi < 0 && iters < 60
        tlo = thi
        thi *= 1.6
        hhi, _ = heval(thi)
        isfinite(hhi) && hhi < hprev - 1e-12 && (nonmonotone = true)
        hprev = hhi
        iters += 1
    end
    if isfinite(hhi) && hhi < 0
        value = dir < 0 ? -Inf : Inf
        stats = (
            evaluations=evaluations,
            gradient_evaluations=gradient_evaluations,
            bracket_expansions=iters,
            root_iterations=0,
            unbounded=true,
            nonmonotone=nonmonotone,
        )
        return value, stats
    end
    nonmonotone && (tlo = 0.0)   # conservative bracket to the first crossing (see _profile_endpoint_result)

    t = (tlo + thi) / 2
    root_iterations = 0
    for _ in 1:80
        root_iterations += 1
        ht, hp = heval(t)
        abs(ht) < 1e-9 && break
        ht < 0 ? (tlo = t) : (thi = t)
        tn = (!nonmonotone && isfinite(hp) && hp > 0) ? t - ht / hp : (tlo + thi) / 2
        t = (tlo < tn < thi) ? tn : (tlo + thi) / 2
        thi - tlo < 1e-8 && break
    end
    value = estimate + dir * t
    stats = (
        evaluations=evaluations,
        gradient_evaluations=gradient_evaluations,
        bracket_expansions=iters,
        root_iterations=root_iterations,
        unbounded=false,
        nonmonotone=nonmonotone,
    )
    return value, stats
end

function _loconly_profiled_resd_nll(obj::LocOnlyObjective, lσ0::Real, lσ_phy::Real)
    x0 = [Float64(lσ0)]
    function fg!(F, G, x)
        val, grad, _, _ = _loconly_profile_fg(obj.prob, x[1], lσ_phy)
        G !== nothing && (G[1] = grad[1])
        return F === nothing ? nothing : val
    end
    res = try
        od = Optim.NLSolversBase.only_fg!(fg!)
        Optim.optimize(
            od,
            x0,
            Optim.LBFGS(; linesearch=Optim.LineSearches.BackTracking(; order=3)),
            Optim.Options(; iterations=80, g_tol=1e-8, x_abstol=1e-10),
        )
    catch
        obj1(x) = _loconly_profile_fg(obj.prob, x[1], lσ_phy)[1]
        Optim.optimize(
            obj1,
            x0,
            Optim.NelderMead(),
            Optim.Options(; iterations=120, x_abstol=1e-10),
        )
    end
    lσ = Optim.minimizer(res)[1]
    val, grad, _, _ = _loconly_profile_fg(obj.prob, lσ, lσ_phy)
    return val, lσ, grad[2]
end

# Profiled objective: minimise nll over every component except k, with θ[k] = v.
# Returns (minimum, û_nuisance) so the caller can WARM-START the next solve from
# the previous point's nuisance optimum (continuation along the profile path) —
# the dominant speedup over cold-starting each solve from the joint MLE.
function _profile_autodiff_mode(nll, nllgrad, θ̂::Vector{Float64})
    nllgrad !== nothing && return :stored
    try
        ForwardDiff.gradient(nll, θ̂)
        return :forward
    catch err
        # Some fitted objectives are exact on Float64 but not dual-number safe
        # because they solve an inner sparse/Laplace mode with Float64 work
        # arrays. Keep profiling valid by using finite-difference nuisance
        # gradients when the Float64 objective itself is fine.
        try
            nll(θ̂)
        catch
            rethrow(err)
        end
        return :finite
    end
end

function _profiled_nll(
    nll,
    θ̂::Vector{Float64},
    k::Int,
    v::Real,
    u0::Vector{Float64};
    autodiff::Symbol=:forward,
    nllgrad=nothing,
)
    p = length(θ̂)
    idx = [i for i in 1:p if i != k]
    isempty(idx) && return (nll([float(v)]), Float64[])
    function obj(u)
        θ = Vector{eltype(u)}(undef, p)
        θ[k] = convert(eltype(u), v)
        @inbounds for (t, i) in enumerate(idx)
            θ[i] = u[t]
        end
        return nll(θ)
    end
    grad_u! = if autodiff === :stored && nllgrad !== nothing
        gfull = zeros(p)
        function (Gout, u)
            θ = Vector{Float64}(undef, p)
            θ[k] = float(v)
            @inbounds for (t, i) in enumerate(idx)
                θ[i] = u[t]
            end
            nllgrad(gfull, θ)
            @inbounds for (t, i) in enumerate(idx)
                Gout[t] = gfull[i]
            end
            return Gout
        end
    else
        nothing
    end
    res = _profile_optimize(obj, u0, autodiff; (grad!)=grad_u!)
    return (Optim.minimum(res), Optim.minimizer(res))
end

function _profile_optimize(obj, u0::Vector{Float64}, autodiff::Symbol; (grad!)=nothing)
    if grad! !== nothing
        try
            od = Optim.OnceDifferentiable(obj, grad!, u0)
            # DRM.jl#494: `BackTracking()`'s own default `iterations` is 1_000,
            # uncapped by the `Optim.Options(iterations=40)` below (that only
            # bounds outer LBFGS steps). When a trial step drives the profiled
            # nuisance parameters to extreme values (measured: the bivariate q4
            # among-axis log-Cholesky diagonal pushed to (-45.2, 61.6) vs. the
            # fit's own ~(-2.6, 0.36)), a single bad outer step could retry the
            # line search up to 1_000 times, each retry a full cold-started
            # inner mode solve — the mechanism behind the rho12 profile runaway
            # (measured 10-20x wall-clock inflation on seed 181; up to 17 min
            # reported). Capping it here removes that multiplier.
            method = Optim.LBFGS(; linesearch=Optim.LineSearches.BackTracking(; iterations=20))
            return Optim.optimize(
                od, u0, method, Optim.Options(; iterations=40, g_tol=1e-6, x_abstol=1e-8)
            )
        catch
            # Previously no `Optim.Options` here, so this inherited Optim's own
            # default `iterations = 1_000` (25x the primary path's 40), each
            # needing a full finite-difference gradient. Match the primary
            # path's budget so this fallback can't reintroduce the same runaway.
            return Optim.optimize(
                obj, u0, Optim.LBFGS(), Optim.Options(; iterations=40, g_tol=1e-6, x_abstol=1e-8);
                autodiff=:finite,
            )
        end
    end
    try
        return Optim.optimize(obj, u0, Optim.LBFGS(); autodiff)
    catch err
        autodiff === :finite || rethrow()
        # Finite-difference gradients can occasionally produce a failed line
        # search on sparse-Laplace profiles. The profile value is what matters;
        # retry with a value-only method instead of failing the interval.
        return Optim.optimize(obj, u0, Optim.NelderMead())
    end
end

# Analytic slope of the PROFILED nll in θ[k], by the envelope theorem: at the
# profiled optimum the nuisance partials vanish, so d/dv [min_u nll] = ∂nll/∂θ_k
# evaluated at (v, û). One ForwardDiff gradient component — no extra solves.
function _profile_slope(
    nll, nllgrad, θ̂::Vector{Float64}, k::Int, v::Real, û::Vector{Float64}
)
    p = length(θ̂)
    idx = [i for i in 1:p if i != k]
    θ = Vector{Float64}(undef, p)
    θ[k] = float(v)
    @inbounds for (t, i) in enumerate(idx)
        θ[i] = û[t]
    end
    if nllgrad !== nothing
        g = zeros(p)
        nllgrad(g, θ)
        return g[k]
    end
    return ForwardDiff.gradient(nll, θ)[k]
end

# Endpoint in working coordinate where the profiled nll rises by `half` above the
# minimum, searching from θ̂[k] in direction dir ∈ {-1,+1}. h(t) = profiled_nll −
# target is increasing in t ≥ 0 with h(0) = −half < 0. We bracket by expansion,
# then root-find with a GUARDED NEWTON step (using the envelope-theorem slope,
# h'(t) = dir · ∂nll/∂θ_k): a Newton step that stays inside the maintained
# bracket is accepted, otherwise we fall back to bisection. Correctness is
# bracket-guaranteed; the analytic slope only buys faster (quadratic) convergence.
# Each evaluation warm-starts the nuisance optimisation from the previous û.
function _profile_endpoint(nll, nllgrad, θ̂, k, nllhat, half, s, dir, u0, autodiff)
    value, _ = _profile_endpoint_result(
        nll, nllgrad, θ̂, k, nllhat, half, s, dir, u0, autodiff
    )
    return value
end

function _profile_endpoint_result(nll, nllgrad, θ̂, k, nllhat, half, s, dir, u0, autodiff)
    target = nllhat + half
    p = length(θ̂)
    nidx = p - 1
    û = copy(u0)
    evaluations = 0
    gradient_evaluations = 0
    # h(t) and its derivative h'(t); updates û in place for warm-starting.
    function heval(t)
        f, unew = _profiled_nll(nll, θ̂, k, θ̂[k] + dir * t, û; autodiff, nllgrad)
        isempty(unew) || (û = unew)
        evaluations += 1
        hp = if nidx == 0 || autodiff === :finite
            NaN
        else
            gradient_evaluations += 1
            dir * _profile_slope(nll, nllgrad, θ̂, k, θ̂[k] + dir * t, û)
        end
        return (f - target, hp)
    end
    # Bracket: expand until h > 0. h(t) is assumed increasing (LR profile), but an
    # inexactly-solved inner nuisance optimisation can make it slightly non-monotone
    # (dip below `target` then rise). If that happens, `tlo` may have advanced past
    # the TRUE first crossing, so the guarded root-find below would converge to a
    # LATER crossing and report an anticonservative (too-tight) endpoint. We track
    # non-monotonicity and, when detected, reset `tlo = 0` so the root-find brackets
    # the full [0, thi] span (h(0) = −half < 0, h(thi) > 0) and returns the FIRST
    # crossing — the conservative endpoint. `nonmonotone` is surfaced in the stats.
    tlo = 0.0
    thi = s
    (hhi, _) = heval(thi)
    hprev = hhi
    nonmonotone = false
    iters = 0
    while hhi < 0 && iters < 40
        tlo = thi
        thi *= 1.6
        (hhi, _) = heval(thi)
        hhi < hprev - 1e-12 && (nonmonotone = true)
        hprev = hhi
        iters += 1
    end
    if hhi < 0
        value = dir < 0 ? -Inf : Inf
        stats = (
            evaluations=evaluations,
            gradient_evaluations=gradient_evaluations,
            bracket_expansions=iters,
            root_iterations=0,
            unbounded=true,
            nonmonotone=nonmonotone,
            endpoint_failed=false,
        )
        return value, stats
    end
    nonmonotone && (tlo = 0.0)   # conservative: bracket the full span to the first crossing
    # Guarded Newton on [tlo, thi]; if the profile is non-monotone fall back to pure
    # bisection (Newton can jump past the first crossing on a noisy slope).
    t = (tlo + thi) / 2
    root_iterations = 0
    # `converged` is set ONLY by the genuine convergence test `abs(ht) < 1e-9`
    # (DRM.jl#493). The loop's OTHER exit, `thi - tlo < 1e-8`, is a bracket-
    # collapse safety valve, not a root: on a trapped, non-monotone profiled-nll
    # surface (the warm-started inner nuisance solve landing in a spurious local
    # optimum ~28 NLL units above the true profile, for every t on the affected
    # arm) `ht` stays pinned near its saturated value the entire time — measured
    # ht ≈ +25.85 at exit on seed 1's degenerate upper sigma arm — while `thi`
    # is repeatedly halved toward `tlo = 0`, exiting with a step of ~7e-9 that
    # looks like a converged endpoint but is not one.
    #
    # Convergence must be judged on the SCALE OF THE PROBLEM, not on an absolute
    # 1e-9 alone. `abs(ht) < 1e-9` is reachable only when the Newton branch is
    # live (`hp` finite and positive). On the BISECTION-ONLY path — `hp = NaN`,
    # i.e. `autodiff === :finite`, which the shipping q2 bivariate structured
    # route takes (`gaussian_bivariate.jl` attaches no gradient callback and
    # ForwardDiff genuinely throws on its inner sparse Cholesky) — pure halving
    # needs ~27 steps to drive an O(0.1) bracket under the 1e-8 floor, and that
    # floor is hit while `abs(ht)` is still ~1e-7. Judging that as failure
    # condemns a perfectly good endpoint: measured 10/12 arms on real q2 fits and
    # 29/30 on healthy Cell U fits forced onto `:finite`, every one of them with
    # a tightly clustered, plausible width.
    #
    # The two populations are separated by magnitude, not by exit route:
    #   legitimate bisection exit   abs(ht) ~ 1e-7 .. 1e-8
    #   genuinely trapped surface   abs(ht) ~ 2.0 .. 1e4   (>= `half` itself)
    # so the discriminator is `abs(ht)` against the LR target `half` (1.92 at
    # 95%). `ABSTOL_REL * half` ~ 1.9e-4 sits ~1900x above the loosest legitimate
    # exit and ~10000x below the tightest genuine trap. Six orders of margin on
    # each side; nothing observed in between across ~500 endpoints.
    ABSTOL_REL = 1e-4
    converged = false
    ht = NaN
    for _ in 1:60
        root_iterations += 1
        (ht, hp) = heval(t)
        if abs(ht) < 1e-9
            converged = true
            break
        end
        ht < 0 ? (tlo = t) : (thi = t)
        tn = (!nonmonotone && isfinite(hp) && hp > 0) ? t - ht / hp : (tlo + thi) / 2   # Newton, else bisect
        t = (tlo < tn < thi) ? tn : (tlo + thi) / 2                     # guard into bracket
        if thi - tlo < 1e-8
            # Bracket collapsed. That is a genuine root iff the residual is small
            # relative to the target; otherwise the surface never crossed and the
            # step is fabricated (DRM.jl#493).
            converged = isfinite(ht) && abs(ht) < ABSTOL_REL * half
            break
        end
    end
    # A failed endpoint mirrors the `unbounded` convention (±Inf toward `dir`,
    # never a fabricated finite value) rather than returning θ̂[k] + dir*t as if
    # it were a real root; `endpoint_failed` distinguishes it from a genuine
    # unbounded profile so callers can tell "doesn't cross" from "solver could
    # not tell where it crosses".
    value = converged ? θ̂[k] + dir * t : (dir < 0 ? -Inf : Inf)
    stats = (
        evaluations=evaluations,
        gradient_evaluations=gradient_evaluations,
        bracket_expansions=iters,
        root_iterations=root_iterations,
        unbounded=false,
        nonmonotone=nonmonotone,
        endpoint_failed=!converged,
    )
    return value, stats
end

function _profile_row(job, nll, nllgrad, θ̂, nllhat, half, se, autodiff)
    row, _ = _profile_row_result(job, nll, nllgrad, θ̂, nllhat, half, se, autodiff)
    return row
end

function _profile_row_result(
    job, nll, nllgrad, θ̂, nllhat, half, se, autodiff; endpoint_threads::Bool=false
)
    k = job.k
    est = θ̂[k]
    s = (isfinite(se[k]) && se[k] > 0) ? se[k] : max(abs(est), 1.0)
    u0 = θ̂[[i for i in 1:length(θ̂) if i != k]]
    if endpoint_threads && Threads.nthreads() > 1
        left = Threads.@spawn _profile_endpoint_result(
            nll, nllgrad, θ̂, k, nllhat, half, s, -1, u0, autodiff
        )
        right = Threads.@spawn _profile_endpoint_result(
            nll, nllgrad, θ̂, k, nllhat, half, s, +1, u0, autodiff
        )
        lo, lstats = fetch(left)
        hi, rstats = fetch(right)
    else
        lo, lstats = _profile_endpoint_result(
            nll, nllgrad, θ̂, k, nllhat, half, s, -1, u0, autodiff
        )
        hi, rstats = _profile_endpoint_result(
            nll, nllgrad, θ̂, k, nllhat, half, s, +1, u0, autodiff
        )
    end
    row = (param=job.param, coef=job.coef, estimate=est, lower=lo, upper=hi)
    stats = (
        param=job.param,
        coef=job.coef,
        evaluations=lstats.evaluations + rstats.evaluations,
        gradient_evaluations=lstats.gradient_evaluations + rstats.gradient_evaluations,
        bracket_expansions=lstats.bracket_expansions + rstats.bracket_expansions,
        root_iterations=lstats.root_iterations + rstats.root_iterations,
        lower_unbounded=lstats.unbounded,
        upper_unbounded=rstats.unbounded,
        nonmonotone=lstats.nonmonotone || rstats.nonmonotone,
        lower_endpoint_failed=lstats.endpoint_failed,
        upper_endpoint_failed=rstats.endpoint_failed,
    )
    return row, stats
end

"""
    bootstrap_ci(formula, family; data, B = 300, level = 0.95, rng = default_rng(), threads = false, K =, A =, tree =, algorithm = :auto, g_tol = 1e-8)
    bootstrap_ci(fit; data, B = 300, level = 0.95, rng = default_rng(), threads = false, K =, A =, tree =, algorithm = :auto, g_tol = 1e-8)

Parametric bootstrap confidence intervals: fit the model, then `simulate` `B`
replicate responses, refit each, and take percentile intervals per coefficient.
Univariate-response models (fixed / random-effect / meta / structured). Same row
shape as [`confint`](@ref). Set `threads = true` to refit bootstrap replicates
in parallel. Pass through the structured-matrix keywords (`K` / `A` / `tree`)
and, for Gaussian fits, the solver controls (`algorithm` / `g_tol`) exactly as
to [`drm`](@ref). Use `bootstrap_result` when you need attempted/used/failed
counts and per-replicate failure messages. If you already have
`fit = drm(...)`, pass the fit directly to avoid refitting the base model before
the bootstrap replicates.
"""
function bootstrap_ci(
    formula::DrmFormula,
    family::Gaussian;
    data,
    B::Int=300,
    level::Real=0.95,
    rng=default_rng(),
    K=nothing,
    A=nothing,
    tree=nothing,
    threads::Bool=false,
    failures::Symbol=:error,
    check_converged::Bool=false,
    algorithm::Symbol=:auto,
    g_tol::Real=1e-8,
)
    rows = bootstrap_summary(
        formula,
        family;
        data,
        B,
        level,
        rng,
        K,
        A,
        tree,
        threads,
        failures,
        check_converged,
        algorithm,
        g_tol,
    )
    return _bootstrap_ci_rows(rows)
end

# Family-agnostic parametric bootstrap — any family `simulate` supports.
# #480: K/A/tree ARE forwardable here — #479 established that the non-Gaussian
# bootstrap can thread a structured covariance; the guard was a one-sided
# plumbing gap, not a real restriction. Same row shape as the Gaussian method
# and `confint`.
function bootstrap_ci(
    formula::DrmFormula,
    family;
    data,
    B::Int=300,
    level::Real=0.95,
    rng=default_rng(),
    K=nothing,
    A=nothing,
    tree=nothing,
    threads::Bool=false,
    failures::Symbol=:error,
    check_converged::Bool=false,
)
    rows = bootstrap_summary(
        formula, family; data, B, level, rng, K, A, tree, threads, failures,
        check_converged
    )
    return _bootstrap_ci_rows(rows)
end

function bootstrap_ci(
    fit::DrmFit;
    data,
    B::Int=300,
    level::Real=0.95,
    rng=default_rng(),
    K=nothing,
    A=nothing,
    tree=nothing,
    threads::Bool=false,
    failures::Symbol=:error,
    check_converged::Bool=false,
)
    rows = bootstrap_summary(
        fit; data, B, level, rng, K, A, tree, threads, failures, check_converged
    )
    return _bootstrap_ci_rows(rows)
end

function bootstrap_ci(
    fit::DrmFit{<:Gaussian};
    data,
    B::Int=300,
    level::Real=0.95,
    rng=default_rng(),
    K=nothing,
    A=nothing,
    tree=nothing,
    threads::Bool=false,
    failures::Symbol=:error,
    check_converged::Bool=false,
    algorithm::Symbol=:auto,
    g_tol::Real=1e-8,
)
    rows = bootstrap_summary(
        fit;
        data,
        B,
        level,
        rng,
        K,
        A,
        tree,
        threads,
        failures,
        check_converged,
        algorithm,
        g_tol,
    )
    return _bootstrap_ci_rows(rows)
end

"""
    bootstrap_summary(formula, family; data, B = 300, level = 0.95, rng = default_rng(), threads = false, K =, A =, tree =, algorithm = :auto, g_tol = 1e-8)
    bootstrap_summary(fit; data, B = 300, level = 0.95, rng = default_rng(), threads = false, K =, A =, tree =, algorithm = :auto, g_tol = 1e-8)

Parametric bootstrap coefficient summaries in one pass: point estimate,
bootstrap standard error, and percentile confidence interval. This is the
bootstrap analogue of using `stderror(fit)` plus `confint(fit)`, avoiding a
second bootstrap run when both SEs and intervals are needed. Row fields are
`(param, coef, estimate, std_error, lower, upper)`. By default, any failed
replicate errors after all failures are recorded. Set `failures = :skip` to
compute summaries from successful replicates; call `bootstrap_result` to
inspect the skipped failures.
"""
function bootstrap_summary(
    formula::DrmFormula,
    family::Gaussian;
    data,
    B::Int=300,
    level::Real=0.95,
    rng=default_rng(),
    K=nothing,
    A=nothing,
    tree=nothing,
    threads::Bool=false,
    failures::Symbol=:error,
    check_converged::Bool=false,
    algorithm::Symbol=:auto,
    g_tol::Real=1e-8,
)
    result = bootstrap_result(
        formula,
        family;
        data,
        B,
        level,
        rng,
        K,
        A,
        tree,
        threads,
        failures,
        check_converged,
        algorithm,
        g_tol,
    )
    return result.summary
end

# Family-agnostic summary method — any family `simulate` supports. #480: K/A/tree
# thread through to `bootstrap_result`, which forwards them to `drm(...)` only
# when supplied — see the comment there for why they are not Gaussian-only.
function bootstrap_summary(
    formula::DrmFormula,
    family;
    data,
    B::Int=300,
    level::Real=0.95,
    rng=default_rng(),
    K=nothing,
    A=nothing,
    tree=nothing,
    threads::Bool=false,
    failures::Symbol=:error,
    check_converged::Bool=false,
)
    result = bootstrap_result(
        formula, family; data, B, level, rng, K, A, tree, threads, failures,
        check_converged
    )
    return result.summary
end

function bootstrap_summary(
    fit::DrmFit;
    data,
    B::Int=300,
    level::Real=0.95,
    rng=default_rng(),
    K=nothing,
    A=nothing,
    tree=nothing,
    threads::Bool=false,
    failures::Symbol=:error,
    check_converged::Bool=false,
)
    result = bootstrap_result(
        fit; data, B, level, rng, K, A, tree, threads, failures, check_converged
    )
    return result.summary
end

function bootstrap_summary(
    fit::DrmFit{<:Gaussian};
    data,
    B::Int=300,
    level::Real=0.95,
    rng=default_rng(),
    K=nothing,
    A=nothing,
    tree=nothing,
    threads::Bool=false,
    failures::Symbol=:error,
    check_converged::Bool=false,
    algorithm::Symbol=:auto,
    g_tol::Real=1e-8,
)
    result = bootstrap_result(
        fit;
        data,
        B,
        level,
        rng,
        K,
        A,
        tree,
        threads,
        failures,
        check_converged,
        algorithm,
        g_tol,
    )
    return result.summary
end

"""
    bootstrap_result(formula, family; data, B = 300, level = 0.95, rng = default_rng(), threads = false, failures = :error, check_converged = false, K =, A =, tree =, algorithm = :auto, g_tol = 1e-8)
    bootstrap_result(fit; data, B = 300, level = 0.95, rng = default_rng(), threads = false, failures = :error, check_converged = false, K =, A =, tree =, algorithm = :auto, g_tol = 1e-8)

Auditable parametric bootstrap. Returns a `NamedTuple` with:

- `summary` — the same rows returned by `bootstrap_summary`;
- `failures` — rows `(replicate, seed, message)` for failed refits;
- `attempted`, `used`, `failed` — replicate counts;
- `seeds` — the per-replicate seeds used for reproducibility;
- `threaded` — whether threaded refits were actually used.
- `worker_threads`, `julia_threads`, `blas_threads`, `blas_oversubscribed`,
  `elapsed` — CPU context and wall-clock time for the simulated-refit phase.

`failures = :error` (default) records failures and then errors if any replicate
failed. `failures = :skip` computes summaries from successful replicates and
keeps the failure records in the return value. Set `check_converged = true` to
treat non-converged refits as failed replicates. Passing an existing `DrmFit`
reuses that point estimate as the bootstrap seed fit and starts directly with
the `B` simulated refits. Gaussian bootstrap refits pass `algorithm` and
`g_tol` through to `drm(...)`; this is useful for large structured models where
`:auto` selects a sparse route and the tolerance is part of the benchmarked
workflow.
"""
function bootstrap_result(
    formula::DrmFormula,
    family::Gaussian;
    data,
    B::Int=300,
    level::Real=0.95,
    rng=default_rng(),
    K=nothing,
    A=nothing,
    tree=nothing,
    threads::Bool=false,
    failures::Symbol=:error,
    check_converged::Bool=false,
    algorithm::Symbol=:auto,
    g_tol::Real=1e-8,
)
    _check_bootstrap_failure_mode(failures)
    fit0 = drm(formula, family; data, K, A, tree, algorithm, g_tol)
    refit = datab -> drm(formula, family; data=datab, K, A, tree, algorithm, g_tol)
    return _bootstrap_result(
        fit0, formula, data, B, level, rng, threads, refit; failures, check_converged
    )
end

function bootstrap_result(
    fit::DrmFit{<:Gaussian};
    data,
    B::Int=300,
    level::Real=0.95,
    rng=default_rng(),
    K=nothing,
    A=nothing,
    tree=nothing,
    threads::Bool=false,
    failures::Symbol=:error,
    check_converged::Bool=false,
    algorithm::Symbol=:auto,
    g_tol::Real=1e-8,
)
    # Bivariate q=4 phylogenetic fit (also a DrmFit{<:Gaussian}): no scalar SD
    # block to refit-and-recoef — the quantities of interest are the among-axis
    # SDs sqrt.(diag(Σ_a)). Route to the dedicated parametric bootstrap, which
    # gives boundary-honest percentile CIs. K/A/tree are carried by the fit.
    if fit.formula isa BivariateDrmFormula && fit.ranef isa NamedTuple &&
       haskey(fit.ranef, :Sigma_a)
        return bootstrap_sigma_a(fit; data = data, B = B, level = level, rng = rng,
                                 failures = (failures === :error ? :error : :warn),
                                 check_converged = check_converged)
    end
    _check_bootstrap_failure_mode(failures)
    formula = _bootstrap_fit_formula(fit)
    refit = datab -> drm(formula, fit.family; data=datab, K, A, tree, algorithm, g_tol)
    # #459: redraw the random effects rather than conditioning on the fitted BLUPs.
    simulate_fn = _marginal_simulator(fit, data; K=K, A=A, tree=tree)
    return _bootstrap_result(
        fit, formula, data, B, level, rng, threads, refit;
        failures, check_converged, simulate_fn
    )
end

function bootstrap_result(
    formula::DrmFormula,
    family;
    data,
    B::Int=300,
    level::Real=0.95,
    rng=default_rng(),
    K=nothing,
    A=nothing,
    tree=nothing,
    threads::Bool=false,
    failures::Symbol=:error,
    check_converged::Bool=false,
)
    _check_bootstrap_failure_mode(failures)
    # #480: mirror #479's fit-based fix. Forward a structured-matrix keyword to
    # `drm(...)` only when the caller actually supplied it -- most non-Gaussian
    # `drm` methods (LogNormal, Tweedie, Student, SkewNormal, ZeroOneBeta,
    # CumulativeLogit, TruncatedNegBinomial2) do not declare `K`/`A`/`tree` at
    # all, so forwarding them unconditionally (even as `nothing`) would throw a
    # MethodError on every ordinary unstructured non-Gaussian fit. The
    # structured routes (Poisson, Binomial, Gamma, Beta, BetaBinomial,
    # NegBinomial2, Gaussian) accept and use them; `drm(...)`'s own per-family
    # checks (e.g. "phylo(1 | g) needs `tree = …`") catch a genuine mismatch
    # loudly instead of silently refitting an unstructured model.
    extra = Dict{Symbol,Any}()
    tree !== nothing && (extra[:tree] = tree)
    K !== nothing && (extra[:K] = K)
    A !== nothing && (extra[:A] = A)
    fit0 = drm(formula, family; data, extra...)
    refit = datab -> drm(formula, family; data=datab, extra...)
    # #459/#479: redraw the random effects rather than conditioning on the
    # fitted BLUPs, so a variance-component bootstrap CI is not degenerate.
    simulate_fn = _marginal_simulator(fit0, data; K=K, A=A, tree=tree)
    return _bootstrap_result(
        fit0, formula, data, B, level, rng, threads, refit;
        failures, check_converged, simulate_fn
    )
end

function bootstrap_result(
    fit::DrmFit;
    data,
    B::Int=300,
    level::Real=0.95,
    rng=default_rng(),
    K=nothing,
    A=nothing,
    tree=nothing,
    threads::Bool=false,
    failures::Symbol=:error,
    check_converged::Bool=false,
)
    # Bivariate q=4 phylogenetic fit: there is no scalar SD block to refit-and-
    # recoef; the quantities of interest are the among-axis SDs sqrt.(diag(Σ_a)).
    # Route to the dedicated parametric bootstrap (boundary-honest percentile CIs).
    if fit.formula isa BivariateDrmFormula && fit.ranef isa NamedTuple &&
       haskey(fit.ranef, :Sigma_a)
        # K/A/tree are carried by the fit (fit.ranef.phy) — accept and ignore them.
        return bootstrap_sigma_a(fit; data = data, B = B, level = level, rng = rng,
                                 failures = (failures === :error ? :error : :warn),
                                 check_converged = check_converged)
    end
    _check_bootstrap_failure_mode(failures)
    formula = _bootstrap_fit_formula(fit)
    # #479: the univariate non-Gaussian structured routes (phylo/relmat/animal/
    # spatial Laplace) do NOT stash the tree/K/A on the fit the way the bivariate
    # q=4 route stashes `fit.ranef.phy` -- `_fit_poisson_general_laplace` et al.
    # never call `_withranef`. So, exactly like the Gaussian method just above,
    # the caller re-supplies the same K/A/tree used to produce `fit`; a mismatch
    # (or an unsupported family/route) is caught loudly by `drm(...)`'s own
    # per-family checks (e.g. "relmat(1 | g) needs K = …") rather than silently
    # refitting an unstructured model.
    extra = Dict{Symbol,Any}()
    tree !== nothing && (extra[:tree] = tree)
    K !== nothing && (extra[:K] = K)
    A !== nothing && (extra[:A] = A)
    refit = datab -> drm(formula, fit.family; data=datab, extra...)
    simulate_fn = _marginal_simulator(fit, data; K=K, A=A, tree=tree)   # #459 / #479
    return _bootstrap_result(
        fit, formula, data, B, level, rng, threads, refit;
        failures, check_converged, simulate_fn
    )
end

function _bootstrap_fit_formula(fit::DrmFit)
    fit.formula isa DrmFormula && return fit.formula
    throw(
        ArgumentError(
            "fit-based bootstrap requires a univariate `DrmFit` created by `drm`; " *
            "bivariate and formula-less internal fits are not yet supported",
        ),
    )
end

# --- Marginal parametric bootstrap simulation (#459) -------------------------
#
# `simulate(fit)` is a CONDITIONAL simulator: for a Gaussian fit it returns
# `fit.means[:mu] .+ fit.scales[:sigma] .* randn(n)`, and `fit.means[:mu]` ALREADY
# CONTAINS the fitted BLUPs. Bootstrapping a fixed effect that way is defensible.
# Bootstrapping a VARIANCE COMPONENT that way is not: every replicate re-uses the
# same realised random effects, so the refitted SD barely moves and the percentile
# interval collapses toward the point estimate.
#
# Measured 2026-08-24 (#459): the phylo-SD bootstrap CI came out 1674x NARROWER
# than native TMB on identical data, B and seed -- implied replicate SD 6.45e-05
# against 0.108. The point estimate was right, which is why it looked plausible.
#
# The correct parametric bootstrap redraws the random effects from their fitted
# distribution and adds them to the FIXED-effect mean:
#
#     y* = Xb + Z u*  + e*,    u* ~ N(0, sd_u^2 K),   e* ~ N(0, sigma^2)
#
# which is exactly what `bootstrap_q4_phylo.jl` already does for the q=4 path
# ("redraws tip random effects from the fitted N(0, Q_cond^-1 (x) Sigma_a) ... adds
# them to the fitted fixed effects"). The univariate path simply never followed it.
#
# Returns a closure `rng -> ysim`, or `nothing` when the fit has NO random effects
# (there conditional and marginal simulation coincide and `simulate` is correct).
function _marginal_simulator(fit::DrmFit, data; K=nothing, A=nothing, tree=nothing,
                             coords=nothing)
    fit.formula isa DrmFormula || return nothing
    # Gaussian needs a residual scale; other families carry their dispersion in the
    # family object or in `scales`, and some (Poisson) have none at all.
    (fit.family isa Gaussian && !haskey(fit.scales, :sigma)) && return nothing
    rhs = Dict(fit.formula.forms)
    haskey(rhs, :mu) || return nothing
    _, re, _, structured = _split_ranef(rhs[:mu])
    # No random effect on the mean: conditional and marginal coincide, and the
    # plain `simulate` is already correct. Nothing to build.
    (isempty(re) && structured === nothing) && return nothing

    # Which grouping factor, and what covariance does its random effect have?
    grp, Kg = if structured !== nothing
        g = structured[2]
        hasproperty(data, g) || return nothing
        _, G0 = _group_index(getproperty(data, g))
        # SCALE TRAP -- verified by round-trip, not assumed. `re_sd` for a PHYLO term
        # is defined against the RAW covariance `sigma_phy_dense(phy)`, whose diagonal
        # is the tree height, NOT the normalised correlation that
        # `_resolve_structured_matrix` returns. Drawing with the correlation matrix
        # under-disperses by sqrt(height): measured round-trip ratios across trees of
        # height 0.85/1.7/5.667 were 1.116/0.699/0.374 with the correlation matrix and
        # 1.032/0.917/0.917 with the raw one. relmat/animal are supplied by the user
        # and used as given, so there the resolver's matrix is already correct.
        if structured[1] === :phylo
            phy = tree isa AbstractString ? augmented_phy(tree) : tree
            phy === nothing && return nothing
            (g, sigma_phy_dense(phy; σ²_phy = 1.0))
        else
            (g, _resolve_structured_matrix(structured[1], g, G0;
                                           K=K, A=A, tree=tree, coords=coords))
        end
    else
        # Ordinary `(1 | g)`: independent random intercepts, so the covariance is I.
        length(re) == 1 || return nothing
        g = re[1][2]
        hasproperty(data, g) || return nothing
        _, G0 = _group_index(getproperty(data, g))
        (g, Matrix{Float64}(LinearAlgebra.I, G0, G0))
    end

    gidx, G = _group_index(getproperty(data, grp))
    size(Kg) == (G, G) || return nothing
    sds = re_sd(fit)
    (sds isa AbstractDict && haskey(sds, grp)) || return nothing
    sd_u = Float64(sds[grp])
    L = cholesky(Symmetric(Matrix{Float64}(Kg))).L

    # The FIXED-effect mean comes from `predict(fit, data)`, not from unpicking
    # `fit.means[:mu]`.
    #
    # Whether `means[:mu]` is conditional or marginal depends on the fitting route,
    # and there is NO usable rule -- measured 2026-08-24 across three routes:
    #
    #   route            ranef has BLUPs   means[:mu] is
    #   phylo(1|g)       yes               CONDITIONAL  (|means - Xb| = 1.53)
    #   relmat(1|g)      no                MARGINAL     (|means - Xb| = 0)
    #   ordinary (1|g)   yes               MARGINAL     (|means - Xb| = 0)
    #
    # So BLUP presence predicts nothing. Both plausible rules were tried and both
    # were wrong: subtracting whenever BLUPs exist double-REMOVES the random effect
    # on the ordinary route (round-trip ratio 1.46 ~ the sqrt(2) signature of
    # counting it twice), and never subtracting double-COUNTS it on the phylo route.
    #
    # `predict(fit, data)` returns the fixed-effect prediction on ALL THREE routes
    # (measured: |predict - Xb| = 0 exactly in each), so it answers the question
    # directly instead of inferring it. Fall back to `means[:mu]` only if `predict`
    # is unavailable, and refuse rather than guess if that is also unusable.
    mu_fixed = try
        v = Vector{Float64}(predict(fit, data))
        length(v) == length(fit.means[:mu]) ? v : nothing
    catch
        nothing
    end
    mu_fixed === nothing && return nothing

    if fit.family isa Gaussian
        sigma = Vector{Float64}(_scale_vector(fit, :sigma))
        n = length(mu_fixed)
        return function (rng)
            u = sd_u .* (L * randn(rng, G))
            return mu_fixed .+ u[gidx] .+ sigma .* randn(rng, n)
        end
    end

    # NON-GAUSSIAN (#462). The Gaussian branch above adds the random effect on the
    # RESPONSE scale because identity is the link. Everywhere else the random effect
    # lives on the LINK scale and has to pass through the inverse link before the
    # family draw:
    #
    #     eta* = Xb + Z u*        u* ~ N(0, sd_u^2 K)
    #     mu*  = linkinv(eta*)
    #     y*   ~ Family(mu*, aux)
    #
    # Measured before the fix: a Poisson `(1|g)` fit produced replicates with a
    # between-group SD of 0.696 against 2.690 in the observed data -- roughly a
    # quarter of the real group structure -- because the conditional simulator
    # reused the fitted mean.
    #
    # `predict(fit, data; type = :link)` is the marginal linear predictor (measured
    # exact for Poisson: |predict(link) - Xb| = 0), and `_simulate_once(fit, rng;
    # mu = ...)` reuses the verified per-family draw at the new mean rather than
    # duplicating it here.
    eta_fixed = try
        Vector{Float64}(predict(fit, data; type = :link))
    catch
        nothing
    end
    eta_fixed === nothing && return nothing
    length(eta_fixed) == fit.nobs || return nothing
    return function (rng)
        u = sd_u .* (L * randn(rng, G))
        mu_star = _mean_response(fit.family, eta_fixed .+ u[gidx])
        return _simulate_once(fit, rng; mu = mu_star)
    end
end

function _bootstrap_result(
    fit0,
    formula::DrmFormula,
    data,
    B::Int,
    level::Real,
    rng,
    threads::Bool,
    refit;
    failures::Symbol=:error,
    check_converged::Bool=false,
    simulate_fn=nothing,
)
    _check_bootstrap_failure_mode(failures)
    B >= 1 || throw(ArgumentError("bootstrap requires B >= 1"))
    est = coef(fit0)
    p = length(est)
    draws = Matrix{Float64}(undef, B, p)
    ok = falses(B)
    messages = Vector{Union{Nothing,String}}(nothing, B)
    seeds = rand(rng, UInt, B)

    function run_one!(b)
        rr = Random.MersenneTwister(seeds[b])
        try
            # Marginal draw when the fit has random effects (#459); the plain
            # `simulate` is conditional and collapses a variance-component CI.
            ysim = simulate_fn === nothing ? simulate(fit0; rng=rr) : simulate_fn(rr)
            datab = _bootstrap_data(formula, data, ysim)
            fitb = refit(datab)
            # `is_converged`, not the raw `.converged` field: the accessor also
            # rejects a degenerate optimum (sigma collapsed, likelihood runaway),
            # which the optimiser's own flag happily calls converged (#461).
            if check_converged && !is_converged(fitb)
                error("refit did not converge or landed on a degenerate optimum")
            end
            draws[b, :] = coef(fitb)
            ok[b] = true
        catch err
            messages[b] = sprint(showerror, err)
        end
        return nothing
    end

    threaded = threads && Threads.nthreads() > 1
    elapsed = @elapsed begin
        if threaded
            Threads.@threads for b in 1:B
                run_one!(b)
            end
        else
            for b in 1:B
                run_one!(b)
            end
        end
    end

    failure_rows = _BootstrapFailureRow[]
    for b in 1:B
        messages[b] === nothing && continue
        push!(failure_rows, (replicate=b, seed=seeds[b], message=messages[b]::String))
    end
    if !isempty(failure_rows) && failures === :error
        first_failure = first(failure_rows)
        throw(
            ErrorException(
                "bootstrap failed in $(length(failure_rows)) of $B replicates; first failure replicate $(first_failure.replicate), seed $(first_failure.seed): $(first_failure.message)",
            ),
        )
    end
    used = count(ok)
    used > 0 || throw(ErrorException("all $B bootstrap replicates failed"))
    summary = _bootstrap_summary_rows(fit0, draws[ok, :], est, level)
    return (
        summary=summary,
        failures=failure_rows,
        attempted=B,
        used=used,
        failed=length(failure_rows),
        seeds=seeds,
        threaded=threaded,
        worker_threads=_worker_threads(threaded, B),
        julia_threads=Threads.nthreads(),
        blas_threads=BLAS.get_num_threads(),
        blas_oversubscribed=_blas_oversubscribed(threaded),
        elapsed=elapsed,
        check_converged=check_converged,
    )
end

function _check_bootstrap_failure_mode(failures::Symbol)
    failures === :error && return nothing
    failures === :skip && return nothing
    throw(ArgumentError("bootstrap failures must be :error or :skip (got :$failures)"))
end

function _bootstrap_data(formula::DrmFormula, data, ysim)
    if formula.response2 === nothing
        return merge(data, NamedTuple{(formula.response,)}((ysim,)))
    end
    ntr =
        Float64.(getproperty(data, formula.response)) .+
        Float64.(getproperty(data, formula.response2))
    fail = ntr .- ysim
    return merge(data, NamedTuple{(formula.response, formula.response2)}((ysim, fail)))
end

function _bootstrap_ci_rows(rows)
    return _CIRow[
        (param=r.param, coef=r.coef, estimate=r.estimate, lower=r.lower, upper=r.upper) for
        r in rows
    ]
end

function _bootstrap_summary_rows(fit0, draws, est, level)
    α = (1 - level) / 2
    rows = _BootstrapSummaryRow[]
    # Index by the stored UnitRange `r` of each block, NOT a private sequential
    # counter (issue #325.3): `coef`/`vcov`/`draws` columns are in θ order, so the
    # block's own range `r` is the correct column set. A sequential `col += 1` is
    # correct only when the blocks partition 1:p contiguously and in θ order — a
    # latent misalignment if a future/bivariate fit reorders or gaps its blocks.
    for ((pp, r), (_, nms)) in zip(fit0.blocks, fit0.coefnames)
        for (j, col) in enumerate(r)
            v = @view draws[:, col]
            push!(
                rows,
                (
                    param=pp,
                    coef=nms[j],
                    estimate=est[col],
                    std_error=Statistics.std(v),
                    lower=Statistics.quantile(v, α),
                    upper=Statistics.quantile(v, 1 - α),
                ),
            )
        end
    end
    return rows
end

# Max |∂nll/∂θ| at the estimate. A location–scale fit carries a `LocScaleObjective`
# whose inner mode-solve is Float64-only (not dual-number safe), so ForwardDiff
# can't differentiate it — use its exact analytic outer gradient instead (which
# also upgrades the diagnostic from NaN to a real gradient norm). Sparse q=4
# fits can store a Float64-only gradient callback; use it before trying
# ForwardDiff through the objective. `nothing` means no objective → NaN.
function _check_max_abs_grad(fit::DrmFit)
    fit.nll === nothing && return NaN
    if fit.nll isa LocScaleObjective
        o = fit.nll
        base = size(o.Xμ, 2) + size(o.Xψ, 2)
        perm = vcat(collect(1:base), [base + 1, base + 3, base + 2])  # recov→engine
        g = _ls_marginal_grad(o.kind, o.y, o.Xμ, o.Xψ, o.gidx, o.G, o.Q, fit.theta[perm])
        return maximum(abs, g)
    end
    if fit.nllgrad !== nothing
        g = zeros(length(fit.theta))
        fit.nllgrad(g, fit.theta)
        return maximum(abs, g)
    end
    return maximum(abs, ForwardDiff.gradient(fit.nll, fit.theta))
end

"""
    check_drm(fit) -> NamedTuple

Post-fit convergence / identifiability diagnostics — drmTMB's `check_drm()`.
Returns a `NamedTuple` and logs a short report:

- `converged` — the optimiser's convergence flag.
- `max_abs_grad` — `max|∇nll|` at the optimum (≈ 0 at a clean interior optimum;
  `NaN` if the objective was not stored on the fit).
- `vcov_complete` — whether the stored covariance is finite throughout. Some
  routes report a **partial** covariance by design: the sparse phylo fitter
  computes the fixed-effect block and leaves the variance-component block `NaN`.
  When this is `false` the three fields below cannot be computed and are reported
  as `false` / `NaN` / `Inf` rather than raising.
- `vcov_posdef` — whether the stored covariance is positive-definite (drmTMB's
  `sdreport` is all-`NaN` exactly when this fails).
- `min_eigval` / `cond` — smallest eigenvalue and condition number of the
  covariance; a near-zero `min_eigval` flags a singular / weakly identified
  direction (e.g. a variance pinned at the boundary).
- `penalized_map` — whether this is a penalized (MAP) fit
  (`penalty = drm_phylo_penalty(...)`). Such a fit reports standard errors from
  the *penalized* curvature, which are credible-interval-shaped rather than
  frequentist, and `loglik` is the *unpenalized* data log-likelihood.
- `ok` — `true` when converged, the gradient is small, and the covariance is PD.
  On a penalized fit the gradient criterion is **dropped**: the stored objective
  is unpenalized, so its gradient is non-zero at the MAP optimum by construction
  and scoring it would report a correct fit as broken.

A non-`ok` result is informative, not an error: a model sitting on a variance
boundary (Watanabe-singular) can be the data's MLE, with valid Wald SEs on the
remaining directions — see [`confint`](@ref).
"""
function check_drm(fit::DrmFit; grad_tol::Real=1e-3)
    mag = _check_max_abs_grad(fit)
    V = fit.vcov
    # A diagnostic must REPORT trouble, not crash on it. Several routes return a
    # deliberately PARTIAL covariance — the sparse phylo fitter
    # (`_fit_structured_gaussian_sparse_lbfgs`) computes the β block and leaves the
    # variance-component block as NaN — and `isposdef`/`eigvals` throw outright on a
    # non-finite matrix. Running the documented health check on a perfectly good
    # phylo fit then raised `ArgumentError: matrix contains Infs or NaNs` instead of
    # returning a report, which is backwards. Report the incompleteness as a field.
    vcov_complete = all(isfinite, V)
    pd, mineig, cnd = if vcov_complete
        _pd = isposdef(Symmetric(V))
        ev = eigvals(Symmetric(V))
        _mineig = minimum(ev)
        _maxeig = maximum(ev)
        (_pd, _mineig, _mineig > 0 ? _maxeig / _mineig : Inf)
    else
        (false, NaN, Inf)
    end
    # A4c: on a penalized (MAP) fit the stored objective is the UNPENALIZED
    # likelihood, whose gradient is deliberately NON-ZERO at the MAP optimum — the
    # penalty's gradient is what cancels it. Scoring that as non-convergence would
    # report a correct fit as broken, so the gradient criterion is dropped for MAP
    # fits and `max_abs_grad` is reported for information only.
    penalized = fit.estim_method === :MAP
    ok = fit.converged && (penalized || isnan(mag) || mag <= grad_tol) && pd
    report = (
        converged=fit.converged,
        max_abs_grad=mag,
        vcov_complete=vcov_complete,
        vcov_posdef=pd,
        min_eigval=mineig,
        cond=cnd,
        penalized_map=penalized,
        ok=ok,
    )
    @info "check_drm" converged = report.converged max_abs_grad = report.max_abs_grad vcov_complete =
        report.vcov_complete vcov_posdef = report.vcov_posdef min_eigval = report.min_eigval cond =
        report.cond penalized_map = report.penalized_map ok = report.ok
    vcov_complete || @warn "check_drm: the stored covariance has non-finite entries, so " *
        "`vcov_posdef` / `min_eigval` / `cond` could not be computed and `ok` is false. This is " *
        "EXPECTED on routes that report a partial covariance — the sparse phylo fitter computes " *
        "the fixed-effect block only. Wald SEs on the finite directions are still usable; for the " *
        "variance components use `profile_ci = true` or `profile_result`."
    # drmTMB emits the equivalent advisory from `check_penalized_fit()`.
    penalized && @warn "check_drm: penalized (MAP) fit — standard errors come from the penalized " *
        "curvature and are credible-interval-shaped, not frequentist. `loglik` is the UNPENALIZED " *
        "data log-likelihood; the penalty is `fit.phylo_penalty`. `lrtest`/`anova` across " *
        "penalized fits are refused."
    return report
end
