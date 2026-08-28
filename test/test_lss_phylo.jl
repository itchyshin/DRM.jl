# #545 — sd_phylo(species) ~ x: climate-dependent PHYLOGENETIC SD, the scale
# component of the Mizuno et al. QQQ model (V = D_a A D_a + D_e²).
# Plus the #548 regression: a structured mean intercept with a heteroscedastic
# residual used to return logLik +1.1e105 with converged = true.
#
# CROSS-ENGINE EVIDENCE (2026-08-28, identical CSV + Newick, 64-tip tree):
#   model                    DRM.jl                drmTMB
#   sd_phylo ~ x   logLik    -69.13730392152723    -69.1373
#                  mu        0.9944436, 0.4478094  0.9944436, 0.4478094
#                  sigma    -1.2629298, 0.6845002 -1.26293,   0.6845002
#                  sd_phylo -0.1869284,-0.1827045 -0.1869285, -0.1827046
#   scalar (M5)    logLik    -70.38332423766208    -70.38332
using Test
using DRM
using StableRNGs
using LinearAlgebra

function _balanced_newick(d)
    function node(prefix, depth)
        depth == 0 && return "$(prefix):$(1/d)"
        l = node(prefix * "a", depth - 1); r = node(prefix * "b", depth - 1)
        return depth == d ? "($l,$r);" : "($l,$r):$(1/d)"
    end
    node("t", d)
end

