using DRM, Test

@testset "bridge exposes selected profile failure" begin
    row = (param=:mu, coef="x", estimate=0.0, lower=-Inf, upper=1.0)
    good = (param=:mu, coef="y", lower_endpoint_failed=false, upper_endpoint_failed=false,
        lower_unbounded=false, upper_unbounded=false)
    bad = (param=:mu, coef="x", lower_endpoint_failed=true, upper_endpoint_failed=false,
        lower_unbounded=false, upper_unbounded=false)
    result = (stats=[bad, good], failed=1)
    outcome = DRM._bridge_profile_outcome(result, row)
    @test outcome.status == "profile_failed"
    @test occursin("failed", outcome.message)
    detailed = merge(bad,(lower_nuisance_reason=:not_converged,
        lower_nuisance_method=:lbfgs_finite,lower_nuisance_fallback=false))
    explanation = DRM._bridge_profile_outcome((stats=[detailed],failed=1),row).message
    @test occursin("not_converged",explanation)
    @test occursin("lbfgs_finite",explanation)
    @test occursin("fallback=false",explanation)
    @test DRM._bridge_profile_outcome(result, merge(row,(coef="y",))).status == "profile"
    # No-crossing within the searched range is different from a failed nuisance solve.
    searched = merge(bad, (lower_endpoint_failed=false,lower_unbounded=true))
    outcome = DRM._bridge_profile_outcome((stats=[searched],failed=0), row)
    @test outcome.status == "profile"
    @test occursin("searched range",outcome.message)
    # A missing per-row diagnostic must not erase an aggregate failure.
    @test DRM._bridge_profile_outcome((stats=NamedTuple[], failed=1),row).status == "profile_failed"
    @test DRM._bridge_profile_outcome((stats=NamedTuple[], failed=0),row).status == "profile"
end
