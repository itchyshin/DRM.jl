# Randomized quantile residuals (Dunn & Smyth; DHARMa / glmmTMB style) via the
# `residuals(fit; type = :quantile)` keyword. Back-compat: `type = :response`
# (the default) is byte-identical to the old `residuals(fit)`.
using DRM
using Test, Random, Statistics
import Distributions          # qualified — DRM exports its own Poisson/Gamma families

@testset "quantile residuals" begin
    @testset "Gaussian — back-compat + loc-scale PIT" begin
        Random.seed!(20260604)
        n = 800
        x = randn(n)
        βμ = [0.5, -0.8]; βσ = [-0.3, 0.4]   # log σ = -0.3 + 0.4x
        μ = βμ[1] .+ βμ[2] .* x
        σ = exp.(βσ[1] .+ βσ[2] .* x)
        y = μ .+ σ .* randn(n)
        data = (; y, x)

        fit = drm(bf(@formula(y ~ x), @formula(sigma ~ x)), Gaussian(); data = data)

        # Back-compat: default == :response, and == y - fitted.
        @test residuals(fit) == residuals(fit; type = :response)
        @test residuals(fit) ≈ (y .- fitted(fit))

        r = residuals(fit; type = :quantile)
        μ̂ = fit.means[:mu]; σ̂ = fit.scales[:sigma]
        # Gaussian PIT through Φ⁻¹(Φ((y-μ)/σ)) = (y-μ)/σ exactly.
        @test r ≈ (y .- μ̂) ./ σ̂ rtol = 1e-8
        # Roughly standard normal on well-fit data.
        @test abs(mean(r)) < 0.2
        @test 0.8 < std(r) < 1.25
    end

    @testset "Poisson — randomized discrete PIT" begin
        Random.seed!(20260615)
        n = 3000
        x = randn(n)
        β = [0.3, 0.5]
        λ = exp.(β[1] .+ β[2] .* x)
        y = Float64.([rand(Distributions.Poisson(λi)) for λi in λ])
        data = (; y, x)

        fit = drm(bf(@formula(y ~ x)), Poisson(); data = data)

        Random.seed!(1)
        r = residuals(fit; type = :quantile)
        @test length(r) == n
        @test all(isfinite, r)
        @test abs(mean(r)) < 0.3
        @test 0.6 < std(r) < 1.4
    end

    @testset "unsupported family throws" begin
        Random.seed!(20260618)
        n = 1000
        x = randn(n)
        β = [0.5, 0.4]; α = 8.0
        μ = exp.(β[1] .+ β[2] .* x)
        y = Float64.([rand(Distributions.Gamma(α, μi / α)) for μi in μ])
        data = (; y, x)

        gfit = drm(bf(@formula(y ~ x), @formula(sigma ~ 1)), Gamma(); data = data)
        @test_throws ArgumentError residuals(gfit; type = :quantile)
    end

    @testset "unknown type throws" begin
        Random.seed!(7)
        n = 200
        x = randn(n)
        y = 0.5 .- 0.8 .* x .+ randn(n)
        data = (; y, x)
        fit = drm(bf(@formula(y ~ x)), Gaussian(); data = data)
        @test_throws ArgumentError residuals(fit; type = :bogus)
    end
end
