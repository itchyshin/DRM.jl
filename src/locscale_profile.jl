# locscale_profile.jl — profile-likelihood confidence intervals for the q=2
# location–scale fit (#202). The right uncertainty tool where Wald is poor — the
# group-covariance (variance/correlation) parameters near weak identification.
#
# For a packed parameter `idx`, the profile NLL fixes θ[idx] and re-optimises the
# rest. Two design choices make this robust AND fast (an earlier LBFGS version
# threw on boundary steps and took minutes):
#  * the constrained inner solve uses a TRUST-REGION NEWTON (exact reduced
#    gradient + the observed-information slice as Hessian), like `_fit_locscale`,
#    so a transient step toward the variance boundary shrinks the trust radius
#    instead of crashing the line search;
#  * the reduced optimisation is WARM-STARTED across profile points (both the
#    free-parameter init and the inner mode), and the CI brackets are SEEDED from
#    the Wald half-width, so the χ²₁ crossing is found in ~a dozen evaluations.

import Distributions

# Profile NLL at θ[idx] = val: minimise the marginal over the other packed params.
# `x0` seeds the free-parameter optimisation (warm-start across profile points);
# `mwarm` is the shared inner-mode warm-start Ref. Returns (minval, minimizer).
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
        return ok ? v : 1e18
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
    return Optim.minimum(res), Optim.minimizer(res)
end

# Bracket-expand from x0 (g<0) in `dir`, seeded with step `init`, then bisect.
# `evalg(val) -> gval` returns the deviance gap (profile NLL − threshold).
function _ls_profile_root(evalg, x0; dir::Float64, init::Float64,
                          maxexpand::Int = 40, nbisect::Int = 18)
    a = float(x0)                              # g(a) < 0
    step = init; b = a; gb = -1.0
    for _ in 1:maxexpand
        b = x0 + dir * step
        gb = evalg(b)
        gb > 0 && break
        a = b                                  # advance the lower (<0) end too
        step *= 1.6
    end
    gb > 0 || return dir > 0 ? Inf : -Inf
    for _ in 1:nbisect
        mid = (a + b) / 2
        evalg(mid) > 0 ? (b = mid) : (a = mid)
    end
    return (a + b) / 2
end

"""
    _ls_profile_ci(kind, y, Xμ, Xψ, gidx, G, Q, θ̂; idx, level=0.95, nll_min=nothing,
                   se=nothing) -> (lower, upper)

Profile-likelihood CI for packed parameter `idx`. Endpoints are `±Inf` when the
profile does not cross the χ²₁ threshold within the search range (an unbounded /
non-identified direction). `se` (a Wald SE for `idx`) seeds the bracket width; if
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
    mwarm = Ref{Union{Nothing,Vector{Float64}}}(nothing)
    lastsol = Ref{Union{Nothing,Vector{Float64}}}(nothing)
    function evalg(val)
        v, s = _ls_profile_nll(kind, y, Xμ, Xψ, gidx, G, Q, θ̂, idx, val;
                               x0 = lastsol[], mwarm = mwarm)
        lastsol[] = s
        return v - thr
    end
    lower = _ls_profile_root(evalg, θ̂[idx]; dir = -1.0, init = step0)
    lastsol[] = nothing                         # reset warm-start before the other side
    upper = _ls_profile_root(evalg, θ̂[idx]; dir = +1.0, init = step0)
    return (lower = lower, upper = upper)
end
