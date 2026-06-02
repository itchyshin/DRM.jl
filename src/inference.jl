# inference.jl — Wald + profile-likelihood inference for fitted DRM models.
# Wald: estimate ± z·se from the observed information stored on the fit, on each
# parameter's working scale (log σ, atanh ρ12, log σ_b). Profile: invert the
# likelihood-ratio statistic — the endpoints where 2(ℓ̂ − ℓ_profile) = χ²₁(level),
# re-optimising the nuisance parameters at each fixed value. Mirrors drmTMB's
# `confint(..., method = "wald" | "profile")`.

using LinearAlgebra: diag, isposdef, Symmetric, eigvals
using Distributions: Normal, Chisq, quantile
import Optim
import Random
import Statistics
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

const _CIRow = NamedTuple{(:param, :coef, :estimate, :lower, :upper),
    Tuple{Symbol,String,Float64,Float64,Float64}}

const _BootstrapSummaryRow = NamedTuple{(:param, :coef, :estimate, :std_error, :lower, :upper),
    Tuple{Symbol,String,Float64,Float64,Float64,Float64}}

const _BootstrapFailureRow = NamedTuple{(:replicate, :seed, :message),
    Tuple{Int,UInt,String}}

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
  quadratic-approximate). Works on any fitted Gaussian model. The endpoint search
  uses warm-start continuation (each profiled solve starts from the previous
  point's optimum) and a guarded-Newton root-find driven by the envelope-theorem
  slope `∂nll/∂θ_k`, falling back to bisection — bracket-guaranteed correctness,
  far fewer inner re-optimisations than cold-started bisection.
  Pass `threads = true` to profile coefficients in parallel when the fitted
  objective is thread-safe.
- `parm = :resd` or `parm = [:mu, :resd]` — restrict intervals to one or more
  parameter blocks. This is especially useful for profiling random-effect SDs
  without also profiling fixed-effect coefficients.

Mirrors drmTMB's `confint(fit, method = "wald" | "profile")`.
"""
function confint(fit::DrmFit; level::Real = 0.95, method::Symbol = :wald,
                 threads::Bool = false, parm = nothing)
    method === :wald && return _wald_ci(fit, level, parm)
    method === :profile && return _profile_ci(fit, level; threads = threads, parm = parm)
    throw(ArgumentError("confint: method must be :wald or :profile (got :$method)"))
end

function _ci_param_selected(param::Symbol, parm)
    parm === nothing && return true
    parm isa Symbol && return param === parm
    parm isa AbstractVector{Symbol} && return param in parm
    throw(ArgumentError("confint: parm must be nothing, a Symbol, or a Vector{Symbol}"))
end

function _wald_ci(fit::DrmFit, level::Real, parm)
    se = stderror(fit)
    z = quantile(Normal(), 1 - (1 - level) / 2)
    rows = _CIRow[]
    for ((p, r), (_, nms)) in zip(fit.blocks, fit.coefnames)
        _ci_param_selected(p, parm) || continue
        for (j, idx) in enumerate(r)
            est = fit.theta[idx]
            s = se[idx]
            push!(rows, (param = p, coef = nms[j], estimate = est, lower = est - z * s, upper = est + z * s))
        end
    end
    return rows
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

function _profiled_nll(nll, θ̂::Vector{Float64}, k::Int, v::Real, u0::Vector{Float64};
                       autodiff::Symbol = :forward, nllgrad = nothing)
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
    res = _profile_optimize(obj, u0, autodiff; grad! = grad_u!)
    return (Optim.minimum(res), Optim.minimizer(res))
end

function _profile_optimize(obj, u0::Vector{Float64}, autodiff::Symbol; grad! = nothing)
    if grad! !== nothing
        try
            od = Optim.OnceDifferentiable(obj, grad!, u0)
            method = Optim.LBFGS(linesearch = Optim.LineSearches.BackTracking())
            return Optim.optimize(od, u0, method, Optim.Options(iterations = 80))
        catch
            return Optim.optimize(obj, u0, Optim.LBFGS(); autodiff = :finite)
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
function _profile_slope(nll, nllgrad, θ̂::Vector{Float64}, k::Int, v::Real, û::Vector{Float64})
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
    target = nllhat + half
    p = length(θ̂)
    nidx = p - 1
    û = copy(u0)
    # h(t) and its derivative h'(t); updates û in place for warm-starting.
    function heval(t)
        f, unew = _profiled_nll(nll, θ̂, k, θ̂[k] + dir * t, û; autodiff, nllgrad)
        isempty(unew) || (û = unew)
        hp = (nidx == 0 || autodiff === :finite) ? NaN :
            dir * _profile_slope(nll, nllgrad, θ̂, k, θ̂[k] + dir * t, û)
        return (f - target, hp)
    end
    # Bracket: expand until h > 0.
    tlo = 0.0
    thi = s; (hhi, _) = heval(thi); iters = 0
    while hhi < 0 && iters < 40
        tlo = thi; thi *= 1.6; (hhi, _) = heval(thi); iters += 1
    end
    hhi < 0 && return dir < 0 ? -Inf : Inf          # profile never crosses → unbounded
    # Guarded Newton on [tlo, thi].
    t = (tlo + thi) / 2
    for _ in 1:60
        (ht, hp) = heval(t)
        abs(ht) < 1e-9 && break
        ht < 0 ? (tlo = t) : (thi = t)
        tn = (isfinite(hp) && hp > 0) ? t - ht / hp : (tlo + thi) / 2   # Newton, else bisect
        t = (tlo < tn < thi) ? tn : (tlo + thi) / 2                     # guard into bracket
        thi - tlo < 1e-8 && break
    end
    return θ̂[k] + dir * t
end

function _profile_ci(fit::DrmFit, level::Real; threads::Bool = false, parm = nothing)
    fit.nll === nothing &&
        throw(ArgumentError("profile intervals require the fitted objective; this model was not built with one"))
    nll = fit.nll
    nllgrad = fit.nllgrad
    θ̂ = copy(fit.theta)
    nllhat = nll(θ̂)
    autodiff = _profile_autodiff_mode(nll, nllgrad, θ̂)
    half = quantile(Chisq(1), level) / 2           # nll rises by χ²₁/2 at each endpoint
    se = stderror(fit)
    jobs = NamedTuple{(:param, :coef, :k),Tuple{Symbol,String,Int}}[]
    for ((pp, r), (_, nms)) in zip(fit.blocks, fit.coefnames)
        _ci_param_selected(pp, parm) || continue
        for (j, k) in enumerate(r)
            push!(jobs, (param = pp, coef = nms[j], k = k))
        end
    end
    rows = Vector{_CIRow}(undef, length(jobs))
    if threads && Threads.nthreads() > 1
        Threads.@threads for i in eachindex(jobs)
            rows[i] = _profile_row(jobs[i], nll, nllgrad, θ̂, nllhat, half, se, autodiff)
        end
    else
        for i in eachindex(jobs)
            rows[i] = _profile_row(jobs[i], nll, nllgrad, θ̂, nllhat, half, se, autodiff)
        end
    end
    return rows
end

function _profile_row(job, nll, nllgrad, θ̂, nllhat, half, se, autodiff)
    k = job.k
    est = θ̂[k]
    s = (isfinite(se[k]) && se[k] > 0) ? se[k] : max(abs(est), 1.0)
    u0 = θ̂[[i for i in 1:length(θ̂) if i != k]]
    lo = _profile_endpoint(nll, nllgrad, θ̂, k, nllhat, half, s, -1, u0, autodiff)
    hi = _profile_endpoint(nll, nllgrad, θ̂, k, nllhat, half, s, +1, u0, autodiff)
    return (param = job.param, coef = job.coef, estimate = est, lower = lo, upper = hi)
end

"""
    bootstrap_ci(formula, family; data, B = 300, level = 0.95, rng = default_rng(), threads = false, K =, A =, tree =)

Parametric bootstrap confidence intervals: fit the model, then `simulate` `B`
replicate responses, refit each, and take percentile intervals per coefficient.
Univariate-response models (fixed / random-effect / meta / structured). Same row
shape as [`confint`](@ref). Set `threads = true` to refit bootstrap replicates
in parallel. Pass through the structured-matrix keywords (`K` / `A` / `tree`)
exactly as to [`drm`](@ref). Use `bootstrap_result` when you need
attempted/used/failed counts and per-replicate failure messages.
"""
function bootstrap_ci(formula::DrmFormula, family::Gaussian; data, B::Int = 300,
        level::Real = 0.95, rng = default_rng(), K = nothing, A = nothing,
        tree = nothing, threads::Bool = false, failures::Symbol = :error,
        check_converged::Bool = false)
    rows = bootstrap_summary(formula, family; data, B, level, rng, K, A, tree,
        threads, failures, check_converged)
    return _bootstrap_ci_rows(rows)
end

# Family-agnostic parametric bootstrap — any family `simulate` supports. No
# structured-matrix keywords (those are Gaussian-only). Same row shape as the
# Gaussian method and `confint`.
function bootstrap_ci(formula::DrmFormula, family; data, B::Int = 300,
        level::Real = 0.95, rng = default_rng(), threads::Bool = false,
        failures::Symbol = :error, check_converged::Bool = false)
    rows = bootstrap_summary(formula, family; data, B, level, rng, threads,
        failures, check_converged)
    return _bootstrap_ci_rows(rows)
end

"""
    bootstrap_summary(formula, family; data, B = 300, level = 0.95, rng = default_rng(), threads = false, K =, A =, tree =)

Parametric bootstrap coefficient summaries in one pass: point estimate,
bootstrap standard error, and percentile confidence interval. This is the
bootstrap analogue of using `stderror(fit)` plus `confint(fit)`, avoiding a
second bootstrap run when both SEs and intervals are needed. Row fields are
`(param, coef, estimate, std_error, lower, upper)`. By default, any failed
replicate errors after all failures are recorded. Set `failures = :skip` to
compute summaries from successful replicates; call `bootstrap_result` to
inspect the skipped failures.
"""
function bootstrap_summary(formula::DrmFormula, family::Gaussian; data, B::Int = 300,
        level::Real = 0.95, rng = default_rng(), K = nothing, A = nothing,
        tree = nothing, threads::Bool = false, failures::Symbol = :error,
        check_converged::Bool = false)
    result = bootstrap_result(formula, family; data, B, level, rng, K, A, tree,
        threads, failures, check_converged)
    return result.summary
end

# Family-agnostic summary method — any family `simulate` supports. No structured
# matrix keywords; those are Gaussian-only.
function bootstrap_summary(formula::DrmFormula, family; data, B::Int = 300,
        level::Real = 0.95, rng = default_rng(), threads::Bool = false,
        failures::Symbol = :error, check_converged::Bool = false)
    result = bootstrap_result(formula, family; data, B, level, rng, threads,
        failures, check_converged)
    return result.summary
end

"""
    bootstrap_result(formula, family; data, B = 300, level = 0.95, rng = default_rng(), threads = false, failures = :error, check_converged = false, K =, A =, tree =)

Auditable parametric bootstrap. Returns a `NamedTuple` with:

- `summary` — the same rows returned by `bootstrap_summary`;
- `failures` — rows `(replicate, seed, message)` for failed refits;
- `attempted`, `used`, `failed` — replicate counts;
- `seeds` — the per-replicate seeds used for reproducibility;
- `threaded` — whether threaded refits were actually used.

`failures = :error` (default) records failures and then errors if any replicate
failed. `failures = :skip` computes summaries from successful replicates and
keeps the failure records in the return value. Set `check_converged = true` to
treat non-converged refits as failed replicates.
"""
function bootstrap_result(formula::DrmFormula, family::Gaussian; data, B::Int = 300,
        level::Real = 0.95, rng = default_rng(), K = nothing, A = nothing,
        tree = nothing, threads::Bool = false, failures::Symbol = :error,
        check_converged::Bool = false)
    _check_bootstrap_failure_mode(failures)
    fit0 = drm(formula, family; data, K, A, tree)
    refit = datab -> drm(formula, family; data = datab, K, A, tree)
    return _bootstrap_result(fit0, formula, data, B, level, rng, threads, refit;
        failures, check_converged)
end

function bootstrap_result(formula::DrmFormula, family; data, B::Int = 300,
        level::Real = 0.95, rng = default_rng(), threads::Bool = false,
        failures::Symbol = :error, check_converged::Bool = false)
    _check_bootstrap_failure_mode(failures)
    fit0 = drm(formula, family; data)
    refit = datab -> drm(formula, family; data = datab)
    return _bootstrap_result(fit0, formula, data, B, level, rng, threads, refit;
        failures, check_converged)
end

function _bootstrap_result(fit0, formula::DrmFormula, data, B::Int, level::Real,
        rng, threads::Bool, refit; failures::Symbol = :error,
        check_converged::Bool = false)
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
            ysim = simulate(fit0; rng = rr)
            datab = _bootstrap_data(formula, data, ysim)
            fitb = refit(datab)
            if check_converged && !fitb.converged
                error("refit did not converge")
            end
            draws[b, :] = coef(fitb)
            ok[b] = true
        catch err
            messages[b] = sprint(showerror, err)
        end
        return nothing
    end

    threaded = threads && Threads.nthreads() > 1
    if threaded
        Threads.@threads for b in 1:B
            run_one!(b)
        end
    else
        for b in 1:B
            run_one!(b)
        end
    end

    failure_rows = _BootstrapFailureRow[]
    for b in 1:B
        messages[b] === nothing && continue
        push!(failure_rows, (replicate = b, seed = seeds[b], message = messages[b]::String))
    end
    if !isempty(failure_rows) && failures === :error
        first_failure = first(failure_rows)
        throw(ErrorException("bootstrap failed in $(length(failure_rows)) of $B replicates; first failure replicate $(first_failure.replicate), seed $(first_failure.seed): $(first_failure.message)"))
    end
    used = count(ok)
    used > 0 || throw(ErrorException("all $B bootstrap replicates failed"))
    summary = _bootstrap_summary_rows(fit0, draws[ok, :], est, level)
    return (summary = summary, failures = failure_rows, attempted = B, used = used,
        failed = length(failure_rows), seeds = seeds, threaded = threaded,
        check_converged = check_converged)
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
    ntr = Float64.(getproperty(data, formula.response)) .+
          Float64.(getproperty(data, formula.response2))
    fail = ntr .- ysim
    return merge(data, NamedTuple{(formula.response, formula.response2)}((ysim, fail)))
end

function _bootstrap_ci_rows(rows)
    return _CIRow[(param = r.param, coef = r.coef, estimate = r.estimate,
        lower = r.lower, upper = r.upper) for r in rows]
end

function _bootstrap_summary_rows(fit0, draws, est, level)
    α = (1 - level) / 2
    rows = _BootstrapSummaryRow[]
    col = 1
    for ((pp, r), (_, nms)) in zip(fit0.blocks, fit0.coefnames)
        for (j, _) in enumerate(r)
            v = @view draws[:, col]
            push!(rows, (param = pp, coef = nms[j], estimate = est[col],
                std_error = Statistics.std(v),
                lower = Statistics.quantile(v, α), upper = Statistics.quantile(v, 1 - α)))
            col += 1
        end
    end
    return rows
end

"""
    check_drm(fit) -> NamedTuple

Post-fit convergence / identifiability diagnostics — drmTMB's `check_drm()`.
Returns a `NamedTuple` and logs a short report:

- `converged` — the optimiser's convergence flag.
- `max_abs_grad` — `max|∇nll|` at the optimum (≈ 0 at a clean interior optimum;
  `NaN` if the objective was not stored on the fit).
- `vcov_posdef` — whether the stored covariance is positive-definite (drmTMB's
  `sdreport` is all-`NaN` exactly when this fails).
- `min_eigval` / `cond` — smallest eigenvalue and condition number of the
  covariance; a near-zero `min_eigval` flags a singular / weakly identified
  direction (e.g. a variance pinned at the boundary).
- `ok` — `true` when converged, the gradient is small, and the covariance is PD.

A non-`ok` result is informative, not an error: a model sitting on a variance
boundary (Watanabe-singular) can be the data's MLE, with valid Wald SEs on the
remaining directions — see [`confint`](@ref).
"""
function check_drm(fit::DrmFit; grad_tol::Real = 1e-3)
    mag = fit.nll === nothing ? NaN : maximum(abs, ForwardDiff.gradient(fit.nll, fit.theta))
    V = fit.vcov
    pd = isposdef(Symmetric(V))
    ev = eigvals(Symmetric(V))
    mineig = minimum(ev); maxeig = maximum(ev)
    cnd = mineig > 0 ? maxeig / mineig : Inf
    ok = fit.converged && (isnan(mag) || mag <= grad_tol) && pd
    report = (converged = fit.converged, max_abs_grad = mag, vcov_posdef = pd,
              min_eigval = mineig, cond = cnd, ok = ok)
    @info "check_drm" converged=report.converged max_abs_grad=report.max_abs_grad vcov_posdef=report.vcov_posdef min_eigval=report.min_eigval cond=report.cond ok=report.ok
    return report
end
