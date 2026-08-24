# summary.jl — human-readable printout for a fitted `DrmFit`.
#
# Two entry points, both built only on existing direct dependencies:
#   * `Base.show(io, MIME"text/plain"(), fit)` — dependency-free REPL summary:
#     family / nobs / logLik / convergence, then a Wald coefficient table
#     (Coef. / Std.Error / z / Pr(>|z|)) sectioned by parameter block, in the
#     order the blocks appear on the fit. This is the always-available verb.
#   * `coeftable(fit; level)` — a `StatsBase.CoefTable` (Estimate / Std.Error /
#     z / Pr(>|z|) / Lower / Upper) across every block. `coeftable` and
#     `CoefTable` both come from StatsModels (a direct dep, re-exporting
#     StatsBase/StatsAPI), so this adds no new dependency.
#
# z = estimate / se on each block's working scale (μ on the response scale; σ on
# log σ; ρ12 on atanh ρ12; random-effect SDs on log σ_b — matching `confint`).
# z / Pr(>|z|) are populated only for blocks where the working-scale-zero null is a
# meaningful hypothesis (:mu/:mu1/:mu2 test coefficient = 0; :rho12 tests ρ12 = 0).
# For :sigma/:resd/:recov/:phylocov etc. the zero-on-working-scale null is not the
# scientific null (log σ = 0 ⇔ σ = 1, not σ = 0), so z / p print as NaN (issue
# #320). A boundary / singular direction (Inf SE) also prints NaN, not a misleading
# z = 0, p = 1 (issue #323.2).

using Printf: @sprintf
using Distributions: Normal, ccdf
import StatsAPI: coeftable
using StatsModels: CoefTable

# Readable section title for each block symbol. Unknown blocks fall back to the
# bare symbol so new families print sensibly without touching this file.
function _block_title(p::Symbol)
    p === :mu      && return "Mean model (μ)"
    p === :mu1     && return "Mean model 1 (μ1)"
    p === :mu2     && return "Mean model 2 (μ2)"
    p === :sigma   && return "Scale model (log σ)"
    p === :sigma1  && return "Scale model 1 (log σ1)"
    p === :sigma2  && return "Scale model 2 (log σ2)"
    p === :rho12   && return "Correlation (atanh ρ12)"
    p === :nu      && return "Shape (ν, working scale)"
    p === :zi      && return "Zero-inflation (logit)"
    p === :hu      && return "Hurdle (logit)"
    p === :zoi     && return "Zero-or-one inflation (logit)"
    p === :coi     && return "Conditional-one inflation (logit)"
    p === :cutpoints && return "Cutpoints"
    p === :range   && return "Spatial range (log)"
    p === :resd    && return "Random-effect SD (log σ_b)"
    p === :resid   && return "Residual scale (log σ)"
    p === :recov   && return "Random-effect covariance (Cholesky)"
    p === :phylocov && return "Group-level covariance Σ_a (log-Cholesky; see vc/coevolution)"
    return String(p)
end

# Clean family label, e.g. `Gaussian()` → "Gaussian". Families are singleton
# structs, so the type name is the right human label.
_family_name(fam) = String(nameof(typeof(fam)))

# Blocks whose zero-on-working-scale null is a MEANINGFUL hypothesis, so a Wald
# z / two-sided p against 0 is interpretable. Location blocks (:mu/:mu1/:mu2) test
# coefficient = 0; :rho12 tests atanh ρ12 = 0 ⇔ ρ12 = 0, a real "no correlation"
# null. All other blocks live on a working scale where 0 is not the scientific
# null (issue #320): :sigma/:sigma1/:sigma2 (log σ = 0 ⇔ σ = 1), :resd/:resid
# (log σ_b = 0 ⇔ σ_b = 1, NOT the σ_b = 0 boundary), :recov/:phylocov (Cholesky
# entries with no individual interpretable null). For those we suppress z / p.
const _WALD_TESTABLE_BLOCKS = (:mu, :mu1, :mu2, :rho12)
_block_wald_testable(p::Symbol) = p in _WALD_TESTABLE_BLOCKS

# Wald z and two-sided p for one coefficient, honouring two suppression rules:
#   * blocks whose working-scale-zero null is meaningless (issue #320) get NaN;
#   * a boundary / singular direction (Inf SE, issue #323.2) gets NaN — NOT the
#     misleading z = est/Inf = 0, p = 2·Φ̄(0) = 1 that reads as a confident null.
# NaN prints as "NaN" in both show and coeftable, flagging "not a hypothesis test"
# / "unidentified direction" rather than a spurious decision.
function _wald_zp(p::Symbol, est::Real, se::Real)
    (_block_wald_testable(p) && isfinite(se)) || return (NaN, NaN)
    z = est / se
    return (z, 2 * ccdf(Normal(), abs(z)))
