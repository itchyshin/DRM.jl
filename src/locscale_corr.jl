# locscale_corr.jl — route the per-family CORRELATED random intercept+slope
# `(1 + x | g)` and the INDEPENDENT slope `(0 + x | g)` onto the unified q=2
# location–scale Laplace core (cluster 1, #202). Promoting the bespoke dense
# K×K Gauss–Hermite `_fit_*_corr_ranef` fitters to the augmented-state Laplace
# core gives the exact O(p) gradient and (where requested) profile/Wald CIs.
#
# The mechanism is the Z_lat generalisation of `locscale_inner.jl`/`locscale_
# grad.jl`: BOTH latent axes per group load the MEAN predictor η with the
# per-obs loading row [1, xᵢ] (the intercept and slope), while the scale
# predictor ψ carries NO latent. So
#   Zη = [1 xᵢ]   (intercept + slope on η),   Zψ = [0 0]   (scale fixed-only).
# The independent slope `(0 + x | g)` is q=1: only the slope axis loads η, with
# Zη = [xᵢ 0] and the intercept axis pinned by a vanishing prior variance.
#
# The 2×2 group covariance Λ the core returns IS Σ_re of the (intercept, slope)
# axes; we map its Cholesky back to the existing `:recov` `[L11, L22, L21]`
# names so `coef`/`summary`/`vc` output is byte-identical to the GHQ fitters.
#
# Which families route here is decided by the family frontends after the
# cross-engine equivalence gate (`test/test_corr_locscale_equiv.jl`): a family
# whose unified-Laplace logLik tracks its GHQ logLik on the shared fixture is
# flipped; one that does not stays on GHQ.

# Family → engine `kind` Val for the q2 leaf kernels.
_corr_kind(::Poisson) = Val(:poisson)
_corr_kind(::Gamma) = Val(:gamma)
_corr_kind(::Beta) = Val(:beta)
_corr_kind(::NegBinomial2) = Val(:nb2)
_corr_kind(::LogNormal) = Val(:lognormal)

# Map the engine's 2×2 covariance Λ (intercept/slope axes) and the engine vcov
# (packed [βμ; βψ; λ] with λ = [logL11, L21, logL22]) into a `DrmFit` whose
# `:recov` block is the GHQ convention [log L11, log L22, L21] (so `vc(fit)`
# rebuilds Σ = L Lᵀ). `engresp` is the response the kernels consumed (raw y,
# log-y for LogNormal handled inside the kernel, or `(s,n)` tuples); `respobs`
# overrides the stored response (observed proportion for the bounded families).
function _corr_build_drmfit(kind, fam, fitres, Xμ, Xψ, nmμ, nmσ, grp::String,
                            y, link::Symbol; respobs = nothing, trials = nothing,
                            extra_blocks = nothing)
    pμ = size(Xμ, 2); pψ = size(Xψ, 2); n = size(Xμ, 1)
    βμ = fitres.beta_mu; βψ = fitres.beta_psi
    λ = fitres.θ[pμ+pψ+1:pμ+pψ+3]                         # [logL11, L21, logL22]
    theta = vcat(βμ, βψ, λ[1], λ[3], λ[2])                # → recov order
    perm = vcat(collect(1:(pμ+pψ)), [pμ+pψ+1, pμ+pψ+3, pμ+pψ+2])
    V = fitres.vcov === nothing ? fill(NaN, length(theta), length(theta)) :
        fitres.vcov[perm, perm]
    blocks = Pair{Symbol,UnitRange{Int}}[:mu => 1:pμ]
    names = Pair{Symbol,Vector{String}}[:mu => nmμ]
    if pψ > 0
        push!(blocks, :sigma => (pμ+1):(pμ+pψ)); push!(names, :sigma => nmσ)
    end
    push!(blocks, :recov => (pμ+pψ+1):(pμ+pψ+3))
    push!(names, :recov => ["$grp:L11", "$grp:L22", "$grp:L21"])
    means = Dict(:mu => link === :logit ? _logistic.(Xμ * βμ) :
                        link === :identity ? Xμ * βμ : exp.(Xμ * βμ))
    obs = Dict(:mu => respobs === nothing ? Float64.(y) : Float64.(respobs))
    scales = pψ > 0 ? Dict(:sigma => exp.(Xψ * βψ)) : Dict{Symbol,Vector{Float64}}()
    trials === nothing || (scales[:trials] = Float64.(trials))
    return DrmFit(fam, blocks, names, theta, V, -fitres.nll, n, fitres.converged,
                  means, obs, scales)
