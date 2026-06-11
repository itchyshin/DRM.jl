# test_rich_bivariate.jl — cluster 5b: bivariate non-Gaussian MR-PMM.
#
# HARD GATE (a): Gaussian×Gaussian reduction.  With both axes Gaussian
# (using :gaussian_mean kernel), the iterated-Laplace marginal MUST equal the
# conjugate coevo_marginal to ≤ 1e-6 (both logLik and gradient).
#
# HARD GATE (b): FD gradient gate for Poisson×Gamma and NB2×Gamma pairs.
# 5-point central-FD, h=1e-4, inner tol=1e-12.  max|Δgrad| ≤ 1e-6.
#
# GATE (c): Recovery on Poisson+Gamma DGP — dispersions, RE SDs, ρ12.
#
# GATE (d): ρ12 profile CI — finite, contains truth, sane.
#
# GATE (e): No-regression (checked by the overall runtests.jl; not repeated here).

using DRM
using Test, LinearAlgebra, Random, SparseArrays

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

function _rb_test_fixture_pg(; p = 30, nrep = 5, seed = 1234)
    rng = MersenneTwister(seed)
    phy = random_balanced_tree(p; branch_length = 0.3)
    Λ = [0.5 0.2; 0.2 0.4]
    β1 = [0.4, 0.2]; β2 = [0.1, -0.1]
    logd1 = 0.0; logd2 = log(2.0)
    sim = simulate_rich_bivar(phy, β1, β2, Λ, logd1, logd2,
                               Val(:poisson), Val(:gamma); nrep=nrep, rng=rng)
    prob, Qc = make_rich_bivar_problem(phy, sim.y1, sim.y2,
                                        sim.X1, sim.X2,
                                        Val(:poisson), Val(:gamma);
                                        species=sim.species)
    return prob, Qc, Λ, β1, β2, logd1, logd2, sim
end

function _rb_test_fixture_gaussian(; p = 10, nrep = 3, seed = 42)
    rng = MersenneTwister(seed)
    phy = random_balanced_tree(p; branch_length = 0.2)
    Λ = [0.5 0.15; 0.15 0.4]
    σ_res = [0.3, 0.35]
    β_mat = zeros(2, 2)
    β_mat[1, :] = [-0.3, 0.4]; β_mat[2, :] = [0.2, -0.15]
    sim = simulate_coevolution(phy, β_mat, Λ, σ_res; nrep=nrep, rng=rng)
    prob_coevo, Qc = make_coevo_problem(phy, sim.Y, sim.X; species=sim.species)
    y1 = sim.Y[:, 1]; y2 = sim.Y[:, 2]
    prob_rb, Qc2 = make_rich_bivar_problem(phy, y1, y2, sim.X, sim.X,
                                            Val(:gaussian_mean), Val(:gaussian_mean);
                                            species=sim.species)
    return prob_coevo, prob_rb, Qc, Qc2, β_mat, Λ, σ_res
end

# 5-point FD gradient
function _fd_grad_5pt(f, θ; h = 1e-4)
    g = similar(θ, Float64)
    for k in eachindex(θ)
        t = Float64.(θ)
        tp2 = copy(t); tp2[k] += 2h
        tp1 = copy(t); tp1[k] += h
        tm1 = copy(t); tm1[k] -= h
        tm2 = copy(t); tm2[k] -= 2h
        g[k] = (-f(tp2) + 8f(tp1) - 8f(tm1) + f(tm2)) / (12h)
    end
    return g
end

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

@testset "rich_bivariate API and types" begin
    prob, Qc, Λ, β1, β2, logd1, logd2, sim = _rb_test_fixture_pg(p = 8, nrep = 2)
    @test prob isa RichBivarProblem
    @test prob.has_disp1 == false   # Poisson: no scalar dispersion
    @test prob.has_disp2 == true    # Gamma: has shape
    @test DRM._rb_theta_len(prob) == size(prob.X1, 2) + size(prob.X2, 2) + 3 + 1

    θ = DRM._rb_pack(prob, β1, β2, Λ, logd1, logd2)
    @test length(θ) == DRM._rb_theta_len(prob)
    β1r, β2r, Λr, _, logd1r, logd2r = DRM._rb_unpack(prob, θ)
    @test β1r ≈ β1; @test β2r ≈ β2; @test Λr ≈ Λ; @test logd2r ≈ logd2

    # NLL is finite at a reasonable point
    nll = DRM._rb_fit_nll(prob, Qc, θ; tol = 1e-9)
    @test isfinite(nll)
    @test nll < 1e17   # not the infeasible sentinel
