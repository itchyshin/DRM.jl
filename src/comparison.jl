# comparison.jl — model-comparison + small accessor parity (drmTMB / glmmTMB).
#
# Built only on existing post-fit accessors (`loglik`, `dof`, `aic`, `nobs`,
# `coef`, `family`) and the public `drm(...)` verb. Adds:
#   * `lrtest` / `anova` — likelihood-ratio test for two nested ML fits.
#   * `aicc`             — small-sample (second-order) AIC correction.
#   * `weights`          — prior observation weights (extends StatsAPI.weights).
#   * `update`           — convenience refit reusing the fitted family.
#
# ML only: REML log-likelihoods are not comparable across different fixed-effect
# structures, so the LR test (and AIC/AICc differences) assume ML fits — which is
# DRM.jl's default.

using Distributions: Chisq, ccdf
import StatsAPI: weights

"""
    lrtest(reduced::DrmFit, full::DrmFit) -> NamedTuple

Likelihood-ratio test for two **nested**, **ML**-fitted models, mirroring
drmTMB's `anova(reduced, full)`. `reduced` must be a special case of `full`
(fewer parameters); both must be fit by maximum likelihood (DRM.jl's default —
REML likelihoods are not comparable across fixed-effect structures).

Returns a `NamedTuple` `(; statistic, dof, pvalue)`:

- `statistic = 2 * (loglik(full) - loglik(reduced))` — the LR statistic, which is
  asymptotically `χ²` with `dof` degrees of freedom under the null that the
  reduced model is adequate.
- `dof = dof(full) - dof(reduced)` — the number of extra parameters in `full`.
- `pvalue = ccdf(Chisq(dof), max(statistic, 0))` — the upper-tail χ² p-value.

`dof` must be positive (`full` must have more parameters than `reduced`),
otherwise an `ArgumentError` is thrown. A negative `statistic` (the reduced model
fits *better* — a sign the models are not actually nested, or one did not
converge) is still returned as-is, but the p-value clamps the statistic at zero
(so `pvalue` stays in `[0, 1]`); inspect `statistic` directly in that case.

# Example
```julia
x = randn(400)
y = 0.5 .- 0.8 .* x .+ exp.(-0.3 .+ 0.4 .* x) .* randn(400)
data = (; y, x)

full    = drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1 + x)), Gaussian(); data)
reduced = drm(bf(@formula(y ~ 1),     @formula(sigma ~ 1)),     Gaussian(); data)

t = lrtest(reduced, full)
t.statistic    # 2·(logLik_full − logLik_reduced), > 0 when x helps
t.dof          # 2 extra parameters (x in μ and in log σ)
t.pvalue       # < 0.05 when x is truly predictive
```
"""
# Mean-structure fingerprint for the REML guard: the :mu block's coefficient
# names (falls back to the :mu block width when names are absent).
function _mean_structure(fit::DrmFit)
    for (p, nms) in fit.coefnames
        p === :mu && return nms
    end
    for (p, r) in fit.blocks
        p === :mu && return string.(collect(r))
    end
    return String[]
end

# REML model-selection guard (issue #11): the classic REML trap is comparing
# likelihoods of REML fits with DIFFERENT fixed-effect (mean) structures — the
# restricted likelihoods are built on different error-contrast bases and are not
# comparable. Comparing REML fits that differ only in VARIANCE structure (same
# mean) is valid. ML fits are always fine. We ERROR on the invalid case (the LR
# test would be meaningless) and stay silent otherwise.
function _reml_compare_guard(a::DrmFit, b::DrmFit, verb::AbstractString)
    (a.estim_method === :REML || b.estim_method === :REML) || return nothing
    if _mean_structure(a) != _mean_structure(b)
        throw(ArgumentError(
            "$verb: cannot compare REML fits with different fixed-effect (mean) structures — " *
            "REML log-likelihoods are not comparable across mean structures (only across " *
            "variance structures). Refit both with method = :ML for a cross-mean-structure test."))
    end
    return nothing
