# =============================================================================
# Quantile residuals (Dunn–Smyth randomized quantile residuals, à la DHARMa /
# glmmTMB) — per-family conditional-distribution dispatch.
#
# This file is included from DRM.jl *after* every family type is defined
# (gaussian, student, poisson, negbinomial, beta, betabinomial, binomial,
# gamma, lognormal, zeroonebeta, tweedie, cumulative). The `_conditional_dist`
# / `_is_continuous_family` methods dispatch on those family types, so they must
# be defined here rather than in gaussian_core.jl (which loads before the family
# files and would otherwise hit `UndefVarError: Student not defined`).
#
# Entry point: `_quantile_residuals(fit, rng)`, called by
# `residuals(fit; type = :quantile)` in gaussian_core.jl.
# =============================================================================

# ---- per-family conditional distribution (the parameter→Distributions map) ----
#
# `_conditional_dist(fam, i; μ, scales, obs)` returns the fitted per-observation
# response distribution `F_i` as a `Distributions.Distribution`. This is the one
# place the working-scale parameters (μ on the response scale; the `scales` Dict)
# are mapped to the `Distributions.jl` constructor, so it is reusable by
# `residuals(type=:quantile)` and any future `simulate`/PIT/predictive checks.
#
# Scale conventions (verified against the family kernels and `simulate`):
#   • Gaussian     Normal(μ, σ),                  σ = scales[:sigma]
#   • Student      μ + σ·TDist(ν)  (LocationScale), σ = scales[:sigma], ν = scales[:nu]
#   • LogNormal    LogNormal(meanlog, sdlog), meanlog = log(μ̂) (μ̂ stored = exp(η_μ),
#                  the response-scale median), sdlog = σ = scales[:sigma]
#   • Gamma        Gamma(α, μ/α),                 α = σ⁻²  (shape; scales[:sigma]⁻²)
#   • Beta         Beta(μφ, (1−μ)φ),              φ = σ⁻²  (precision)
#   • Poisson      Poisson(μ)
#   • NegBinomial2 NegativeBinomial(φ, φ/(φ+μ)),  φ = scales[:sigma] **directly**
#                  (the NB2 kernel stores size θ = exp(η_σ) in the sigma slot, NOT σ⁻²)
#   • TruncNB2     truncated(NegativeBinomial(φ, p); lower = 0)   (support ≥ 1)
#   • Binomial     Binomial(n, p),  p = μ (success prob), n = scales[:trials]
#   • BetaBinomial BetaBinomial(n, μφ, (1−μ)φ),  φ = σ⁻², n = scales[:trials]
# ZeroOneBeta and CumulativeLogit are mixtures / need cut intervals and are handled
# by the atomic / ordinal drivers below rather than returning a single Distribution.
function _conditional_dist(fam::Gaussian, i; μ, scales, obs)
    return Distributions.Normal(μ[i], scales[:sigma][i])
end
function _conditional_dist(fam::Student, i; μ, scales, obs)
    return μ[i] + scales[:sigma][i] * Distributions.TDist(scales[:nu][i])
end
function _conditional_dist(fam::LogNormal, i; μ, scales, obs)
    return Distributions.LogNormal(log(max(μ[i], eps())), scales[:sigma][i])
end
function _conditional_dist(fam::Gamma, i; μ, scales, obs)
    α = 1 / (scales[:sigma][i]^2)
    return Distributions.Gamma(α, μ[i] / α)
end
function _conditional_dist(fam::Beta, i; μ, scales, obs)
    φ = 1 / (scales[:sigma][i]^2)
    m = clamp(μ[i], eps(), 1 - eps())
    return Distributions.Beta(m * φ, (1 - m) * φ)
end
function _conditional_dist(fam::Poisson, i; μ, scales, obs)
    return Distributions.Poisson(max(μ[i], 0.0))
end
function _conditional_dist(fam::NegBinomial2, i; μ, scales, obs)
    φ = 1 / (scales[:sigma][i]^2)               # scales[:sigma] = σ now; NB2 size = 1/σ²
    return Distributions.NegativeBinomial(φ, φ / (φ + μ[i]))
