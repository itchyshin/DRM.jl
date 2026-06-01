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
"""
stderror(fit::DrmFit) = sqrt.(diag(fit.vcov))

const _CIRow = NamedTuple{(:param, :coef, :estimate, :lower, :upper),
    Tuple{Symbol,String,Float64,Float64,Float64}}

"""
    confint(fit; level = 0.95, method = :wald, threads = false)

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

Mirrors drmTMB's `confint(fit, method = "wald" | "profile")`.
"""
function confint(fit::DrmFit; level::Real = 0.95, method::Symbol = :wald,
                 threads::Bool = false)
    method === :wald && return _wald_ci(fit, level)
    method === :profile && return _profile_ci(fit, level; threads = threads)
    throw(ArgumentError("confint: method must be :wald or :profile (got :$method)"))
end

function _wald_ci(fit::DrmFit, level::Real)
    se = stderror(fit)
    z = quantile(Normal(), 1 - (1 - level) / 2)
    rows = _CIRow[]
    for ((p, r), (_, nms)) in zip(fit.blocks, fit.coefnames)
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
function _profiled_nll(nll, θ̂::Vector{Float64}, k::Int, v::Real, u0::Vector{Float64})
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
    res = Optim.optimize(obj, u0, Optim.LBFGS(); autodiff = :forward)
    return (Optim.minimum(res), Optim.minimizer(res))
end

# Analytic slope of the PROFILED nll in θ[k], by the envelope theorem: at the
# profiled optimum the nuisance partials vanish, so d/dv [min_u nll] = ∂nll/∂θ_k
# evaluated at (v, û). One ForwardDiff gradient component — no extra solves.
function _profile_slope(nll, θ̂::Vector{Float64}, k::Int, v::Real, û::Vector{Float64})
    p = length(θ̂)
    idx = [i for i in 1:p if i != k]
    θ = Vector{Float64}(undef, p)
    θ[k] = float(v)
    @inbounds for (t, i) in enumerate(idx)
        θ[i] = û[t]
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
function _profile_endpoint(nll, θ̂, k, nllhat, half, s, dir, u0)
    target = nllhat + half
    p = length(θ̂)
    nidx = p - 1
    û = copy(u0)
    # h(t) and its derivative h'(t); updates û in place for warm-starting.
    function heval(t)
        f, unew = _profiled_nll(nll, θ̂, k, θ̂[k] + dir * t, û)
        isempty(unew) || (û = unew)
        hp = nidx == 0 ? NaN : dir * _profile_slope(nll, θ̂, k, θ̂[k] + dir * t, û)
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

function _profile_ci(fit::DrmFit, level::Real; threads::Bool = false)
    fit.nll === nothing &&
        throw(ArgumentError("profile intervals require the fitted objective; this model was not built with one"))
    nll = fit.nll
    θ̂ = copy(fit.theta)
    nllhat = nll(θ̂)
    half = quantile(Chisq(1), level) / 2           # nll rises by χ²₁/2 at each endpoint
    se = stderror(fit)
    jobs = NamedTuple{(:param, :coef, :k),Tuple{Symbol,String,Int}}[]
    for ((pp, r), (_, nms)) in zip(fit.blocks, fit.coefnames)
        for (j, k) in enumerate(r)
            push!(jobs, (param = pp, coef = nms[j], k = k))
        end
    end
    rows = Vector{_CIRow}(undef, length(jobs))
    if threads && Threads.nthreads() > 1
        Threads.@threads for i in eachindex(jobs)
            rows[i] = _profile_row(jobs[i], nll, θ̂, nllhat, half, se)
        end
    else
        for i in eachindex(jobs)
            rows[i] = _profile_row(jobs[i], nll, θ̂, nllhat, half, se)
        end
    end
    return rows
end

function _profile_row(job, nll, θ̂, nllhat, half, se)
    k = job.k
    est = θ̂[k]
    s = (isfinite(se[k]) && se[k] > 0) ? se[k] : max(abs(est), 1.0)
    u0 = θ̂[[i for i in 1:length(θ̂) if i != k]]
    lo = _profile_endpoint(nll, θ̂, k, nllhat, half, s, -1, u0)
    hi = _profile_endpoint(nll, θ̂, k, nllhat, half, s, +1, u0)
    return (param = job.param, coef = job.coef, estimate = est, lower = lo, upper = hi)
end

"""
    bootstrap_ci(formula, family; data, B = 300, level = 0.95, rng = default_rng(), threads = false, K =, A =, tree =)

