using DRM
using Test, LinearAlgebra, Random, SparseArrays

function _q2_known_cov_fixture(K, β, Λ, residual_cov; nrep, rng)
    G = size(K, 1)
    Q = sparse(Matrix(inv(cholesky(Symmetric(K)))))
    P = DRM.prior_precision(Q, inv(Λ))
    F = cholesky(Symmetric(P))
    u = F.UP \ randn(rng, size(P, 1))
    group = repeat(1:G, inner = nrep)
    n = length(group)
    x = randn(rng, n)
    X = hcat(ones(n), x)
    L = cholesky(Symmetric(residual_cov)).L
    Y = zeros(n, 2)
    for i in 1:n
        base = 2 * (group[i] - 1)
        Y[i, 1] = sum(X[i, :] .* β[:, 1]) + u[base + 1]
        Y[i, 2] = sum(X[i, :] .* β[:, 2]) + u[base + 2]
        Y[i, :] .+= L * randn(rng, 2)
    end
    return (; Y, X, group)
end

@testset "q2 direct export status contract" begin
    rows = DRM._bridge_q2_direct_export_status()
    schema = DRM._bridge_q2_direct_export_schema()

    @test length(rows) == 4
    @test all(row -> propertynames(row) == schema, rows)
    @test Set(row.structured_type for row in rows) == Set(["phylo", "spatial", "animal", "relmat"])
    @test all(row -> row.dimension == "q2", rows)
    @test all(row -> row.route == "direct_drmjl", rows)
    @test all(row -> row.estimator == "ML", rows)
    by_type = Dict(row.structured_type => row for row in rows)
    @test by_type["phylo"].direct_status == "available_residual_correlation_point_export"
    @test all(
        structured_type -> by_type[structured_type].direct_status ==
                           "available_known_covariance_residual_correlation_point_export",
        ("animal", "relmat"),
    )
    @test by_type["spatial"].direct_status ==
          "available_fixed_covariance_residual_correlation_fixture"
    @test all(row -> row.bridge_status == "experimental", rows)
    @test occursin("residual-correlation direct export", by_type["phylo"].unavailable_reason)
    @test occursin("R-via-Julia bridge support is narrow fixture support",
                   by_type["phylo"].claim_boundary)
    @test occursin("no broad q2 bridge support", by_type["phylo"].claim_boundary)
    @test occursin("not a range-estimating spatial route", by_type["spatial"].claim_boundary)
    @test occursin("range-estimating spatial route remains unsupported",
                   by_type["spatial"].unavailable_reason)
    @test all(row -> occursin("no broad q2 bridge support", row.claim_boundary), rows)

    expected_order = join((
        "mu1:(Intercept)",
        "mu1:x",
        "mu2:(Intercept)",
        "mu2:x",
        "sd_mu1:structured(group)",
        "sd_mu2:structured(group)",
        "cor_mu1_mu2:structured(group)",
    ), ";")
    @test all(row -> row.coefficient_order == expected_order, rows)

    validation = DRM._bridge_q2_validate_direct_export_status(rows)
    @test validation.ok
    @test isempty(validation.errors)
    @test validation.n_rows == 4
    @test validation.schema == schema

    bad_rows = collect(rows)
    bad_rows[1] = merge(bad_rows[1], (coefficient_order = "bad",))
    bad_validation = DRM._bridge_q2_validate_direct_export_status(Tuple(bad_rows))
    @test !bad_validation.ok
    @test any(err -> occursin("coefficient order", err), bad_validation.errors)
end

