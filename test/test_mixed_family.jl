using DRM
using Test, Random, Statistics, LinearAlgebra
using SpecialFunctions: trigamma   # for the Tier-2 link_residual value checks

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
        # Tier-2 dispersion families (each maps its own dispersion convention)
        @test DRM.link_residual(NegBinomial2(); dispersion = 5.0) ≈ trigamma(5.0)
        @test DRM.link_residual(Gamma(); dispersion = 0.25) ≈ trigamma(1 / 0.25)   # disp = σ²
        @test DRM.link_residual(Beta(), 0.4; dispersion = 8.0) ≈ trigamma(0.4 * 8) + trigamma(0.6 * 8)
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

    @testset "Wald + profile + bootstrap CI on rho (Gaussian x Poisson)" begin
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
                                   y2 = y2, X2 = X2, fam2 = Poisson(),
                                   profile = true, B = 60, rng = MersenneTwister(123))
        # the returned point estimates must be plain Float64 (closure-boxing guard)
        @test eltype(fit.β1) == Float64 && fit.λ1 isa Float64

        lo, hi = fit.rho_ci_wald
        @test isfinite(lo) && isfinite(hi)
        @test 0 < hi - lo < 0.5                    # finite, sensible Wald width
        @test lo ≤ fit.rho_latent ≤ hi
        @test isapprox(fit.rho_latent, ρ_true; atol = 0.12)

        # profile-likelihood CI (recommended): finite, brackets the estimate, and
        # close to the Wald interval for this near-quadratic likelihood.
        plo, phi = fit.rho_ci_profile
        @test isfinite(plo) && isfinite(phi)
        @test plo < fit.rho_latent < phi
        @test 0 < phi - plo < 0.6
        @test isapprox(phi - plo, hi - lo; atol = 0.15)

        blo, bhi = fit.rho_ci_boot
        @test isfinite(blo) && isfinite(bhi)
        @test 0 < bhi - blo < 0.6                       # bootstrap interval finite & sensible
        @test blo - 0.1 < fit.rho_latent < bhi + 0.1    # brackets the point estimate
    end

    # ---- Tier-2 cross-family pairs. Each shares a latent u; recovery is checked
    # for β/λ and the dispersion. Identified because at least one axis either is a
    # non-Gaussian (NB2×Gaussian breaks the moment-only λ ridge) or carries no free
    # residual variance at all (Binomial, Poisson). Simulation reuses DRM's own
    # per-family sampler `_mf_rand` (same code path as the bootstrap).

    @testset "NB2 x Gaussian recovery (identified)" begin
        rng = MersenneTwister(20260610)
        n = 2000
        x = randn(rng, n)
        X1 = hcat(ones(n), x); X2 = hcat(ones(n), x)
        β1 = [0.6, 0.4]; β2 = [0.3, -0.5]
        λ1 = 0.7; λ2 = 0.6; θ_nb = 6.0; σ2 = 0.5
        u = randn(rng, n)
        η1 = X1 * β1 .+ λ1 .* u
        η2 = X2 * β2 .+ λ2 .* u
        y1 = [DRM._mf_rand(NegBinomial2(), η1[i], 1.0, θ_nb, rng) for i in 1:n]   # size θ
        y2 = [DRM._mf_rand(Gaussian(), η2[i], 1.0, σ2, rng) for i in 1:n]

        fit = DRM.fit_mixed_family(y1 = y1, X1 = X1, fam1 = NegBinomial2(),
                                   y2 = y2, X2 = X2, fam2 = Gaussian())
        @test fit.converged
        @test isapprox(fit.β1, β1; atol = 0.12)
        @test isapprox(fit.β2, β2; atol = 0.12)
        @test isapprox(fit.λ1, λ1; atol = 0.20)
        @test isapprox(fit.λ2, λ2; atol = 0.20)
        @test isapprox(fit.σ2, σ2; atol = 0.10)              # Gaussian residual SD
        # The NB2 size θ is only WEAKLY identified in this pair: the shared latent
        # already injects variance into the count axis, so θ and λ1 are partly
        # confounded (both add count variance). Across seeds θ̂ scatters widely and
        # for some draws drifts toward the Poisson limit (θ→∞). We therefore assert
        # only that θ̂ is finite/positive and that the link-variance mapping holds,
        # not a tight point recovery. β/λ — the structural targets — are robust.
        @test isfinite(fit.σ1) && fit.σ1 > 1.0               # NB2 size θ (weakly identified)
        @test fit.v1 ≈ trigamma(fit.σ1)                      # link-scale variance mapping
        @test fit.rho_latent > 0.0
    end

    @testset "Beta x Binomial recovery (identified)" begin
        rng = MersenneTwister(424242)
        n = 1800
        x = randn(rng, n)
        X1 = hcat(ones(n), x); X2 = hcat(ones(n), x)
        β1 = [0.2, 0.6]; β2 = [-0.1, 0.8]
        λ1 = 0.6; λ2 = 0.7; σ1 = 0.35; ntri = 10.0
        u = randn(rng, n)
        η1 = X1 * β1 .+ λ1 .* u
        η2 = X2 * β2 .+ λ2 .* u
        y1 = [DRM._mf_rand(Beta(), η1[i], 1.0, σ1, rng) for i in 1:n]               # σ → φ=1/σ²
        y2 = [DRM._mf_rand(Binomial(), η2[i], ntri, 1.0, rng) for i in 1:n]
        trials2 = fill(ntri, n)

        fit = DRM.fit_mixed_family(y1 = y1, X1 = X1, fam1 = Beta(),
                                   y2 = y2, X2 = X2, fam2 = Binomial(),
                                   trials2 = trials2)
        @test fit.converged
        @test isapprox(fit.β1, β1; atol = 0.12)
        @test isapprox(fit.β2, β2; atol = 0.15)
        @test isapprox(fit.λ1, λ1; atol = 0.20)
        @test isapprox(fit.λ2, λ2; atol = 0.22)
        @test isapprox(fit.σ1, σ1; atol = 0.08)              # Beta σ (precision φ=1/σ²)
        @test isnan(fit.σ2)                                  # Binomial: dispersionless
        @test fit.v2 ≈ (π^2) / 3                             # Binomial link variance
        @test fit.rho_latent > 0.0
    end

    @testset "Gamma x Poisson recovery (identified)" begin
        rng = MersenneTwister(31415)
        n = 1800
        x = randn(rng, n)
        X1 = hcat(ones(n), x); X2 = hcat(ones(n), x)
        β1 = [0.5, 0.3]; β2 = [0.4, -0.4]
        λ1 = 0.6; λ2 = 0.5; σ1 = 0.4
        u = randn(rng, n)
        η1 = X1 * β1 .+ λ1 .* u
        η2 = X2 * β2 .+ λ2 .* u
        y1 = [DRM._mf_rand(Gamma(), η1[i], 1.0, σ1, rng) for i in 1:n]              # σ → α=1/σ²
        y2 = [DRM._mf_rand(Poisson(), η2[i], 1.0, 1.0, rng) for i in 1:n]

        fit = DRM.fit_mixed_family(y1 = y1, X1 = X1, fam1 = Gamma(),
                                   y2 = y2, X2 = X2, fam2 = Poisson())
        @test fit.converged
        @test isapprox(fit.β1, β1; atol = 0.12)
        @test isapprox(fit.β2, β2; atol = 0.12)
        @test isapprox(fit.λ1, λ1; atol = 0.20)
        @test isapprox(fit.λ2, λ2; atol = 0.20)
        @test isapprox(fit.σ1, σ1; atol = 0.08)              # Gamma σ (shape α=1/σ²)
        @test isnan(fit.σ2)                                  # Poisson: dispersionless
        @test fit.v1 ≈ trigamma(1 / fit.σ1^2)                # Gamma link variance trigamma(α)
        @test fit.rho_latent > 0.0
    end
end
