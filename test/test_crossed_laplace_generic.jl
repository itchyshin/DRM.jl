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

    shape = 7.0
    yg = Float64.([rand(rng, Distributions.Gamma(shape, μ[i] / shape)) for i in 1:n])
    fit_gamma = DRM._fit_gamma_fixed_crossed_laplace(DRM.Gamma(), yg, shape, X, comps, ["(Intercept)", "x"], 1e-7)
    sd_gamma = re_sd(fit_gamma)
    @test fit_gamma.converged
    @test abs(coef(fit_gamma, :mu)[2] - β[2]) < 0.08
    @test abs(sd_gamma[:g] - σg) < 0.12
    @test abs(sd_gamma[:h] - σh) < 0.12

    φ = 25.0
    p = logistic.(η)
    yb = Float64.([rand(rng, Distributions.Beta(p[i] * φ, (1 - p[i]) * φ)) for i in 1:n])
    fit_beta = DRM._fit_beta_fixed_crossed_laplace(DRM.Beta(), yb, φ, X, comps, ["(Intercept)", "x"], 1e-7)
    sd_beta = re_sd(fit_beta)
    @test fit_beta.converged
    @test abs(coef(fit_beta, :mu)[2] - β[2]) < 0.08
    @test abs(sd_beta[:g] - σg) < 0.12
    @test abs(sd_beta[:h] - σh) < 0.12
end
