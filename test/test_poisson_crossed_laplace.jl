# Sparse-Laplace proving slice for crossed non-Gaussian random effects:
# Poisson y ~ x + (1|g) + (1|h). This is an engine-lane test and deliberately
# calls the internal fitter directly; the public formula routing is Claude-owned.
using DRM
using Test, Random
import Distributions

@testset "Poisson crossed random intercepts — sparse Laplace recovery" begin
    Random.seed!(20260706)
    G = 20; H = 18; n = 900
    g = rand(1:G, n); h = rand(1:H, n); x = randn(n)
    β = [0.25, 0.45]; σg = 0.45; σh = 0.35
    bg = σg .* randn(G); bh = σh .* randn(H)
    λ = exp.(β[1] .+ β[2] .* x .+ bg[g] .+ bh[h])
    y = Float64.([rand(Distributions.Poisson(λi)) for λi in λ])
    X = hcat(ones(n), x)
    gidx, Gfit = DRM._group_index(g)
    hidx, Hfit = DRM._group_index(h)
    comps = [(ones(n), gidx, Gfit, "g"), (ones(n), hidx, Hfit, "h")]

    fit = DRM._fit_poisson_crossed_laplace(DRM.Poisson(), y, X, comps, ["(Intercept)", "x"], 1e-7)

    @test coef(fit, :mu)[2] ≈ β[2] atol = 0.12
    rs = re_sd(fit)
    @test rs[:g] ≈ σg atol = 0.20
    @test rs[:h] ≈ σh atol = 0.20
    @test isfinite(loglik(fit))
    @test all(fitted(fit) .> 0)
end

@testset "Poisson single-factor Laplace gate uses GHQ path" begin
    Random.seed!(20260707)
    G = 16; m = 25; n = G * m
    g = repeat(1:G, inner = m); x = randn(n)
    β = [0.2, 0.35]; σb = 0.5
    bg = σb .* randn(G)
    λ = exp.(β[1] .+ β[2] .* x .+ bg[g])
    y = Float64.([rand(Distributions.Poisson(λi)) for λi in λ])
    X = hcat(ones(n), x)
    gidx, Gfit = DRM._group_index(g)
    comps = [(ones(n), gidx, Gfit, "g")]

    fit_laplace_gate = DRM._fit_poisson_crossed_laplace(DRM.Poisson(), y, X, comps, ["(Intercept)", "x"], 1e-8)
    fit_ghq = DRM._fit_poisson_ranef(DRM.Poisson(), y, X, gidx, Gfit, ["(Intercept)", "x"], :g, 1e-8)

    @test coef(fit_laplace_gate) ≈ coef(fit_ghq) atol = 1e-10
    @test loglik(fit_laplace_gate) ≈ loglik(fit_ghq) atol = 1e-10
end

@testset "Poisson crossed intercepts via drm() routing" begin
    Random.seed!(20260708)
    G = 20; H = 16; n = 800
    g = rand(1:G, n); h = rand(1:H, n); x = randn(n)
    β = [0.3, 0.4]; σg = 0.5; σh = 0.4
    bg = σg .* randn(G); bh = σh .* randn(H)
    λ = exp.(β[1] .+ β[2] .* x .+ bg[g] .+ bh[h])
    y = Float64.([rand(Distributions.Poisson(λi)) for λi in λ])
    dat = (; y, x, g, h)
    fit = drm(bf(@formula(y ~ x + (1 | g) + (1 | h))), Poisson(); data = dat)
    @test coef(fit, :mu)[2] ≈ β[2] atol = 0.12
    rs = re_sd(fit)
    @test rs[:g] ≈ σg atol = 0.20
    @test rs[:h] ≈ σh atol = 0.20
    @test isfinite(loglik(fit))
end
