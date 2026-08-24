# Regression: the parametric bootstrap must REDRAW the random effects (#459).
#
# `simulate(fit)` is a CONDITIONAL simulator -- it returns
# `fit.means[:mu] .+ sigma .* randn(n)`, and `fit.means[:mu]` already contains the
# fitted BLUPs. The bootstrap used it directly, so every replicate re-used the same
# realised random effects, the refitted variance component barely moved, and the
# percentile CI collapsed onto the point estimate.
#
# Measured before the fix: the phylo-SD bootstrap CI was 1674x NARROWER than native
# TMB on identical data, B and seed. Nothing failed, nothing warned, and the point
# estimate was correct -- which is exactly why it survived. These tests fail if the
# conditional simulator is ever restored.

using Test, DRM, StatsModels, Random, Statistics, LinearAlgebra
import Distributions   # qualified: DRM exports its own `Poisson` FAMILY

@testset "#459 parametric bootstrap redraws random effects" begin
    Random.seed!(20260607)
    G = 32
    phy = random_balanced_tree(G; branch_length = 0.3)
    Craw = sigma_phy_dense(phy; σ²_phy = 1.0)
    d = sqrt.(diag(Craw)); Kc = Craw ./ (d * d')
    m = 4; n = G * m
    species = repeat(1:G, inner = m)
    x = randn(n)
    σ = 0.4; σs = 0.9
    u = σs .* (cholesky(Symmetric(Kc)).L * randn(G))
    y = 0.2 .+ 0.5 .* x .+ u[species] .+ σ .* randn(n)
    dat = (; y, x, species)
    fit = drm(bf(@formula(y ~ x + phylo(1 | species)), @formula(sigma ~ 1)),
              Gaussian(); data = dat, tree = phy)

    sim = DRM._marginal_simulator(fit, dat; tree = phy)
    @test sim !== nothing

    rng = MersenneTwister(11)
    sims = [sim(rng) for _ in 1:60]

    # 1. The replicates must NOT sit at residual distance from the CONDITIONAL mean.
    #    If the random effects are not redrawn, sd(y* - conditional mean) collapses
    #    to exactly the residual sigma -- that single number is the whole bug.
    resid_sigma = exp(coef(fit, :sigma)[1])
    spread = mean(std(s .- fit.means[:mu]) for s in sims)
    @test spread > 1.5 * resid_sigma

    # 2. The between-group signal must vary ACROSS replicates. With the BLUPs held
    #    fixed this equals sigma/sqrt(m); a marginal draw is far larger.
    grpmean(s, g) = mean(s[species .== g])
    across = std([grpmean(s, 1) for s in sims])
    @test across > 2 * (resid_sigma / sqrt(m))

    # 3. The variance-component CI must be non-degenerate AND contain the estimate.
    #    The pre-fix interval failed both: it was ~1e-4 wide, and because the draws
    #    were shifted it did not even bracket the point estimate.
    res = bootstrap_result(fit; data = dat, tree = phy, B = 40, level = 0.95,
                           rng = MersenneTwister(20260824),
                           failures = :skip, check_converged = false)
    sd_rows = [r for r in res.summary if occursin("sd", lowercase(String(r.param)))]
    @test !isempty(sd_rows)
    row = first(sd_rows)
    @test row.upper > row.lower
    @test row.lower <= row.estimate <= row.upper
    # A degenerate interval was ~2.5e-4 wide on the log scale; a real one is ~0.4.
    @test (row.upper - row.lower) > 0.05
end

@testset "#459 marginal simulator uses the RAW phylo covariance" begin
    # `re_sd` for a phylo term is defined against `sigma_phy_dense(phy)`, whose
    # diagonal is the TREE HEIGHT -- not against the normalised correlation that
    # `_resolve_structured_matrix` returns. Drawing with the correlation matrix
    # under-disperses by sqrt(height), which is invisible on a height-1 tree and
    # badly wrong otherwise. This pins the scale on a tall tree, where the two
    # choices differ by more than a factor of two.
    Random.seed!(4242)
    G = 24
    phy = random_balanced_tree(G; branch_length = 1.0)   # tall: height >> 1
    Craw = sigma_phy_dense(phy; σ²_phy = 1.0)
    height = mean(diag(Craw))
    @test height > 2                                      # the trap is live here
    d = sqrt.(diag(Craw)); Kc = Craw ./ (d * d')
    m = 4; n = G * m
    species = repeat(1:G, inner = m); x = randn(n)
    u = 0.8 .* (cholesky(Symmetric(Kc)).L * randn(G))
    y = 0.2 .+ 0.5 .* x .+ u[species] .+ 0.4 .* randn(n)
    dat = (; y, x, species)
    fit = drm(bf(@formula(y ~ x + phylo(1 | species)), @formula(sigma ~ 1)),
              Gaussian(); data = dat, tree = phy)

    # Round-trip: simulate at the FITTED sd and refit. The correct covariance
    # returns the fitted sd back (up to ML shrinkage); the correlation matrix
    # returns it shrunk by roughly sqrt(height).
    sdhat = re_sd(fit)[:species]
    sim = DRM._marginal_simulator(fit, dat; tree = phy)
    rng = MersenneTwister(7)
    got = Float64[]
    for _ in 1:6
        ys = sim(rng)
        f2 = drm(bf(@formula(y ~ x + phylo(1 | species)), @formula(sigma ~ 1)),
                 Gaussian(); data = (; y = ys, x, species), tree = phy)
        push!(got, re_sd(f2)[:species])
    end
    ratio = median(got) / sdhat
    # Correlation-scale draws would land near 1/sqrt(height) < 0.6 here.
    @test 0.75 < ratio < 1.3
end

@testset "#461 a degenerate optimum is not reported as converged" begin
    # With ONE row per group a structured random effect can interpolate the data:
    # sigma collapses toward 0 and the Gaussian log-likelihood runs away to +Inf.
    # `Optim.converged` returns true there, so before this guard 25% of bootstrap
    # replicates were admitted with values like sd_phylo = 22980, sigma = 7.5e-15,
    # loglik = 6.8e13 -- and the percentile interval inherited them.
    Random.seed!(4242)
    G = 100
    phy = random_balanced_tree(G; branch_length = 0.3)
    C = sigma_phy_dense(phy; σ²_phy = 1.0)
    dd = sqrt.(diag(C)); Kc = C ./ (dd * dd')
    species = collect(1:G)                      # exactly one row per species
    x = randn(G)
    u = 0.9 .* (cholesky(Symmetric(Kc)).L * randn(G))
    y = 0.2 .+ 0.5 .* x .+ u .+ 0.4 .* randn(G)
    dat = (; y, x, species)
    fit = drm(bf(@formula(y ~ x + phylo(1 | species)), @formula(sigma ~ 1)),
              Gaussian(); data = dat, tree = phy)

    # The observed fit itself is healthy and must NOT be rejected -- the guard has
    # to be specific to degeneracy, not merely to one-row-per-group designs.
    @test is_converged(fit)

    res = bootstrap_result(fit; data = dat, tree = phy, B = 60, level = 0.95,
                           rng = MersenneTwister(20260824),
                           failures = :skip, check_converged = true)
    # Degenerate replicates must be DROPPED AND COUNTED, not silently included.
    @test res.failed > 0
    @test res.used > 0
    sd_rows = [r for r in res.summary if occursin("sd", lowercase(String(r.param)))]
    @test !isempty(sd_rows)
    row = first(sd_rows)
    # Before the guard the upper percentile reached ~179 (and 22980 in the raw
    # draws) against an estimate near 1. Anything within a factor of 20 is sane.
    @test isfinite(row.upper)
    @test row.upper < 20 * max(row.estimate, 1e-3)
end

@testset "#461 guard is Gaussian-only (a small dispersion is not degeneracy)" begin
    # For NB2/Beta/Gamma the `:sigma` slot holds a dispersion or shape, where a
    # genuinely small value is legitimate. The guard must not reject those.
    Random.seed!(77)
    n = 200; x = randn(n)
    y = Float64[rand(Distributions.Poisson(exp(0.6 + 0.4 * xi))) for xi in x]
    f = drm(bf(@formula(y ~ 1 + x)), Poisson(); data = (; y, x))
    @test is_converged(f) == f.converged      # non-Gaussian: guard is a no-op
end
