# locscale_frontend.jl — public `drm()` routing for the non-Gaussian location–
# scale model (#202, slice 3b). Mirrors drmTMB/brms: a correlated random-effect
# tag `(1 | <tag> | group)` shared by the `mu` and `sigma` formulas couples the
# mean-axis and dispersion-axis intercept REs into ONE 2×2 group-level covariance
# Λ — exactly what `_fit_locscale` estimates. No new family handle: the shared
# tag across the two formulas is itself the trigger.
#
#   drm(bf(@formula(y ~ x + (1|p|sp)), @formula(sigma ~ x + (1|p|sp))),
#       NegBinomial2(); data) → _fit_locscale(Val(:nb2), …; se=true)
#
# First cut: intercept-only coupled term, i.i.d. grouping (Q = I). The phylo
# correlated-RE path waits on the phylo-fit-robustness fix (see #209).

using SparseArrays: sparse
using LinearAlgebra: I

# Split a formula rhs into its fixed part and a single coupled `(1 | tag | group)`
# term, if present. Returns `(fixed_rhs, coupled)` where `coupled` is `(tag,
# group)::Tuple{Symbol,Symbol}` or `nothing`. Julia parses `1 | p | g` left-
# associatively as `|(|(1, p), g)`, so the coupled term is a `FunctionTerm{|}`
# whose first argument is itself a `FunctionTerm{|}`.
function _ls_parse_coupled(rhs)
    terms = rhs isa Tuple ? collect(rhs) : Any[rhs]
    fixed = Any[]
    coupled = nothing
    for t in terms
        if t isa FunctionTerm && t.f === (|) &&
           t.args[1] isa FunctionTerm && t.args[1].f === (|)
            coef = t.args[1].args[1]
            (coef isa ConstantTerm && coef.n == 1) ||
                error("location–scale coupled random effect must be intercept-only: " *
                      "`(1 | tag | group)` (got `($coef | … | …)`)")
            coupled === nothing ||
                error("only one coupled `(1 | tag | group)` term per formula is supported")
            coupled = (t.args[1].args[2].sym, t.args[2].sym)   # (tag, group)
        else
            push!(fixed, t)
        end
    end
    fixed_rhs = isempty(fixed) ? ConstantTerm(1) :
                length(fixed) == 1 ? fixed[1] : Tuple(fixed)
    return fixed_rhs, coupled
end

# Detect a coupled location–scale random effect shared by the mean and sigma
# formulas. Returns `(group, fixed_mu, fixed_sigma)` or `nothing`. Errors if a
# coupled term appears on only one axis or the tag/group disagree.
function _ls_coupled_re(rhs_mu, rhs_sigma)
    fμ, cμ = _ls_parse_coupled(rhs_mu)
    fσ, cσ = _ls_parse_coupled(rhs_sigma)
    if cμ === nothing && cσ === nothing
        return nothing
    elseif cμ === nothing || cσ === nothing
        error("a coupled random effect `(1 | tag | group)` must appear in BOTH the mean " *
              "and the `sigma` formula to form a location–scale covariance")
    elseif cμ != cσ
        error("the coupled random-effect tag/group must match across mu and sigma " *
              "(got `$(cμ)` vs `$(cσ)`)")
    end
    return (group = cμ[2], fixed_mu = fμ, fixed_sigma = fσ)
end

# Build a `DrmFit` from a `_fit_locscale` result. The engine packs
# λ = [log L11, L21, log L22]; the package's `:recov` block (reused for summary /
# `vc`) expects [log L11, log L22, L21], so we permute the last three entries of
# θ and of the covariance.
function _build_locscale_drmfit(fam, fitres, y, Xμ, Xψ, nmμ, nmσ, grp::String)
    pμ = size(Xμ, 2); pψ = size(Xψ, 2); n = length(y)
    βμ = fitres.beta_mu; βψ = fitres.beta_psi
    λ = fitres.θ[pμ+pψ+1:pμ+pψ+3]                         # [logL11, L21, logL22]
    theta = vcat(βμ, βψ, λ[1], λ[3], λ[2])                # → recov order
    perm = vcat(collect(1:(pμ+pψ)), [pμ+pψ+1, pμ+pψ+3, pμ+pψ+2])
    V = fitres.vcov === nothing ? fill(NaN, length(theta), length(theta)) :
        fitres.vcov[perm, perm]
    blocks = [:mu => 1:pμ, :sigma => (pμ+1):(pμ+pψ),
              :recov => (pμ+pψ+1):(pμ+pψ+3)]
    names = [:mu => nmμ, :sigma => nmσ,
             :recov => ["$grp:L11", "$grp:L22", "$grp:L21"]]
    means = Dict(:mu => exp.(Xμ * βμ))
    obs = Dict(:mu => Float64.(y))
    scales = Dict(:sigma => exp.(Xψ * βψ))
    return DrmFit(fam, blocks, names, theta, V, -fitres.nll, n, fitres.converged,
                  means, obs, scales)
end

# Route a coupled location–scale formula to the engine and wrap the result.
function _fit_locscale_frontend(kind, fam, f, rhs, lc, data; g_tol, se)
    y, Xμ, nmμ = _design(f.response, lc.fixed_mu, data)
    _, Xψ, nmσ = _design(f.response, lc.fixed_sigma, data)
    if kind isa Val{:nb2}
        all(yi -> yi ≥ 0 && isinteger(yi), y) ||
            error("NegBinomial2() requires non-negative integer counts as the response")
    elseif kind isa Val{:gamma}
        all(yi -> yi > 0, y) ||
            error("Gamma() requires strictly positive responses")
    end
    gidx, G = _group_index(getproperty(data, lc.group))
    Q = sparse(1.0 * I, G, G)
    fitres = _fit_locscale(kind, y, Xμ, Xψ, gidx, G, Q; g_tol = g_tol, se = se)
    fit = _build_locscale_drmfit(fam, fitres, y, Xμ, Xψ, nmμ, nmσ, String(lc.group))
    # Carry the structured design so `confint(:profile)` can route to the robust
    # location–scale profiler. The objective uses the engine packing; the DrmFit
    # `theta` is in `:recov` order, so the profile router permutes between them.
    return _withnll(fit, LocScaleObjective(kind, y, Xμ, Xψ, gidx, G, Q))
end
