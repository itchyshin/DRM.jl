# Wald inference for fitted DRM models: standard errors from the observed
# information (vcov) and Wald confidence intervals. Mirrors drmTMB's default
# `confint(..., method = "wald")`.
using DRM
using Test, Random, LinearAlgebra

@testset "Wald inference: stderror + confint" begin
    Random.seed!(20260602)
    n = 3000
    x = randn(n)
    βμ = [0.5, -0.8]
    βσ = [-0.3, 0.4]
    y = βμ[1] .+ βμ[2] .* x .+ exp.(βσ[1] .+ βσ[2] .* x) .* randn(n)
    fit = drm(bf(@formula(y ~ x), @formula(sigma ~ x)), Gaussian(); data = (; y, x))

    se = stderror(fit)
    @test se ≈ sqrt.(diag(vcov(fit)))
    @test all(se .> 0)

    ci = confint(fit; level = 0.95)
    @test length(ci) == 4
    @test all(c.lower < c.estimate < c.upper for c in ci)

    # confint is exactly estimate ± z·se (deterministic Wald property)
    z = 1.959963984540054      # qnorm(0.975)
    for (k, c) in enumerate(ci)
        @test c.lower ≈ c.estimate - z * se[k]
        @test c.upper ≈ c.estimate + z * se[k]
    end

    # μ estimates recover the truth (loose), in [intercept, slope] order
    mu_ci = filter(c -> c.param === :mu, ci)
    @test [c.estimate for c in mu_ci] ≈ βμ atol = 0.1

    # narrower confidence level ⇒ narrower interval
    ci90 = confint(fit; level = 0.90)
    @test (ci90[1].upper - ci90[1].lower) < (ci[1].upper - ci[1].lower)
end
