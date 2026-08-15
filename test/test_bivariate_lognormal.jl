# Bivariate lognormal residual-correlation model — drmTMB's `biv_lognormal()`.
#
# The likelihood is closed form: log(Y) is bivariate normal, so
# log f_Y(y) = log phi_2(log y) - sum(log y). The Jacobian is parameter-free, so
# the MLE and its covariance must be IDENTICAL to the bivariate Gaussian fit on
# log(y) and only the likelihood value may shift. Both identities are asserted
# below — they are what makes delegating to the verified Gaussian kernel correct
# rather than merely convenient.

using DRM
using Test
using Random

@testset "bivariate lognormal (drmTMB biv_lognormal)" begin

    rng = MersenneTwister(11)
    n = 500
    x = randn(rng, n)
    s1, s2, rho = 0.5, 0.8, 0.6
    z1 = randn(rng, n)
    z2 = rho .* z1 .+ sqrt(1 - rho^2) .* randn(rng, n)
    y1 = exp.(0.4 .+ 0.9 .* x .+ s1 .* z1)
    y2 = exp.(-0.2 .+ 0.5 .* x .+ s2 .* z2)
    data = (; y1 = y1, y2 = y2, x = x)
    f = bf(mu1 = @formula(y1 ~ x), mu2 = @formula(y2 ~ x),
           sigma1 = @formula(sigma1 ~ 1), sigma2 = @formula(sigma2 ~ 1),
           rho12 = @formula(rho12 ~ 1))

    fit = drm(f, LogNormal(); data = data)

    @testset "parameter recovery on the log scale" begin
        @test is_converged(fit)
        est = coef(fit)
        truth = [0.4, 0.9, -0.2, 0.5, log(s1), log(s2), atanh(rho)]
        @test length(est) == 7
        @test isapprox(est, truth; atol = 0.12)
        # rho12 is reported on the correlation scale, guarded off ±1
        r̂ = first(values(corpairs(fit)))[1]
        @test isapprox(r̂, rho; atol = 0.08)
        @test -1 < r̂ < 1
    end

    @testset "closed-form identities vs the Gaussian kernel on log(y)" begin
        gfit = drm(f, Gaussian(); data = (; y1 = log.(y1), y2 = log.(y2), x = x))
        # The Jacobian does not depend on any parameter, so the optimum is the same.
        @test coef(fit) ≈ coef(gfit) atol = 1e-10
        @test vcov(fit) ≈ vcov(gfit) atol = 1e-10
        # ... and the likelihood differs by exactly that Jacobian.
        jac = sum(log.(y1)) + sum(log.(y2))
        @test loglik(gfit) - loglik(fit) ≈ jac rtol = 1e-10
        # aic/bic inherit the shift (same k, same n)
        # AIC = 2k - 2*loglik, and loglik(fit) = loglik(gfit) - jac, so the
        # lognormal AIC is LARGER by exactly 2*jac.
        @test aic(fit) - aic(gfit) ≈ 2 * jac rtol = 1e-10
    end

    @testset "the response must be strictly positive" begin
        bad = (; y1 = copy(y1), y2 = copy(y2), x = x)
        bad.y1[3] = -1.0
        @test_throws ArgumentError drm(f, LogNormal(); data = bad)
        zero_y = (; y1 = copy(y1), y2 = copy(y2), x = x)
        zero_y.y2[7] = 0.0
        @test_throws ArgumentError drm(f, LogNormal(); data = zero_y)
    end

    @testset "first-slice boundary is enforced, matching drmTMB" begin
        # No REML: the residual-only route has no random effects to integrate out.
        @test_throws ArgumentError drm(f, LogNormal(); data = data, method = :REML)
    end

    @testset "bridge routes the drmTMB family tag" begin
        b = drm_bridge(; formula = Dict(:mu1 => "y1 ~ x", :mu2 => "y2 ~ x",
                                        :sigma1 => "sigma1 ~ 1", :sigma2 => "sigma2 ~ 1",
                                        :rho12 => "rho12 ~ 1"),
                       family = "biv_lognormal", data = data)
        @test b["converged"] == true
        @test b["coefficients"] ≈ coef(fit)
        @test b["loglik"] ≈ loglik(fit)
        # the post-fit contract from A2a still holds for this family
        dp = b["dpars"]
        @test Set(keys(dp)) == Set(["mu1", "mu2", "sigma1", "sigma2", "rho12"])
        @test all(length(v) == n for v in values(dp))
        @test all(dp["sigma1"] .> 0) && all(dp["sigma2"] .> 0)
        @test all(-1 .< dp["rho12"] .< 1)
    end
end