end
# TruncatedNegBinomial2 returns the *base* (untruncated) NB2; the zero-truncation
# F(k) = (NB.cdf(k) − NB.cdf(0)) / (1 − NB.cdf(0)) for k ≥ 1 is applied in the
# discrete driver (avoids the `truncated` discrete-lower-bound convention).
function _conditional_dist(fam::TruncatedNegBinomial2, i; μ, scales, obs)
    φ = 1 / (scales[:sigma][i]^2)               # scales[:sigma] = σ now; NB2 size = 1/σ²
    return Distributions.NegativeBinomial(φ, φ / (φ + μ[i]))
end
function _conditional_dist(fam::Binomial, i; μ, scales, obs)
    n = round(Int, scales[:trials][i])
    return Distributions.Binomial(n, clamp(μ[i], eps(), 1 - eps()))
end
function _conditional_dist(fam::BetaBinomial, i; μ, scales, obs)
    φ = 1 / (scales[:sigma][i]^2)
    m = clamp(μ[i], eps(), 1 - eps())
    n = round(Int, scales[:trials][i])
    return Distributions.BetaBinomial(n, m * φ, (1 - m) * φ)
end

# Families whose conditional distribution is continuous (PIT = F(y), no RNG) vs
# discrete (randomized PIT u ~ Uniform[F(y⁻), F(y)]).
_is_continuous_family(::Gaussian)   = true
_is_continuous_family(::Student)    = true
_is_continuous_family(::LogNormal)  = true
_is_continuous_family(::Gamma)      = true
_is_continuous_family(::Beta)       = true
_is_continuous_family(::Poisson)    = false
_is_continuous_family(::NegBinomial2) = false
_is_continuous_family(::TruncatedNegBinomial2) = false
_is_continuous_family(::Binomial)   = false
_is_continuous_family(::BetaBinomial) = false

# The observed value the PIT is evaluated at. Binomial/BetaBinomial store the
# observed proportion in obs[:mu]; the count is proportion × trials.
_pit_obs(::Binomial, i; obs, scales)     = round(Int, obs[:mu][i] * scales[:trials][i])
_pit_obs(::BetaBinomial, i; obs, scales) = round(Int, obs[:mu][i] * scales[:trials][i])
_pit_obs(::Any, i; obs, scales)          = obs[:mu][i]

# Randomized quantile residuals r_i = Φ⁻¹(u_i) (Dunn & Smyth; DHARMa / glmmTMB).
# Continuous families use u = F(y); discrete families randomize within the jump
# interval [F(y⁻), F(y)]; ZeroOneBeta / CumulativeLogit use the atomic / ordinal
# drivers (point-mass mixtures). The per-family parameter map lives in
# `_conditional_dist`.
function _quantile_residuals(fit::DrmFit, rng)
    haskey(fit.means, :mu) ||
        throw(ArgumentError("residuals(type=:quantile) is univariate-only"))
    fam = fit.family
    (fam isa Gaussian && haskey(fit.scales, :sigma1)) &&
        throw(ArgumentError("residuals(type=:quantile) is univariate-only"))
    y = fit.obs[:mu]
    μ = fit.means[:mu]
    n = length(y)
    lo = eps(); hi = 1 - eps()
    std_normal = Distributions.Normal()

    if fam isa ZeroOneBeta
        return _quantile_residuals_zeroonebeta(fit, rng, lo, hi)
    elseif fam isa CumulativeLogit
        return _quantile_residuals_cumulative(fit, rng, lo, hi)
    elseif fam isa Tweedie
        throw(ArgumentError("residuals(type=:quantile): Tweedie has no closed-form CDF " *
            "in Distributions.jl; a Tweedie compound Poisson–Gamma CDF is tracked as a " *
            "follow-up. All other DRM.jl families are supported."))
    end

    # Single-distribution families via `_conditional_dist`.
    applicable(_is_continuous_family, fam) ||
        throw(ArgumentError("residuals(type=:quantile): $(nameof(typeof(fam))) has no " *
            "verified per-family CDF mapping yet"))
    u = Vector{Float64}(undef, n)
    if _is_continuous_family(fam)
        @inbounds for i in 1:n
            d = _conditional_dist(fam, i; μ = μ, scales = fit.scales, obs = fit.obs)
            u[i] = clamp(Distributions.cdf(d, y[i]), lo, hi)
        end
    elseif fam isa TruncatedNegBinomial2
        @inbounds for i in 1:n
            d = _conditional_dist(fam, i; μ = μ, scales = fit.scales, obs = fit.obs)
            yi = round(Int, y[i])
            F0 = Distributions.cdf(d, 0)            # NB.cdf(0) = P(0)
            denom = 1 - F0
            # zero-truncated CDF: F_t(k) = (NB.cdf(k) − F0)/(1 − F0), k ≥ 1
            a = (Distributions.cdf(d, yi - 1) - F0) / denom
            b = (Distributions.cdf(d, yi) - F0) / denom
            u[i] = clamp(a + (b - a) * rand(rng), lo, hi)
        end
    else
        @inbounds for i in 1:n
            d = _conditional_dist(fam, i; μ = μ, scales = fit.scales, obs = fit.obs)
            yi = _pit_obs(fam, i; obs = fit.obs, scales = fit.scales)
            a = Distributions.cdf(d, yi - 1)
            b = Distributions.cdf(d, yi)
            u[i] = clamp(a + (b - a) * rand(rng), lo, hi)
        end
    end
    return Distributions.quantile.(std_normal, u)
