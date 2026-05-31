# Parametric simulation from a fitted Gaussian model (the building block for a
# parametric bootstrap). Residual-level draws: y* = μ̂ + (model residual SD)·z.
using DRM
using Test, Random

@testset "simulate" begin
    Random.seed!(9)
    n = 600
    x = randn(n)
    y = 0.5 .+ 0.4 .* x .+ exp.(-0.2 .+ 0.3 .* x) .* randn(n)
    fit = drm(bf(@formula(y ~ x), @formula(sigma ~ x)), Gaussian(); data = (; y, x))

    ys = simulate(fit; rng = MersenneTwister(1))
    @test length(ys) == n
    @test ys != y                                   # a fresh draw, not the data

    # refit on simulated data recovers similar coefficients (bootstrap sanity)
    fit2 = drm(bf(@formula(y ~ x), @formula(sigma ~ x)), Gaussian(); data = (; y = ys, x))
    @test coef(fit2, :mu) ≈ coef(fit, :mu) atol = 0.3

    # bivariate: per-response draws
    y2 = -0.3 .+ 0.5 .* x .+ 0.4 .* randn(n)
    bv = drm(bf(mu1 = @formula(y ~ x), mu2 = @formula(y2 ~ x),
                sigma1 = @formula(sigma1 ~ 1), sigma2 = @formula(sigma2 ~ 1),
                rho12 = @formula(rho12 ~ 1)), Gaussian(); data = (; y, y2, x))
    s = simulate(bv; rng = MersenneTwister(2))
    @test haskey(s, :mu1) && haskey(s, :mu2)
    @test length(s[:mu1]) == n
end
