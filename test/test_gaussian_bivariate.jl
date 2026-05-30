# Bivariate Gaussian location–scale with predictor-dependent residual
# correlation ρ12 — fixed effects. Recovery test (Curie): simulate a correlated
# bivariate response with known coefficients on μ1, μ2, log σ1, log σ2, and
# atanh(ρ12), fit via the keyword `bf(mu1=…, mu2=…, …)` front end, recover.
using DRM
using Test, Random

@testset "Bivariate Gaussian location-scale + rho12 — recovery" begin
    Random.seed!(20260531)
    n = 6000
    x = randn(n)
    βμ1 = [0.3, 0.5]
    βμ2 = [-0.2, 0.4]
    βσ1 = [-0.1, 0.2]      # on log σ1
    βσ2 = [0.0, -0.3]      # on log σ2
    βρ = [0.4, 0.3]        # on atanh(ρ12)  (ρ = tanh(η))

    μ1 = βμ1[1] .+ βμ1[2] .* x
    μ2 = βμ2[1] .+ βμ2[2] .* x
    σ1 = exp.(βσ1[1] .+ βσ1[2] .* x)
    σ2 = exp.(βσ2[1] .+ βσ2[2] .* x)
    ρ = tanh.(βρ[1] .+ βρ[2] .* x)

    z1 = randn(n); z2 = randn(n)
    y1 = μ1 .+ σ1 .* z1
    y2 = μ2 .+ σ2 .* (ρ .* z1 .+ sqrt.(1 .- ρ .^ 2) .* z2)
    data = (; y1, y2, x)

    fit = drm(bf(mu1 = @formula(y1 ~ x), mu2 = @formula(y2 ~ x),
                 sigma1 = @formula(sigma1 ~ x), sigma2 = @formula(sigma2 ~ x),
                 rho12 = @formula(rho12 ~ x)), Gaussian(); data = data)

    @test coef(fit, :mu1) ≈ βμ1 atol = 0.06
    @test coef(fit, :mu2) ≈ βμ2 atol = 0.06
    @test coef(fit, :sigma1) ≈ βσ1 atol = 0.06
    @test coef(fit, :sigma2) ≈ βσ2 atol = 0.06
    @test coef(fit, :rho12) ≈ βρ atol = 0.10
    @test isfinite(loglik(fit))
end
