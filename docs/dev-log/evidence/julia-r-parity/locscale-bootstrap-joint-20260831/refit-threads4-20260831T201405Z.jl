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


@assert Threads.nthreads() == 4 && BLAS.get_num_threads() == 1
@testset "coupled Gamma public bootstrap B2" begin
    fit = _locscale_profile_threads_fixture()
    @test is_converged(fit)
    obj = fit.nll
    data = (; y = copy(obj.y), x = copy(obj.Xμ[:,2]), species = copy(obj.gidx))
    for threaded in (false, true)
        println("START_B2 threads=",threaded); flush(stdout)
        result = bootstrap_result(fit; data, B=2, rng=MersenneTwister(4001),
            threads=threaded, failures=:skip, check_converged=true)
        println("B2_RESULT ", repr(result)); flush(stdout)
        @test (result.attempted,result.used,result.failed)==(2,2,0)
        @test result.threaded == threaded
        if !threaded
            global serial_result = result
        else
            @test result.seeds == serial_result.seeds
            @test result.failures == serial_result.failures
            @test result.summary == serial_result.summary
        end
    end
end
println("LOCSCALE_BOOTSTRAP_REFIT_B2_PASS")