Parametric bootstrap confidence intervals: fit the model, then `simulate` `B`
replicate responses, refit each, and take percentile intervals per coefficient.
Univariate-response models (fixed / random-effect / meta / structured). Same row
shape as [`confint`](@ref). Set `threads = true` to refit bootstrap replicates
in parallel. Pass through the structured-matrix keywords (`K` / `A` / `tree`)
exactly as to [`drm`](@ref).
"""
function bootstrap_ci(formula::DrmFormula, family::Gaussian; data, B::Int = 300,
        level::Real = 0.95, rng = default_rng(), K = nothing, A = nothing,
        tree = nothing, threads::Bool = false)
    fit0 = drm(formula, family; data, K, A, tree)
    est = coef(fit0)
    p = length(est)
    draws = Matrix{Float64}(undef, B, p)
    seeds = rand(rng, UInt, B)
    if threads && Threads.nthreads() > 1
        Threads.@threads for b in 1:B
            rr = Random.MersenneTwister(seeds[b])
            ysim = simulate(fit0; rng = rr)
            datab = _bootstrap_data(formula, data, ysim)
            draws[b, :] = coef(drm(formula, family; data = datab, K, A, tree))
        end
    else
        for b in 1:B
            rr = Random.MersenneTwister(seeds[b])
            ysim = simulate(fit0; rng = rr)
            datab = _bootstrap_data(formula, data, ysim)
            draws[b, :] = coef(drm(formula, family; data = datab, K, A, tree))
        end
    end
    return _bootstrap_rows(fit0, draws, est, level)
end

# Family-agnostic parametric bootstrap — any family `simulate` supports. No
# structured-matrix keywords (those are Gaussian-only). Same row shape as the
# Gaussian method and `confint`.
function bootstrap_ci(formula::DrmFormula, family; data, B::Int = 300,
        level::Real = 0.95, rng = default_rng(), threads::Bool = false)
    fit0 = drm(formula, family; data)
    est = coef(fit0)
    p = length(est)
    draws = Matrix{Float64}(undef, B, p)
    seeds = rand(rng, UInt, B)
    if threads && Threads.nthreads() > 1
        Threads.@threads for b in 1:B
            rr = Random.MersenneTwister(seeds[b])
            ysim = simulate(fit0; rng = rr)
            datab = _bootstrap_data(formula, data, ysim)
            draws[b, :] = coef(drm(formula, family; data = datab))
        end
    else
        for b in 1:B
            rr = Random.MersenneTwister(seeds[b])
            ysim = simulate(fit0; rng = rr)
            datab = _bootstrap_data(formula, data, ysim)
            draws[b, :] = coef(drm(formula, family; data = datab))
        end
    end
    return _bootstrap_rows(fit0, draws, est, level)
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

function _bootstrap_rows(fit0, draws, est, level)
    α = (1 - level) / 2
    rows = NamedTuple{(:param, :coef, :estimate, :lower, :upper),
        Tuple{Symbol,String,Float64,Float64,Float64}}[]
    col = 1
    for ((pp, r), (_, nms)) in zip(fit0.blocks, fit0.coefnames)
        for (j, _) in enumerate(r)
            v = @view draws[:, col]
            push!(rows, (param = pp, coef = nms[j], estimate = est[col],
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
