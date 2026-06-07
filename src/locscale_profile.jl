# locscale_profile.jl — profile-likelihood confidence intervals for the q=2
# location–scale fit (#202). The right uncertainty tool where Wald is poor — the
# group-covariance (variance/correlation) parameters near weak identification.
#
# For a packed parameter `idx`, the profile NLL fixes θ[idx] and re-optimises the
# rest. Three design choices make this robust AND fast:
#  * the constrained inner solve uses a TRUST-REGION NEWTON (exact reduced
#    gradient + the observed-information slice as Hessian), like `_fit_locscale`,
#    so a transient step toward the variance boundary shrinks the trust radius
#    instead of crashing the line search;
#  * the χ²₁ crossing is found by a VENZON–MOOLGAVKAR-style guarded-Newton root-
#    find that uses the profile deviance AND its envelope-theorem slope
#    (∂nll/∂θ[idx] at the constrained optimum, from the exact gradient), with a
#    bracket/bisection safeguard for guaranteed correctness — far fewer
#    constrained re-optimisations than a fixed bisection schedule;
#  * everything is WARM-STARTED across profile points (free-parameter init + inner
#    mode), and the brackets are SEEDED from the Wald half-width.
#
# Variance/correlation robustness: profiling such a parameter toward its boundary
# can drive Λ near-singular, so the constrained solve returns the documented
# infeasible sentinel. The root-finder treats an infeasible trial as a hard
# boundary (an unbounded direction → ±Inf if no crossing was bracketed) rather
# than crashing — so `confint(:profile)` works on the FULL parameter vector.

import Distributions

# Marginal-NLL sentinel: `_ls_fit_nll` / the profile inner objective return this
# when the inner mode (or the prior factorisation) is infeasible — e.g. a profiled
# variance/correlation parameter driven toward its boundary makes Λ near-singular.
# A constrained optimum whose value is at/above this is treated as INFEASIBLE.
const _LS_PROFILE_INFEASIBLE = 1e18

# Profile NLL at θ[idx] = val: minimise the marginal over the other packed params.
# `x0` seeds the free-parameter optimisation (warm-start across profile points);
# `mwarm` is the shared inner-mode warm-start Ref. Returns (minval, minimizer, ok)
# where `ok = false` flags an infeasible constrained solve (the value sentinel or
# a non-finite optimum), so the endpoint search can treat that trial as a boundary
# rather than a genuine deviance crossing.
function _ls_profile_nll(kind, y, Xμ, Xψ, gidx, G, Q, θ̂, idx::Int, val::Real;
                         x0 = nothing, mwarm = Ref{Union{Nothing,Vector{Float64}}}(nothing))
    p = length(θ̂); pμ = size(Xμ, 2); pψ = size(Xψ, 2)
    free = [k for k in 1:p if k != idx]
    build(θf) = (θ = collect(float.(θ̂)); θ[free] .= θf; θ[idx] = val; θ)
    function f(θf)
        θ = build(θf)
        βμ = @view θ[1:pμ]; βψ = @view θ[pμ+1:pμ+pψ]
        Λ = _ls_lc_to_Λ(θ[pμ+pψ+1:pμ+pψ+3])
        P = prior_precision(Q, _ls_inv2x2(Λ))
        v, a, ok = _ls_marginal_nll(kind, y, Xμ * βμ, Xψ * βψ, gidx, G, P; a0 = mwarm[])
        ok && (mwarm[] = copy(a))
        return ok ? v : _LS_PROFILE_INFEASIBLE
    end
    function g!(gf, θf)
        gfull = _ls_marginal_grad(kind, y, Xμ, Xψ, gidx, G, Q, build(θf); a0 = mwarm[])
        gf .= gfull[free]
        return gf
    end
    function h!(Hf, θf)
        H = Matrix(_ls_obs_information(kind, y, Xμ, Xψ, gidx, G, Q, build(θf); a0 = mwarm[]))
        Hf .= H[free, free]
        return Hf
    end
    init = x0 === nothing ? float.(θ̂[free]) : float.(x0)
    res = Optim.optimize(f, g!, h!, init, Optim.NewtonTrustRegion(),
                         Optim.Options(g_tol = 1e-7, iterations = 200))
    minval = Optim.minimum(res)
    xmin = Optim.minimizer(res)
    ok = isfinite(minval) && minval < _LS_PROFILE_INFEASIBLE / 2 && all(isfinite, xmin)
    return minval, xmin, ok
end

