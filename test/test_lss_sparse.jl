# test/test_lss_sparse.jl
# Issue #551: O(p) sparse exact marginal LSS engine verification
# Compares sparse LSS against dense LSS comparator on:
# - log-likelihood (ML and REML)
# - parameter estimates θ̂ (tolerance ≤ 1e-5)
# - standard errors (tolerance ≤ 1e-5)
# - scalar and multi-column α linear predictors
# - BLUPs

using Test
using DRM
using StableRNGs
using LinearAlgebra
using SparseArrays
using Random

function _make_balanced_newick(d)
    function node(prefix, depth)
        depth == 0 && return "$(prefix):$(1/d)"
        l = node(prefix * "a", depth - 1); r = node(prefix * "b", depth - 1)
        return depth == d ? "($l,$r);" : "($l,$r):$(1/d)"
    end
    node("t", d)
end

function _simulate_lss_phylo(; depth = 5, n_per_group = 2, multi_cov = false, seed = 42)
    phy = DRM.augmented_phy(_make_balanced_newick(depth))
    G = phy.n_leaves
    K0 = DRM.sigma_phy_dense(phy; σ²_phy = 1.0)
    dK = sqrt.(diag(K0)); K = K0 ./ (dK * dK')
    rng = StableRNG(seed)

    sp_names = String.(phy.leaf_names)
    n = G * n_per_group
    gidx = repeat(1:G, inner = n_per_group)
    species = sp_names[gidx]

    # Covariates
    x1 = randn(rng, n)
    x2 = randn(rng, n)

    # Group-level covariates for sd_phylo
    z1_g = randn(rng, G)
    z2_g = randn(rng, G)
    z1 = z1_g[gidx]
    z2 = z2_g[gidx]

    if multi_cov
        sda = exp.(-0.5 .+ 0.3 .* z1_g .- 0.2 .* z2_g)
        sde = exp.(-1.0 .- 0.25 .* x1 .+ 0.2 .* x2)
        βμ = [1.5, 0.6, -0.4]
        Xμ = [ones(n) x1 x2]
    else
        sda = exp.(-0.4 .+ 0.35 .* z1_g)
        sde = exp.(-1.1 .- 0.3 .* x1)
        βμ = [1.2, 0.5]
        Xμ = [ones(n) x1]
    end

    chK = cholesky(Symmetric(K))
    u_phylo = chK.L * randn(rng, G)
    a = sda .* u_phylo
    y = Xμ * βμ + a[gidx] + sde .* randn(rng, n)

    dat = (y = y, x1 = x1, x2 = x2, z1 = z1, z2 = z2, species = species)
    return phy, dat, K
end

@testset "Sparse LSS vs Dense Comparator: Scalar α (Single Predictor)" begin
    phy, dat, K = _simulate_lss_phylo(depth = 3, n_per_group = 2, multi_cov = false, seed = 123)
    f = bf(@formula(y ~ x1 + phylo(1 | species)),
           @formula(sigma ~ x1),
           @formula(sd(species, phylogenetic) ~ z1))

    # ML fit
    fit_dense_ml = drm(f, Gaussian(); data = dat, tree = phy, algorithm = :lbfgs, method = :ML, g_tol = 1e-8)
    fit_sparse_ml = drm(f, Gaussian(); data = dat, tree = phy, algorithm = :sparse, method = :ML, g_tol = 1e-8)

    @test fit_dense_ml.converged
    @test fit_sparse_ml.converged

    # Log-likelihood agreement (tol ≤ 1e-5)
    @test isapprox(loglik(fit_sparse_ml), loglik(fit_dense_ml); atol = 1e-5)

    # Parameter estimates agreement (tol ≤ 1e-5)
    @test isapprox(coef(fit_sparse_ml, :mu), coef(fit_dense_ml, :mu); atol = 1e-5)
    @test isapprox(coef(fit_sparse_ml, :sigma), coef(fit_dense_ml, :sigma); atol = 1e-5)
    @test isapprox(coef(fit_sparse_ml, :sd_phylo), coef(fit_dense_ml, :sd_phylo); atol = 1e-5)

    # Standard errors agreement (tol ≤ 1e-5)
    se_dense_ml = stderror(fit_dense_ml)
    se_sparse_ml = stderror(fit_sparse_ml)
    @test isapprox(se_sparse_ml, se_dense_ml; atol = 1e-4)

    # BLUP random effects agreement
    re_dense = ranef(fit_dense_ml)[:species]
    re_sparse = ranef(fit_sparse_ml)[:species]
    @test isapprox(re_sparse, re_dense; atol = 1e-5)

    # REML fit
    fit_dense_reml = drm(f, Gaussian(); data = dat, tree = phy, algorithm = :lbfgs, method = :REML, g_tol = 1e-8)
    fit_sparse_reml = drm(f, Gaussian(); data = dat, tree = phy, algorithm = :sparse, method = :REML, g_tol = 1e-8)

    @test fit_dense_reml.converged
    @test fit_sparse_reml.converged
    @test estimation_method(fit_sparse_reml) === :REML

    # REML log-likelihood agreement
    @test isapprox(reml_loglik(fit_sparse_reml), reml_loglik(fit_dense_reml); atol = 1e-5)
    @test isapprox(ml_loglik(fit_sparse_reml), ml_loglik(fit_dense_reml); atol = 1e-5)

    # REML parameter estimates agreement
    @test isapprox(coef(fit_sparse_reml, :mu), coef(fit_dense_reml, :mu); atol = 1e-5)
    @test isapprox(coef(fit_sparse_reml, :sigma), coef(fit_dense_reml, :sigma); atol = 1e-5)
    @test isapprox(coef(fit_sparse_reml, :sd_phylo), coef(fit_dense_reml, :sd_phylo); atol = 1e-5)

    # REML standard errors agreement
    se_dense_reml = stderror(fit_dense_reml)
    se_sparse_reml = stderror(fit_sparse_reml)
    @test isapprox(se_sparse_reml, se_dense_reml; atol = 1e-4)
end

@testset "Sparse LSS vs Dense Comparator: Multi-column α (Multiple Predictors)" begin
    phy, dat, K = _simulate_lss_phylo(depth = 3, n_per_group = 3, multi_cov = true, seed = 456)
    f = bf(@formula(y ~ x1 + x2 + phylo(1 | species)),
           @formula(sigma ~ x1 + x2),
           @formula(sd(species, phylogenetic) ~ z1 + z2))

    # ML fit
    fit_dense_ml = drm(f, Gaussian(); data = dat, tree = phy, algorithm = :lbfgs, method = :ML, g_tol = 1e-8)
    fit_sparse_ml = drm(f, Gaussian(); data = dat, tree = phy, algorithm = :sparse, method = :ML, g_tol = 1e-8)

    @test fit_dense_ml.converged
    @test fit_sparse_ml.converged

    # Log-likelihood agreement
    @test isapprox(loglik(fit_sparse_ml), loglik(fit_dense_ml); atol = 1e-5)

    # Parameter estimates agreement
    @test isapprox(coef(fit_sparse_ml, :mu), coef(fit_dense_ml, :mu); atol = 1e-5)
    @test isapprox(coef(fit_sparse_ml, :sigma), coef(fit_dense_ml, :sigma); atol = 1e-5)
    @test isapprox(coef(fit_sparse_ml, :sd_phylo), coef(fit_dense_ml, :sd_phylo); atol = 1e-5)

    # REML fit
    fit_dense_reml = drm(f, Gaussian(); data = dat, tree = phy, algorithm = :lbfgs, method = :REML, g_tol = 1e-8)
    fit_sparse_reml = drm(f, Gaussian(); data = dat, tree = phy, algorithm = :sparse, method = :REML, g_tol = 1e-8)

    @test fit_dense_reml.converged
    @test fit_sparse_reml.converged

    @test isapprox(reml_loglik(fit_sparse_reml), reml_loglik(fit_dense_reml); atol = 1e-5)
    @test isapprox(coef(fit_sparse_reml, :mu), coef(fit_dense_reml, :mu); atol = 1e-5)
    @test isapprox(coef(fit_sparse_reml, :sigma), coef(fit_dense_reml, :sigma); atol = 1e-5)
    @test isapprox(coef(fit_sparse_reml, :sd_phylo), coef(fit_dense_reml, :sd_phylo); atol = 1e-5)
end

@testset "Sparse LSS: Routing and sparse = true keyword" begin
    phy, dat, _ = _simulate_lss_phylo(depth = 3, n_per_group = 2, multi_cov = false, seed = 789)
    f = bf(@formula(y ~ x1 + phylo(1 | species)),
           @formula(sigma ~ x1),
           @formula(sd(species, phylogenetic) ~ z1))

    # sparse = true flag
    fit_flag = drm(f, Gaussian(); data = dat, tree = phy, sparse = true, g_tol = 1e-8)
    # algorithm = :sparse_lbfgs
    fit_alg = drm(f, Gaussian(); data = dat, tree = phy, algorithm = :sparse_lbfgs, g_tol = 1e-8)

    @test fit_flag.converged
    @test fit_alg.converged
    @test isapprox(loglik(fit_flag), loglik(fit_alg); atol = 1e-10)
    @test isapprox(fit_flag.theta, fit_alg.theta; atol = 1e-8)
end

@testset "Sparse LSS: Large tree scaling sanity" begin
    # Test on a 64-species tree (depth = 6)
    phy, dat, _ = _simulate_lss_phylo(depth = 6, n_per_group = 2, multi_cov = false, seed = 101)
    f = bf(@formula(y ~ x1 + phylo(1 | species)),
           @formula(sigma ~ x1),
           @formula(sd(species, phylogenetic) ~ z1))

    fit_sparse = drm(f, Gaussian(); data = dat, tree = phy, sparse = true, g_tol = 1e-8)
    @test fit_sparse.converged
    @test isfinite(loglik(fit_sparse))
    @test length(coef(fit_sparse, :mu)) == 2
    @test length(coef(fit_sparse, :sigma)) == 2
    @test length(coef(fit_sparse, :sd_phylo)) == 2
end
