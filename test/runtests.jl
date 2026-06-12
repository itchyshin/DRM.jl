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
# REML estimation (opt-in, fixed-effect Gaussian location–scale) + the
# model-selection guard for the classic REML trap (issue #11). Placed early so it
# runs near the core Gaussian tests.
include("test_reml.jl")
include("test_bf_grammar.jl")
include("test_gaussian_bivariate.jl")
include("test_gaussian_bivariate_phylo.jl")
include("test_missing_response.jl")
include("test_missing_response_nongaussian.jl")
include("test_corpairs.jl")
include("test_gaussian_ranef.jl")
include("test_inference.jl")
include("test_profile_ci.jl")
include("test_check_drm.jl")
include("test_bias_correct.jl")
include("test_visualization.jl")
include("test_postfit.jl")
include("test_meta.jl")
include("test_simulate.jl")
include("test_gaussian_structured.jl")
include("test_two_structured_gaussian.jl")
include("test_two_structured_gaussian_sparse.jl")
include("test_heritability.jl")
include("test_conjugate_em.jl")
include("test_bootstrap.jl")
include("test_gaussian_spatial.jl")
include("test_predict.jl")
include("test_predict_response.jl")
include("test_ranef.jl")
include("test_correlated_re.jl")
include("test_multi_re.jl")
include("test_sigma_re.jl")
include("test_sigma.jl")
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
include("test_poisson_slope_re.jl")
include("test_poisson_crossed_laplace.jl")
include("test_poisson_phylo_laplace.jl")
include("test_nb2_phylo_laplace.jl")
include("test_gamma_beta_phylo_laplace.jl")
include("test_binomial_phylo_laplace.jl")
include("test_crossed_laplace_generic.jl")
include("test_crossed_selected_inverse.jl")
include("test_locscale_kernels.jl")
include("test_locscale_inner.jl")
include("test_locscale_marginal.jl")
include("test_locscale_fit.jl")
include("test_locscale_grad.jl")
include("test_locscale_infer.jl")
include("test_locscale_profile.jl")
include("test_locscale_gamma_e2e.jl")
include("test_locscale_phylo_e2e.jl")
include("test_locscale_frontend.jl")
include("test_nbinom2_slope_re.jl")
include("test_beta_slope_re.jl")
include("test_gamma_slope_re.jl")
include("test_nbinom2_re.jl")
include("test_beta_re.jl")
include("test_gamma_re.jl")
include("test_student_re.jl")
include("test_student_slope_re.jl")
include("test_lognormal_re.jl")
include("test_lognormal_slope_re.jl")
include("test_betabinomial_re.jl")
include("test_betabinomial_slope_re.jl")
include("test_binomial.jl")
include("test_binomial_re.jl")
include("test_summary.jl")
include("test_bootstrap_nongaussian.jl")
include("test_aic_bic.jl")
include("test_variational.jl")
include("test_family_accessor.jl")
include("test_parity_accessors.jl")
include("test_rho12_accessor.jl")
include("test_summary_method.jl")
include("test_predict_parameters.jl")
include("test_prediction_grid.jl")
include("test_bridge.jl")

# NOTE (HANDOVER step): richer tests exist in test/*.jl migrated from the poc
# (test_step1_sparse, check_sparse_tmb, grad_check_*). They use the poc's
# script-style include paths and need path/`using DRM` updates before wiring
# into this suite.

# Always-on R-parity HARNESS smoke test (machinery only, no R, no fixtures).
# Placed at the END to avoid colliding with other in-flight branches' includes.
include("test_parity_harness.jl")

# Delta-method prediction standard errors (feat-predict-se).
include("test_predict_se.jl")

# Standing Q-gate (issue #14): FD-vs-exact gradient check ≤ 1e-6 for the verified
# q4 sparse-Laplace engine (Workflow Q).
include("test_qgate_fd_gradient.jl")

# Standing engine-quality Q-gate (issue #15): zero-allocation gate on the inner
# Newton mode-finder's pure-Julia arithmetic (the CHOLMOD factor is excluded as
# out-of-Julia-control). Cheap → per-PR. (Workflow Q.)
include("test_qgate_alloc_inner.jl")

# Standing FD-vs-exact gradient gate (issue #165) for the non-Gaussian (Poisson)
# phylogenetic sparse-Laplace route — the exact implicit-logdet outer gradient.
include("test_poisson_phylo_grad_gate.jl")

# Standing FD-vs-exact gradient gate (#165) for the Poisson CROSSED-random-
# intercepts route — same full-Newton-in-basin inner-mode fix as the phylo route.
include("test_poisson_crossed_grad_gate.jl")

# Standing FD-vs-exact gradient gates (#165) for the other non-Gaussian phylo
# routes (NB2, Gamma, Binomial ≤ 1e-6; Beta reported honestly).
include("test_nongaussian_phylo_grad_gate.jl")

# Gated real-parity suite vs committed drmTMB fixtures (off by default).
if get(ENV, "DRM_PARITY_TESTS", "0") == "1"
    @testset "R-parity vs drmTMB v0.1.3" begin
        include("parity/runparity.jl")
    end
else
    @info "R-parity suite skipped (set DRM_PARITY_TESTS=1 to run)"
end

# Model comparison + accessor parity (lrtest / anova / aicc / weights / update).
include("test_comparison.jl")

# Randomized quantile residuals (DHARMa/glmmTMB style) — feat-quantile-residuals.
include("test_quantile_residuals.jl")

# S3: cross-family bivariate (shared-latent GHQ) + link-residual standardization.
include("test_mixed_family.jl")