# Venzon–Moolgavkar-style endpoint search. Find t ≥ 0 where the profile-deviance
# gap h(t) = profile_nll(x0 + dir·t) − thr crosses zero (h(0) < 0; h increasing in
# t). The work splits into a SHORT bracket expansion to straddle the crossing,
# then a GUARDED NEWTON refinement using the analytic envelope-theorem slope
# h'(t) = dir·∂nll/∂θ[idx], falling back to bisection whenever a Newton step would
# leave the maintained bracket or the slope is unusable — so correctness is
# bracket-guaranteed while the slope buys quadratic convergence.
#
# `evalh(val) -> (gap, slope, ok)` returns the profile gap, its θ[idx]-slope (NOT
# yet multiplied by `dir`), and a feasibility flag. `ok = false` means the
# constrained solve was infeasible at `val` (Λ near-singular): if no crossing has
# been bracketed yet, the endpoint is unbounded (±Inf); once bracketed, the upper
# bracket end is pulled in so the root stays in the feasible region.
function _ls_profile_root(evalh, x0; dir::Float64, init::Float64,
                          maxexpand::Int = 40, maxnewton::Int = 30,
                          ftol::Float64 = 1e-7, xtol::Float64 = 1e-8)
    tlo = 0.0                                   # h(tlo) < 0 (feasible by construction)
    thi = init
    ghi = -1.0; shi = NaN; bracketed = false
    for _ in 1:maxexpand
        gap, slope, ok = evalh(x0 + dir * thi)
        ok || return dir > 0 ? Inf : -Inf       # infeasible before a crossing → unbounded
        if gap > 0
            ghi = gap; shi = slope; bracketed = true; break
        end
        tlo = thi; thi *= 1.6
    end
    bracketed || return dir > 0 ? Inf : -Inf

    # Guarded Newton on [tlo, thi]: h(tlo) < 0 ≤ h(thi). Start at the bracketed
    # upper end and walk inward.
    t = thi; gap = ghi; slope = shi
    for _ in 1:maxnewton
        abs(gap) < ftol && break
        thi - tlo < xtol && break
        gap > 0 ? (thi = t) : (tlo = t)
        sd = dir * slope                        # chain factor: h'(t) = dir·∂nll/∂θ[idx]
        tn = (isfinite(sd) && sd > 0) ? t - gap / sd : (tlo + thi) / 2
        tnext = (tlo < tn < thi) ? tn : (tlo + thi) / 2
        g2, s2, ok2 = evalh(x0 + dir * tnext)
        if !ok2
            # Trial fell into the infeasible region: pull the upper bracket in and
            # bisect within the feasible part.
            thi = tnext
            tnext = (tlo + thi) / 2
            g2, s2, ok2 = evalh(x0 + dir * tnext)
            ok2 || break                        # give up cleanly; return best bracketed t
        end
        t = tnext; gap = g2; slope = s2
    end
    return x0 + dir * t
end

"""
    _ls_profile_ci(kind, y, Xμ, Xψ, gidx, G, Q, θ̂; idx, level=0.95, nll_min=nothing,
                   se=nothing) -> (lower, upper)

Profile-likelihood CI for packed parameter `idx`, inverting `2(ℓ̂ − ℓ_profile) =
χ²₁(level)` by a Venzon–Moolgavkar-style guarded-Newton root-find (the profile
deviance and its envelope-theorem slope, bracket-safeguarded). Endpoints are
`±Inf` when the profile does not cross the χ²₁ threshold (an unbounded direction)
or when the constrained solve becomes infeasible before a crossing (a variance/
correlation boundary). `se` (a Wald SE for `idx`) seeds the bracket width; if
omitted it is derived from the observed information.
"""
function _ls_profile_ci(kind, y, Xμ, Xψ, gidx, G, Q, θ̂; idx::Int, level::Real = 0.95,
                        nll_min = nothing, se = nothing)
    nmin = nll_min === nothing ? _ls_fit_nll(kind, y, Xμ, Xψ, gidx, G, Q, θ̂) : nll_min
    thr = nmin + Distributions.quantile(Distributions.Chisq(1), level) / 2
    z = Distributions.quantile(Distributions.Normal(), 1 - (1 - level) / 2)
    if se === nothing
        V = _ls_vcov(kind, y, Xμ, Xψ, gidx, G, Q, θ̂)
        se = (V === nothing || V[idx, idx] ≤ 0) ? abs(θ̂[idx]) + 1.0 : sqrt(V[idx, idx])
    end
    step0 = max(z * se, 1e-3)
    p = length(θ̂); free = [k for k in 1:p if k != idx]
    mwarm = Ref{Union{Nothing,Vector{Float64}}}(nothing)
    lastsol = Ref{Union{Nothing,Vector{Float64}}}(nothing)
    # Profile gap, its envelope-theorem slope, and feasibility at θ[idx] = val.
    function evalh(val)
        v, s, ok = _ls_profile_nll(kind, y, Xμ, Xψ, gidx, G, Q, θ̂, idx, val;
                                   x0 = lastsol[], mwarm = mwarm)
        ok || return (NaN, NaN, false)
        lastsol[] = s
        # Slope ∂nll/∂θ[idx] at the constrained optimum: the idx-component of the
        # exact full gradient (free-parameter components ≈ 0 by stationarity).
        θ = collect(float.(θ̂)); θ[free] .= s; θ[idx] = val
        g = _ls_marginal_grad(kind, y, Xμ, Xψ, gidx, G, Q, θ; a0 = mwarm[])
        slope = (length(g) == p && isfinite(g[idx])) ? g[idx] : NaN
        return (v - thr, slope, true)
    end
    lower = _ls_profile_root(evalh, θ̂[idx]; dir = -1.0, init = step0)
    lastsol[] = nothing                         # reset warm-start before the other side
    mwarm[] = nothing
    upper = _ls_profile_root(evalh, θ̂[idx]; dir = +1.0, init = step0)
    return (lower = lower, upper = upper)
end
