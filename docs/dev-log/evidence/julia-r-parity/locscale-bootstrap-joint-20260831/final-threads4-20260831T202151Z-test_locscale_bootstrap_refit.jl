# Retained failing public Gamma bootstrap fixture. Two identical-seed serial
# and threaded refits must meet the original convergence criterion. B=2 is an
# integration regression only, never evidence of interval coverage.
using DRM
using Test, Random, LinearAlgebra
import Distributions

function _locscale_bootstrap_refit_fixture()
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


@testset "coupled Gamma public bootstrap B2" begin
    fit = _locscale_bootstrap_refit_fixture()
    @test is_converged(fit)
    obj = fit.nll
    data = (; y = copy(obj.y), x = copy(obj.Xμ[:,2]), species = copy(obj.gidx))
    serial_result = nothing
    for threaded in (false, true)
        println("START_B2 threads=",threaded); flush(stdout)
        result = bootstrap_result(fit; data, B=2, rng=MersenneTwister(4001),
            threads=threaded, failures=:skip, check_converged=true)
        println("B2_COUNTS threads=",threaded," attempted=",result.attempted," used=",result.used," failures=",repr(result.failures)); flush(stdout)
        @test (result.attempted,result.used,result.failed)==(2,2,0)
        @test result.threaded == (threaded && Threads.nthreads() > 1)
        if !threaded
            serial_result = result
        else
            @test result.seeds == serial_result.seeds
            @test result.failures == serial_result.failures
            @test isequal(result.summary, serial_result.summary)
        end
    end
    # Check the repaired replicate independently of the returned convergence
    # flag. Merely relabelling the previous failed fit as converged must fail.
    seed = first(rand(MersenneTwister(4001), UInt, 2))
    yb = DRM._marginal_simulator(fit, data)(MersenneTwister(seed))
    replay = drm(fit.formula, fit.family; data=DRM._bootstrap_data(fit.formula, data, yb))
    p = size(obj.Xμ, 2) + size(obj.Xψ, 2)
    theta = vcat(replay.theta[1:p], replay.theta[p+1], replay.theta[p+3], replay.theta[p+2])
    @test maximum(abs, DRM._ls_objective_gradient(replay.nll, theta)) <= 1e-8
    previous_failed = [0.7100026355628111, 0.11333869814470285,
        1.1136994971048377, -9.904592396244107, -2.9795300738040686e-6,
        -10.214044558800888]
    @test maximum(abs, DRM._ls_objective_gradient(replay.nll, previous_failed)) > 1e-8
    @test replay.nll(theta) <= replay.nll(previous_failed) + 8eps(46.50801917858662)
end
