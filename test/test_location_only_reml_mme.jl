using DRM
using Test, Random, LinearAlgebra, Statistics

@testset "Location-only Gaussian phylo: supplied-variance REML and traces" begin
    Random.seed!(20260621)
    G = 10
    phy = random_balanced_tree(G; branch_length = 0.25)
    species = repeat(1:G, inner = 2)
    n = length(species)
    x = range(-1.0, 1.0; length = n)
    X = hcat(ones(n), collect(x))
    C = sigma_phy_dense(phy; σ²_phy = 1.0)
    σ = 0.45
    σ_phy = 0.7
    u = σ_phy .* (cholesky(Symmetric(C)).L * randn(G))
    y = X * [0.25, -0.4] .+ u[species] .+ σ .* randn(n)
    prob = DRM.make_loc_problem(phy, y, X; species = species)
    lσ = log(σ)
    lσ_phy = log(σ_phy)

    comp = DRM._loconly_reml_components(prob, lσ, lσ_phy)
    @test comp.converged
    @test isfinite(comp.nll)
    @test isfinite(comp.ml_nll)
    @test isfinite(comp.penalty)
    @test length(comp.beta) == size(X, 2)
    dense_comp = DRM._loconly_dense_reml_components(prob, lσ, lσ_phy)
    cmp_diag = DRM._loconly_dense_comparator_diagnostic(prob, lσ, lσ_phy)
    score_diag = DRM._loconly_reml_dense_score_diagnostic(prob, lσ, lσ_phy)
    sparse_score_diag = DRM._loconly_reml_sparse_score_diagnostic(prob, lσ, lσ_phy)
    boundary = DRM._loconly_reml_boundary_status(prob, lσ, lσ_phy)

    V = σ^2 .* I(n) + σ_phy^2 .* C[species, species]
    chV = cholesky(Symmetric(Matrix(V)))
    VinvX = chV \ X
    Vinvy = chV \ y
    info_dense = X' * VinvX
    beta_dense = info_dense \ (X' * Vinvy)
    r = y .- X * beta_dense
    ml_nll_dense = 0.5 * (n * log(2π) + logdet(chV) + dot(r, chV \ r))
    reml_nll_dense = ml_nll_dense + sum(log, LinearAlgebra.diag(cholesky(Symmetric(info_dense)).U))

    @test comp.beta ≈ beta_dense rtol = 1e-8 atol = 1e-8
    @test comp.ml_nll ≈ ml_nll_dense rtol = 1e-8 atol = 1e-8
    @test comp.info ≈ info_dense rtol = 1e-8 atol = 1e-8
    @test comp.nll ≈ reml_nll_dense rtol = 1e-8 atol = 1e-8
    @test DRM._loconly_reml_nll(prob, lσ, lσ_phy) ≈ reml_nll_dense rtol = 1e-8 atol = 1e-8
    @test dense_comp.converged
    @test dense_comp.matrix_mode === :dense_developer
    @test dense_comp.beta ≈ beta_dense rtol = 1e-8 atol = 1e-8
    @test dense_comp.info ≈ info_dense rtol = 1e-8 atol = 1e-8
    @test dense_comp.nll ≈ reml_nll_dense rtol = 1e-8 atol = 1e-8
    @test cmp_diag.comparator === :dense_same_estimand_oracle
    @test cmp_diag.finite
    @test cmp_diag.nll_absdiff < 1e-8
    @test cmp_diag.beta_absdiff < 1e-8
    @test cmp_diag.info_absdiff < 1e-8
    @test score_diag.target === :gaussian_loconly_reml
    @test score_diag.parameterization === :log_sd
    @test score_diag.matrix_mode === :dense_developer
    @test score_diag.finite
    @test score_diag.score ≈ score_diag.fd_score rtol = 1e-6 atol = 1e-6
    @test score_diag.max_absdiff < 1e-6
    @test sparse_score_diag.target === :gaussian_loconly_reml
    @test sparse_score_diag.parameterization === :log_sd
    @test sparse_score_diag.matrix_mode === :sparse_woodbury_developer
    @test sparse_score_diag.finite
    @test sparse_score_diag.score ≈ score_diag.score rtol = 1e-8 atol = 1e-8
    @test sparse_score_diag.score ≈ sparse_score_diag.fd_score rtol = 1e-6 atol = 1e-6
    @test sparse_score_diag.max_absdiff_dense < 1e-8
    @test sparse_score_diag.max_absdiff_fd < 1e-6
    @test all(isfinite, sparse_score_diag.trace_terms)
    @test all(isfinite, sparse_score_diag.quadratic_terms)
    @test all(isfinite, sparse_score_diag.correction_terms)
    @test boundary.boundary_status === :interior
    @test boundary.finite
    @test boundary.converged

    _, M, chM, _ = DRM.build_M(prob, σ_phy^2, σ^2)
    tr_QM, tr_SMS = DRM.exact_traces(prob, chM)
    Minv = inv(Matrix(M))
    tr_QM_dense = tr(Matrix(prob.Q_cond) * Minv)
    tr_SMS_dense = sum(prob.STS_diag .* LinearAlgebra.diag(Minv))
    diag = DRM._loconly_takahashi_trace_diagnostic(prob, lσ, lσ_phy)
    pev = DRM._loconly_takahashi_pev_diagnostic(prob, lσ, lσ_phy)

    @test diag.trace_mode === :takahashi_selinv
    @test diag.finite
    @test diag.tr_QM ≈ tr_QM_dense rtol = 1e-8 atol = 1e-8
    @test diag.tr_SMS ≈ tr_SMS_dense rtol = 1e-8 atol = 1e-8
    @test tr_QM ≈ tr_QM_dense rtol = 1e-8 atol = 1e-8
    @test tr_SMS ≈ tr_SMS_dense rtol = 1e-8 atol = 1e-8
    @test pev.trace_mode === :takahashi_selinv
    @test pev.finite
    @test pev.n_keep == prob.n_keep
    @test pev.n_leaves == G
    @test pev.posterior_variance ≈ LinearAlgebra.diag(Minv) rtol = 1e-8 atol = 1e-8
    @test pev.leaf_posterior_variance ≈ LinearAlgebra.diag(Minv)[prob.leaf_pos] rtol = 1e-8 atol = 1e-8
    @test all(>=(0), pev.leaf_posterior_variance)
    @test pev.posterior_variance_min >= 0
    @test pev.posterior_variance_max >= pev.posterior_variance_min
    @test pev.leaf_posterior_variance_mean ≈ mean(pev.leaf_posterior_variance) rtol = 1e-12 atol = 1e-12
    @test pev.weighted_leaf_posterior_trace ≈ tr_SMS_dense rtol = 1e-8 atol = 1e-8

    info_diag = DRM._loconly_ai_information_diagnostic(prob, lσ, lσ_phy)
    sparse_info_diag = DRM._loconly_reml_sparse_ai_information_diagnostic(prob, lσ, lσ_phy)
    @test info_diag.target === :gaussian_loconly_reml
    @test info_diag.parameterization === :log_sd
    @test info_diag.matrix_mode === :dense_developer
    @test info_diag.finite
    @test size(info_diag.ai) == (2, 2)
    @test size(info_diag.observed) == (2, 2)
    @test info_diag.ai ≈ info_diag.ai' atol = 1e-10
    @test info_diag.observed ≈ info_diag.observed' atol = 1e-8
    @test info_diag.relative_error < 0.1
    @test sparse_info_diag.target === :gaussian_loconly_reml
    @test sparse_info_diag.parameterization === :log_sd
    @test sparse_info_diag.matrix_mode === :sparse_woodbury_developer
    @test sparse_info_diag.finite
    @test sparse_info_diag.ai ≈ sparse_info_diag.ai' atol = 1e-10
    @test sparse_info_diag.ai ≈ info_diag.ai rtol = 1e-8 atol = 1e-8
    @test sparse_info_diag.max_absdiff_dense < 1e-8
    @test sparse_info_diag.relative_error_observed < 0.1

    opt_diag = DRM._loconly_reml_optimizer_diagnostic(
        prob; starts = [[lσ, lσ_phy], [log(σ * 1.2), log(σ_phy * 0.8)]],
        iterations = 80,
    )
    @test opt_diag.target === :gaussian_loconly_reml
    @test opt_diag.estimator === :fd_reml_optimizer_experiment
    @test opt_diag.parameterization === :log_sd
    @test opt_diag.optimizer === :lbfgs_fd_gradient
    @test opt_diag.claim_status === :optimizer_experiment
    @test !opt_diag.ai_reml_ready
    @test occursin("finite-difference", opt_diag.reason_not_ai_reml)
    @test opt_diag.finite
    @test length(opt_diag.records) == 2
    @test opt_diag.best_nll <= reml_nll_dense + 1e-5
    @test DRM._loconly_reml_nll(prob, opt_diag.best_minimizer[1], opt_diag.best_minimizer[2]) ≈ opt_diag.best_nll rtol = 1e-8 atol = 1e-8
    @test opt_diag.dense_comparator.finite
    @test opt_diag.dense_comparator.nll_absdiff < 1e-7
    @test opt_diag.observed_hessian ≈ opt_diag.observed_hessian' atol = 1e-8
    @test opt_diag.observed_hessian_pd
    @test opt_diag.boundary_status === :interior
    @test opt_diag.local_profile.finite
    @test opt_diag.local_profile.center_is_axis_min
    @test opt_diag.fd_stability.finite
    @test opt_diag.fd_stability.gradient_max_absdiff < 1e-3
    @test opt_diag.fd_stability.hessian_max_absdiff < 1e-2
    @test opt_diag.dense_score.finite
    @test opt_diag.dense_score.max_absdiff < 1e-6
    @test opt_diag.best_score_norm < 1e-3
    @test opt_diag.n_starts == 2
    @test opt_diag.n_finite_records == 2
    @test opt_diag.n_accepted_records >= 1
    @test opt_diag.best_improvement >= -1e-8

    score_opt = DRM._loconly_reml_dense_score_optimizer_diagnostic(
        prob; starts = [[lσ, lσ_phy], [log(σ * 1.2), log(σ_phy * 0.8)]],
        iterations = 80,
    )
    @test score_opt.target === :gaussian_loconly_reml
    @test score_opt.estimator === :dense_score_reml_optimizer_experiment
    @test score_opt.optimizer === :lbfgs_dense_reml_score
    @test score_opt.claim_status === :optimizer_experiment
    @test !score_opt.ai_reml_ready
    @test occursin("dense analytic score", score_opt.reason_not_ai_reml)
    @test score_opt.finite
    @test score_opt.accepted
    @test score_opt.dense_comparator.finite
    @test score_opt.boundary_status === :interior
    @test score_opt.n_starts == 2
    @test score_opt.n_finite_records == 2
    @test score_opt.best_score_norm < 1e-3
    @test score_opt.best_nll ≈ opt_diag.best_nll rtol = 1e-6 atol = 1e-6

    sparse_score_opt = DRM._loconly_reml_sparse_score_optimizer_diagnostic(
        prob; starts = [[lσ, lσ_phy], [log(σ * 1.2), log(σ_phy * 0.8)]],
        iterations = 80,
    )
    @test sparse_score_opt.target === :gaussian_loconly_reml
    @test sparse_score_opt.estimator === :sparse_score_reml_optimizer_experiment
    @test sparse_score_opt.optimizer === :lbfgs_sparse_woodbury_reml_score
    @test sparse_score_opt.claim_status === :optimizer_experiment
    @test !sparse_score_opt.ai_reml_ready
    @test occursin("sparse Woodbury score", sparse_score_opt.reason_not_ai_reml)
    @test sparse_score_opt.finite
    @test sparse_score_opt.accepted
    @test sparse_score_opt.dense_comparator.finite
    @test sparse_score_opt.boundary_status === :interior
    @test sparse_score_opt.sparse_score.finite
    @test sparse_score_opt.best_max_absdiff_dense < 1e-8
    @test sparse_score_opt.n_starts == 2
    @test sparse_score_opt.n_finite_records == 2
    @test sparse_score_opt.best_score_norm < 1e-3
    @test sparse_score_opt.best_nll ≈ score_opt.best_nll rtol = 1e-6 atol = 1e-6

    ai_update_opt = DRM._loconly_reml_ai_update_optimizer_diagnostic(
        prob; starts = [[lσ, lσ_phy], [log(σ * 1.2), log(σ_phy * 0.8)]],
        iterations = 30,
    )
    @test ai_update_opt.target === :gaussian_loconly_reml
    @test ai_update_opt.estimator === :guarded_ai_update_reml_optimizer_experiment
    @test ai_update_opt.optimizer === :guarded_sparse_average_information_update
    @test ai_update_opt.claim_status === :optimizer_experiment
    @test !ai_update_opt.ai_reml_ready
    @test occursin("guarded average-information", ai_update_opt.reason_not_ai_reml)
    @test ai_update_opt.finite
    @test ai_update_opt.accepted
    @test ai_update_opt.dense_comparator.finite
    @test ai_update_opt.boundary_status === :interior
    @test ai_update_opt.sparse_score.finite
    @test ai_update_opt.sparse_information.finite
    @test ai_update_opt.n_starts == 2
    @test ai_update_opt.n_finite_records == 2
    @test ai_update_opt.n_accepted_records >= 1
    @test ai_update_opt.best_score_norm < 1e-3
    @test ai_update_opt.best_nll ≈ opt_diag.best_nll rtol = 1e-5 atol = 1e-5
    @test ai_update_opt.best_nll ≈ score_opt.best_nll rtol = 1e-5 atol = 1e-5
    @test ai_update_opt.best_nll ≈ sparse_score_opt.best_nll rtol = 1e-5 atol = 1e-5
    @test any(r -> any(t -> t.status === :accepted_step, r.trace), ai_update_opt.records)
    @test all(r -> all(t -> t.halvings >= 0, r.trace), ai_update_opt.records)

    payload = DRM._loconly_reml_diagnostic_payload(prob, lσ, lσ_phy)
    @test payload.target === :gaussian_loconly_phylo_reml
    @test payload.estimator === :supplied_variance_reml
    @test payload.boundary.boundary_status === :interior
    @test payload.dense_comparator.finite
    @test payload.score.finite
    @test payload.sparse_score.finite
    @test payload.sparse_score.max_absdiff_dense < 1e-8
    @test payload.trace.finite
    @test payload.pev.finite
    @test payload.information.finite
    @test payload.sparse_information.finite
    @test payload.sparse_information.max_absdiff_dense < 1e-8
    @test payload.fd_stability.finite
    @test payload.local_profile.finite
    @test payload.validation_status.claim_status === :internal_diagnostic
    @test payload.bridge_schema.r_bridge_status == "planned"
    @test payload.claim_status === :internal_diagnostic

    recovery = DRM._loconly_reml_recovery_grid_diagnostic(
        ; reps = 3, G = 10, n_per_species = 3, sigma = σ, sigma_phy = σ_phy,
        seed = 20260624, iterations = 30,
    )
    @test recovery.target === :gaussian_loconly_phylo_reml
    @test recovery.estimator === :guarded_ai_update_reml_optimizer_experiment
    @test recovery.design === :tiny_deterministic_recovery_grid
    @test recovery.claim_status === :simulation_diagnostic
    @test recovery.coverage_status === :not_evaluated
    @test !recovery.ai_reml_ready
    @test recovery.conditions.reps == 3
    @test recovery.conditions.G == 10
    @test recovery.conditions.n_per_species == 3
    @test recovery.n_reps == 3
    @test recovery.n_accepted == 3
    @test recovery.convergence_rate == 1.0
    @test recovery.boundary_counts.interior == 3
    @test all(r -> r.accepted && r.finite, recovery.records)
    @test all(r -> r.score_norm < 1e-3, recovery.records)
    @test isfinite(recovery.bias_sigma)
    @test isfinite(recovery.bias_sigma_phy)
    @test isfinite(recovery.rmse_sigma)
    @test isfinite(recovery.rmse_sigma_phy)
    @test isfinite(recovery.mcse_bias_sigma)
    @test isfinite(recovery.mcse_bias_sigma_phy)
    @test abs(recovery.bias_sigma) < 0.05
    @test abs(recovery.bias_sigma_phy) < 0.25

    condition_grid = DRM._loconly_reml_recovery_condition_grid_diagnostic(
        ; reps = 2, iterations = 30,
    )
    @test condition_grid.target === :gaussian_loconly_phylo_reml
    @test condition_grid.estimator === :guarded_ai_update_reml_optimizer_experiment
    @test condition_grid.design === :tiny_condition_recovery_grid
    @test condition_grid.claim_status === :simulation_diagnostic
    @test condition_grid.coverage_status === :not_evaluated
    @test !condition_grid.ai_reml_ready
    @test condition_grid.n_cells == 2
    @test length(condition_grid.rows) == 2
    @test condition_grid.min_convergence_rate == 1.0
    @test condition_grid.all_cells_accepted
    @test Set(r.cell for r in condition_grid.rows) ==
        Set((:baseline_interior, :higher_phylo_interior))
    @test all(r -> r.n_reps == 2 && r.n_accepted == 2, condition_grid.rows)
    @test all(r -> r.boundary_counts.interior == 2, condition_grid.rows)
    @test all(r -> isfinite(r.bias_sigma) && isfinite(r.bias_sigma_phy), condition_grid.rows)
    @test all(r -> r.diagnostic.claim_status === :simulation_diagnostic, condition_grid.rows)
end

@testset "Location-only Gaussian phylo: boundary diagnostics are finite or explicit" begin
    Random.seed!(20260622)
    G = 8
    species = repeat(1:G, inner = 2)
    n = length(species)
    x = range(-1.0, 1.0; length = n)
    X = hcat(ones(n), collect(x))

    phy_weak = random_balanced_tree(G; branch_length = 0.25)
    y_weak = X * [0.2, 0.1] .+ 0.4 .* randn(n)
    prob_weak = DRM.make_loc_problem(phy_weak, y_weak, X; species = species)
    comp_zero = DRM._loconly_reml_components(prob_weak, log(0.4), log(1e-8))
    trace_zero = DRM._loconly_takahashi_trace_diagnostic(prob_weak, log(0.4), log(1e-8))
    score_zero = DRM._loconly_reml_sparse_score_diagnostic(prob_weak, log(0.4), log(1e-8))
    boundary_zero = DRM._loconly_reml_boundary_status(prob_weak, log(0.4), log(1e-8))
    @test comp_zero.converged
    @test isfinite(comp_zero.nll)
    @test trace_zero.finite
    @test trace_zero.tr_QM >= 0
    @test trace_zero.tr_SMS >= 0
    @test score_zero.finite
    @test score_zero.max_absdiff_dense < 1e-8
    @test boundary_zero.boundary_status === :near_zero_variance

    phy_near = random_balanced_tree(G; branch_length = 1e-5)
    C_near = sigma_phy_dense(phy_near; σ²_phy = 1.0)
    u_near = 0.1 .* (cholesky(Symmetric(C_near)).L * randn(G))
    y_near = X * [0.2, 0.1] .+ u_near[species] .+ 0.4 .* randn(n)
    prob_near = DRM.make_loc_problem(phy_near, y_near, X; species = species)
    comp_near = DRM._loconly_reml_components(prob_near, log(0.4), log(0.1))
    trace_near = DRM._loconly_takahashi_trace_diagnostic(prob_near, log(0.4), log(0.1))
    @test comp_near.converged
    @test isfinite(comp_near.nll)
    @test trace_near.finite

    X_bad = hcat(ones(n), ones(n))
    prob_bad = DRM.make_loc_problem(phy_weak, y_weak, X_bad; species = species)
    comp_bad = DRM._loconly_reml_components(prob_bad, log(0.4), log(0.2))
    info_bad = DRM._loconly_ai_information_diagnostic(prob_bad, log(0.4), log(0.2))
    sparse_info_bad = DRM._loconly_reml_sparse_ai_information_diagnostic(prob_bad, log(0.4), log(0.2))
    score_bad = DRM._loconly_reml_sparse_score_diagnostic(prob_bad, log(0.4), log(0.2))
    ai_update_bad = DRM._loconly_reml_ai_update_optimizer_diagnostic(
        prob_bad; starts = [[log(0.4), log(0.2)]], iterations = 5,
    )
    boundary_bad = DRM._loconly_reml_boundary_status(prob_bad, log(0.4), log(0.2))
    boundary_invalid = DRM._loconly_reml_boundary_status(prob_bad, Inf, log(0.2))
    @test !comp_bad.converged
    @test comp_bad.nll == DRM._LOCONLY_PENALTY
    @test !info_bad.finite
    @test !sparse_info_bad.finite
    @test !score_bad.finite
    @test !ai_update_bad.finite
    @test !ai_update_bad.accepted
    @test ai_update_bad.n_starts == 1
    @test boundary_bad.boundary_status === :singular_fixed_effect_information
    @test boundary_invalid.boundary_status === :nonfinite_objective

    weak_probe = DRM._loconly_reml_weak_signal_recovery_probe(
        ; reps = 2, seed = 20260630, iterations = 25,
    )
    @test weak_probe.target === :gaussian_loconly_phylo_reml
    @test weak_probe.design === :weak_signal_boundary_probe
    @test weak_probe.expected_behavior === :boundary_states_allowed
    @test weak_probe.claim_status === :simulation_diagnostic
    @test weak_probe.coverage_status === :not_evaluated
    @test !weak_probe.ai_reml_ready
    @test weak_probe.diagnostic.n_reps == 2
    @test weak_probe.boundary_reps >= 1
    @test weak_probe.boundary_rate >= 0.5
    @test weak_probe.convergence_rate <= 1.0

    sim_status = DRM._loconly_reml_simulation_status()
    @test sim_status.target === :gaussian_loconly_phylo_reml
    @test sim_status.estimator === :guarded_ai_update_reml_optimizer_experiment
    @test sim_status.claim_status === :simulation_diagnostic
    @test sim_status.coverage_status === :not_evaluated
    @test !sim_status.ai_reml_ready
    @test sim_status.n_rows == 4
    @test length(sim_status.rows) == 4
    @test Tuple(r.row_id for r in sim_status.rows) == (
        :stable_recovery,
        :condition_grid,
        :weak_signal_boundary_probe,
        :larger_interior_stress,
    )
    schema = DRM._loconly_reml_simulation_status_schema()
    @test :expected_behavior in schema
    @test :failure_reason_counts in schema
    @test :runtime_budget_seconds in schema
    @test :seed_registry in schema
    @test all(r -> all(field -> field in propertynames(r), schema), sim_status.rows)
    @test all(r -> r.target === :gaussian_loconly_phylo_reml, sim_status.rows)
    @test all(r -> r.estimator === :guarded_ai_update_reml_optimizer_experiment, sim_status.rows)
    @test all(r -> r.claim_status === :simulation_diagnostic, sim_status.rows)
    @test all(r -> r.coverage_status === :not_evaluated, sim_status.rows)
    @test all(r -> r.expected_behavior in (
        :stable_interior_recovery,
        :row_separated_stable_recovery,
        :boundary_states_allowed,
        :stress_smoke,
    ), sim_status.rows)
    @test all(r -> r.n_reps >= 2, sim_status.rows)
    @test all(r -> r.n_accepted <= r.n_reps, sim_status.rows)
    @test all(r -> r.boundary_rate >= 0 && r.boundary_rate <= 1, sim_status.rows)
    @test all(r -> sum(values(r.failure_reason_counts)) <= r.n_reps, sim_status.rows)
    @test all(r -> r.mcse_status === :diagnostic_only, sim_status.rows)
    @test all(r -> r.runtime_seconds >= 0, sim_status.rows)
    @test all(r -> r.runtime_budget_seconds > 0, sim_status.rows)
    @test all(r -> !isempty(string(r.seed)), sim_status.rows)
    @test all(r -> r.seed_registry.deterministic, sim_status.rows)
    @test all(r -> !isempty(r.evidence), sim_status.rows)
    @test all(r -> r.next_gate in (
        :broader_recovery_grid,
        :broader_condition_grid,
        :boundary_diagnostics,
        :optional_runtime_stress,
    ), sim_status.rows)
    weak_row = only(filter(r -> r.row_id === :weak_signal_boundary_probe, sim_status.rows))
    @test weak_row.expected_behavior === :boundary_states_allowed
    @test weak_row.boundary_rate >= 0.5
    stress_row = only(filter(r -> r.row_id === :larger_interior_stress, sim_status.rows))
    @test stress_row.expected_behavior === :stress_smoke
    @test stress_row.n_reps == 2
    @test stress_row.n_accepted == 2

    validation = DRM._loconly_reml_validate_simulation_status(sim_status)
    @test validation.ok
    @test isempty(validation.errors)
    @test validation.required_fields == schema
    @test validation.row_order == Tuple(r.row_id for r in sim_status.rows)
    @test validation.coverage_status === :not_evaluated
    @test !validation.ai_reml_ready

    mktempdir() do dir
        path = joinpath(dir, "loconly-status.tsv")
        write_result = DRM._loconly_reml_write_simulation_status_tsv(path; status = sim_status)
        @test write_result.path == path
        @test write_result.n_rows == sim_status.n_rows
        @test write_result.schema == schema
        @test write_result.validation.ok
        lines = readlines(path)
        @test String.(split(lines[1], '\t')) == collect(string.(schema))
        @test length(lines) == sim_status.n_rows + 1
        @test first(split(lines[2], '\t')) == "stable_recovery"
    end

    medium_status = DRM._loconly_reml_simulation_status(
        ; include_medium_stress = true,
        medium_stress_reps = 1,
    )
    @test medium_status.n_rows == 5
    @test Tuple(r.row_id for r in medium_status.rows)[1:4] ==
        Tuple(r.row_id for r in sim_status.rows)
    medium_row = only(filter(r -> r.row_id === :medium_interior_stress,
                             medium_status.rows))
    @test medium_row.expected_behavior === :stress_smoke
    @test medium_row.n_reps == 1
    @test medium_row.runtime_budget_seconds == 15.0
    @test DRM._loconly_reml_validate_simulation_status(medium_status).ok

    broader = DRM._loconly_reml_broader_recovery_grid_diagnostic(
        ; reps = 1,
        iterations = 25,
    )
    @test broader.target === :gaussian_loconly_phylo_reml
    @test broader.design === :broader_recovery_grid
    @test broader.n_cells == 3
    @test broader.expected_behavior === :stable_or_stress_recovery
    @test broader.claim_status === :simulation_diagnostic
    @test broader.coverage_status === :not_evaluated
    @test !broader.ai_reml_ready
    @test Set(r.cell for r in broader.rows) == Set((
        :baseline_interior,
        :higher_phylo_interior,
        :medium_interior_stress,
    ))
    @test all(r -> r.n_reps == 1, broader.rows)

    weak_grid = DRM._loconly_reml_weak_signal_condition_grid_diagnostic(
        ; reps = 1,
        iterations = 20,
    )
    @test weak_grid.target === :gaussian_loconly_phylo_reml
    @test weak_grid.design === :weak_signal_condition_grid
    @test weak_grid.n_cells == 2
    @test weak_grid.expected_behavior === :boundary_states_allowed
    @test weak_grid.claim_status === :simulation_diagnostic
    @test weak_grid.coverage_status === :not_evaluated
    @test !weak_grid.ai_reml_ready
    @test Set(r.cell for r in weak_grid.rows) ==
        Set((:low_phylo_signal, :near_zero_phylo_signal))
    @test all(r -> r.diagnostic.coverage_status === :not_evaluated, weak_grid.rows)
end

@testset "Location-only Gaussian phylo: status schema and scaling smoke" begin
    status = DRM._loconly_reml_validation_status()
    @test status.target === :gaussian_loconly_phylo_reml
    @test status.estimator === :supplied_variance_reml
    @test status.source_status === :partial
    @test status.tests_status === :partial
    @test status.comparator_status === :dense_same_estimand_oracle
    @test status.optimizer_status === :experiment_only
    @test status.r_bridge_status === :planned
    @test status.claim_status === :internal_diagnostic
    @test status.q4_status === :excluded

    schema = DRM._loconly_reml_bridge_payload_schema()
    @test schema.target == "gaussian_loconly_phylo_reml"
    @test schema.estimator == "supplied_variance_reml"
    @test schema.effective_REML === true
    @test schema.trace_mode == "takahashi_selinv"
    @test schema.score_mode == "dense_or_sparse_woodbury_diagnostic"
    @test schema.information_mode == "ai_vs_observed_diagnostic"
    @test schema.claim_status == "internal_diagnostic"
    @test schema.r_bridge_status == "planned"
    @test "near_zero_variance" in schema.boundary_status_levels

    Random.seed!(20260623)
    elapsed = Float64[]
    for G in (8, 16, 32)
        phy = random_balanced_tree(G; branch_length = 0.2)
        species = collect(1:G)
        X = hcat(ones(G), range(-0.5, 0.5; length = G))
        y = X * [0.1, 0.3] .+ 0.35 .* randn(G)
        prob = DRM.make_loc_problem(phy, y, X; species = species)
        push!(elapsed, @elapsed begin
            comp = DRM._loconly_reml_components(prob, log(0.35), log(0.2))
            trace_diag = DRM._loconly_takahashi_trace_diagnostic(prob, log(0.35), log(0.2))
            pev_diag = DRM._loconly_takahashi_pev_diagnostic(prob, log(0.35), log(0.2))
            @test comp.converged
            @test isfinite(comp.nll)
            @test trace_diag.finite
            @test pev_diag.finite
            @test length(pev_diag.leaf_posterior_variance) == G
        end)
    end
    @test all(isfinite, elapsed)
    @test all(>=(0), elapsed)

    phy = random_balanced_tree(10; branch_length = 0.25)
    X1 = hcat(ones(10), range(-0.5, 0.5; length = 10))
    y1 = X1 * [0.1, 0.2]
    prob_single = DRM.make_loc_problem(phy, y1, X1; species = collect(1:10))
    species_double = repeat(1:10, inner = 2)
    X2 = X1[species_double, :]
    y2 = y1[species_double]
    prob_double = DRM.make_loc_problem(phy, y2, X2; species = species_double)
    pev_single = DRM._loconly_takahashi_pev_diagnostic(prob_single, log(0.4), log(0.3))
    pev_double = DRM._loconly_takahashi_pev_diagnostic(prob_double, log(0.4), log(0.3))
    @test pev_single.finite
    @test pev_double.finite
    @test all(pev_double.leaf_posterior_variance .<= pev_single.leaf_posterior_variance .+ 1e-12)
end
