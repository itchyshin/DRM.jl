using DRM
using Test, LinearAlgebra, Random, SparseArrays, Statistics

const _Q4_TEST_BETA = (
    mu1 = [1.0, 0.5],
    mu2 = [-0.3, 0.4],
    s1 = [-0.4],
    s2 = [-0.5],
    rho = [0.3],
)

const _Q4_TEST_SIGMA_A = Matrix(Symmetric([
    0.25 0.10 0.05 0.00
    0.10 0.25 0.00 0.04
    0.05 0.00 0.09 0.02
    0.00 0.04 0.02 0.09
]))

function _q4_frontend_data(; p::Int = 10, nrep::Int = 3, seed::Int = 187)
    rng = MersenneTwister(seed)
    phy = random_balanced_tree(p; branch_length = 0.2)
    keep = setdiff(1:phy.n_total, [phy.root_index])
    Q_cond = phy.Q_topology[keep, keep]
    P = prior_precision(Q_cond, inv(_Q4_TEST_SIGMA_A))
    F = cholesky(Symmetric(P))
    u_aug = F.UP \ randn(rng, size(P, 1))
    pos = Dict(node => i for (i, node) in enumerate(keep))
    leaf_pos = [pos[phy.leaf_indices[k]] for k in 1:p]

    species_idx = repeat(1:p, inner = nrep)
    species = [phy.leaf_names[k] for k in species_idx]
    n = length(species_idx)
    x = randn(rng, n)
    y1 = Vector{Float64}(undef, n)
    y2 = Vector{Float64}(undef, n)
    @inbounds for i in 1:n
        k = species_idx[i]
        u = @view u_aug[(4 * (leaf_pos[k] - 1) + 1):(4 * leaf_pos[k])]
        m1 = _Q4_TEST_BETA.mu1[1] + _Q4_TEST_BETA.mu1[2] * x[i] + u[1]
        m2 = _Q4_TEST_BETA.mu2[1] + _Q4_TEST_BETA.mu2[2] * x[i] + u[2]
        s1 = exp(_Q4_TEST_BETA.s1[1] + u[3])
        s2 = exp(_Q4_TEST_BETA.s2[1] + u[4])
        ρ = DRM.RHO_GUARD * tanh(_Q4_TEST_BETA.rho[1])
        e = cholesky(Symmetric([s1^2 ρ*s1*s2; ρ*s1*s2 s2^2])).L * randn(rng, 2)
        y1[i] = m1 + e[1]
        y2[i] = m2 + e[2]
    end
    return (; data = (; y1, y2, x, species), phy)
end

_q4_formula() = bf(
    mu1 = @formula(y1 ~ x + phylo(1 | species)),
    mu2 = @formula(y2 ~ x + phylo(1 | species)),
    sigma1 = @formula(sigma1 ~ 1 + phylo(1 | species)),
    sigma2 = @formula(sigma2 ~ 1 + phylo(1 | species)),
    rho12 = @formula(rho12 ~ 1),
)

_q4_formula_partial() = bf(
    mu1 = @formula(y1 ~ x + phylo(1 | species)),
    mu2 = @formula(y2 ~ x),
    sigma1 = @formula(sigma1 ~ 1),
    sigma2 = @formula(sigma2 ~ 1),
    rho12 = @formula(rho12 ~ 1),
)

_q4_formula_mismatched_group() = bf(
    mu1 = @formula(y1 ~ x + phylo(1 | species)),
    mu2 = @formula(y2 ~ x + phylo(1 | other_species)),
    sigma1 = @formula(sigma1 ~ 1 + phylo(1 | species)),
    sigma2 = @formula(sigma2 ~ 1 + phylo(1 | species)),
    rho12 = @formula(rho12 ~ 1),
)

_q4_formula_rho_marker() = bf(
    mu1 = @formula(y1 ~ x + phylo(1 | species)),
    mu2 = @formula(y2 ~ x + phylo(1 | species)),
    sigma1 = @formula(sigma1 ~ 1 + phylo(1 | species)),
    sigma2 = @formula(sigma2 ~ 1 + phylo(1 | species)),
    rho12 = @formula(rho12 ~ 1 + phylo(1 | species)),
)

_q4_formula_nonintercept_marker() = bf(
    mu1 = @formula(y1 ~ x + phylo(x | species)),
    mu2 = @formula(y2 ~ x + phylo(x | species)),
    sigma1 = @formula(sigma1 ~ 1 + phylo(x | species)),
    sigma2 = @formula(sigma2 ~ 1 + phylo(x | species)),
    rho12 = @formula(rho12 ~ 1),
)

@testset "Bivariate Gaussian q=4 phylo front end" begin
    fixture = _q4_frontend_data()
    fit = drm(
        _q4_formula(),
        Gaussian();
        data = fixture.data,
        tree = fixture.phy,
        q4_iterations = 120,
        q4_n_newton = 30,
        q4_vcov = false,
    )

    @test isfinite(loglik(fit))
    @test fit.nobs == length(fixture.data.y1)
    @test :phylocov in first.(fit.blocks)
    @test haskey(fit.scales, :rho12)
    @test all(isfinite, coef(fit, :rho12))
    @test keys(predict_parameters(fit, fixture.data)) == Set([:mu1, :mu2, :sigma1, :sigma2, :rho12])
    @test !haskey(predict_parameters(fit, fixture.data), :phylocov)

    @test fit.ranef isa NamedTuple
    @test haskey(fit.ranef, :Sigma_a)
    @test size(fit.ranef.Sigma_a) == (4, 4)
    @test fit.ranef.axes == (:mu1, :mu2, :sigma1, :sigma2)
    @test haskey(ranef(fit), :species)
    @test size(ranef(fit)[:species], 1) == 4
    @test size(ranef(fit)[:species], 2) == fixture.phy.n_leaves
end

@testset "Bivariate q=4 phylo front-end validation" begin
    fixture = _q4_frontend_data(p = 6, nrep = 2)

    @test_throws ErrorException drm(
        _q4_formula_partial(),
        Gaussian();
        data = fixture.data,
        tree = fixture.phy,
        q4_vcov = false,
    )

    bad_group_data = merge(fixture.data, (; other_species = fixture.data.species))
    @test_throws ErrorException drm(
        _q4_formula_mismatched_group(),
        Gaussian();
        data = bad_group_data,
        tree = fixture.phy,
        q4_vcov = false,
    )

    @test_throws ErrorException drm(
        _q4_formula_rho_marker(),
        Gaussian();
        data = fixture.data,
        tree = fixture.phy,
        q4_vcov = false,
    )

    @test_throws ErrorException drm(
        _q4_formula_nonintercept_marker(),
        Gaussian();
        data = fixture.data,
        tree = fixture.phy,
        q4_vcov = false,
    )

    @test_throws ErrorException drm(
        _q4_formula(),
        Gaussian();
        data = fixture.data,
        q4_vcov = false,
    )
end