end

# Latent loadings for the correlated / independent slope on the mean axis.
#   :corr  → Zη = [1 xᵢ] (intercept + slope),  Zψ = [0 0]
#   :slope → Zη = [xᵢ 0] (slope only),          Zψ = [0 0]
function _corr_loadings(rk::Symbol, xs)
    n = length(xs)
    Zψ = zeros(n, 2)
    if rk === :corr
        Zη = hcat(ones(n), xs)
    else  # :slope (independent) — single loading column, intercept axis unused
        Zη = hcat(xs, zeros(n))
    end
    return Zη, Zψ
end

# Initial λ (log-Cholesky [logL11, L21, logL22]) for the group covariance.
# For the independent slope the intercept axis is pinned to a tiny variance so
# Λ stays PD while contributing nothing (its loading column is zero).
_corr_λ0(rk::Symbol) = rk === :corr ? [log(0.4), 0.0, log(0.4)] :
                                      [log(1e-3), 0.0, log(0.4)]

"""
    _fit_corr_locscale(fam, kind, rk, y, Xμ, Xψ, xs, gidx, G, nmμ, nmσ, grp;
                       link, se, g_tol, respobs, trials, Q)

Fit a correlated (`rk == :corr`) or independent (`rk == :slope`) random
intercept/slope on the mean of a non-Gaussian family through the unified q2
location–scale Laplace core, and wrap it as a `DrmFit` with the GHQ `:recov`
block. `Xψ` is the scale fixed-effect design (`zeros(n,0)` for the mean-only
Poisson). `link` is the mean inverse link (`:log`/`:logit`/`:identity`).
`Q` is the G×G group-level precision; default `sparse(I,G,G)` (i.i.d. groups,
cluster 1 byte-identical behaviour). A structured Q (from `_general_cov_setup`
or `_locscale_phylo_setup`) routes the kron(Q,Λ⁻¹) prior through the same
spine (cluster 3: structured non-Gaussian random slopes).
"""
function _fit_corr_locscale(fam, kind, rk::Symbol, y, Xμ, Xψ, xs, gidx, G,
                            nmμ, nmσ, grp::String; link::Symbol,
                            se::Bool = true, g_tol::Real = 1e-6,
                            respobs = nothing, trials = nothing,
                            Q = sparse(1.0 * I, G, G))
    Zη, Zψ = _corr_loadings(rk, xs)
    fitres = _fit_locscale(kind, y, Xμ, Xψ, gidx, G, Q;
                           Zη = Zη, Zψ = Zψ, λ0 = _corr_λ0(rk),
                           g_tol = g_tol, se = se)
    return _corr_build_drmfit(kind, fam, fitres, Xμ, Xψ, nmμ, nmσ, grp, y, link;
                              respobs = respobs, trials = trials)
end

# Parse a formula rhs for a structured correlated slope:
#   `relmat(1 + x | g)`, `animal(1 + x | g)`, `phylo(1 + x | g)`,
#   `spatial(1 + x | g)`.
# Returns `(struct_kind::Symbol, slope_var::Symbol, grp_sym::Symbol)` or
# `nothing`. Does NOT consume ordinary `(1 + x | g)` terms (those are handled
# by the `re` path).
function _parse_structured_slope(rhs)
    terms = rhs isa Tuple ? collect(rhs) : Any[rhs]
    for t in terms
        t isa FunctionTerm || continue
        f = t.f
        (f === relmat || f === animal || f === phylo || f === spatial) || continue
        length(t.args) == 1 || continue
        inner = t.args[1]                              # should be `(1 + x | g)`
        inner isa FunctionTerm && inner.f === (|) || continue
        lhs = inner.args[1]
        grp_term = inner.args[2]
        grp_term isa Term || continue
        try
            rk, var = _re_kind(lhs)
            rk === :corr || continue                   # only correlated slope
            struct_kind = f === relmat  ? :relmat  :
                          f === animal  ? :animal  :
                          f === phylo   ? :phylo   : :spatial
            return (struct_kind, var, grp_term.sym)
        catch
            continue
        end
    end
    return nothing
end