@testset "q2 known covariance fixtures export residual-correlation targets" begin
    rng = MersenneTwister(20260626)
    G = 14
    idx = collect(1:G)
    relmat_K = [0.65 ^ abs(i - j) for i in idx, j in idx] + 1e-6I
    animal_K = [0.45 ^ abs(i - j) + (i == j ? 0.40 : 0.0) for i in idx, j in idx]
    coords = hcat(range(0.0, 1.0; length = G), sin.(range(0.0, π; length = G)))
    D = [sqrt(sum(abs2, coords[i, :] .- coords[j, :])) for i in idx, j in idx]
    spatial_K = exp.(-D ./ 0.45) + 1e-6I
    β = [0.25 -0.18; 0.20 0.12]
    Λ = Matrix(Symmetric([0.24 0.07; 0.07 0.19]))
    residual_cov = Matrix(Symmetric([0.11 0.035; 0.035 0.15]))

    for (structured_type, K) in (
        "relmat" => relmat_K,
        "animal" => animal_K,
        "spatial" => spatial_K,
    )
        sim = _q2_known_cov_fixture(K, β, Λ, residual_cov; nrep = 3, rng = rng)
        prob, Q = DRM.make_coevo_problem_from_covariance(K, sim.Y, sim.X; group = sim.group)
        fit = DRM.fit_coevolution_q2_residual(
            prob,
            Q;
            β0 = β,
            Λ0 = Λ,
            σ0 = sqrt.(diag(residual_cov)),
            rho0 = residual_cov[1, 2] / sqrt(residual_cov[1, 1] * residual_cov[2, 2]),
            iterations = 160,
            g_tol = 2e-4,
        )
        point_export = DRM._bridge_q2_point_export(
            fit;
            family = "biv_gaussian",
            structured_type = structured_type,
        )

        @test fit.converged
        @test point_export["target"] ==
              "gaussian_q2_mu1_mu2_$(structured_type)_residual_correlation"
        @test point_export["structured_type"] == structured_type
        @test point_export["sigma_a_source"] == "fit_coevolution_q2_residual.Λ"
        @test point_export["sigma_a"] ≈ fit.Λ
        @test point_export["residual_sd"]["mu1"] ≈ fit.σ_res[1]
        @test point_export["residual_sd"]["mu2"] ≈ fit.σ_res[2]
        @test point_export["residual_correlation"] ≈ fit.rho12
        @test occursin("known-matrix", point_export["claim_boundary"])
        @test occursin("exact-Gaussian ML", point_export["claim_boundary"])
        @test occursin("R-via-Julia support is limited to route-specific q2 fixtures",
                       point_export["claim_boundary"])
        @test occursin("no broad q2 bridge support", point_export["claim_boundary"])
    end

    @test_throws ErrorException DRM.make_coevo_problem_from_covariance(
        [1.0 2.0; 2.0 1.0],
        zeros(2, 2),
        ones(2, 1);
        group = [1, 2],
    )
    @test_throws ErrorException DRM.make_coevo_problem_from_covariance(
        relmat_K,
        zeros(2, 2),
        ones(2, 1);
        group = [1, G + 1],
    )
end

