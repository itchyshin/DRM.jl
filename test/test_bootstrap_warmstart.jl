# Warm-started parametric bootstrap (design 179 Stage B). The warm path reuses the
# fitted optimum θ̂ as the optimiser start for every replicate refit, so each refit
# reaches the same MLE in fewer iterations — the repeated-re-optimisation workload
# native TMB cannot make cheap. Correctness gate: on identical seeds the warm and
# cold bootstraps must return matching summaries — the replicate-derived quantities
# (std_error / lower / upper) agree to optimiser tolerance (~1e-7, not bit-for-bit,
# since LBFGS terminates at a slightly different point from each start). The
# `estimate` field is the ORIGINAL fit's coefficient (independent of the refits), so
# it is exactly equal — a consistency check, not parity evidence. Currently
# implemented for the fixed-effect Gaussian location–scale cell; richer fits are
# rejected with a clear error.
using DRM
using Test, Random

@testset "Warm-start bootstrap — fixed-effect Gaussian location–scale" begin
    Random.seed!(424242)
    n = 220
    x = randn(n)
    g = randn(n)
    βμ = [0.5, 0.4]
    βσ = [-0.3, 0.25]
    μ = βμ[1] .+ βμ[2] .* x
    σ = exp.(βσ[1] .+ βσ[2] .* g)
    y = μ .+ σ .* randn(n)
    dat = (; y, x, g)
    form = bf(@formula(y ~ x), @formula(sigma ~ g))
    fit = drm(form, Gaussian(); data = dat)

    @testset "warm == cold (parity gate)" begin
        cold = bootstrap_result(fit; data = dat, B = 80, rng = MersenneTwister(7))
        warm = bootstrap_result(fit; data = dat, B = 80, rng = MersenneTwister(7),
                                warmstart = true)
        @test warm.seeds == cold.seeds                 # identical replicate data
        @test warm.attempted == warm.used == 80
        @test warm.failed == 0
        @test length(warm.summary) == length(cold.summary) == length(coef(fit))
        for (rw, rc) in zip(warm.summary, cold.summary)
            @test rw.param == rc.param && rw.coef == rc.coef
            @test isapprox(rw.estimate, rc.estimate; atol = 1e-10)
            @test isapprox(rw.std_error, rc.std_error; atol = 1e-7, rtol = 1e-7)
            @test isapprox(rw.lower, rc.lower; atol = 1e-7, rtol = 1e-7)
            @test isapprox(rw.upper, rc.upper; atol = 1e-7, rtol = 1e-7)
        end
    end

    @testset "bootstrap_ci / bootstrap_summary expose warmstart" begin
        cic = bootstrap_ci(fit; data = dat, B = 50, rng = MersenneTwister(11))
        ciw = bootstrap_ci(fit; data = dat, B = 50, rng = MersenneTwister(11),
                           warmstart = true)
        @test length(ciw) == length(cic)
        for (rw, rc) in zip(ciw, cic)
            @test rw.coef == rc.coef
            @test isapprox(rw.lower, rc.lower; atol = 1e-7, rtol = 1e-7)
            @test isapprox(rw.upper, rc.upper; atol = 1e-7, rtol = 1e-7)
        end
        sw = bootstrap_summary(fit; data = dat, B = 50, rng = MersenneTwister(11),
                               warmstart = true)
        sc = bootstrap_summary(fit; data = dat, B = 50, rng = MersenneTwister(11))
        # estimate = original-fit coefficient (refit-independent) -> exactly equal;
        # std_error / lower / upper are replicate-derived -> agree to optimiser
        # tolerance (~1e-7), since LBFGS stops at a slightly different point per start.
        for (rw, rc) in zip(sw, sc)
            @test rw.coef == rc.coef
            @test rw.estimate == rc.estimate          # refit-independent consistency
            @test isapprox(rw.std_error, rc.std_error; atol = 1e-7, rtol = 1e-7)
            @test isapprox(rw.lower, rc.lower; atol = 1e-7, rtol = 1e-7)
            @test isapprox(rw.upper, rc.upper; atol = 1e-7, rtol = 1e-7)
        end
    end

    @testset "warmstart rejects unsupported (random-effect) fits" begin
        gf = string.(repeat(1:22, inner = 10))
        yr = μ .+ σ .* randn(n)
        datr = (; y = yr, x, g, grp = gf)
        fitr = drm(bf(@formula(y ~ x + (1 | grp)), @formula(sigma ~ g)),
                   Gaussian(); data = datr)
        @test_throws ArgumentError bootstrap_result(fitr; data = datr, B = 5,
                                                    warmstart = true)
    end
end
