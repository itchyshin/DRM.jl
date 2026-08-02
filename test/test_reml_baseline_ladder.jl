using Test

include(joinpath(@__DIR__, "..", "bench", "reml_baseline_ladder.jl"))

@testset "REML baseline ladder report contract (#291)" begin
    metadata = reml_baseline_ladder_metadata()
    @test all(name -> hasproperty(metadata, name),
              (:sha, :dirty, :julia_version, :threads, :blas))
    @test metadata.threads >= 1
    @test !isempty(metadata.julia_version)
    @test !isempty(metadata.blas)

    record = (
        method = :REML,
        seconds = 1.25,
        converged = true,
        objective = (reported_loglik = -10.0, ml_loglik = -9.5, reml_loglik = -10.0),
        estimates = (theta = [0.1, 0.2], sigma_a_diagonal = [0.3, 0.4, 0.5, 0.6]),
        interval_status = :not_evaluated,
    )
    report = (; metadata..., fixture = (p = 8, nrep = 3, seed = 291), fits = [record])
    @test all(name -> hasproperty(report, name), REML_BASELINE_LADDER_REPORT_FIELDS)
    @test all(name -> hasproperty(only(report.fits), name), REML_BASELINE_LADDER_FIT_FIELDS)
    markdown = reml_baseline_ladder_markdown(report)
    @test occursin("SHA:", markdown)
    @test occursin("Dirty tracked tree:", markdown)
    @test occursin("Julia:", markdown)
    @test occursin("Threads:", markdown)
    @test occursin("BLAS:", markdown)
    @test occursin("interval_status=not_evaluated", markdown)
    @test occursin("sigma_a_diagonal=", markdown)
end
