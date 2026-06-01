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

# The fast endpoint finder (warm-start continuation + guarded-Newton using the
# envelope-theorem slope) must stay correct on an ASYMMETRIC profile — the scale
# parameter, where the log-σ likelihood is not symmetric, so bisection-vs-Newton
# and the bracket guard are genuinely exercised (the mean case above is near
# quadratic). Endpoints must be finite, bracket the estimate, and (since the LR
# and Wald agree to first order) sit within a sane neighbourhood of the Wald CI.
@testset "Profile CI on the scale parameter (asymmetric)" begin
    Random.seed!(20260601)
    n = 400
    x = randn(n)
    y = 0.5 .+ 0.7 .* x .+ exp.(0.2 .* x) .* randn(n)     # heteroscedastic → σ ~ x
    data = (; y, x)
    fit = drm(bf(@formula(y ~ x), @formula(sigma ~ x)), Gaussian(); data = data)

    prof = confint(fit; method = :profile)
    wald = confint(fit; method = :wald)
    @test [r.param for r in prof] == [r.param for r in wald]
    @test all(isfinite(r.lower) && isfinite(r.upper) for r in prof)
    @test all(r.lower < r.estimate < r.upper for r in prof)

    # profile endpoints should land near Wald (same first-order curvature), but
    # need not be symmetric — a loose neighbourhood check, not equality.
    for (r, w) in zip(prof, wald)
        @test r.lower ≈ w.lower atol = 0.15
        @test r.upper ≈ w.upper atol = 0.15
    end
end
