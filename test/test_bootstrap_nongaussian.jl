# Parametric bootstrap on non-Gaussian families. bootstrap_ci was Gaussian-only
# because simulate() only knew how to draw Gaussian responses; this exercises the
# generalised simulate + the family-agnostic bootstrap path.
using DRM
using Test, Random
import Distributions

@testset "Parametric bootstrap — non-Gaussian families" begin
    @testset "Poisson bootstrap brackets β and covers truth" begin
        Random.seed!(20260801)
        n = 400; x = randn(n)
        β = [0.4, 0.6]
        y = Float64[rand(Distributions.Poisson(exp(β[1] + β[2] * x[i]))) for i in 1:n]
        dat = (; y, x)
        rows = bootstrap_ci(bf(@formula(y ~ x)), Poisson(); data = dat, B = 200,
                            rng = MersenneTwister(1))
        xr = first(r for r in rows if r.coef == "x")
        @test xr.lower < xr.estimate < xr.upper
        @test xr.lower < β[2] < xr.upper
        @test isfinite(xr.lower) && isfinite(xr.upper)
    end

    @testset "Gamma bootstrap brackets β" begin
        Random.seed!(20260802)
        n = 400; x = randn(n)
        β = [0.5, 0.4]; α = 8.0
        μ = exp.(β[1] .+ β[2] .* x)
        y = Float64[rand(Distributions.Gamma(α, μ[i] / α)) for i in 1:n]
        dat = (; y, x)
        rows = bootstrap_ci(bf(@formula(y ~ x), @formula(sigma ~ 1)), Gamma();
                            data = dat, B = 200, rng = MersenneTwister(2))
        xr = first(r for r in rows if r.coef == "x")
        @test xr.lower < xr.estimate < xr.upper
        @test xr.lower < β[2] < xr.upper
    end

    @testset "simulate draws valid non-Gaussian responses" begin
        Random.seed!(20260803)
        n = 300; x = randn(n)
        yp = Float64[rand(Distributions.Poisson(exp(0.3 + 0.5x[i]))) for i in 1:n]
        fitp = drm(bf(@formula(y ~ x)), Poisson(); data = (; y = yp, x))
        sp = simulate(fitp; rng = MersenneTwister(3))
        @test length(sp) == n
        @test all(sp .>= 0) && all(isinteger, sp)      # counts
    end
end