end

"""
    family(fit::DrmFit)

Return the response family object the model was fitted with, e.g. `Gaussian()`,
`Poisson()`, `Student()`. This is the post-fit accessor for the `family` slot
passed to [`drm`](@ref); `family(fit) === fit.family`.
"""
family(fit::DrmFit) = fit.family

"""
    rho12(fit)

Fitted **residual correlation** ρ12 for a bivariate model (`bf(mu1=…, mu2=…, rho12=…)`),
on the response scale (ρ12 ∈ (-1, 1)), one value per observation. Mirrors drmTMB's
`rho12`. Errors for univariate fits, which have no residual correlation.
"""
function rho12(fit::DrmFit)
    haskey(fit.scales, :rho12) || throw(ArgumentError(
        "rho12 is defined only for bivariate models (bf(mu1=…, mu2=…, rho12=…)); this fit has no residual correlation"))
    return fit.scales[:rho12]
end

"""
    is_converged(fit::DrmFit) -> Bool

Whether this fit may be trusted: the optimiser reported convergence **and** the
optimum is not degenerate. A `false` here means the reported estimates / standard
errors should not be trusted.

This is deliberately STRICTER than the raw `fit.converged` flag. The Gaussian
log-likelihood is unbounded as the residual scale goes to zero: with one row per
group a structured random effect can interpolate the data, so `sigma` collapses and
the objective runs away to `+Inf`. `Optim.converged` only asks whether the gradient
test was met, and at such a point it returns `true`.

Measured 2026-08-24 on a one-row-per-species phylo fit (#461):
`sd_phylo = 22980`, `sigma = 7.5e-15`, `loglik = 6.8e13`, `converged = true` — and
25% of parametric-bootstrap replicates landed on such a point. Downstream that is
WORSE than an outright failure, because every consumer treats the fit as usable and
a percentile interval silently inherits the nonsense.

Checked here, at the single public accessor, rather than at the ~30 `DrmFit`
construction sites across 20 family files — one place that every consumer already
goes through. `fit.converged` still exposes the raw optimiser flag for anyone who
wants it.
"""
is_converged(fit::DrmFit) = fit.converged && _nondegenerate_fit(fit)

# The degeneracy test behind `is_converged`. GAUSSIAN ONLY: for NB2/Beta/Gamma the
# `:sigma` slot holds a dispersion or shape, where a genuinely small value is
# legitimate, so applying a residual-scale test there would reject good fits.
function _nondegenerate_fit(fit::DrmFit)
    isfinite(fit.loglik) || return false
    fit.family isa Gaussian || return true
    haskey(fit.scales, :sigma) || return true
    s = fit.scales[:sigma]
    smax = maximum(abs, s)
    isfinite(smax) || return false
    # Scale-free bar: a residual SD a millionth of the response SD is
    # interpolation, not a fit. An absolute floor alone would misjudge data
    # measured in small units.
    yv = get(fit.obs, :mu, nothing)
    yscale = (yv isa AbstractVector && length(yv) > 1) ? std(yv) : 1.0
    return smax > 1e-6 * max(yscale, eps(Float64))
end

"""
    deviance(fit::DrmFit) -> Float64

Deviance of the fitted model, `-2 · loglik(fit)` — drmTMB's `deviance()`.
Extends `StatsAPI.deviance`.
"""
deviance(fit::DrmFit) = -2 * loglik(fit)

"""
    dof_residual(fit::DrmFit) -> Int

Residual degrees of freedom, `nobs(fit) - dof(fit)` (R's `df.residual`).
Extends `StatsAPI.dof_residual`.
"""
dof_residual(fit::DrmFit) = nobs(fit) - dof(fit)

