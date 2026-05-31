# Negative-binomial (NB2) family: overdispersed counts. Log link on the mean μ
# and on the dispersion/size θ (carried in the `sigma` slot). Var = μ + μ²/θ; as
# θ → ∞ it tends to Poisson. Fixed effects, ML. Mirrors drmTMB's `nbinom2`.
using DRM
using Test, Random
import Distributions          # qualified — DRM has its own family type

@testset "Negative binomial (NB2, overdispersed counts) — recovery" begin
    Random.seed!(20260616)
    n = 4000
    x = randn(n)
    β = [0.4, 0.5]; θ = 2.5                      # log μ = 0.4 + 0.5 x; dispersion θ
    μ = exp.(β[1] .+ β[2] .* x)
    y = Float64.([rand(Distributions.NegativeBinomial(θ, θ / (θ + μi))) for μi in μ])
    data = (; y, x)

    fit = drm(bf(@formula(y ~ x), @formula(sigma ~ 1)), NegBinomial2(); data = data)

    @test coef(fit, :mu)[1] ≈ β[1] atol = 0.08    # log-mean intercept
    @test coef(fit, :mu)[2] ≈ β[2] atol = 0.08    # log-mean slope
    @test exp(coef(fit, :sigma)[1]) ≈ θ atol = 0.8  # dispersion (size) — weakly identified
    @test isfinite(loglik(fit))
    @test all(fitted(fit) .> 0)
end
