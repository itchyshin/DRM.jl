# locscale_profile.jl — profile-likelihood confidence intervals for the q=2
# location–scale fit (#202). Profile CIs are the right uncertainty tool where the
# Wald approximation is poor — notably the group-covariance (variance/correlation)
# parameters near weak identification, for which the observed information can be
# near-singular (see the phylo fit notes).
#
# For a packed parameter `idx`, the profile NLL fixes θ[idx] and re-optimises the
# rest (with the exact reduced gradient, warm-started); the CI endpoints are where
# 2·(profile NLL − NLL_min) crosses the χ²₁(level) threshold, found by
# bracket-expand + bisection on each side of the estimate.

import Distributions

# Profile NLL at θ[idx] = val: minimise the marginal over all other packed params.
function _ls_profile_nll(kind, y, Xμ, Xψ, gidx, G, Q, θ̂, idx::Int, val::Real)
    p = length(θ̂); pμ = size(Xμ, 2); pψ = size(Xψ, 2)
    free = [k for k in 1:p if k != idx]
    warm = Ref{Union{Nothing,Vector{Float64}}}(nothing)
    build(θf) = (θ = collect(float.(θ̂)); θ[free] .= θf; θ[idx] = val; θ)
    function f(θf)
        θ = build(θf)
        βμ = @view θ[1:pμ]; βψ = @view θ[pμ+1:pμ+pψ]
        Λ = _ls_lc_to_Λ(θ[pμ+pψ+1:pμ+pψ+3])
        P = prior_precision(Q, _ls_inv2x2(Λ))
        v, a, ok = _ls_marginal_nll(kind, y, Xμ * βμ, Xψ * βψ, gidx, G, P; a0 = warm[])
        ok && (warm[] = copy(a))
        return ok ? v : 1e18
    end
    function g!(gf, θf)
        gfull = _ls_marginal_grad(kind, y, Xμ, Xψ, gidx, G, Q, build(θf); a0 = warm[])
        @views gf .= gfull[free]
        return gf
    end
    res = Optim.optimize(f, g!, float.(θ̂[free]), Optim.LBFGS(),
                         Optim.Options(g_tol = 1e-7, iterations = 500))
    return Optim.minimum(res)
end

# Bracket-expand from x0 (where g<0) in `dir`, then bisect to the root of g.
function _ls_profile_root(g, x0; dir::Float64, maxexpand::Int = 80, init::Float64 = 0.05)
    a = float(x0)                       # g(a) < 0 throughout
    step = init; b = a; gb = -1.0
    for _ in 1:maxexpand
        b = x0 + dir * step
        gb = g(b)
        gb > 0 && break
        step *= 1.5
    end
    gb > 0 || return dir > 0 ? Inf : -Inf      # could not bracket (flat/unbounded)
    for _ in 1:40                              # 2⁻⁴⁰ of the bracket — ample precision
        mid = (a + b) / 2
        g(mid) > 0 ? (b = mid) : (a = mid)
    end
    return (a + b) / 2
end

"""
    _ls_profile_ci(kind, y, Xμ, Xψ, gidx, G, Q, θ̂; idx, level=0.95, nll_min=nothing)
        -> (lower, upper)

Profile-likelihood confidence interval for the packed parameter `idx`. Endpoints
are returned as `±Inf` when the profile does not cross the threshold within the
search range (an unbounded / non-identified direction).
"""
function _ls_profile_ci(kind, y, Xμ, Xψ, gidx, G, Q, θ̂; idx::Int, level::Real = 0.95,
                        nll_min = nothing)
    nmin = nll_min === nothing ? _ls_fit_nll(kind, y, Xμ, Xψ, gidx, G, Q, θ̂) : nll_min
    thr = nmin + Distributions.quantile(Distributions.Chisq(1), level) / 2
    g(val) = _ls_profile_nll(kind, y, Xμ, Xψ, gidx, G, Q, θ̂, idx, val) - thr
    lower = _ls_profile_root(g, θ̂[idx]; dir = -1.0)
    upper = _ls_profile_root(g, θ̂[idx]; dir = +1.0)
    return (lower = lower, upper = upper)
end
