using Test

include(joinpath(@__DIR__, "..", "bench", "reml_baseline_ladder.jl"))

@testset "REML baseline ladder report contract (#291)" begin
    metadata = reml_baseline_ladder_metadata()
    @test all(name -> hasproperty(metadata, name),
              (:sha, :dirty, :julia_version, :threads, :blas))
    @test metadata.threads >= 1
    @test !isempty(metadata.julia_version)
    @test !isempty(metadata.blas)

    @test REML_BASELINE_LADDER_INTERMEDIATE_FIXTURE == (p = 16, nrep = 3, seed = 291)
    intermediate = _reml_baseline_ladder_fixture(; REML_BASELINE_LADDER_INTERMEDIATE_FIXTURE...)
    @test length(intermediate.data.y1) == 48
    @test length(intermediate.phy.leaf_names) == 16

    accounting = reml_baseline_q4_structural_accounting()
    @test accounting.n_outer_phi == 11
    @test accounting.structural_evals_per_gradient_request == 23
    @test accounting.source === :central_fd_route_upper_bound

    record = (
        method = :REML,
        seconds = 1.25,
        converged = true,
        objective = (reported_loglik = -10.0, ml_loglik = -9.5, reml_loglik = -10.0),
        estimates = (theta = [0.1, 0.2], sigma_a_diagonal = [0.3, 0.4, 0.5, 0.6]),
        interval_status = :not_evaluated,
        timing_class = :warm_timed,
        fit_order = 3,
    )
    report = (;
        metadata...,
        fixture = (p = 8, nrep = 3, seed = 291),
        protocol = :warm_bidirectional,
        accounting,
        evidence_class = :warm_comparable,
        fits = [record],
    )
    @test all(name -> hasproperty(report, name), REML_BASELINE_LADDER_REPORT_FIELDS)
    @test all(name -> hasproperty(only(report.fits), name), REML_BASELINE_LADDER_FIT_FIELDS)
    markdown = reml_baseline_ladder_markdown(report)
    @test occursin("SHA:", markdown)
    @test occursin("Dirty tracked tree:", markdown)
    @test occursin("Julia:", markdown)
    @test occursin("Threads:", markdown)
    @test occursin("BLAS:", markdown)
    @test occursin("Protocol: `warm_bidirectional`", markdown)
    @test occursin("Evidence class: `warm_comparable`", markdown)
    @test occursin("n_outer_phi: `11`", markdown)
    @test occursin("structural_evals_per_gradient_request: `23`", markdown)
    @test occursin("timing_class=warm_timed", markdown)
    @test occursin("interval_status=not_evaluated", markdown)
    @test occursin("sigma_a_diagonal=", markdown)
    @test occursin("not a public speed headline", markdown)

    cold = (;
        metadata...,
        fixture = (p = 8, nrep = 3, seed = 291),
        protocol = :cold_ml_first,
        accounting,
        evidence_class = :diagnostic_only,
        fits = [(; record..., timing_class = :cold_includes_compile, fit_order = 1)],
    )
    cold_md = reml_baseline_ladder_markdown(cold)
    @test occursin("diagnostic only", cold_md)
end
