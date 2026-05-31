# Profile-likelihood confidence intervals: confint(fit; method = :profile).
# Mirrors drmTMB's confint(fit, method = "profile"). For each parameter the
# interval endpoints are the values where 2(ℓ̂ − ℓ_profile) = χ²₁(level), with
# the nuisance parameters re-optimised at each fixed value. For a Gaussian mean
# coefficient the log-likelihood is near-quadratic, so the profile interval
# closely matches the Wald interval — that is the cross-check here.
using DRM
using Test, Random

@testset "Profile-likelihood CI: confint(fit; method=:profile)" begin
    Random.seed!(20260612)
    n = 500
    x = randn(n); z = randn(n)
    β = [0.4, 0.8, -0.5]; σ = 0.5
    y = β[1] .+ β[2] .* x .+ β[3] .* z .+ σ .* randn(n)
    data = (; y, x, z)
    fit = drm(bf(@formula(y ~ x + z), @formula(sigma ~ 1)), Gaussian(); data = data)

    wald = confint(fit; method = :wald)
    prof = confint(fit; method = :profile)

    @test length(prof) == length(wald)
    @test [r.param for r in prof] == [r.param for r in wald]   # same rows / order
    @test [r.coef for r in prof] == [r.coef for r in wald]
    @test all(r.estimate ≈ w.estimate for (r, w) in zip(prof, wald))

    @test all(r.lower < r.estimate < r.upper for r in prof)    # every CI brackets est

    # mean coefficients: near-quadratic likelihood ⇒ profile ≈ Wald
    for (r, w) in zip(prof, wald)
        r.param === :mu || continue
        @test r.lower ≈ w.lower atol = 0.03
        @test r.upper ≈ w.upper atol = 0.03
    end

    @test confint(fit) == wald                                 # default stays Wald
end
