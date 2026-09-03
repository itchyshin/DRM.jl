# test_phylo_slope_refusal.jl — silent-data-loss fix (tonight's issue).
#
# `_split_ranef` (src/gaussian_ranef.jl:19) used to keep only the grouping
# symbol of a `phylo(...)` marker, so `phylo(1 + x | group)` (and
# `phylo(0 + x | group)`, `phylo(x | group)`) silently fit the SAME
# intercept-only phylogenetic random effect as `phylo(1 | group)` on every
# univariate family, Gaussian included — no error, byte-for-byte identical
# theta/loglik/coefnames. drmTMB fits a genuine two-SD phylogenetic random
# slope on Gaussian for this construct; DRM.jl has no such route yet.
#
# Fix: fail closed. `phylo(<not literal 1> | group)` on a univariate route
# now throws `ArgumentError` naming the marker and saying it is not
# implemented, instead of quietly dropping the slope.
#
# Untouched by design (regression-asserted below, not exercised by the fix):
#   - bivariate q4/q2 `phylo(1 | species)` / `phylo(1 | tag | species)`
#     (gaussian_bivariate.jl `_split_bivariate_q4_rhs` / `_q4_marker_group`
#     already enforce intercept-only independently of `_split_ranef`).
#   - the `(1 | tag | phylo(group))` mean↔scale coupling
#     (locscale_frontend.jl `_ls_parse_coupled`; `phylo` there wraps only the
#     grouping symbol, never reaches `_split_ranef`'s phylo branch at all).
using DRM
using Test, Random, LinearAlgebra
import Distributions

@testset "phylo(<not 1> | group) refused on univariate routes" begin
    Random.seed!(20260902)
    p = 8
    phy = random_balanced_tree(p; branch_length = 0.25)
    species = repeat(1:p, inner = 3)
    n = length(species)
    x = randn(n)

    @testset "Poisson" begin
        y = Float64.([rand(Distributions.Poisson(exp(0.2 + 0.25xi))) for xi in x])
        data = (; y, x, species)

        err1 = try
            drm(bf(@formula(y ~ x + phylo(1 + x | species))), Poisson();
                data = data, tree = phy, se = false)
            nothing
        catch e
            e
        end
        @test err1 isa ArgumentError
        @test occursin("phylo(1 + x | species)", err1.msg)
        @test occursin("not implemented", err1.msg)

        err2 = try
            drm(bf(@formula(y ~ x + phylo(0 + x | species))), Poisson();
                data = data, tree = phy, se = false)
            nothing
        catch e
            e
        end
        @test err2 isa ArgumentError
        @test occursin("phylo(0 + x | species)", err2.msg)
        @test occursin("not implemented", err2.msg)

        # Positive control: the still-supported intercept-only marker still fits.
        fit = drm(bf(@formula(y ~ x + phylo(1 | species))), Poisson();
                   data = data, tree = phy, se = false)
        @test all(isfinite, fit.theta)
    end

    @testset "Gaussian" begin
        y = 0.2 .+ 0.4 .* x .+ 0.3 .* randn(n)
        data = (; y, x, species)

        err1 = try
            drm(bf(@formula(y ~ x + phylo(1 + x | species))), Gaussian();
                data = data, tree = phy)
            nothing
        catch e
            e
        end
        @test err1 isa ArgumentError
        @test occursin("phylo(1 + x | species)", err1.msg)
        @test occursin("not implemented", err1.msg)

        err2 = try
            drm(bf(@formula(y ~ x + phylo(0 + x | species))), Gaussian();
                data = data, tree = phy)
            nothing
        catch e
            e
        end
        @test err2 isa ArgumentError
        @test occursin("phylo(0 + x | species)", err2.msg)
        @test occursin("not implemented", err2.msg)

        # Positive control: the still-supported intercept-only marker still fits.
        fit = drm(bf(@formula(y ~ x + phylo(1 | species))), Gaussian();
                   data = data, tree = phy)
        @test all(isfinite, fit.theta)
    end
end

@testset "regression: bivariate q4 phylo (different syntax) unaffected" begin
    # Small self-contained copy of the `_q4_frontend_data`/`_q4_formula` DGP and
    # call in test_gaussian_bivariate_phylo.jl: `phylo(1 | species)` on mu1, mu2,
    # sigma1, sigma2 — the labelled 3-part-bar front end never routes through
    # `_split_ranef` for these axes, so it must still construct and fit after
    # the univariate-route fix above.
    Random.seed!(20260904)
    p = 8
    nrep = 3
    phy = random_balanced_tree(p; branch_length = 0.2)
    species_idx = repeat(1:p, inner = nrep)
    species = [phy.leaf_names[k] for k in species_idx]
    n = length(species_idx)
    x = randn(n)
    y1 = 1.0 .+ 0.5 .* x .+ 0.2 .* randn(n)
    y2 = -0.3 .+ 0.4 .* x .+ 0.2 .* randn(n)
    data = (; y1, y2, x, species)

    form = bf(
        mu1 = @formula(y1 ~ x + phylo(1 | species)),
        mu2 = @formula(y2 ~ x + phylo(1 | species)),
        sigma1 = @formula(sigma1 ~ 1 + phylo(1 | species)),
        sigma2 = @formula(sigma2 ~ 1 + phylo(1 | species)),
        rho12 = @formula(rho12 ~ 1),
    )
    fit = drm(form, Gaussian();
              data = data, tree = phy,
              q4_iterations = 30, q4_n_newton = 10, q4_vcov = false)
    @test isfinite(loglik(fit))
end

@testset "regression: (1 | tag | phylo(group)) location-scale coupling unaffected" begin
    # Different syntax again: `phylo` here wraps only the grouping symbol inside
    # a coupled `(1 | tag | phylo(group))` term, parsed by locscale_frontend.jl,
    # never by `_split_ranef`'s phylo branch.
    Random.seed!(20260903)
    p = 8
    m = 3
    phy = random_balanced_tree(p; branch_length = 0.25)
    species = repeat(1:p, inner = m)
    n = length(species)
    x = randn(n)
    y = Float64.([rand(Distributions.Gamma(1.0, exp(0.2 + 0.3xi))) for xi in x])
    data = (; y, x, species)

    fit = drm(bf(@formula(y ~ x + (1 | p | phylo(species))),
                 @formula(sigma ~ 1 + (1 | p | phylo(species)))),
              DRM.Gamma(); data = data, tree = phy, se = false)
    @test isfinite(loglik(fit))
end