@testset "q2 relmat and animal formula routes export their structured type" begin
    rng = MersenneTwister(20260627)
    G = 12
    idx = collect(1:G)
    K = [0.55 ^ abs(i - j) for i in idx, j in idx] + 1e-6I
    β = [0.20 -0.12; 0.18 0.10]
    Λ = Matrix(Symmetric([0.20 0.05; 0.05 0.17]))
    residual_cov = Matrix(Symmetric([0.10 0.025; 0.025 0.14]))
    sim = _q2_known_cov_fixture(K, β, Λ, residual_cov; nrep = 3, rng = rng)
    labels = ["g$(i)" for i in sim.group]
    dat = (;
        y1 = sim.Y[:, 1],
        y2 = sim.Y[:, 2],
        x = sim.X[:, 2],
        group_id = labels,
    )

    relmat_form = bf(
        mu1 = @formula(y1 ~ x + relmat(1 | group_id)),
        mu2 = @formula(y2 ~ x + relmat(1 | group_id)),
        sigma1 = @formula(sigma1 ~ 1),
        sigma2 = @formula(sigma2 ~ 1),
        rho12 = @formula(rho12 ~ 1),
    )
    relmat_fit = drm(relmat_form, Gaussian(); data = dat, K = K, g_tol = 2e-4)
    relmat_export = DRM._bridge_q2_point_export(relmat_fit; family = "biv_gaussian")
    relmat_bridged = drm_bridge(;
        formula = Dict(
            :mu1 => "y1 ~ x + relmat(1 | group_id)",
            :mu2 => "y2 ~ x + relmat(1 | group_id)",
            :sigma1 => "sigma1 ~ 1",
            :sigma2 => "sigma2 ~ 1",
            :rho12 => "rho12 ~ 1",
        ),
        family = "biv_gaussian",
        data = dat,
        K = K,
        options = Dict(:g_tol => 2e-4),
    )

    @test relmat_fit.ranef.structured_type == :relmat
    @test relmat_export["target"] == "gaussian_q2_mu1_mu2_relmat_residual_correlation"
    @test relmat_export["structured_type"] == "relmat"
    @test occursin("relmat", relmat_export["claim_boundary"])
    @test relmat_bridged["q2_point_export"]["target"] ==
          "gaussian_q2_mu1_mu2_relmat_residual_correlation"
    @test relmat_bridged["q2_point_export"]["residual_correlation"] ≈ first(rho12(relmat_fit))
    @test relmat_bridged["loglik"] ≈ loglik(relmat_fit)

    animal_form = bf(
        mu1 = @formula(y1 ~ x + animal(1 | group_id)),
        mu2 = @formula(y2 ~ x + animal(1 | group_id)),
        sigma1 = @formula(sigma1 ~ 1),
        sigma2 = @formula(sigma2 ~ 1),
        rho12 = @formula(rho12 ~ 1),
    )
    animal_fit = drm(animal_form, Gaussian(); data = dat, A = K, g_tol = 2e-4)
    animal_export = DRM._bridge_q2_point_export(animal_fit; family = "biv_gaussian")
    animal_bridged = drm_bridge(;
        formula = Dict(
            :mu1 => "y1 ~ x + animal(1 | group_id)",
            :mu2 => "y2 ~ x + animal(1 | group_id)",
            :sigma1 => "sigma1 ~ 1",
            :sigma2 => "sigma2 ~ 1",
            :rho12 => "rho12 ~ 1",
        ),
        family = "biv_gaussian",
        data = dat,
        A = K,
        options = Dict(:g_tol => 2e-4),
    )

    @test animal_fit.ranef.structured_type == :animal
    @test animal_export["target"] == "gaussian_q2_mu1_mu2_animal_residual_correlation"
    @test animal_export["structured_type"] == "animal"
    @test occursin("animal", animal_export["claim_boundary"])
    @test animal_bridged["q2_point_export"]["target"] ==
          "gaussian_q2_mu1_mu2_animal_residual_correlation"
    @test animal_bridged["q2_point_export"]["residual_correlation"] ≈ first(rho12(animal_fit))
    @test animal_bridged["loglik"] ≈ loglik(animal_fit)
    @test_throws ErrorException drm(
        bf(
            mu1 = @formula(y1 ~ x + spatial(1 | group_id)),
            mu2 = @formula(y2 ~ x + spatial(1 | group_id)),
            sigma1 = @formula(sigma1 ~ 1),
            sigma2 = @formula(sigma2 ~ 1),
            rho12 = @formula(rho12 ~ 1),
        ),
        Gaussian();
        data = dat,
        coords = hcat(collect(1:G), collect(1:G)),
    )
end

