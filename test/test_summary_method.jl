# `summary(fit)` parity method: fit a tiny Gaussian location–scale model and
# assert `summary(fit)` returns the same coefficient table as `coeftable(fit)`,
# plus sanity-check the `coef`/`vcov`/`nobs` accessor shapes.
using DRM
using Test, Random
using StatsModels: CoefTable

@testset "summary(fit) method + coef/vcov/nobs shapes" begin
    Random.seed!(20260603)
    n = 500
    x = randn(n)
    y = 0.5 .- 0.8 .* x .+ exp.(-0.3 .+ 0.4 .* x) .* randn(n)
    data = (; y, x)

    fit = drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1 + x)), Gaussian(); data = data)

    # summary(fit) is the drmTMB-parity analogue of coeftable(fit).
    @test summary(fit) isa CoefTable
    @test summary(fit) == coeftable(fit)

    # Accessor shapes: 4 coefficients (mu intercept+slope, sigma intercept+slope).
    b = coef(fit)
    @test length(b) == 4
    V = vcov(fit)
    @test size(V) == (4, 4)
    @test nobs(fit) == n
end