function _qqq_sim(; depth = 6)
    phy = DRM.augmented_phy(_balanced_newick(depth))
    G = phy.n_leaves
    K0 = DRM.sigma_phy_dense(phy; σ²_phy = 1.0)
    dK = sqrt.(diag(K0)); K = K0 ./ (dK * dK')
    rng = StableRNG(11)
    x = randn(rng, G)
    sp = String.(phy.leaf_names)          # REAL tip labels: a placeholder name
                                          # matches no leaf and the fit is refused
    sda = exp.(-0.5 .+ 0.4 .* x)
    sde = exp.(-1.0 .- 0.3 .* x)
    a = Diagonal(sda) * (cholesky(Symmetric(K)).L * randn(rng, G))
    y = 1.0 .+ 0.5 .* x .+ a .+ sde .* randn(rng, G)
    return phy, (y = y, x = x, species = sp)
end

@testset "sd_phylo: grammar and refusals" begin
    phy, dat = _qqq_sim()
    f = bf(@formula(y ~ x + phylo(1 | species)), @formula(sigma ~ x),
           @formula(sd_phylo(species) ~ x))
    @test any(p -> first(p) === :sdphy_species, f.forms)
    # sd_phylo without a phylo() mean marker
    @test_throws ArgumentError drm(bf(@formula(y ~ x + (1 | species)),
                                      @formula(sd_phylo(species) ~ x)),
                                   Gaussian(); data = dat, tree = phy)
    # sd_phylo naming a different grouping than the phylo marker
    @test_throws ArgumentError drm(bf(@formula(y ~ x + phylo(1 | species)),
                                      @formula(sd_phylo(x) ~ 1)),
                                   Gaussian(); data = dat, tree = phy)
    # sd() and sd_phylo() together
    @test_throws ArgumentError drm(bf(@formula(y ~ x + phylo(1 | species)),
                                      @formula(sd(species) ~ 1),
                                      @formula(sd_phylo(species) ~ 1)),
                                   Gaussian(); data = dat, tree = phy)
    # REML not yet wired on this route (ML is the Mizuno protocol's estimator)
    @test_throws ArgumentError drm(f, Gaussian(); data = dat, tree = phy, method = :REML)
end

@testset "sd_phylo: QQQ fit matches drmTMB and recovers the mean" begin
    phy, dat = _qqq_sim()
    fit = drm(bf(@formula(y ~ x + phylo(1 | species)), @formula(sigma ~ x),
                 @formula(sd_phylo(species) ~ x)), Gaussian(); data = dat, tree = phy)
    @test fit.converged
    @test isfinite(fit.loglik)
    # pinned against drmTMB on the identical fixture (agreement to 7 s.f.)
    @test isapprox(fit.loglik, -69.1373; atol = 1e-3)
    @test isapprox(coef(fit, :mu), [0.9944436, 0.4478094]; atol = 1e-4)
    @test isapprox(coef(fit, :sigma), [-1.26293, 0.6845002]; atol = 1e-4)
    @test isapprox(coef(fit, :sd_phylo), [-0.1869285, -0.1827046]; atol = 1e-4)
    # the mean is the well-identified component and must recover truth (1.0, 0.5)
    @test isapprox(coef(fit, :mu), [1.0, 0.5]; atol = 0.15)
    # single-SD summaries refuse on a scale-scale fit
    @test_throws ArgumentError re_sd(fit)
end

@testset "sd_phylo: reduction invariant + #548 regression" begin
    phy, dat = _qqq_sim()
    f1 = drm(bf(@formula(y ~ x + phylo(1 | species)), @formula(sigma ~ x),
                @formula(sd_phylo(species) ~ 1)), Gaussian(); data = dat, tree = phy)
    f0 = drm(bf(@formula(y ~ x + phylo(1 | species)), @formula(sigma ~ x)),
             Gaussian(); data = dat, tree = phy)
    @test f1.converged && f0.converged
    # #548: this scalar fit returned logLik +1.1467e105 with converged = true
    # before the stable dense assembly landed; drmTMB says -70.38332.
    @test isfinite(f0.loglik)
    @test isapprox(f0.loglik, -70.38332; atol = 1e-3)
    @test f0.loglik < 0
    # reduction: sd_phylo(s) ~ 1 IS the scalar model
    @test abs(f1.loglik - f0.loglik) ≤ 1e-8
    @test :resd in first.(f0.blocks)          # scalar route keeps its block name
    @test :sd_phylo in first.(f1.blocks)
end

@testset "sd_phylo: homoscedastic structured route is untouched (#548 guard)" begin
    phy, dat = _qqq_sim()
    # pσ == 1 keeps the verified Woodbury path; assert it still fits sanely
    fh = drm(bf(@formula(y ~ x + phylo(1 | species))), Gaussian(); data = dat, tree = phy)
    @test fh.converged && isfinite(fh.loglik) && fh.loglik < 0
    @test :resd in first.(fh.blocks)
end

@testset "bridge: sd()/sd_phylo() parts route (#546)" begin
    dat = (y = [1.0, 2.0, 3.0, 4.0], x = [0.0, 1.0, 0.0, 1.0],
           z = [1.0, 1.0, 2.0, 2.0], g = ["a", "a", "b", "b"])
    # positional spelling — what drmTMB's `drm_julia_formula_entry` emits
    b, _ = DRM._bridge_formula(["y ~ x + (1 | g)", "sigma ~ x", "sd(g) ~ z"], "gaussian", dat)
    @test first.(b.forms) == [:mu, :sigma, :sd_g]
    # dict spelling — what JuliaCall marshals a named R list into. The key is the
    # marker call itself, so the value (already the full formula) passes through
    # rather than becoming `f(x) = body`, which Julia reads as a function def.
    dphy = (y = [1.0, 2.0], x = [0.0, 1.0], species = ["a", "b"])
    d = Dict{Symbol,Any}(:mu => "y ~ x + phylo(1 | species)", :sigma => "sigma ~ x",
                         Symbol("sd_phylo(species)") => "sd_phylo(species) ~ x")
    b2, _ = DRM._bridge_formula(d, "gaussian", dphy)
    @test Set(first.(b2.forms)) == Set([:mu, :sigma, :sdphy_species])
    # an unknown keyed part must ERROR, never be silently dropped (issue-#2 class)
    @test_throws ArgumentError DRM._bridge_formula(
        Dict{Symbol,Any}(:mu => "y ~ x", :bogus => "bogus ~ x"), "gaussian",
        (y = [1.0, 2.0], x = [0.0, 1.0]))
end
