# test_cumlogit_phylo.jl — phylogenetic random intercept on the cumulative-logit
# (ordinal) mean, `phylo(1 | species)` (#563 S8 follow-on).
#
# drmTMB 0.7.0 ground truth (R/drmTMB.R `validate_ordinal_phylo_mu_structured_term()`,
# tests/testthat/test-cumulative-logit.R "cumulative-logit admits the first
# phylogenetic mu intercept gate"): `cumulative_logit()` `mu` admits an
# UNLABELLED, intercept-only `phylo(1 | species, tree = tree)` structured term.
# This was left as a scope decision (not a drmTMB-parity gap) by the iid
# random-effect slice (test_cumlogit_ranef.jl's "structured phylo marker on mu
# — refused" test) — this file implements that route via the sparse-Laplace
# GLMM engine already proven for Poisson/Gamma/Binomial `phylo(1 | g)`
# (src/sparse_laplace_glmm.jl), plugging in the ordinal cumulative-logit
# likelihood + its η- and cutpoint-derivatives.
#
# R oracle fixture: test/parity/fixtures/cumlogit-mu-phylo/gen_data.R —
#
#   Rscript test/parity/fixtures/cumlogit-mu-phylo/gen_data.R
#
# with drmTMB 0.7.0, giving (60-tip ape::rcoal coalescent tree, Brownian phylo
# intercept u = chol(vcv(tree, corr = TRUE)) %*% rnorm(60, 0, 0.9), n_each = 5,
# K = 3 categories, cutpoints c(-0.5, 0.6), seed 20260902,
# control = drm_control(se = FALSE) — drmTMB's OWN phylo-ordinal gate test
# disables SE for this combination too):
#
#   coef(fit, "mu")        = 0.6648765
#   cutpoints               = -0.3104333, 0.8591587
#   sdpars$mu[["phylo(1 | species)"]] = 1.471822   (CORRELATION scale)
#   logLik(fit)             = -269.5563
#   tree_height              = 2.00224
#   opt$convergence = 0
#
# THE SCALE TRAP (same as test_parity_gaussian_phylo_mean.jl): DRM.jl's
# `re_sd(fit)[:species]` is on the RAW branch-length scale (tip variance =
# tree height h); drmTMB's `sd_phylo` is on the CORRELATION scale
# (`ape::vcv(tree, corr = TRUE)`, tip variance 1 regardless of h). Compare via
# `re_sd(fit)[:species] * sqrt(tree_height)`.
#
# TOLERANCE: both engines run a Laplace approximation of the SAME marginal
# integral here (TMB's analytic-Hessian Laplace vs. DRM.jl's sparse augmented
# -state Laplace with the exact O(p) IFT gradient) — unlike the iid slice's
# GHQ-vs-TMB-Laplace mismatch, so tighter agreement is expected than
# test_cumlogit_ranef.jl's atol=1e-2/rtol=0.05/atol=1.0. MEASURED (2026-09-02,
# this fixture): |Δβ| = 2.7e-7, |Δcutpoints| = 9.6e-7, sd_phylo relative gap =
# 1.6e-6, |Δlogscape lik| = 3.8e-5 — i.e. the two engines land on essentially
# the SAME optimum (both are exact Laplace approximations of the same model),
# far tighter than the task brief's starting guesses of 1e-3/2%/0.1. Asserted
# below at atol=1e-3 (β, cutpoints), rtol=1e-3 (phylo SD), atol=0.01 (logLik)
# — a comfortable margin over the measured gap, not the razor edge, so a
# platform/BLAS-level optimizer-path difference does not flake the suite.

module TestCumlogitPhylo

using DRM
using Test
using DelimitedFiles: readdlm
using Random, LinearAlgebra
import Distributions

const FIXTURE = joinpath(@__DIR__, "parity", "fixtures", "cumlogit-mu-phylo")