end

# ZeroOneBeta atomic driver. Mixture: P(0) = zoi(1−coi) at the atom 0, P(1) = zoi·coi
# at the atom 1, and the interior is (1−zoi)·Beta(μβφ,(1−μβ)φ) on (0,1). The CDF is
#   F(0⁻)=0, F(0)=zoi(1−coi);
#   F(y∈(0,1)) = zoi(1−coi) + (1−zoi)·Beta.cdf(y);   (continuous interior)
#   F(1⁻)=zoi(1−coi)+(1−zoi), F(1)=1.
# A value AT an atom gets u ~ Uniform[F(atom⁻), F(atom)] (randomized across the mass);
# interior values get the plain PIT. Generalizes the discrete driver.
function _quantile_residuals_zeroonebeta(fit::DrmFit, rng, lo, hi)
    y = fit.obs[:mu]; n = length(y)
    μb = fit.scales[:beta_mu]; σ = fit.scales[:sigma]
    zoi = fit.scales[:zoi]; coi = fit.scales[:coi]
    std_normal = Distributions.Normal()
    u = Vector{Float64}(undef, n)
    @inbounds for i in 1:n
        p0 = zoi[i] * (1 - coi[i])              # mass at 0
        if y[i] == 0
            u[i] = clamp((0.0) + (p0 - 0.0) * rand(rng), lo, hi)
        elseif y[i] == 1
            a = p0 + (1 - zoi[i])               # F(1⁻)
            u[i] = clamp(a + (1.0 - a) * rand(rng), lo, hi)
        else
            φ = 1 / (σ[i]^2); m = clamp(μb[i], eps(), 1 - eps())
            Fc = Distributions.cdf(Distributions.Beta(m * φ, (1 - m) * φ), y[i])
            u[i] = clamp(p0 + (1 - zoi[i]) * Fc, lo, hi)
        end
    end
    return Distributions.quantile.(std_normal, u)
end

# CumulativeLogit ordinal driver. For category k ∈ {1,…,K}, F(k) = logistic(cuts[k] − η)
# (F(K)=1, F(0)=0); the observed category gets a randomized PIT within its probability
# interval [F(k−1), F(k)] — the discrete driver applied to the cumulative cutpoints.
function _quantile_residuals_cumulative(fit::DrmFit, rng, lo, hi)
    y = round.(Int, fit.obs[:mu]); n = length(y)
    η = fit.scales[:ordinal_eta]; cuts = fit.scales[:ordinal_cuts]
    K = length(cuts) + 1
    std_normal = Distributions.Normal()
    Fcum(k, i) = k <= 0 ? 0.0 : k >= K ? 1.0 : _logistic(cuts[k] - η[i])
    u = Vector{Float64}(undef, n)
    @inbounds for i in 1:n
        k = y[i]
        a = Fcum(k - 1, i); b = Fcum(k, i)
        u[i] = clamp(a + (b - a) * rand(rng), lo, hi)
    end
    return Distributions.quantile.(std_normal, u)
end
