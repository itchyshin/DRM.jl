# Skew-normal family: location–scale–shape regression with an asymmetric
# Gaussian. A formula per parameter — μ (mean, identity), σ (SD, log link), ν
# (slant α, identity). The public parameterisation is the moment form (μ = mean,
# σ = SD); data are simulated from a skew-normal with a known mean/SD/slant and
# the fit recovers all three. Fixed effects, maximum likelihood. Mirrors drmTMB's
# `skew_normal`.
using DRM
using Test, Random, Statistics
using Distributions: SkewNormal as DSkewNormal

# Map the public moment params (mean μ, SD σ, slant α) to Azzalini's internal
# (ξ, ω, α), so we can draw from Distributions.SkewNormal(ξ, ω, α) and know the
# true mean/SD exactly.
function _moment_to_internal(μ, σ, α)
    δ = α / sqrt(1 + α^2)
    ω = σ / sqrt(1 - 2 * δ^2 / π)
    ξ = μ - ω * δ * sqrt(2 / π)
    return ξ, ω
end

@testset "Skew-normal location–scale–shape — recovery" begin
    Random.seed!(20260610)
    n = 800
    x = randn(n)
    β = [1.0, -0.6]; σ = 1.2; α = 4.0          # mean intercept/slope, SD, slant
    μ = β[1] .+ β[2] .* x                       # per-observation mean
    y = similar(μ)
    for i in 1:n
        ξ, ω = _moment_to_internal(μ[i], σ, α)
        y[i] = rand(DSkewNormal(ξ, ω, α))       # mean = μ[i], SD = σ, slant = α
    end
    data = (; y, x)

    fit = drm(bf(@formula(y ~ x), @formula(sigma ~ 1), @formula(nu ~ 1)), SkewNormal(); data = data)

    @test is_converged(fit)
    @test coef(fit, :mu)[1] ≈ β[1] atol = 0.12        # mean intercept
    @test coef(fit, :mu)[2] ≈ β[2] atol = 0.10        # mean slope
    @test exp(coef(fit, :sigma)[1]) ≈ σ atol = 0.15   # SD
    @test coef(fit, :nu)[1] ≈ α atol = 2.0            # slant (weakly identified — loose)
    @test sign(coef(fit, :nu)[1]) == sign(α)          # at least gets the skew direction right
    @test isfinite(loglik(fit))
end