function Base.show(io::IO, ::MIME"text/plain", fit::DrmFit)
    se = stderror(fit)
    fam = _family_name(fit.family)
    println(io, "Distributional regression fit (", fam, ")")
    println(io, "  nobs = ", fit.nobs,
                "   logLik = ", @sprintf("%.4f", fit.loglik),
                "   converged = ", fit.converged)

    # Pre-format every cell so column widths fit the actual content.
    fmt(x) = isfinite(x) ? @sprintf("%.4f", x) : (isnan(x) ? "NaN" : (x > 0 ? "Inf" : "-Inf"))
    fmtp(x) = isfinite(x) ? @sprintf("%.4g", x) : "NaN"
    headers = ("Coef.", "Std.Error", "z", "Pr(>|z|)")

    for ((p, r), (_, nms)) in zip(fit.blocks, fit.coefnames)
        println(io)
        println(io, _block_title(p), ":")
        # Build the rows for this block.
        labels = String[]; c1 = String[]; c2 = String[]; c3 = String[]; c4 = String[]
        for (j, idx) in enumerate(r)
            est = fit.theta[idx]
            s = se[idx]
            z, pval = _wald_zp(p, est, s)
            push!(labels, nms[j])
            push!(c1, fmt(est)); push!(c2, fmt(s)); push!(c3, fmt(z)); push!(c4, fmtp(pval))
        end
        # Column widths: header vs widest cell, right-aligned numerics.
        wlab = maximum(length, labels; init = 0)
        w1 = max(length(headers[1]), maximum(length, c1; init = 0))
        w2 = max(length(headers[2]), maximum(length, c2; init = 0))
        w3 = max(length(headers[3]), maximum(length, c3; init = 0))
        w4 = max(length(headers[4]), maximum(length, c4; init = 0))
        println(io, "  ", rpad("", wlab), "  ",
                    lpad(headers[1], w1), "  ", lpad(headers[2], w2), "  ",
                    lpad(headers[3], w3), "  ", lpad(headers[4], w4))
        for j in eachindex(labels)
            println(io, "  ", rpad(labels[j], wlab), "  ",
                        lpad(c1[j], w1), "  ", lpad(c2[j], w2), "  ",
                        lpad(c3[j], w3), "  ", lpad(c4[j], w4))
        end
    end
    return nothing
end

"""
    summary(fit::DrmFit)

Coefficient table for a fitted model — the DRM.jl analogue of drmTMB's `summary()`.
Returns the same `CoefTable` as [`coeftable`](@ref) (estimates, SEs, z, p, CIs).
"""
Base.summary(fit::DrmFit) = coeftable(fit)

"""
    coeftable(fit::DrmFit; level = 0.95) -> StatsBase.CoefTable

Wald coefficient table across every parameter block: columns Estimate,
Std.Error, z, Pr(>|z|), and a `level` confidence interval (Lower/Upper). Values
are on each block's working scale (μ on the response scale; σ on log σ; ρ12 on
atanh ρ12; random-effect SDs on log σ_b). Row names are prefixed with the block
(e.g. `"mu: (Intercept)"`) so they stay unique across blocks.

The `z` and `Pr(>|z|)` columns carry an interpretable Wald test **only** for
blocks whose working-scale-zero null is a meaningful hypothesis: the location
blocks `:mu`/`:mu1`/`:mu2` (coefficient = 0) and `:rho12` (atanh ρ12 = 0 ⇔ no
correlation). For `:sigma`/`:sigma1`/`:sigma2`/`:resd`/`:resid`/`:recov`/
`:phylocov` the zero-on-working-scale null is not the scientific one — e.g.
`log σ = 0` means `σ = 1`, not the `σ = 0` variance boundary — so those rows show
`z` and `Pr(>|z|)` as `NaN` rather than a misleading test of an arbitrary scale
reference (issue #320). To test a variance component against 0 use a
boundary-corrected likelihood-ratio test (`lrt_boundary`); the estimate and SE for
those blocks are still reported. A boundary / singular direction (Inf SE) also
reports `NaN` z / p rather than a spurious `z = 0, p = 1` (issue #323.2).
"""
function coeftable(fit::DrmFit; level::Real = 0.95)
    se = stderror(fit)
    z = quantile(Normal(), 1 - (1 - level) / 2)
    est = Float64[]; ses = Float64[]; zs = Float64[]; ps = Float64[]
    lo = Float64[]; hi = Float64[]; rownms = String[]
    for ((p, r), (_, nms)) in zip(fit.blocks, fit.coefnames)
        for (j, idx) in enumerate(r)
            e = fit.theta[idx]; s = se[idx]
            zval, pval = _wald_zp(p, e, s)
            push!(est, e); push!(ses, s); push!(zs, zval)
            push!(ps, pval)
            push!(lo, e - z * s); push!(hi, e + z * s)
            push!(rownms, string(p, ": ", nms[j]))
        end
    end
    lvl = round(Int, 100 * level)
    colnms = ["Estimate", "Std.Error", "z", "Pr(>|z|)", "Lower $lvl%", "Upper $lvl%"]
    mat = hcat(est, ses, zs, ps, lo, hi)
    return CoefTable(mat, colnms, rownms, 4, 3)   # pvalcol = 4, teststatcol = 3
end
