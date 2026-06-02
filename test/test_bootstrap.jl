# Parametric bootstrap confidence intervals: simulate B replicates from the
# fitted model, refit each, take percentile intervals. Reuses simulate + drm.
using DRM
using Test, Random

@testset "Parametric bootstrap CI" begin
    Random.seed!(11)
    n = 500
    x = randn(n)
    βμ = [0.4, 0.7]
    y = βμ[1] .+ βμ[2] .* x .+ exp.(-0.3 .+ 0.2 .* x) .* randn(n)
    form = bf(@formula(y ~ x), @formula(sigma ~ x))
    fit = drm(form, Gaussian(); data = (; y, x))

    bci = bootstrap_ci(form, Gaussian(); data = (; y, x), B = 300, level = 0.95, rng = MersenneTwister(1))
    @test length(bci) == 4
    @test all(r.lower < r.upper for r in bci)

    # the bootstrap intervals bracket the point estimates
    pe = coef(fit, :mu)
    mu = filter(r -> r.param === :mu, bci)
    @test mu[1].lower ≤ pe[1] ≤ mu[1].upper
    @test mu[2].lower ≤ pe[2] ≤ mu[2].upper

    # and the true slope is covered at this n
    @test mu[2].lower ≤ 0.7 ≤ mu[2].upper

    bs = bootstrap_summary(form, Gaussian(); data = (; y, x), B = 40,
        level = 0.95, rng = MersenneTwister(2))
    bci2 = bootstrap_ci(form, Gaussian(); data = (; y, x), B = 40,
        level = 0.95, rng = MersenneTwister(2))
    bs_fit = bootstrap_summary(fit; data = (; y, x), B = 40,
        level = 0.95, rng = MersenneTwister(2))
    bci_fit = bootstrap_ci(fit; data = (; y, x), B = 40,
        level = 0.95, rng = MersenneTwister(2))
    @test length(bs) == length(bci2) == 4
    @test all(r.std_error > 0 for r in bs)
    @test [(r.param, r.coef, r.estimate, r.lower, r.upper) for r in bs] ==
          [(r.param, r.coef, r.estimate, r.lower, r.upper) for r in bci2]
    @test bs_fit == bs
    @test bci_fit == bci2

    br = bootstrap_result(form, Gaussian(); data = (; y, x), B = 20,
        level = 0.95, rng = MersenneTwister(3))
    br_fit = bootstrap_result(fit; data = (; y, x), B = 20,
        level = 0.95, rng = MersenneTwister(3))
    bs2 = bootstrap_summary(form, Gaussian(); data = (; y, x), B = 20,
        level = 0.95, rng = MersenneTwister(3))
    @test br.attempted == 20
    @test br.used == 20
    @test br.failed == 0
    @test isempty(br.failures)
    @test length(br.seeds) == 20
    @test br.threaded == false
    @test br.julia_threads == Threads.nthreads()
    @test br.blas_threads >= 1
    @test br.elapsed >= 0
    @test br.summary == bs2
    @test br_fit.summary == br.summary
    @test br_fit.seeds == br.seeds
    @test br_fit.attempted == br.attempted
    @test br_fit.used == br.used
    @test br_fit.failed == br.failed
    @test_throws ArgumentError bootstrap_result(form, Gaussian(); data = (; y, x),
        B = 2, failures = :warn)
    @test_throws ArgumentError bootstrap_result(DRM._withformula(fit, nothing);
        data = (; y, x), B = 2)

    fit0 = drm(form, Gaussian(); data = (; y, x))
    calls = Ref(0)
    function forced_refit(datab)
        calls[] += 1
        calls[] == 2 && error("forced refit failure")
        return drm(form, Gaussian(); data = datab)
    end
    forced = DRM._bootstrap_result(fit0, form, (; y, x), 5, 0.95,
        MersenneTwister(4), false, forced_refit; failures = :skip)
    @test forced.attempted == 5
    @test forced.used == 4
    @test forced.failed == 1
    @test forced.failures[1].replicate == 2
    @test occursin("forced refit failure", forced.failures[1].message)
    @test length(forced.summary) == length(bs)

    calls[] = 0
    @test_throws ErrorException DRM._bootstrap_result(fit0, form, (; y, x), 5,
        0.95, MersenneTwister(4), false, forced_refit; failures = :error)
end
