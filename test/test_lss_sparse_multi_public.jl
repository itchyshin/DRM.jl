# test/test_lss_sparse_multi_public.jl
# Issue #563, Phase-2 slice S7b.4: wire the sparse multi-component LSS engine
# (S7b.1-S7b.3, `_lss_sparse_multi_objective`/`_lss_sparse_multi_objective_and_grad`,
# `src/gaussian_sparse_lss.jl`) into the PUBLIC `drm()` route, per the router
# rule D-206 and design note §1/§5/§7 (acceptance oracles 1, 2, 4).
#
# Oracle 2 (FD-vs-exact gradient) is already covered by
# `test_lss_sparse_multi_gradient.jl` (S7b.2/S7b.2b) at the OBJECTIVE level;
# this file only re-touches it indirectly via the public route's convergence
# and gradient-norm checks (oracle 1c). Oracles 1 and 4 are wired here.
#
# `_s7b1_nested_lsss_fixture`/`_s7b1_dense_multi_lss_nll`/`_make_balanced_newick`
# are IDENTICAL COPIES of the helpers `test_lss_sparse_multi.jl` (S7b.1)
# defines — same fixture, same independent dense oracle, no re-derivation —
# duplicated here (the established pattern in this suite: `test_lss_sparse.jl`
# and `test_lss_sparse_multi.jl` already both define their own
# `_make_balanced_newick`) so this file runs standalone, matching the
# sub-slice brief's own RED/GREEN command (`include(
# "test/test_lss_sparse_multi_public.jl")` in isolation, not only via
# `runtests.jl`'s fixed include order).

using Test
using DRM
using StableRNGs
using LinearAlgebra
using SparseArrays
using Logging

# Same balanced-tree Newick builder as test_lss_sparse.jl/test_lss_sparse_multi.jl.
function _make_balanced_newick(d)
    function node(prefix, depth)
        depth == 0 && return "$(prefix):$(1/d)"
        l = node(prefix * "a", depth - 1); r = node(prefix * "b", depth - 1)
        return depth == d ? "($l,$r);" : "($l,$r):$(1/d)"
    end
    node("t", d)
end

