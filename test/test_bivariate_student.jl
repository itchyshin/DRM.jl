# Bivariate Student-t scatter-correlation model — drmTMB's `biv_student()`.
#
# The exact bivariate-t density, parameterised exactly as drmTMB's own
# `simulate()` draws it: Y = mu + diag(sigma) * Z * sqrt(nu / chisq_nu) with
# Z ~ N(0, R). So sigma1/sigma2 are SCALE parameters (not marginal SDs),
# rho12 is the SCATTER correlation, and nu is SHARED across both margins by
# construction — one scalar mixing variable governs both.

using DRM
using Test
using Random

@testset "bivariate Student-t (drmTMB biv_student)" begin

    rng = MersenneTwister(21)
    n = 800
    x = randn(rng, n)
    s1, s2, rho, nu = 0.7, 1.1, 0.5, 6.0
    z1 = randn(rng, n)
    z2 = rho .* z1 .+ sqrt(1 - rho^2) .* randn(rng, n)
    chi = [sum(randn(rng, 6) .^ 2) for _ in 1:n]      # chisq_6
    sh = sqrt.(nu ./ chi)
    y1 = 0.5 .+ 0.8 .* x .+ s1 .* z1 .* sh
    y2 = -0.3 .+ 0.4 .* x .+ s2 .* z2 .* sh
    data = (; y1 = y1, y2 = y2, x = x)
    f = bf(mu1 = @formula(y1 ~ x), mu2 = @formula(y2 ~ x),
           sigma1 = @formula(sigma1 ~ 1), sigma2 = @formula(sigma2 ~ 1),
           nu = @formula(nu ~ 1), rho12 = @formula(rho12 ~ 1))

    fit = drm(f, Student(); data = data)

    @testset "parameter recovery incl. the shared nu" begin
        @test is_converged(fit)
        est = coef(fit)
        # drmTMB's dpar ORDER: mu1, mu2, sigma1, sigma2, nu, rho12 — nu before rho12.
        truth = [0.5, 0.8, -0.3, 0.4, log(s1), log(s2), log(nu - 2), atanh(rho)]
        @test length(est) == 8
        @test isapprox(est, truth; atol = 0.25)
        ν̂ = 2 + exp(coef(fit, :nu)[1])
        @test 3.5 < ν̂ < 10.0                     # heavy-tailed, finite variance
        @test isapprox(fit.scales[:rho12][1], rho; atol = 0.08)
    end

    @testset "logm2 link keeps nu > 2 (finite variance)" begin
        # nu = 2 + exp(eta) can never reach 2 from below, whatever eta does.
        @test all(fit.scales[:nu] .> 2)
        @test coef(fit, :nu) isa AbstractVector
    end

    @testset "block layout matches drmTMB's dpar order" begin
        ks = first.(fit.blocks)
        @test ks == [:mu1, :mu2, :sigma1, :sigma2, :nu, :rho12]
    end

    @testset "first-slice boundary is enforced, matching drmTMB" begin
        @test_throws ArgumentError drm(f, Student(); data = data, method = :REML)
    end

    @testset "nu is shared — the grammar offers no per-margin df" begin
        # `bf` has one `nu`, not `nu1`/`nu2`: under the exact bivariate-t a single
        # scalar mixing variable governs both margins (dr19). A per-margin df
        # would need a copula, losing the exact density.
        @test_throws ArgumentError bf(mu1 = @formula(y1 ~ x), mu2 = @formula(y2 ~ x),
                                      nu = @formula(nu1 ~ 1))
        # ... and the Gaussian/lognormal bundles must be untouched by nu existing.
        gf = bf(mu1 = @formula(y1 ~ x), mu2 = @formula(y2 ~ x))
        @test first.(gf.forms) == [:mu1, :mu2, :sigma1, :sigma2, :rho12]
    end

    @testset "nu defaults to intercept-only when omitted" begin
        f_nonu = bf(mu1 = @formula(y1 ~ x), mu2 = @formula(y2 ~ x),
                    sigma1 = @formula(sigma1 ~ 1), sigma2 = @formula(sigma2 ~ 1),
                    rho12 = @formula(rho12 ~ 1))
        fit2 = drm(f_nonu, Student(); data = data)
        @test length(coef(fit2)) == 8
        @test isapprox(coef(fit2), coef(fit); atol = 1e-6)
    end
end