end

function lrtest(reduced::DrmFit, full::DrmFit)
    _reml_compare_guard(reduced, full, "lrtest")
    Δdof = dof(full) - dof(reduced)
    Δdof > 0 || throw(ArgumentError(
        "lrtest: `full` must have more parameters than `reduced` " *
        "(dof(full) = $(dof(full)), dof(reduced) = $(dof(reduced)); " *
        "did you pass the arguments as (reduced, full)?)"))
    statistic = 2 * (loglik(full) - loglik(reduced))
    pvalue = ccdf(Chisq(Δdof), max(statistic, 0))
    return (; statistic, dof = Δdof, pvalue)
end

"""
    anova(reduced::DrmFit, full::DrmFit) -> NamedTuple

Alias for [`lrtest`](@ref), matching drmTMB's `anova(reduced, full)` spelling for
a nested likelihood-ratio test. Returns the same
`(; statistic, dof, pvalue)` NamedTuple.

# Example
```julia
anova(reduced, full) == lrtest(reduced, full)   # true
```
"""
anova(reduced::DrmFit, full::DrmFit) = lrtest(reduced, full)

"""
    aicc(fit::DrmFit) -> Float64

Corrected Akaike information criterion (AICc) — the small-sample, second-order
correction to [`aic`](@ref):

    AICc = AIC + 2k(k + 1) / (n − k − 1)

with `k = dof(fit)` estimated parameters and `n = nobs(fit)` observations. The
correction is always positive, so `aicc(fit) ≥ aic(fit)`, and it converges to
`aic(fit)` as `n → ∞`. Prefer AICc over AIC when `n / k` is small (a common rule
of thumb is `n / k < 40`). Like AIC, AICc compares models fit by **ML** on the
same data; lower is better.

If `n - k - 1 <= 0` (too few observations for the correction to be defined),
returns `Inf`.

# Example
```julia
fit = drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1 + x)), Gaussian(); data)
aicc(fit) > aic(fit)        # the correction is strictly positive
isfinite(aicc(fit))         # finite whenever n - k - 1 > 0
```
"""
function aicc(fit::DrmFit)
    k = dof(fit)
    n = nobs(fit)
    n - k - 1 > 0 || return Inf
    return aic(fit) + 2 * k * (k + 1) / (n - k - 1)
end

"""
    weights(fit::DrmFit) -> Vector{Float64}

Prior (per-observation) weights used in the fit — drmTMB / glmmTMB's `weights()`.
DRM.jl fits do not currently store prior weights, so this returns
`ones(nobs(fit))` (every observation weighted equally). Extends
`StatsAPI.weights`.

# Example
```julia
fit = drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1)), Gaussian(); data)
weights(fit) == ones(nobs(fit))   # all-ones prior weights
```
"""
weights(fit::DrmFit) = ones(nobs(fit))

"""
    update(fit::DrmFit, formula; data, kwargs...) -> DrmFit

Refit `fit`'s model with a new `formula` (a [`bf`](@ref) bundle), reusing the
**fitted family** — the convenience refit verb, mirroring R's `update`. Equivalent
to `drm(formula, family(fit); data = data, kwargs...)`.

`data` must be supplied: a `DrmFit` does **not** retain its data, so `update`
cannot reuse the original observations. Any extra keyword arguments (`K`, `A`,
`tree`, `coords`, `g_tol`, …) are forwarded to [`drm`](@ref).

# Example
```julia
full    = drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1 + x)), Gaussian(); data)
# Drop x everywhere, keeping the same Gaussian family:
reduced = update(full, bf(@formula(y ~ 1), @formula(sigma ~ 1)); data = data)
length(coef(reduced)) < length(coef(full))   # fewer parameters
```
"""
update(fit::DrmFit, formula; data, kwargs...) =
    drm(formula, fit.family; data = data, kwargs...)
