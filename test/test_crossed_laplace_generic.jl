using Test, Random
import Distributions
using DRM

logistic(x) = 1 / (1 + exp(-x))

function crossed_components(g, h)
    gidx, G = DRM._group_index(g)
    hidx, H = DRM._group_index(h)
    return [
        (ones(length(g)), gidx, G, "g"),
        (ones(length(h)), hidx, H, "h"),
    ]
end

@testset "Generic crossed sparse-Laplace non-Gaussian kernels" begin
    rng = MersenneTwister(70)
    G = 28
    H = 24
    n = 2400
    x = randn(rng, n)
    g = [Symbol("g", rand(rng, 1:G)) for _ in 1:n]
    h = [Symbol("h", rand(rng, 1:H)) for _ in 1:n]
    gmap = Dict(Symbol("g", j) => j for j in 1:G)
    hmap = Dict(Symbol("h", j) => j for j in 1:H)
    X = hcat(ones(n), x)
    comps = crossed_components(g, h)

    β = [0.2, 0.45]
    σg = 0.45
    σh = 0.35
    bg = σg .* randn(rng, G)
    bh = σh .* randn(rng, H)
    η = [β[1] + β[2] * x[i] + bg[gmap[g[i]]] + bh[hmap[h[i]]] for i in 1:n]

    ntr = fill(8.0, n)
    s = Float64.([rand(rng, Distributions.Binomial(round(Int, ntr[i]), logistic(η[i]))) for i in 1:n])
    fit_bin = DRM._fit_binomial_crossed_laplace(DRM.Binomial(), s, ntr, X, comps, ["(Intercept)", "x"], 1e-7)
    sd_bin = re_sd(fit_bin)
    @test fit_bin.converged
    @test abs(coef(fit_bin, :mu)[2] - β[2]) < 0.08
    @test abs(sd_bin[:g] - σg) < 0.12
    @test abs(sd_bin[:h] - σh) < 0.12

    μ = exp.(η)
    size = 3.0
    ynb = Float64.([rand(rng, Distributions.NegativeBinomial(size, size / (size + μ[i]))) for i in 1:n])
    fit_nb = DRM._fit_nb2_fixed_crossed_laplace(DRM.NegBinomial2(), ynb, size, X, comps, ["(Intercept)", "x"], 1e-7)
    sd_nb = re_sd(fit_nb)
    @test fit_nb.converged
    @test abs(coef(fit_nb, :mu)[2] - β[2]) < 0.08
    @test abs(sd_nb[:g] - σg) < 0.12
    @test abs(sd_nb[:h] - σh) < 0.12
    fit_nb_est = DRM._fit_nb2_crossed_laplace(DRM.NegBinomial2(), ynb, X, ones(n, 1), comps, ["(Intercept)", "x"], ["(Intercept)"], 1e-7)
    sd_nb_est = re_sd(fit_nb_est)
    @test fit_nb_est.converged
    @test abs(coef(fit_nb_est, :mu)[2] - β[2]) < 0.08
    @test abs(exp(coef(fit_nb_est, :sigma)[1]) - size) < 0.8
    @test abs(sd_nb_est[:g] - σg) < 0.12
    @test abs(sd_nb_est[:h] - σh) < 0.12

    shape = 7.0
    yg = Float64.([rand(rng, Distributions.Gamma(shape, μ[i] / shape)) for i in 1:n])
    fit_gamma = DRM._fit_gamma_fixed_crossed_laplace(DRM.Gamma(), yg, shape, X, comps, ["(Intercept)", "x"], 1e-7)
    sd_gamma = re_sd(fit_gamma)
    @test fit_gamma.converged
    @test abs(coef(fit_gamma, :mu)[2] - β[2]) < 0.08
    @test abs(sd_gamma[:g] - σg) < 0.12
    @test abs(sd_gamma[:h] - σh) < 0.12
    fit_gamma_est = DRM._fit_gamma_crossed_laplace(DRM.Gamma(), yg, X, ones(n, 1), comps, ["(Intercept)", "x"], ["(Intercept)"], 1e-7)
    sd_gamma_est = re_sd(fit_gamma_est)
    @test fit_gamma_est.converged
    @test abs(coef(fit_gamma_est, :mu)[2] - β[2]) < 0.08
    @test abs(exp(-2 * coef(fit_gamma_est, :sigma)[1]) - shape) < 2.0
    @test abs(sd_gamma_est[:g] - σg) < 0.12
    @test abs(sd_gamma_est[:h] - σh) < 0.12

    φ = 25.0
    p = logistic.(η)
    yb = Float64.([rand(rng, Distributions.Beta(p[i] * φ, (1 - p[i]) * φ)) for i in 1:n])
    fit_beta = DRM._fit_beta_fixed_crossed_laplace(DRM.Beta(), yb, φ, X, comps, ["(Intercept)", "x"], 1e-7)
    sd_beta = re_sd(fit_beta)
    @test fit_beta.converged
    @test abs(coef(fit_beta, :mu)[2] - β[2]) < 0.08
    @test abs(sd_beta[:g] - σg) < 0.12
    @test abs(sd_beta[:h] - σh) < 0.12
    fit_beta_est = DRM._fit_beta_crossed_laplace(DRM.Beta(), yb, X, ones(n, 1), comps, ["(Intercept)", "x"], ["(Intercept)"], 1e-7)
    sd_beta_est = re_sd(fit_beta_est)
    @test fit_beta_est.converged
    @test abs(coef(fit_beta_est, :mu)[2] - β[2]) < 0.08
    @test abs(exp(-2 * coef(fit_beta_est, :sigma)[1]) - φ) < 7.0
    @test abs(sd_beta_est[:g] - σg) < 0.12
    @test abs(sd_beta_est[:h] - σh) < 0.12
end

@testset "Crossed sparse-Laplace public routing smoke" begin
    rng = MersenneTwister(71)
    G = 14
    H = 12
    n = 900
    x = randn(rng, n)
    g = [Symbol("g", rand(rng, 1:G)) for _ in 1:n]
    h = [Symbol("h", rand(rng, 1:H)) for _ in 1:n]
    gmap = Dict(Symbol("g", j) => j for j in 1:G)
    hmap = Dict(Symbol("h", j) => j for j in 1:H)
    β = [0.2, 0.45]
    bg = 0.35 .* randn(rng, G)
    bh = 0.25 .* randn(rng, H)
    η = [β[1] + β[2] * x[i] + bg[gmap[g[i]]] + bh[hmap[h[i]]] for i in 1:n]

    ntr = fill(8.0, n)
    s = Float64.([rand(rng, Distributions.Binomial(round(Int, ntr[i]), logistic(η[i]))) for i in 1:n])
    fail = ntr .- s
    fit_bin = drm(bf(@formula(cbind(s, fail) ~ x + (1 | g) + (1 | h))), Binomial();
                  data = (; s, fail, x, g, h))
    @test fit_bin.converged
    @test haskey(re_sd(fit_bin), :g)
    @test haskey(re_sd(fit_bin), :h)

    μ = exp.(η)
    ynb = Float64.([rand(rng, Distributions.NegativeBinomial(3.0, 3.0 / (3.0 + μ[i]))) for i in 1:n])
    fit_nb = drm(bf(@formula(ynb ~ x + (1 | g) + (1 | h)), @formula(sigma ~ 1)),
                 NegBinomial2(); data = (; ynb, x, g, h))
    @test fit_nb.converged
    @test haskey(re_sd(fit_nb), :g)
    @test haskey(re_sd(fit_nb), :h)
end
