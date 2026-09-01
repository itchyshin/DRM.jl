# Canonical location-scale profile jobs are independent across coefficients, but
# each coefficient retains its serial lower/upper warm-start chain.  This small
# public fit keeps the test below the slow full-vector profile fixture.
using DRM
using Test, Random, LinearAlgebra
import Distributions

function _locscale_profile_threads_fixture()
    Random.seed!(20_260_831)
    # Gamma has a smooth positive-response likelihood and the deliberately
    # separated fixed and group effects make both mean coefficients identifiable
    # in this compact profile fixture.
    G, m = 4, 8
    n = G * m
    species = repeat(1:G, inner=m)
    x = repeat(range(-1.0, 1.0; length=m), G)
    re_mu = 0.16 .* randn(G)
    re_sigma = 0.10 .* randn(G)
    eta = 0.70 .+ 0.55 .* x .+ re_mu[species]
    psi = 1.05 .+ re_sigma[species]
    y = [begin
        shape = exp(psi[i])
        mu = exp(eta[i])
        Float64(rand(Distributions.Gamma(shape, mu / shape)))
    end for i in 1:n]
    fit = drm(
        bf(
            @formula(y ~ x + (1 | profile_thread | species)),
            @formula(sigma ~ 1 + (1 | profile_thread | species)),
        ),
        Gamma();
        data=(; y, x, species),
    )
    @test fit.nll isa DRM.LocScaleObjective
    return fit
end

@testset "canonical location-scale profile coefficient threading" begin
    fit = _locscale_profile_threads_fixture()
    blas_before = BLAS.get_num_threads()

    # The serial and threaded calls repeat the same two profile intervals through
    # independent scheduling paths, guarding against shared warm starts or scratch
    # state.
    serial = profile_result(fit; parm=:mu, threads=false)
    threaded = profile_result(fit; parm=:mu, threads=true)
    @test BLAS.get_num_threads() == blas_before
    @test serial.threaded == false
    @test serial.worker_threads == 1
    @test serial.attempted == serial.used == 2
    @test threaded.attempted == threaded.used == 2
    @test all(r -> isfinite(r.lower) && isfinite(r.upper), serial.ci)
    @test reduce(vcat, ([r.lower r.upper] for r in threaded.ci)) ≈
          reduce(vcat, ([r.lower r.upper] for r in serial.ci)) rtol=1e-7 atol=1e-8
    @test [(s.lower_unbounded, s.upper_unbounded, s.lower_endpoint_failed,
            s.upper_endpoint_failed, s.lower_nuisance_reason, s.upper_nuisance_reason)
           for s in threaded.stats] ==
          [(s.lower_unbounded, s.upper_unbounded, s.lower_endpoint_failed,
            s.upper_endpoint_failed, s.lower_nuisance_reason, s.upper_nuisance_reason)
           for s in serial.stats]
    fallback_flags(result) = [
        (diag.lower.nuisance !== nothing && diag.lower.nuisance.fallback,
         diag.upper.nuisance !== nothing && diag.upper.nuisance.fallback)
        for diag in result.endpoint_diagnostics
    ]
    @test fallback_flags(threaded) == fallback_flags(serial)
    @test [(s.lower_nuisance_fallback, s.upper_nuisance_fallback)
           for s in serial.stats] == fallback_flags(serial)
    @test [(s.lower_nuisance_fallback, s.upper_nuisance_fallback)
           for s in threaded.stats] == fallback_flags(threaded)

    if Threads.nthreads() > 1
        @test threaded.threaded
        @test threaded.worker_threads == min(2, Threads.nthreads())
    else
        # A process without worker threads falls back to the serial route even
        # when the caller requests threading.
        @test threaded.threaded == false
        @test threaded.worker_threads == 1
    end

    # One selected mean slope. Endpoint arms stay
    # serial, so this call must not claim coefficient parallelism.
    one = profile_result(fit; parm=:mu => "x", threads=true)
    @test one.attempted == one.used == 1
    @test one.threaded == false
    @test one.worker_threads == 1
    @test isfinite(only(one.ci).lower) && isfinite(only(one.ci).upper)
    @test BLAS.get_num_threads() == blas_before
end
