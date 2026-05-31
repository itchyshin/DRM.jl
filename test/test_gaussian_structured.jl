# Gaussian structured random effect with a KNOWN relatedness matrix K:
# relmat(1 | id) with `K` supplied. A structured random intercept u ~ N(0, σ_s² K)
# keeps the marginal exactly Gaussian — y ~ N(Xβ, D + σ_s² Z K Zᵀ) — fit in
# closed form (PGLS-style). This is the engine that animal()/phylo() reuse.
using DRM
using Test, Random, LinearAlgebra

@testset "Gaussian structured RE: relmat(1|id, K) — recovery" begin
    Random.seed!(20260605)
    G = 70
    # a random correlation matrix K over the G levels
    A = let M = randn(G, G); M * M' / G + I end
    d = sqrt.(diag(A)); K = A ./ (d * d')
    m = 6; n = G * m
    id = repeat(1:G, inner = m)
    x = randn(n)
    β = [0.3, 0.5]; σ = 0.4; σs = 0.8
    u = σs .* (cholesky(Symmetric(K)).L * randn(G))     # u ~ N(0, σ_s² K)
    y = β[1] .+ β[2] .* x .+ u[id] .+ σ .* randn(n)
    data = (; y, x, id)

    fit = drm(bf(@formula(y ~ x + relmat(1 | id)), @formula(sigma ~ 1)), Gaussian(); data = data, K = K)

    @test coef(fit, :mu)[2] ≈ β[2] atol = 0.1           # slope (x independent of the structured RE)
    @test exp(coef(fit, :sigma)[1]) ≈ σ atol = 0.12     # residual SD
    @test re_sd(fit)[:id] ≈ σs atol = 0.25              # structured RE SD
    @test isfinite(loglik(fit))
end