end

@testset "rich_bivariate HARD GATE (a): Gaussian reduction (logLik + gradient)" begin
    prob_coevo, prob_rb, Qc, Qc2, β_mat, Λ, σ_res = _rb_test_fixture_gaussian()
    test_cases = Any[
        (β_mat, Λ, σ_res),
        ([0.1 -0.2; 0.05 0.1], [0.3 0.05; 0.05 0.25], [0.2, 0.25]),
        ([0.0 0.0; 0.0 0.0], [0.6 0.0; 0.0 0.5], [0.4, 0.4]),
        ([-0.5 0.3; 0.15 -0.1], [0.8 -0.2; -0.2 0.6], [0.5, 0.45]),
    ]
    max_ll = 0.0; max_g = 0.0
    for (β, Λt, σ) in test_cases
        ℓ_coevo, = coevo_marginal(prob_coevo, Qc, β, Λt, σ)
        β1 = β[:, 1]; β2 = β[:, 2]
        θ = DRM._rb_pack(prob_rb, β1, β2, Λt, log(σ[1]), log(σ[2]))
        nll_rb = DRM._rb_fit_nll(prob_rb, Qc2, θ; tol = 1e-12)
        dl = abs(ℓ_coevo - (-nll_rb))
        max_ll = max(max_ll, dl)

        g_exact = DRM._rb_marginal_grad(prob_rb, Qc2, θ; tol = 1e-12)
        g_fd = _fd_grad_5pt(θ -> DRM._rb_fit_nll(prob_rb, Qc2, Float64.(θ); tol = 1e-12), θ)
        max_g = max(max_g, maximum(abs, g_exact .- g_fd))
    end
    @test max_ll ≤ 1e-6    # logLik reduction ≤ 1e-6
    @test max_g  ≤ 1e-6    # gradient reduction ≤ 1e-6
end

@testset "rich_bivariate HARD GATE (b): FD gradient (Poisson×Gamma, NB2×Gamma)" begin
    rng = MersenneTwister(1234)
    p = 16; nrep = 5
    phy = random_balanced_tree(p; branch_length = 0.3)
    Λ_pg = [0.6 0.2; 0.2 0.5]
    β1_pg = [0.5, 0.3]; β2_pg = [0.3, -0.2]
    logd2_pg = log(2.0)

    sim_pg = simulate_rich_bivar(phy, β1_pg, β2_pg, Λ_pg, 0.0, logd2_pg,
                                  Val(:poisson), Val(:gamma); nrep = nrep, rng = rng)
    prob_pg, Qc_pg = make_rich_bivar_problem(phy, sim_pg.y1, sim_pg.y2,
                                              sim_pg.X1, sim_pg.X2,
                                              Val(:poisson), Val(:gamma);
                                              species = sim_pg.species)
    θ_pg = DRM._rb_pack(prob_pg, β1_pg .* 0.8, β2_pg .* 1.1, Λ_pg .* 0.9, 0.0, log(1.5))

    rng2 = MersenneTwister(5678)
    β1_nb = [0.4, 0.2]; β2_nb = [0.2, -0.15]
    sim_nb = simulate_rich_bivar(phy, β1_nb, β2_nb, Λ_pg, log(3.0), log(2.5),
                                  Val(:nb2), Val(:gamma); nrep = nrep, rng = rng2)
    prob_nb, Qc_nb = make_rich_bivar_problem(phy, sim_nb.y1, sim_nb.y2,
                                              sim_nb.X1, sim_nb.X2,
                                              Val(:nb2), Val(:gamma);
                                              species = sim_nb.species)
    θ_nb = DRM._rb_pack(prob_nb, β1_nb .* 0.9, β2_nb .* 1.05, Λ_pg, log(2.0), log(2.0))

    function chk(prob, Qc, θ)
        g = DRM._rb_marginal_grad(prob, Qc, θ; tol = 1e-12)
        gfd = _fd_grad_5pt(tv -> DRM._rb_fit_nll(prob, Qc, Float64.(tv); tol = 1e-12), θ)
        maximum(abs, g .- gfd)
    end
    @test chk(prob_pg, Qc_pg, θ_pg) ≤ 1e-6    # Poisson×Gamma
    @test chk(prob_nb, Qc_nb, θ_nb) ≤ 1e-6    # NB2×Gamma
