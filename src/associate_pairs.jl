# associate_pairs.jl — staged (frozen-margin) association, the Julia twin of
# drmTMB's `associate_pairs()` / `latent_normal()` / `association()`.
#
# THIS IS A TWO-STAGE ESTIMATOR, NOT A JOINT MODEL. Two univariate models are
# fitted independently, then FROZEN, and a single latent-normal copula
# association is estimated conditional on them. The margins are never refitted.
#
# The consequence has to be stated wherever the uncertainty is reported: because
# the margins are treated as exact, the association's standard error is
# CONDITIONAL — it ignores margin estimation error. drmTMB bounds its own version
# the same way (alpha-scale Wald only, an experimental-interval warning, and no
# simultaneous eta bands or profiles), and this port must not offer intervals the
# twin refuses.
#
# First slice: the `gaussian_bernoulli` pair class, whose likelihood is CLOSED
# FORM. The Gaussian margin's latent is observed exactly, so the Bernoulli's
# contribution is a conditional univariate normal CDF — no rectangle probability,
# no quadrature, no new dependency. The four pair classes that censor BOTH
# latents need a 1-D adaptive integral with a retained error estimate and are
# deliberately deferred (design note
# `docs/dev-log/design/2026-08-15-a3c-design-staged-association.md`).

using Distributions: Normal, cdf, logcdf, logpdf, quantile

"""
    LatentNormal

Association kernel for [`associate_pairs`](@ref) — drmTMB's `latent_normal()`.
The two margins are coupled through a bivariate standard normal latent with
correlation `eta`.
"""
struct LatentNormal end

"""
    latent_normal()

The latent-normal association kernel. Must be passed explicitly: like drmTMB,
there is no implicit association model.
"""
latent_normal() = LatentNormal()

"""
    PairAssociation

Result of [`associate_pairs`](@ref): a staged, frozen-margin association fit.

Fields: `pair_class`, `coefficients` (association scale, `alpha`), `eta`
(`0.999999·tanh(alpha)`), `loglik`, `score` and `curvature` (finite-difference
diagnostics at the optimum), `near_boundary`, `multistart_disagreement`, and
`nobs`.

**The uncertainty is conditional on the frozen margins.** See
[`association`](@ref).
"""
struct PairAssociation
    pair_class::Symbol
    coefficients::Vector{Float64}
    coefnames::Vector{String}
    eta::Float64
    loglik::Float64
    score::Vector{Float64}
    curvature::Vector{Float64}
    near_boundary::Bool
    multistart_disagreement::Bool
    nobs::Int
end

const _ASSOC_ETA_GUARD = 0.999999
const _ASSOC_BOUND = 8.0

_assoc_eta(alpha) = _ASSOC_ETA_GUARD * tanh(alpha)

"""
    associate_pairs(fit_1, fit_2; kernel, association = nothing)

Estimate a staged latent-normal association between two **already-fitted**
univariate models — drmTMB's `associate_pairs()`.

`kernel` must be given explicitly as [`latent_normal()`](@ref). `association`
defaults to an intercept (`~ 1`); only the intercept-only form is implemented in
this slice, matching drmTMB's boundary for every pair class except its one
Bernoulli × NB2 exception.

The margins are **frozen**: `fit_1` and `fit_2` are used as fitted and are never
re-estimated. Reported uncertainty is therefore conditional on them.

Implemented pair class: **gaussian × binomial** (`gaussian_bernoulli`). The other
four reviewed classes need a rectangle probability and are not implemented yet;
they error rather than silently approximating.

```julia
fg = drm(bf(@formula(y ~ x), @formula(sigma ~ 1)), Gaussian(); data = d)
fb = drm(bf(@formula(z ~ x)), Binomial(); data = d)
a  = associate_pairs(fg, fb; kernel = latent_normal())
a.eta
```
"""
function associate_pairs(fit_1::DrmFit, fit_2::DrmFit; kernel = nothing,
                         association = nothing)
    kernel isa LatentNormal ||
        throw(ArgumentError("associate_pairs: supply an explicit " *
            "`kernel = latent_normal()` declaration — there is no implicit " *
            "association kernel."))
    association === nothing || _assoc_intercept_only(association)

    pc, comps = _assoc_components(fit_1, fit_2)
    n = length(comps.gaussian_y)
    loglik = alpha -> _assoc_loglik_gaussian_bernoulli(alpha, comps)

    # Multistart on a bounded scalar: the profile is not assumed unimodal, and
    # drmTMB starts from -1, 0, 1 for the intercept-only case.
    starts = (-1.0, 0.0, 1.0)
    objective(a) = (v = loglik(a); isfinite(v) ? -v : prevfloat(Inf))
    best_a, best_o = 0.0, Inf
    objectives = Float64[]
    for s in starts
        a = _assoc_optimise_scalar(objective, s)
        o = objective(a)
        push!(objectives, o)
        if o < best_o
            best_o, best_a = o, a
        end
    end

    # Finite-difference score + curvature, exactly as drmTMB: no Hessian, and no
    # report at all when the optimum sits on the box boundary.
    h = 1e-4
    if best_a - h <= -_ASSOC_BOUND || best_a + h >= _ASSOC_BOUND
        score, curv = NaN, NaN
    else
        lo, hi = objective(best_a - h), objective(best_a + h)
        score = (lo - hi) / (2h)
        curv = -(hi - 2 * objective(best_a) + lo) / h^2
    end

    η = _assoc_eta(best_a)
    tol = 1e-7 * (1 + abs(best_o))
    finite = filter(isfinite, objectives)
    disagree = length(finite) < 2 || (maximum(finite) - minimum(finite)) > tol

    return PairAssociation(pc, [best_a], ["(Intercept)"], η, -best_o,
                           [score], [curv], abs(η) >= 0.995, disagree, n)
