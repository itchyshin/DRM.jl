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
