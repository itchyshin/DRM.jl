# Random effect on the SCALE parameter: sigma ~ 1 + (1 | g). Group-level
# deviations on log σ. Unlike a mean random effect this has no closed-form
# marginal (b enters σ nonlinearly), so the random effect is integrated out per
# group by Gauss–Hermite quadrature (drmTMB uses Laplace; for a 1-D effect AGHQ
# is the standard, more accurate sibling). Recovery: mean coefficients, the σ
# intercept (which absorbs the realized mean of b at finite G), and σ_b.
using DRM
using Test, Random

@testset "Gaussian random effect on sigma: sigma ~ 1 + (1|g) — recovery" begin
    Random.seed!(20260613)
    G = 40; m = 25; n = G * m
    g = repeat(1:G, inner = m); x = randn(n)
    β = [0.5, -0.3]; γ0 = log(0.5); σb = 0.5
    bg = σb .* randn(G)
    y = β[1] .+ β[2] .* x .+ exp.(γ0 .+ bg[g]) .* randn(n)
    data = (; y, x, g)

    fit = drm(bf(@formula(y ~ x), @formula(sigma ~ 1 + (1 | g))), Gaussian(); data = data)

    @test coef(fit, :mu)[1] ≈ β[1] atol = 0.06
    @test coef(fit, :mu)[2] ≈ β[2] atol = 0.06
    # σ intercept on log scale absorbs the realized mean of b (finite G)
    @test exp(coef(fit, :sigma)[1]) ≈ exp(γ0 + sum(bg) / G) atol = 0.08
    @test re_sd(fit)[:g] ≈ σb atol = 0.15          # scale-RE SD
    @test isfinite(loglik(fit))
end
