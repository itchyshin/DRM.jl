# Conjugate-EM solver wired as an opt-in `algorithm = :em` (issue #12).
#
# The EM path fits the Gaussian phylogenetic-MEAN cell — a single phylo(1 | g)
# structured mean random effect with a constant residual scale — by closed-form
# E/M steps with exact O(p) Takahashi traces. It is the SAME MLE as the default
# GLS/LBFGS structured-Gaussian fit, so the correctness anchor is: same μ
# coefficients, same residual σ, and same marginal logLik (rtol ~1e-3).
using DRM
using Test, Random, LinearAlgebra

@testset "conjugate EM (#12): :em matches the default phylo-mean fit" begin
    Random.seed!(20260607)
    # A power-of-two leaf count makes `random_balanced_tree` perfectly balanced
    # (no leftover odd node carried up), so every leaf is the SAME depth from the
    # root. Then the Brownian leaf covariance C has a constant diagonal, i.e.
    # C = c·Kc with Kc the correlation. The default GLS fitter parametrizes the
    # phylo effect as σ_s²·Kc while the EM uses σ²_phy·C; with a constant diagonal
    # these are the SAME marginal model (σ_s² = c·σ²_phy), so β, residual σ, and
    # logLik coincide — the correctness anchor. (On an unbalanced tree the two
    # marginals genuinely differ and only logLik/σ stay close, not β.)
    G = 64
    phy = random_balanced_tree(G; branch_length = 0.3)
    C = sigma_phy_dense(phy; σ²_phy = 1.0)            # phylo covariance over leaves
    d = sqrt.(diag(C)); Kc = C ./ (d * d')            # correlation
    m = 4; n = G * m
    species = repeat(1:G, inner = m)
    x = randn(n)
    β = [0.2, 0.5]; σ = 0.4; σs = 0.9
    u = σs .* (cholesky(Symmetric(Kc)).L * randn(G))
    y = β[1] .+ β[2] .* x .+ u[species] .+ σ .* randn(n)
    data = (; y, x, species)

    form = bf(@formula(y ~ x + phylo(1 | species)), @formula(sigma ~ 1))
    fit_def = drm(form, Gaussian(); data = data, tree = phy)                       # :auto
    fit_em  = drm(form, Gaussian(); data = data, tree = phy, algorithm = :em)

    # (a) correctness anchor — same MLE on β, residual σ, and logLik.
    @test coef(fit_em, :mu) ≈ coef(fit_def, :mu) rtol = 1e-3
    @test exp(coef(fit_em, :sigma)[1]) ≈ exp(coef(fit_def, :sigma)[1]) rtol = 1e-3
    @test loglik(fit_em) ≈ loglik(fit_def) rtol = 1e-3
    @test fit_em.converged

    # (c) accessors / summary run on the EM fit.
    @test nobs(fit_em) == n
    @test length(coef(fit_em)) == length(coef(fit_def))
    @test isfinite(loglik(fit_em))
    @test haskey(re_sd(fit_em), :species)              # EM reports its Brownian phylo SD
    @test re_sd(fit_em)[:species] > 0
    @test fitted(fit_em) ≈ fitted(fit_def) rtol = 1e-3
    @test length(sigma(fit_em)) == n
    # EM yields no coefficient vcov → NaNs (documented).
    @test all(isnan, vcov(fit_em))
    @test sprint(show, fit_em) isa String              # show() runs
end

@testset "conjugate EM (#12): :em rejects unsupported cells" begin
    Random.seed!(99)
    G = 24
    phy = random_balanced_tree(G; branch_length = 0.3)
    m = 4; n = G * m
    species = repeat(1:G, inner = m)
    x = randn(n)
    y = 0.2 .+ 0.5 .* x .+ 0.4 .* randn(n)
    data = (; y, x, species)

    # (b) non-constant sigma is unsupported.
    @test_throws ArgumentError drm(
        bf(@formula(y ~ x + phylo(1 | species)), @formula(sigma ~ x)),
        Gaussian(); data = data, tree = phy, algorithm = :em)

    # No structured mean RE at all is unsupported.
    @test_throws ArgumentError drm(
        bf(@formula(y ~ x), @formula(sigma ~ 1)),
        Gaussian(); data = data, algorithm = :em)

    # A plain (non-phylo) random intercept is unsupported.
    @test_throws ArgumentError drm(
        bf(@formula(y ~ x + (1 | species)), @formula(sigma ~ 1)),
        Gaussian(); data = data, algorithm = :em)

    # An unknown algorithm symbol is rejected up front.
    @test_throws ArgumentError drm(
        bf(@formula(y ~ x), @formula(sigma ~ 1)),
        Gaussian(); data = data, algorithm = :nope)
end
