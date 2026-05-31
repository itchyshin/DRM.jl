# Parametric bootstrap confidence intervals: simulate B replicates from the
# fitted model, refit each, take percentile intervals. Reuses simulate + drm.
using DRM
using Test, Random

@testset "Parametric bootstrap CI" begin
    Random.seed!(11)
    n = 500
    x = randn(n)
    βμ = [0.4, 0.7]
    y = βμ[1] .+ βμ[2] .* x .+ exp.(-0.3 .+ 0.2 .* x) .* randn(n)
    form = bf(@formula(y ~ x), @formula(sigma ~ x))
    fit = drm(form, Gaussian(); data = (; y, x))

    bci = bootstrap_ci(form, Gaussian(); data = (; y, x), B = 300, level = 0.95, rng = MersenneTwister(1))
    @test length(bci) == 4
    @test all(r.lower < r.upper for r in bci)

    # the bootstrap intervals bracket the point estimates
    pe = coef(fit, :mu)
    mu = filter(r -> r.param === :mu, bci)
    @test mu[1].lower ≤ pe[1] ≤ mu[1].upper
    @test mu[2].lower ≤ pe[2] ≤ mu[2].upper

    # and the true slope is covered at this n
    @test mu[2].lower ≤ 0.7 ≤ mu[2].upper
end
