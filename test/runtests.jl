using DRM
using Test, LinearAlgebra, SparseArrays, Random

@testset "DRM.jl — engine loads + phylo foundation" begin
    @testset "public API present" begin
        for f in (:fit_q4_sparse_tmb, :marginal_and_exact_grad, :make_problem,
                  :estep_mode, :prior_precision, :augmented_phy,
                  :random_balanced_tree, :sigma_phy_dense, :takahashi_selinv)
            @test isdefined(DRM, f)
        end
    end

    @testset "sparse augmented phylo precision (p=8)" begin
        Random.seed!(1); p = 8
        phy = random_balanced_tree(p; branch_length = 0.2)
        Σ = sigma_phy_dense(phy; σ²_phy = 1.0)          # dense leaf covariance
        @test size(Σ) == (p, p)
        @test isposdef(Symmetric(Σ))                    # well-conditioned tree cov
        # kron(Q_cond, Λ⁻¹) prior precision is sparse + PD (the O(p) engine core)
        Λ = Matrix(Symmetric(0.3I(4) + 0.02 * (ones(4, 4) - I(4))))
        keep = setdiff(1:phy.n_total, [phy.root_index])
        P = prior_precision(phy.Q_topology[keep, keep], inv(Λ))
        @test issparse(P)
        @test isposdef(Symmetric(Matrix(P)))
    end
end

# Gaussian location–scale front end (drm/bf public API).
include("test_gaussian_core.jl")
include("test_gaussian_bivariate.jl")
include("test_gaussian_ranef.jl")
include("test_inference.jl")
include("test_profile_ci.jl")
include("test_postfit.jl")
include("test_meta.jl")
include("test_simulate.jl")
include("test_gaussian_structured.jl")
include("test_bootstrap.jl")
include("test_gaussian_spatial.jl")
include("test_predict.jl")
include("test_correlated_re.jl")
include("test_multi_re.jl")
include("test_sigma_re.jl")
include("test_student.jl")
include("test_poisson.jl")
include("test_nbinom2.jl")
include("test_beta.jl")
include("test_gamma.jl")
include("test_zi.jl")
include("test_lognormal.jl")
include("test_hurdle.jl")
include("test_truncated_nb.jl")
include("test_betabinomial.jl")
include("test_zeroonebeta.jl")
include("test_tweedie.jl")
include("test_cumulative.jl")
include("test_poisson_re.jl")

# NOTE (HANDOVER step): richer tests exist in test/*.jl migrated from the poc
# (test_step1_sparse, check_sparse_tmb, grad_check_*). They use the poc's
# script-style include paths and need path/`using DRM` updates before wiring
# into this suite.