end

# Bounded scalar optimisation by golden-section on [-8, 8]: the association scale
# is one bounded coordinate, so this needs no gradient and cannot leave the box
# (mirroring drmTMB's `nlminb` bounds).
function _assoc_optimise_scalar(objective, start::Float64)
    lo, hi = -_ASSOC_BOUND, _ASSOC_BOUND
    # Bracket around the start so a multistart actually explores different basins.
    width = 4.0
    lo = max(lo, start - width)
    hi = min(hi, start + width)
    invphi = (sqrt(5.0) - 1) / 2
    c = hi - invphi * (hi - lo)
    d = lo + invphi * (hi - lo)
    fc, fd = objective(c), objective(d)
    for _ in 1:200
        if fc < fd
            hi, d, fd = d, c, fc
            c = hi - invphi * (hi - lo)
            fc = objective(c)
        else
            lo, c, fc = c, d, fd
            d = lo + invphi * (hi - lo)
            fd = objective(d)
        end
        (hi - lo) < 1e-10 && break
    end
    return (lo + hi) / 2
end

# Only `~ 1` in this slice. drmTMB allows a varying association formula for one
# pair class only (literal-Bernoulli × ordinary-NB2), which is not implemented
# here — so reject rather than silently fit an intercept.
function _assoc_intercept_only(association)
    ok = association isa FormulaTerm && association.rhs isa ConstantTerm
    ok || throw(ArgumentError("associate_pairs: only an intercept-only " *
        "`association = @formula(association ~ 1)` is implemented. drmTMB admits a " *
        "varying association formula for literal-Bernoulli × ordinary-NB2 only; " *
        "that cell is not ported yet."))
    return association
end

# Freeze the margins and pull out exactly what the pair likelihood consumes.
function _assoc_components(fit_1::DrmFit, fit_2::DrmFit)
    g_idx = fit_1.family isa Gaussian ? 1 : (fit_2.family isa Gaussian ? 2 : 0)
    b_idx = fit_1.family isa Binomial ? 1 : (fit_2.family isa Binomial ? 2 : 0)
    (g_idx != 0 && b_idx != 0 && g_idx != b_idx) ||
        throw(ArgumentError("associate_pairs: this slice implements the " *
            "`gaussian_bernoulli` pair class (one `Gaussian` fit and one `Binomial` " *
            "fit). drmTMB also reviews gaussian×nbinom2, bernoulli×nbinom2, " *
            "bernoulli×bernoulli and nbinom2×nbinom2; those censor BOTH latents and " *
            "need a rectangle probability, which is not ported yet."))

    gfit = g_idx == 1 ? fit_1 : fit_2
    bfit = b_idx == 1 ? fit_1 : fit_2

    gy = gfit.obs[:mu]
    gmu = gfit.means[:mu]
    gsd = gfit.scales[:sigma]
    gsd = length(gsd) == 1 ? fill(gsd[1], length(gy)) : gsd
    bp = bfit.means[:mu]                    # fitted success probability
    by = bfit.obs[:mu]                      # observed proportion; Bernoulli ⇒ 0/1

    length(gy) == length(bp) ||
        throw(ArgumentError("associate_pairs: the two fits must share the same rows " *
            "(got $(length(gy)) and $(length(bp)))."))
    all(v -> v == 0 || v == 1, by) ||
        throw(ArgumentError("associate_pairs: the binomial margin must be literal " *
            "Bernoulli (0/1 responses, one trial per row) for the " *
            "`gaussian_bernoulli` class."))

    return :gaussian_bernoulli,
           (gaussian_y = Vector{Float64}(gy), gaussian_mu = Vector{Float64}(gmu),
            gaussian_sigma = Vector{Float64}(gsd), binary_y = Vector{Float64}(by),
            binary_p = Vector{Float64}(bp))
end

# Closed form. The Gaussian latent is OBSERVED (z), so the Bernoulli's
# contribution is the conditional normal CDF at the shifted threshold — no
# bivariate CDF and no quadrature is required for this pair class.
function _assoc_loglik_gaussian_bernoulli(alpha, c)
    η = _assoc_eta(alpha)
    s = sqrt(1 - η * η)
    s > 0 || return -Inf
    Z = Normal()
    total = 0.0
    @inbounds for i in eachindex(c.gaussian_y)
        z = (c.gaussian_y[i] - c.gaussian_mu[i]) / c.gaussian_sigma[i]
        thr = quantile(Z, 1 - c.binary_p[i])          # qnorm(p, lower = FALSE)
        cz = (thr - η * z) / s
        lb = c.binary_y[i] == 1 ? logcdf(Z, -cz) : logcdf(Z, cz)
        total += logpdf(Normal(c.gaussian_mu[i], c.gaussian_sigma[i]), c.gaussian_y[i]) + lb
    end
    return total
end

"""
    association(a::PairAssociation)

Association summary for a staged fit — drmTMB's `association()`.

Returns a `NamedTuple` with `eta` (the latent correlation), `alpha` (the
association-scale coefficient), `score`/`curvature` diagnostics,
`near_boundary`, and `multistart_disagreement`.

**The uncertainty is conditional on the frozen margins** — it ignores margin
estimation error, so it is not a joint standard error. Matching drmTMB, no
simultaneous `eta` bands or profile intervals are offered.
"""
function association(a::PairAssociation)
    return (pair_class = a.pair_class, eta = a.eta, alpha = a.coefficients[1],
            score = a.score[1], curvature = a.curvature[1],
            near_boundary = a.near_boundary,
            multistart_disagreement = a.multistart_disagreement,
            nobs = a.nobs, loglik = a.loglik,
            uncertainty = "conditional on frozen margins; experimental")
end