@testset "q2 residual-correlation phylo route carries the same target as bivariate rho12" begin
    rng = MersenneTwister(20260625)
    phy = DRM.random_balanced_tree(14; branch_length = 0.2)
    β = [0.20 -0.15; 0.25 0.10]
    Λ = Matrix(Symmetric([0.22 0.07; 0.07 0.18]))
    residual_cov = Matrix(Symmetric([0.12 0.04; 0.04 0.16]))
    Q_cond, leaf_pos, _ = DRM.augmented_tree_precision(phy)
    P = DRM.prior_precision(Q_cond, inv(Λ))
    F = cholesky(Symmetric(P))
    u = F.UP \ randn(rng, size(P, 1))
    species = repeat(1:phy.n_leaves, inner = 3)
    n = length(species)
    x = randn(rng, n)
    X = hcat(ones(n), x)
    L = cholesky(Symmetric(residual_cov)).L
    Y = zeros(n, 2)
    for i in 1:n
        base = 2 * (leaf_pos[species[i]] - 1)
        for a in 1:2
            Y[i, a] = sum(X[i, :] .* β[:, a]) + u[base + a]
        end
        Y[i, :] .+= L * randn(rng, 2)
    end

    prob, Q = DRM.make_coevo_problem(phy, Y, X; species = species)
    fit = DRM.fit_coevolution_q2_residual(
        prob,
        Q;
        iterations = 180,
        g_tol = 1e-4,
    )
    point_export = DRM._bridge_q2_point_export(fit; family = "biv_gaussian")

    @test fit.converged
    @test point_export["target"] == "gaussian_q2_mu1_mu2_phylo_residual_correlation"
    @test point_export["sigma_a_source"] == "fit_coevolution_q2_residual.Λ"
    @test point_export["sigma_a"] ≈ fit.Λ
    @test point_export["residual_sd"]["mu1"] ≈ fit.σ_res[1]
    @test point_export["residual_sd"]["mu2"] ≈ fit.σ_res[2]
    @test point_export["residual_correlation"] ≈ fit.rho12
    @test occursin("residual-correlation", point_export["claim_boundary"])
    @test occursin("complete-response exact-Gaussian ML", point_export["claim_boundary"])

    form = bf(
        mu1 = @formula(y1 ~ x + phylo(1 | species_name)),
        mu2 = @formula(y2 ~ x + phylo(1 | species_name)),
        sigma1 = @formula(sigma1 ~ 1),
        sigma2 = @formula(sigma2 ~ 1),
        rho12 = @formula(rho12 ~ 1),
    )
    dat = (;
        y1 = Y[:, 1],
        y2 = Y[:, 2],
        x,
        species_name = [phy.leaf_names[k] for k in species],
    )
    front = drm(form, Gaussian(); data = dat, tree = phy, g_tol = 1e-4)
    front_export = DRM._bridge_q2_point_export(front; family = "biv_gaussian")
    @test isfinite(loglik(front))
    @test front.ranef.axes == (:mu1, :mu2)
    @test size(front.ranef.Sigma_a) == (2, 2)
    @test front_export["target"] == "gaussian_q2_mu1_mu2_phylo_residual_correlation"
    @test front_export["residual_correlation"] ≈ first(rho12(front))
    bridged = drm_bridge(;
        formula = Dict(
            :mu1 => "y1 ~ x + phylo(1 | species_name)",
            :mu2 => "y2 ~ x + phylo(1 | species_name)",
            :sigma1 => "sigma1 ~ 1",
            :sigma2 => "sigma2 ~ 1",
            :rho12 => "rho12 ~ 1",
        ),
        family = "biv_gaussian",
        data = dat,
        tree = phy,
        options = Dict(:g_tol => 1e-4),
    )
    @test bridged["q2_point_export"]["target"] ==
          "gaussian_q2_mu1_mu2_phylo_residual_correlation"
    @test bridged["q2_point_export"]["residual_correlation"] ≈ first(rho12(front))
    @test bridged["loglik"] ≈ loglik(front)
    @test_throws ArgumentError drm(
        bf(
            mu1 = @formula(y1 ~ x + phylo(1 | species_name)),
            mu2 = @formula(y2 ~ x + phylo(1 | species_name)),
            sigma1 = @formula(sigma1 ~ x),
            sigma2 = @formula(sigma2 ~ 1),
            rho12 = @formula(rho12 ~ 1),
        ),
        Gaussian();
        data = dat,
        tree = phy,
    )
end

@testset "restricted q2 phylo point export carries coevolution covariance" begin
    rng = MersenneTwister(20260623)
    phy = DRM.random_balanced_tree(24; branch_length = 0.2)
    β = [0.25 -0.20; 0.15 0.10]
    Λ = Matrix(Symmetric([0.25 0.08; 0.08 0.16]))
    σ_res = [0.35, 0.40]
    sim = DRM.simulate_coevolution(phy, β, Λ, σ_res; nrep = 3, rng = rng)
    prob, Q_cond = DRM.make_coevo_problem(phy, sim.Y, sim.X; species = sim.species)
    fit = DRM.fit_coevolution(
        prob,
        Q_cond;
        iterations = 180,
        g_tol = 1e-4,
    )

    point_export = DRM._bridge_q2_point_export(fit; family = "biv_gaussian")

    @test point_export["target"] == "gaussian_q2_mu1_mu2_phylo_restricted_diagonal_residual"
    @test point_export["dimension"] == "q2"
    @test point_export["family"] == "biv_gaussian"
    @test point_export["structured_type"] == "phylo"
    @test point_export["estimator"] == "ML"
    @test point_export["axes"] == ["mu1", "mu2"]
    @test point_export["sigma_a_source"] == "fit_coevolution.Λ"
    @test point_export["sigma_a"] ≈ fit.Λ
    @test point_export["sd"]["mu1"] ≈ sqrt(fit.Λ[1, 1])
    @test point_export["sd"]["mu2"] ≈ sqrt(fit.Λ[2, 2])
    @test point_export["correlation"][1, 2] ≈ fit.Λ[1, 2] / sqrt(fit.Λ[1, 1] * fit.Λ[2, 2])
    @test point_export["residual_sd"]["mu1"] ≈ fit.σ_res[1]
    @test point_export["residual_sd"]["mu2"] ≈ fit.σ_res[2]
    @test point_export["converged"] == fit.converged
    @test isfinite(point_export["loglik"])
    @test occursin("diagonal-residual coevolution fixture", point_export["claim_boundary"])
    @test occursin("no R-via-Julia q2 bridge support", point_export["claim_boundary"])
    @test occursin("interval coverage", point_export["claim_boundary"])

    non_q2 = (Λ = Matrix(I, 3, 3),)
    @test isempty(DRM._bridge_q2_point_export(non_q2))