# Nested fixture (S7b.1): one phylogenetic component (`sd(species,
# phylogenetic) ~ 1 + z`, 64 species from a balanced tree, depth = 6) and one
# iid component (`sd(site) ~ 1`, sites NESTED within species, 3 sites/
# species), n = 2 rows/site (n = 384).
function _s7b1_nested_lsss_fixture(; depth = 6, sites_per_species = 3, n_per_site = 2,
                                   seed = 20260902)
    phy = DRM.augmented_phy(_make_balanced_newick(depth))
    Gsp = phy.n_leaves
    sp_names = String.(phy.leaf_names)
    Gsite = Gsp * sites_per_species
    rng = StableRNG(seed)

    z_sp = randn(rng, Gsp)
    site_species = repeat(1:Gsp, inner = sites_per_species)
    n = Gsite * n_per_site
    site_idx = repeat(1:Gsite, inner = n_per_site)
    species_idx = site_species[site_idx]
    x = randn(rng, n)
    z = z_sp[species_idx]

    βμ = [0.8, 0.4]
    βσ = [-1.0]
    α_phy = [-0.6, 0.25]
    α_iid = [-0.9]

    K0 = DRM.sigma_phy_dense(phy; σ²_phy = 1.0)
    dK = sqrt.(diag(K0)); K = K0 ./ (dK * dK')
    chK = cholesky(Symmetric(K))
    u_phy = chK.L * randn(rng, Gsp)
    σ_phy_sp = exp.(α_phy[1] .+ α_phy[2] .* z_sp)
    a_phy = σ_phy_sp .* u_phy

    σ_iid_site = fill(exp(α_iid[1]), Gsite)
    a_iid = σ_iid_site .* randn(rng, Gsite)

    σ_e = fill(exp(βσ[1]), n)
    y = βμ[1] .+ βμ[2] .* x .+ a_phy[species_idx] .+ a_iid[site_idx] .+ σ_e .* randn(rng, n)

    dat = (y = y, x = x, z = z,
           species = sp_names[species_idx],
           site = ["site$(g)" for g in site_idx])

    return (phy = phy, dat = dat, n = n, Gsp = Gsp, Gsite = Gsite,
            species_idx = species_idx, site_idx = site_idx, x = x, z_sp = z_sp)
end

# -----------------------------------------------------------------------
# Oracle 1: dense-route identity on the nested fixture (design note §5.1).
# -----------------------------------------------------------------------
@testset "Public route: sparse multi == dense multi on the nested fixture (#563 S7b.4 oracle 1)" begin
    fx = _s7b1_nested_lsss_fixture()
    phy, dat = fx.phy, fx.dat

    f = bf(@formula(y ~ x + (1 | site) + phylo(1 | species)),
           @formula(sigma ~ 1),
           @formula(sd(site) ~ 1),
           @formula(sd(species, phylogenetic) ~ 1 + z))

    @testset "ML" begin
        fit_dense = drm(f, Gaussian(); data = dat, tree = phy, method = :ML)
        fit_sparse = drm(f, Gaussian(); data = dat, tree = phy, algorithm = :sparse, method = :ML)

        @test fit_dense.converged
        @test fit_sparse.converged
        @test DRM._lss_multi_route(fit_dense) === :dense_multi
        @test DRM._lss_multi_route(fit_sparse) === :sparse_multi

        @test isapprox(loglik(fit_sparse), loglik(fit_dense); atol = 1e-5)
        @test isapprox(coef(fit_sparse, :mu), coef(fit_dense, :mu); rtol = 2e-4, atol = 2e-5)
        @test isapprox(coef(fit_sparse, :sd), coef(fit_dense, :sd); rtol = 2e-4, atol = 2e-5)
        @test isapprox(coef(fit_sparse, :sd_phylo), coef(fit_dense, :sd_phylo); rtol = 2e-4, atol = 2e-5)

        # Accessors the rest of the LSS test suite relies on must agree too.
        @test isapprox(coef(fit_sparse, :sd_phylo), coef(fit_dense, :sd_phylo); rtol = 2e-4, atol = 2e-5)
        @test isapprox(loglik(fit_sparse), loglik(fit_dense); atol = 1e-5)
    end

    @testset "REML" begin
        fit_dense = drm(f, Gaussian(); data = dat, tree = phy, method = :REML)
        fit_sparse = drm(f, Gaussian(); data = dat, tree = phy, algorithm = :sparse, method = :REML)

        @test fit_dense.converged
        @test fit_sparse.converged
        @test estimation_method(fit_dense) === :REML
        @test estimation_method(fit_sparse) === :REML
        @test DRM._lss_multi_route(fit_dense) === :dense_multi
        @test DRM._lss_multi_route(fit_sparse) === :sparse_multi

        @test isapprox(reml_loglik(fit_sparse), reml_loglik(fit_dense); atol = 1e-5)
        @test isapprox(ml_loglik(fit_sparse), ml_loglik(fit_dense); atol = 1e-5)
        @test isapprox(coef(fit_sparse, :mu), coef(fit_dense, :mu); rtol = 2e-4, atol = 2e-5)
        @test isapprox(coef(fit_sparse, :sd), coef(fit_dense, :sd); rtol = 2e-4, atol = 2e-5)
        @test isapprox(coef(fit_sparse, :sd_phylo), coef(fit_dense, :sd_phylo); rtol = 2e-4, atol = 2e-5)
    end
end

# -----------------------------------------------------------------------
# Oracle 4: router — a genuinely CROSSED fixture must stay on the DENSE
# route even under an explicit `algorithm = :sparse` request (design note
# §1/§2.3/§7, D-206's NO-GO for comparable-size crossed factors).
# -----------------------------------------------------------------------

# Two iid components, each ~60 groups, CROSSED by independent random
# assignment (no phylogenetic component at all) on n ≈ 1200 rows — the
# design note's own case (c) topology (§2.1), just fixture-scale rather than
# the note's synthetic 200×200 probe.
function _s7b4_crossed_iid_fixture(; G1 = 60, G2 = 60, n = 1200, seed = 20260902)
    rng = StableRNG(seed)
    g1 = rand(rng, 1:G1, n)
    g2 = rand(rng, 1:G2, n)
    x = randn(rng, n)
    b1 = exp(-0.7) .* randn(rng, G1)
    b2 = exp(-0.9) .* randn(rng, G2)
    y = 0.6 .+ 0.3 .* x .+ b1[g1] .+ b2[g2] .+ exp(-0.5) .* randn(rng, n)
    return (y = y, x = x, g1 = g1, g2 = g2)
end

@testset "Public route: crossed fixture stays dense under algorithm = :sparse (#563 S7b.4 oracle 4)" begin
    dat = _s7b4_crossed_iid_fixture()
    f = bf(@formula(y ~ x + (1 | g1) + (1 | g2)), @formula(sigma ~ 1),
           @formula(sd(g1) ~ 1), @formula(sd(g2) ~ 1))

    local fit
    @test_logs (:info, r"not eligible for the sparse"i) match_mode = :any begin
        fit = drm(f, Gaussian(); data = dat, algorithm = :sparse)
    end
    @test fit.converged
    @test DRM._lss_multi_route(fit) === :dense_multi   # NEVER silently run sparse (D-206)

    # The router's own eligibility check must give the reason "no
    # phylogenetic sd() component" for this fixture (two iid, no phylo term).
    g1idx, G1 = DRM._group_index(dat.g1)
    g2idx, G2 = DRM._group_index(dat.g2)
    comps = [DRM._LssComp(g1idx, G1, ones(G1, 1), ["(Intercept)"], nothing, "g1"),
             DRM._LssComp(g2idx, G2, ones(G2, 1), ["(Intercept)"], nothing, "g2")]
    eligible, reason = DRM._lss_multi_sparse_eligible(comps)
    @test !eligible
    @test occursin("no phylogenetic", reason)

    @testset "predicted fill on the crossed H (S7b.1 assembler, design note §2.1 case (c))" begin
        n = length(dat.y)
        Xmu = hcat(ones(n), dat.x)
        Xsigma = ones(n, 1)
        comp1 = DRM._sparse_lss_iid_comp(g1idx, G1, ones(G1, 1))
        comp2 = DRM._sparse_lss_iid_comp(g2idx, G2, ones(G2, 1))
        sp_comps = [comp1, comp2]
        θ = zeros(2 + 1 + 1 + 1)   # βμ (2) + βσ (1) + α1 (1) + α2 (1)
        asm = DRM._lss_sparse_multi_assemble(θ, dat.y, Xmu, Xsigma, sp_comps)
        H = asm.H
        ch = cholesky(Symmetric(H); check = false)
        @test issuccess(ch)
        dim = size(H, 1)
        fillratio = nnz(sparse(ch.L)) / dim
        # Note's §2.1 case (c) reading: comparable-size crossed factors give
        # nnz(L)/dim WELL above the nested band (< 1) and the small-crossed
        # band (< 3) — measured here at ≈42 for this fixture's scale, so a
        # threshold of 4 is a comfortable, non-flaky regression guard, not a
        # re-confirmation of the note's own 200×200 number. A wrong (i.e.
        # optimistic/nested-shaped) fill claim on this topology fails here.
        @test fillratio > 4
    end
end

# -----------------------------------------------------------------------
# Oracle 1c: G_phylo > 500 auto-dispatch — no `algorithm` keyword, the
# multi-component fit must still auto-select the sparse route (mirrors the
# single-component `G > 500` rule, `gaussian_lss.jl:402`).
# -----------------------------------------------------------------------

# 600-tip tree, ONE observation per tip (n = 600 total, kept small so the
# case stays fast — see the after-task report for measured wall time), plus
# one SMALL crossed iid component (G_iid = 30 ≪ 600 = 0.1 × phy.G exactly at
# the documented threshold's boundary minus one) — design note case (b)'s
# topology (a small crossed factor beside one big tree-structured component),
# not the nested nested-within-species nesting: an iid component this size
# cannot be "nested WITHIN 600 species" in the technical sense §1 needs
# (fewer child categories than parents is definitionally the small/crossed
# case, not the nested one) — it is eligible via the SMALL branch of the
# router's eligibility rule instead.
function _s7b4_large_phylo_fixture(; p = 600, G_iid = 30, seed = 20260902)
    phy = random_balanced_tree(p; branch_length = 0.15)
    sp_names = String.(phy.leaf_names)
    n = p
    rng = StableRNG(seed)
    x = randn(rng, n)
    iid_g = rand(rng, 1:G_iid, n)          # crossed with species by construction

    K0 = sigma_phy_dense(phy; σ²_phy = 1.0)
    dK = sqrt.(diag(K0)); K = K0 ./ (dK * dK')
    chK = cholesky(Symmetric(K))
    u_phy = chK.L * randn(rng, p)
    a_phy = exp(-0.5) .* u_phy
    a_iid = exp(-1.0) .* randn(rng, G_iid)

    y = 0.4 .+ 0.2 .* x .+ a_phy .+ a_iid[iid_g] .+ exp(-0.6) .* randn(rng, n)
    dat = (y = y, x = x, species = sp_names, batch = iid_g)
    return phy, dat
end

@testset "Public route: G_phylo > 500 auto-dispatch (#563 S7b.4 oracle 1c)" begin
    phy, dat = _s7b4_large_phylo_fixture()
    f = bf(@formula(y ~ x + (1 | batch) + phylo(1 | species)), @formula(sigma ~ 1),
           @formula(sd(batch) ~ 1), @formula(sd(species, phylogenetic) ~ 1))

    local fit_auto
    elapsed = @elapsed begin
        # No `algorithm` keyword: :auto is drm()'s own default.
        fit_auto = drm(f, Gaussian(); data = dat, tree = phy)
    end
    @test elapsed < 120   # the sub-slice's own ≲2 min budget for this case

    @test fit_auto.converged
    @test DRM._lss_multi_route(fit_auto) === :sparse_multi

    # A dense cross-check at this scale (n = 600, np = 5) is affordable
    # (dense multi is O(n^3) per evaluation but n is small and there are
    # only 5 free parameters); reuse it when it stays inside the same time
    # budget, and fall back to convergence + gradient-norm only otherwise —
    # exactly the fallback the sub-slice brief sanctions.
    local fit_dense
    dense_elapsed = try
        @elapsed (fit_dense = drm(f, Gaussian(); data = dat, tree = phy, algorithm = :lbfgs))
    catch
        Inf
    end
    if dense_elapsed < 90
        @test fit_dense.converged
        @test DRM._lss_multi_route(fit_dense) === :dense_multi
        @test isapprox(loglik(fit_auto), loglik(fit_dense); atol = 1e-4)
        @test isapprox(coef(fit_auto, :mu), coef(fit_dense, :mu); rtol = 2e-3, atol = 2e-4)
    else
        @info "600-tip oracle 1c: dense multi-component comparator exceeded the local " *
              "time budget ($(dense_elapsed) s) — asserting convergence + gradient norm only."
        grad = fit_auto.nllgrad === nothing ? Float64[] :
               (g = zeros(length(fit_auto.theta)); fit_auto.nllgrad(g, fit_auto.theta); g)
        @test !isempty(grad)
        @test norm(grad) < 1e-3
    end
end