function _load(dir)
    raw, header = readdlm(joinpath(dir, "data.csv"), ','; header = true)
    cols = Symbol.(strip.(string.(vec(header))))
    j = Dict(c => i for (i, c) in enumerate(cols))
    species = string.(raw[:, j[:species]])
    x = Float64[parse(Float64, string(v)) for v in raw[:, j[:x]]]
    y = Float64[parse(Float64, string(v)) for v in raw[:, j[:y_int]]]
    return (; species, x, y)
end

_within(a, b, rtol, atol) = abs(a - b) <= max(atol, rtol * max(abs(a), abs(b)))

@testset "CumulativeLogit phylo(1 | species) mu random intercept (#563 S8 follow-on)" begin
    data = _load(FIXTURE)
    tree = read(joinpath(FIXTURE, "tree.newick"), String)

    @testset "same-target vs drmTMB 0.7.0" begin
        fit = drm(bf(@formula(y ~ x + phylo(1 | species))), CumulativeLogit();
                  data = data, tree = tree, se = false)

        @test fit.converged
        @test isfinite(loglik(fit))

        # R oracle (see fixture header above).
        β_R = 0.6648765
        cuts_R = [-0.3104333, 0.8591587]
        sdphylo_corr_R = 1.471822
        loglik_R = -269.5563
        tree_height_R = 2.00224

        @test coef(fit, :mu)[1] ≈ β_R atol = 1e-3
        δ = coef(fit, :cutpoints)
        cutŝ = similar(δ); cutŝ[1] = δ[1]
        for k in 2:length(δ); cutŝ[k] = cutŝ[k-1] + exp(δ[k]); end
        @test cutŝ ≈ cuts_R atol = 1e-3

        phy = augmented_phy(tree)
        h = phylo_tree_height(phy)
        @test h ≈ tree_height_R atol = 1e-4
        sds = re_sd(fit)
        @test haskey(sds, :species)
        sd_phylo_corr = Float64(sds[:species]) * sqrt(h)
        @test _within(sd_phylo_corr, sdphylo_corr_R, 1e-3, 0.0)

        @test loglik(fit) ≈ loglik_R atol = 0.01
    end

    @testset "missing tree= errors" begin
        @test_throws Exception drm(
            bf(@formula(y ~ x + phylo(1 | species))), CumulativeLogit(); data = data)
    end

    @testset "phylo combined with an ordinary random effect on mu — refused" begin
        tree_local = tree
        @test_throws Exception drm(
            bf(@formula(y ~ x + phylo(1 | species) + (1 | species))), CumulativeLogit();
            data = data, tree = tree_local)
    end

    @testset "sparse-Laplace gradient sanity (small synthetic tree)" begin
        Random.seed!(20260902)
        p = 10
        phy_small = random_balanced_tree(p; branch_length = 0.25)
        species_small = repeat(1:p, inner = 12)
        n = length(species_small)
        x_small = randn(n)
        C = sigma_phy_dense(phy_small; σ²_phy = 0.30^2)
        u = cholesky(Symmetric(C)).L * randn(p)
        cuts_true = [-0.4, 0.5]
        lat = 0.5 .* x_small .+ u[species_small] .+ rand(Distributions.Logistic(), n)
        y_small = Float64.(clamp.(searchsortedfirst.(Ref(cuts_true), lat), 1, 3))

        fit = drm(bf(@formula(y_small ~ x_small + phylo(1 | species_small))), CumulativeLogit();
                  data = (; y_small, x_small, species_small), tree = phy_small, se = false)
        θ = coef(fit)
        g = zeros(length(θ))
        fit.nllgrad(g, θ)

        h = 1e-4
        fd = similar(g)
        for k in eachindex(θ)
            e = zeros(length(θ))
            e[k] = h
            fd[k] = (fit.nll(θ .+ e) - fit.nll(θ .- e)) / (2h)
        end
        @test g ≈ fd rtol = 5e-3 atol = 5e-3
    end
end

end # module
