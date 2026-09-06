# Hurdle (`hu`) modifier for count families: a two-part model. A logit "hurdle"
# decides zero vs positive (π = P(y=0)); positive counts follow the ZERO-TRUNCATED
# count distribution. Unlike `zi`, all zeros are structural. Mirrors drmTMB's `hu`.
using DRM
using Test, Random
import Distributions

_logis(η) = 1 / (1 + exp(-η))
rtpois(λ) = (while true; k = rand(Distributions.Poisson(λ)); k > 0 && return k; end)
rtnb(r, p) = (while true; k = rand(Distributions.NegativeBinomial(r, p)); k > 0 && return k; end)

@testset "Hurdle Poisson: y ~ x, hu ~ 1 — recovery" begin
    Random.seed!(20260620)
    n = 4000; x = randn(n)
    βμ = [0.6, 0.4]; πz = _logis(-0.4)                  # π ≈ 0.40 structural zeros
    λ = exp.(βμ[1] .+ βμ[2] .* x)
    y = Float64.([rand() < πz ? 0 : rtpois(λ[i]) for i in 1:n])

    fit = drm(bf(@formula(y ~ x), @formula(hu ~ 1)), Poisson(); data = (; y, x))

    @test coef(fit, :mu)[1] ≈ βμ[1] atol = 0.08          # log-λ intercept (positive part)
    @test coef(fit, :mu)[2] ≈ βμ[2] atol = 0.08          # log-λ slope
    @test _logis(coef(fit, :hu)[1]) ≈ πz atol = 0.05     # hurdle (zero) probability
    @test isfinite(loglik(fit))
end

@testset "Hurdle negative-binomial: y ~ x, hu ~ 1 — recovery" begin
    Random.seed!(20260621)
    n = 5000; x = randn(n)
    βμ = [0.7, 0.3]; θ = 3.0; πz = _logis(-0.3)          # π ≈ 0.43
    μ = exp.(βμ[1] .+ βμ[2] .* x)
    y = Float64.([rand() < πz ? 0 : rtnb(θ, θ / (θ + μ[i])) for i in 1:n])

    fit = drm(bf(@formula(y ~ x), @formula(sigma ~ 1), @formula(hu ~ 1)), NegBinomial2(); data = (; y, x))

    @test coef(fit, :mu)[1] ≈ βμ[1] atol = 0.12
    @test coef(fit, :mu)[2] ≈ βμ[2] atol = 0.10
    @test _logis(coef(fit, :hu)[1]) ≈ πz atol = 0.06
    @test isfinite(loglik(fit))
end

# drmTMB spells the hurdle NB2 as `truncated_nbinom2()` + `hu ~ ...` — it has no
# `hurdle_nbinom2()` constructor, and the positive component of a hurdle IS the
# zero-truncated count distribution. Accepting that spelling here is what lets a
# drmTMB user flip `engine =` on ONE call. It must fit the SAME likelihood as the
# `NegBinomial2()` + `hu` spelling, not merely a similar one.
@testset "Hurdle NB2 — TruncatedNegBinomial2() + hu is the same fit as NegBinomial2() + hu" begin
    Random.seed!(20260905)
    n = 1200; x = randn(n); w = randn(n)
    βμ = [0.5, 0.35]; θ = exp(2 * 0.30)                   # σ = exp(-0.30) ⇒ θ = 1/σ²
    μ = exp.(βμ[1] .+ βμ[2] .* x)
    πz = _logis.(-0.6 .+ 0.5 .* w)
    y = Float64.([rand() < πz[i] ? 0 : rtnb(θ, θ / (θ + μ[i])) for i in 1:n])
    data = (; y, x, w)
    @test any(y .== 0) && any(y .> 0)                     # a real hurdle fixture

    form = bf(@formula(y ~ x), @formula(sigma ~ 1), @formula(hu ~ w))
    fit_t = drm(form, TruncatedNegBinomial2(); data = data)
    fit_n = drm(form, NegBinomial2(); data = data)

    for p in (:mu, :sigma, :hu)
        @test coef(fit_t, p) == coef(fit_n, p)            # same code path, bit-for-bit
    end
    @test loglik(fit_t) == loglik(fit_n)
    @test isfinite(loglik(fit_t))
    # The delegation is declared, not hidden: the fit reports the family whose
    # `_fit_negbin2_hu` kernel actually ran.
    @test fit_t.family isa NegBinomial2
    # and it is the HURDLE, not the plain zero-truncated model: the hu block
    # exists and both its intercept and slope are recovered
    @test _logis(coef(fit_t, :hu)[1]) ≈ _logis(-0.6) atol = 0.06
    @test coef(fit_t, :hu)[2] ≈ 0.5 atol = 0.15
    @test coef(fit_t, :mu)[1] ≈ βμ[1] atol = 0.15
    @test coef(fit_t, :mu)[2] ≈ βμ[2] atol = 0.10
    # a zero-truncated response check would have rejected this data outright
    @test count(iszero, y) > 100
end

# A formula part the family does not consume must be an ERROR, never a silent
# drop. Before this guard, `zi` was quietly deleted from the likelihood and
# `TruncatedNegBinomial2()` fitted the plain zero-truncated model instead — a
# different model than the caller wrote, with no diagnostic.
@testset "TruncatedNegBinomial2 refuses a formula part it does not consume" begin
    Random.seed!(20260905)
    n = 300; x = randn(n); w = randn(n)
    y = Float64.([rtnb(3.0, 3.0 / (3.0 + exp(0.5 + 0.3 * x[i]))) for i in 1:n])
    data = (; y, x, w)
    @test all(y .>= 1)

    err = try
        drm(bf(@formula(y ~ x), @formula(sigma ~ 1), @formula(zi ~ w)),
            TruncatedNegBinomial2(); data = data)
        ""
    catch e
        sprint(showerror, e)
    end
    @test occursin("unsupported formula part `zi`", err)
    @test occursin("belongs to NegBinomial2()", err)

    # the plain zero-truncated fit still works, unchanged
    fit = drm(bf(@formula(y ~ x), @formula(sigma ~ 1)), TruncatedNegBinomial2(); data = data)
    @test isfinite(loglik(fit))
    @test length(coef(fit, :mu)) == 2
end