end

@testset "private q2 known-precision bridge consumes Q directly" begin
    rng = MersenneTwister(20260628)
    G = 10
    idx = collect(1:G)
    K = [0.50 ^ abs(i - j) for i in idx, j in idx] + 1e-6I
    Q = Matrix(inv(cholesky(Symmetric(K))))
    β = [0.18 -0.11; 0.16 0.09]
    Λ = Matrix(Symmetric([0.18 0.04; 0.04 0.14]))
    residual_cov = Matrix(Symmetric([0.09 0.020; 0.020 0.12]))
    sim = _q2_known_cov_fixture(K, β, Λ, residual_cov; nrep = 2, rng = rng)

    prob, Q_cond = DRM.make_coevo_problem_from_precision(
        Q,
        sim.Y,
        sim.X;
        group = sim.group,
    )
    direct = DRM.fit_coevolution_q2_residual(
        prob,
        Q_cond;
        iterations = 120,
        g_tol = 2e-4,
    )
    out = DRM.drm_bridge_q2_known_precision(;
        Y = sim.Y,
        X = sim.X,
        group = sim.group,
        Q = Q,
        options = Dict("iterations" => 120, "g_tol" => 2e-4),
    )

    @test out["target"] == "gaussian_q2_mu1_mu2_relmat_residual_correlation"
    @test out["structured_type"] == "relmat"
    @test out["input_scale"] == "precision"
    @test out["precision_source"] == "Q"
    @test out["precision_matrix"] ≈ Q
    @test out["sigma_a_source"] == "fit_coevolution_q2_residual.Λ"
    @test out["sigma_a"] ≈ direct.Λ
    @test out["residual_sd"]["mu1"] ≈ direct.σ_res[1]
    @test out["residual_sd"]["mu2"] ≈ direct.σ_res[2]
    @test out["residual_correlation"] ≈ direct.rho12
    @test out["loglik"] ≈ direct.loglik
    @test occursin("without implicit Q-to-K conversion", out["claim_boundary"])
    @test occursin("No R-via-Julia formula support", out["claim_boundary"])
    @test occursin("structured slope support", out["claim_boundary"])

    @test_throws ArgumentError DRM.drm_bridge_q2_known_precision(;
        Y = sim.Y[:, 1:1],
        X = sim.X,
        group = sim.group,
        Q = Q,
    )
    @test_throws ErrorException DRM.drm_bridge_q2_known_precision(;
        Y = sim.Y,
        X = sim.X,
        group = sim.group,
        Q = [1.0 2.0; 2.0 1.0],
    )
end

@testset "private q2 phylo bridge primitive returns restricted point export" begin
    rng = MersenneTwister(20260624)
    phy = DRM.random_balanced_tree(16; branch_length = 0.2)
    β = [0.15 -0.10; 0.20 0.05]
    Λ = Matrix(Symmetric([0.20 0.05; 0.05 0.18]))
    σ_res = [0.30, 0.35]
    sim = DRM.simulate_coevolution(phy, β, Λ, σ_res; nrep = 2, rng = rng)

    out = DRM.drm_bridge_q2_phylo(;
        Y = sim.Y,
        X = sim.X,
        species = sim.species,
        tree = phy,
        options = Dict("iterations" => 100, "g_tol" => 1e-4),
    )

    @test out["target"] == "gaussian_q2_mu1_mu2_phylo_restricted_diagonal_residual"
    @test out["dimension"] == "q2"
    @test out["structured_type"] == "phylo"
    @test out["axes"] == ["mu1", "mu2"]
    @test size(out["sigma_a"]) == (2, 2)
    @test out["correlation"][1, 1] ≈ 1.0
    @test out["correlation"][2, 2] ≈ 1.0
    @test haskey(out, "residual_sd")
    @test haskey(out, "loglik")
    @test occursin("Direct q2 phylo restricted point export only", out["claim_boundary"])
    @test occursin("no R-via-Julia q2 bridge support", out["claim_boundary"])

    @test_throws ArgumentError DRM.drm_bridge_q2_phylo(;
        Y = sim.Y[:, 1:1],
        X = sim.X,
        species = sim.species,
        tree = phy,
    )
end
