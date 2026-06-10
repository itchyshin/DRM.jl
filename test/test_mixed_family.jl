using DRM
using Test, Random, Statistics, LinearAlgebra

# Knuth Poisson sampler (keeps the test free of a Distributions dependency).
function _rpois(rng, λ)
    L = exp(-λ)
    k = 0
    p = 1.0
    while true
        k += 1
        p *= rand(rng)
        p <= L && return k - 1
    end
end

@testset "S3 cross-family bivariate (shared-latent GHQ)" begin
    @testset "link_residual values" begin
        @test DRM.link_residual(Binomial(), 0.3) ≈ (π^2) / 3
        @test DRM.link_residual(Poisson(), 2.0) ≈ log(1.5)
        @test DRM.link_residual(Gaussian(); dispersion = 4.0) ≈ 4.0
    end

    @testset "Gaussian x Poisson recovery (identified)" begin
        rng = MersenneTwister(20260610)
        n = 800
        x = randn(rng, n)
        X1 = hcat(ones(n), x)
        X2 = hcat(ones(n), x)
        β1 = [0.5, 0.8]; β2 = [0.3, -0.5]
        λ1 = 0.8; λ2 = 0.6; σ1 = 0.5
        u = randn(rng, n)
        y1 = X1 * β1 .+ λ1 .* u .+ σ1 .* randn(rng, n)
        η2 = X2 * β2 .+ λ2 .* u
        y2 = Float64[_rpois(rng, exp(clamp(η2[i], -20.0, 20.0))) for i in 1:n]

        fit = DRM.fit_mixed_family(y1 = y1, X1 = X1, fam1 = Gaussian(),
                                   y2 = y2, X2 = X2, fam2 = Poisson())
        @test fit.converged
        @test isapprox(fit.β1, β1; atol = 0.12)
        @test isapprox(fit.β2, β2; atol = 0.12)
        @test isapprox(fit.λ1, λ1; atol = 0.20)
        @test isapprox(fit.λ2, λ2; atol = 0.20)
        @test isapprox(fit.σ1, σ1; atol = 0.12)
        @test fit.rho_latent > 0.0
    end

    @testset "Gaussian x Gaussian == bivariate rho12 (logLik + rho parity)" begin
        rng = MersenneTwister(7)
        n = 600
        x = randn(rng, n)
        X1 = hcat(ones(n), x)
        X2 = hcat(ones(n), x)
        β1 = [0.4, 0.7]; β2 = [-0.2, 0.5]
        λ1 = 0.7; λ2 = 0.6; σ1 = 0.5; σ2 = 0.6
        u = randn(rng, n)
        y1 = X1 * β1 .+ λ1 .* u .+ σ1 .* randn(rng, n)
        y2 = X2 * β2 .+ λ2 .* u .+ σ2 .* randn(rng, n)
        ρ_true = (λ1 * λ2) / sqrt((λ1^2 + σ1^2) * (λ2^2 + σ2^2))

        mf = DRM.fit_mixed_family(y1 = y1, X1 = X1, fam1 = Gaussian(),
                                  y2 = y2, X2 = X2, fam2 = Gaussian())
        biv = drm(bf(mu1 = @formula(y1 ~ x), mu2 = @formula(y2 ~ x),
                     sigma1 = @formula(sigma1 ~ 1), sigma2 = @formula(sigma2 ~ 1),
                     rho12 = @formula(rho12 ~ 1)),
                  Gaussian(); data = (; y1, y2, x))

        # Same bivariate-normal MLE: the 1-factor marginal == the rho12 model.
        @test isapprox(mf.loglik, loglik(biv); atol = 0.1)
        @test isapprox(mf.rho_latent, ρ_true; atol = 0.1)
    end

    @testset "Fisher-z Wald CI on rho (Gaussian x Poisson)" begin
        rng = MersenneTwister(99)
        n = 1000
        x = randn(rng, n)
        X1 = hcat(ones(n), x); X2 = hcat(ones(n), x)
        β1 = [0.5, 0.3]; β2 = [0.2, -0.3]; λ1 = 0.8; λ2 = 0.7; σ1 = 0.5
        u = randn(rng, n)
        y1 = X1 * β1 .+ λ1 .* u .+ σ1 .* randn(rng, n)
        η2 = X2 * β2 .+ λ2 .* u
        y2 = Float64[_rpois(rng, exp(clamp(η2[i], -20.0, 20.0))) for i in 1:n]
        v2_true = log1p(1 / mean(exp.(η2)))
        ρ_true = (λ1 * λ2) / sqrt((λ1^2 + σ1^2) * (λ2^2 + v2_true))

        fit = DRM.fit_mixed_family(y1 = y1, X1 = X1, fam1 = Gaussian(),
                                   y2 = y2, X2 = X2, fam2 = Poisson())
        lo, hi = fit.rho_ci_wald
        @test isfinite(lo) && isfinite(hi)
        @test 0 < hi - lo < 0.5                    # finite, sensible Wald width
        @test lo ≤ fit.rho_latent ≤ hi
        @test isapprox(fit.rho_latent, ρ_true; atol = 0.12)
    end
end
