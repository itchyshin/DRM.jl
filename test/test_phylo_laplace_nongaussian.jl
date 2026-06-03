using DRM
using Test, Random, LinearAlgebra
import Distributions

function _nongaussian_phylo_fixture(; seed = 20260603, G = 6, n_each = 10)
    Random.seed!(seed)
    n = G * n_each
    tree = random_balanced_tree(G; branch_length = 0.1)
    C = sigma_phy_dense(tree; σ²_phy = 1.0)
    d = sqrt.(diag(C))
    K = Matrix(Symmetric(C ./ (d * d') + 1e-8I))
    u = cholesky(Symmetric(K)).L * (0.35 .* randn(G))
    gidx = repeat(1:G, inner = n_each)
    x = randn(n)
    X = hcat(ones(n), x)
    Xσ = ones(n, 1)
    η = 0.10 .+ 0.45 .* x .+ u[gidx]
    μ = exp.(η)
    p = 1 ./ (1 .+ exp.(-η))
    y_gamma = [rand(Distributions.Gamma(7.0, μ[i] / 7.0)) for i in 1:n]
    y_nb = [rand(Distributions.NegativeBinomial(3.0, 3.0 / (3.0 + μ[i]))) for i in 1:n]
    y_beta = [rand(Distributions.Beta(p[i] * 25.0, (1 - p[i]) * 25.0)) for i in 1:n]
    s = [rand(Distributions.Binomial(8, p[i])) for i in 1:n]
    fail = fill(8, n) .- s
    species = repeat(1:G, inner = n_each)
    return (; tree, K, gidx, G, X, Xσ, x, species, y_gamma, y_nb, y_beta, s,
            fail, ntr = fill(8, n))
end

function _central_gradient(f, θ; h = 1e-5)
    g = similar(θ)
    for i in eachindex(θ)
        step = zeros(length(θ))
        step[i] = h
        g[i] = (f(θ .+ step) - f(θ .- step)) / (2h)
    end
    return g
end

@testset "non-Gaussian phylo sparse-Laplace internals" begin
    d = _nongaussian_phylo_fixture()
    nmμ = ["(Intercept)", "x"]
    nmσ = ["(Intercept)"]
    label = "phylo(1 | species)"

    fits = [
        DRM._fit_binomial_phylo_laplace(
            DRM.Binomial(), d.s, d.ntr, d.X, d.gidx, d.G, d.K, nmμ, label, 1e-7
        ),
        DRM._fit_nb2_phylo_laplace(
            DRM.NegBinomial2(), d.y_nb, d.X, d.Xσ, d.gidx, d.G, d.K, nmμ, nmσ, label, 1e-7
        ),
        DRM._fit_gamma_phylo_laplace(
            DRM.Gamma(), d.y_gamma, d.X, d.Xσ, d.gidx, d.G, d.K, nmμ, nmσ, label, 1e-7
        ),
        DRM._fit_beta_phylo_laplace(
            DRM.Beta(), d.y_beta, d.X, d.Xσ, d.gidx, d.G, d.K, nmμ, nmσ, label, 1e-7
        ),
    ]

    @test all(fit -> fit.converged, fits)
    @test all(fit -> isfinite(DRM.loglik(fit)), fits)
    @test all(fit -> all(isfinite, DRM.coef(fit)), fits)
    @test all(fit -> first(Dict(fit.coefnames)[:resd]) == label, fits)

    beta_fit = fits[end]
    θ = DRM.coef(beta_fit)
    g = zeros(length(θ))
    beta_fit.nllgrad(g, θ)
    g_fd = _central_gradient(beta_fit.nll, θ)
    @test maximum(abs.(g .- g_fd)) < 1e-5
end

@testset "non-Gaussian phylo public formula routing" begin
    d = _nongaussian_phylo_fixture()
    data = (;
        y_nb = d.y_nb,
        y_gamma = d.y_gamma,
        y_beta = d.y_beta,
        s = d.s,
        fail = d.fail,
        x = d.x,
        species = d.species,
    )
    label = Symbol("phylo(1 | species)")

    fits = [
        drm(bf(@formula(y_nb ~ x + phylo(1 | species)), @formula(sigma ~ 1)),
            NegBinomial2(); data, tree = d.tree, g_tol = 1e-7),
        drm(bf(@formula(y_gamma ~ x + phylo(1 | species)), @formula(sigma ~ 1)),
            Gamma(); data, tree = d.tree, g_tol = 1e-7),
        drm(bf(@formula(y_beta ~ x + phylo(1 | species)), @formula(sigma ~ 1)),
            Beta(); data, tree = d.tree, g_tol = 1e-7),
        drm(bf(@formula(cbind(s, fail) ~ x + phylo(1 | species))),
            Binomial(); data, tree = d.tree, g_tol = 1e-7),
    ]

    @test all(fit -> fit.converged, fits)
    @test all(fit -> isfinite(loglik(fit)), fits)
    @test all(fit -> haskey(re_sd(fit), label), fits)
    @test all(fit -> isfinite(re_sd(fit)[label]) && re_sd(fit)[label] > 0, fits)

    @test_throws ErrorException drm(
        bf(@formula(y_gamma ~ x + phylo(1 | species)), @formula(sigma ~ 1)),
        Gamma(); data, g_tol = 1e-7
    )
    @test_throws ErrorException drm(
        bf(@formula(y_gamma ~ x + phylo(1 + x | species)), @formula(sigma ~ 1)),
        Gamma(); data, tree = d.tree, g_tol = 1e-7
    )
    @test_throws ErrorException drm(
        bf(@formula(y_gamma ~ x), @formula(sigma ~ 1 + phylo(1 | species))),
        Gamma(); data, tree = d.tree, g_tol = 1e-7
    )
end