end

@testset "rich_bivariate GATE (c): recovery on Poisson+Gamma DGP" begin
    rng = MersenneTwister(2024)
    p = 80; nrep = 5
    phy = random_balanced_tree(p; branch_length = 0.3)
    Λ_true = [0.7 0.3; 0.3 0.6]
    β1_true = [0.5, 0.3]; β2_true = [0.2, -0.15]
    logd2_true = log(2.0)
    rho12_true = Λ_true[1,2] / sqrt(Λ_true[1,1] * Λ_true[2,2])

    sim = simulate_rich_bivar(phy, β1_true, β2_true, Λ_true, 0.0, logd2_true,
                               Val(:poisson), Val(:gamma); nrep = nrep, rng = rng)
    prob, Qc = make_rich_bivar_problem(phy, sim.y1, sim.y2,
                                        sim.X1, sim.X2,
                                        Val(:poisson), Val(:gamma);
                                        species = sim.species)
    fit = fit_rich_bivar(prob, Qc; g_tol = 1e-4, iterations = 500)
    @test fit.converged

    sd_true = sqrt.(diag(Λ_true))
    sd_hat  = sqrt.(diag(fit.Λ))
    @test all(abs.(sd_hat .- sd_true) .< 0.25)   # RE SDs within sampling

    @test abs(fit.rho12 - rho12_true) < 0.2      # cross-trait ρ12 within sampling

    shape_hat = exp(fit.logd2)
    @test abs(shape_hat - 2.0) / 2.0 < 0.25      # Gamma shape within 25% relative

    @test fit.Λ ≈ fit.Λ'    # Λ symmetric
    @test isposdef(Symmetric(fit.Λ))
end

@testset "rich_bivariate GATE (d): ρ12 profile CI" begin
    rng = MersenneTwister(2024)
    p = 80; nrep = 5
    phy = random_balanced_tree(p; branch_length = 0.3)
    Λ_true = [0.7 0.3; 0.3 0.6]
    β1_true = [0.5, 0.3]; β2_true = [0.2, -0.15]
    logd2_true = log(2.0)
    rho12_true = Λ_true[1,2] / sqrt(Λ_true[1,1] * Λ_true[2,2])

    sim = simulate_rich_bivar(phy, β1_true, β2_true, Λ_true, 0.0, logd2_true,
                               Val(:poisson), Val(:gamma); nrep = nrep, rng = rng)
    prob, Qc = make_rich_bivar_problem(phy, sim.y1, sim.y2,
                                        sim.X1, sim.X2,
                                        Val(:poisson), Val(:gamma);
                                        species = sim.species)
    fit = fit_rich_bivar(prob, Qc; g_tol = 1e-4, iterations = 500)
    nll_min = -fit.loglik
    ci = rich_bivar_profile_ci_rho12(prob, Qc, fit.θ; level = 0.90, nll_min = nll_min)

    @test isfinite(ci.lower); @test isfinite(ci.upper)
    @test ci.lower < fit.rho12 < ci.upper    # CI brackets the MLE
    @test ci.lower > -1; @test ci.upper < 1  # valid correlation range
    @test ci.lower < rho12_true < ci.upper   # truth inside CI (90% level; passes for this seed)
end

@testset "rich_bivariate simulate_rich_bivar draws and family dispatch" begin
    rng = MersenneTwister(99)
    p = 8; nrep = 4
    phy = random_balanced_tree(p; branch_length = 0.2)
    Λ = [0.3 0.0; 0.0 0.2]   # diagonal
    β1 = [0.5, 0.2]; β2 = [0.2, -0.1]    # intercept + slope (matches X1/X2 with 2 cols)
    sim = simulate_rich_bivar(phy, β1, β2, Λ, 0.0, log(3.0),
                               Val(:poisson), Val(:gamma); nrep=nrep, rng=rng)
    @test all(isinteger.(sim.y1))         # Poisson: integer counts
    @test all(sim.y2 .> 0)               # Gamma: positive
    @test length(sim.y1) == p * nrep
    @test length(sim.y2) == p * nrep

    # NB2
    sim_nb = simulate_rich_bivar(phy, β1, β2, Λ, log(5.0), log(3.0),
                                  Val(:nb2), Val(:gamma); nrep=nrep, rng=rng)
    @test all(isinteger.(sim_nb.y1))
    @test all(sim_nb.y2 .> 0)
end
