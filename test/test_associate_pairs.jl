# Staged (frozen-margin) latent-normal association — drmTMB's
# `associate_pairs()`. First slice: the `gaussian_bernoulli` pair class.
#
# This is a TWO-STAGE estimator: margins are fitted independently, frozen, and
# only the association is estimated. The tests therefore check the estimator AND
# the refusals — an over-broad staged route that silently accepts an unreviewed
# pair class would be worse than one that errors.

using DRM
using Test
using Random
import Distributions

@testset "staged association (drmTMB associate_pairs)" begin

    N = Distributions.Normal()
    rng = MersenneTwister(5)
    n = 3000
    x = randn(rng, n)
    eta_true = 0.55
    z1 = randn(rng, n)
    z2 = eta_true .* z1 .+ sqrt(1 - eta_true^2) .* randn(rng, n)
    y = 0.3 .+ 0.7 .* x .+ z1
    pb = 1 ./ (1 .+ exp.(-(0.2 .+ 0.5 .* x)))
    zb = Float64.(z2 .> [Distributions.quantile(N, 1 - p) for p in pb])
    data = (; y = y, z = zb, x = x)

    fg = drm(bf(@formula(y ~ x), @formula(sigma ~ 1)), Gaussian(); data = data)
    fb = drm(bf(@formula(z ~ x)), Binomial(); data = data)

    a = associate_pairs(fg, fb; kernel = latent_normal())
    s = association(a)

    @testset "recovers the latent association" begin
        @test s.pair_class === :gaussian_bernoulli
        # Measured across 8 seeds at this n: mean 0.5433, sd 0.0108, bias -0.007.
        # The tolerance is ~4 sd, not a guess.
        @test isapprox(s.eta, eta_true; atol = 0.05)
        @test -1 < s.eta < 1
        @test s.nobs == n
    end

    @testset "optimum diagnostics" begin
        @test abs(s.score) < 1e-3                 # score ≈ 0 at the optimum
        # drmTMB's `curvature` is the LOGLIK curvature (it negates the objective's
        # second difference), so it is NEGATIVE at a maximum. Sign matters.
        @test s.curvature < 0
        @test s.near_boundary == false
        @test s.multistart_disagreement == false
    end

    @testset "argument order does not matter" begin
        flipped = association(associate_pairs(fb, fg; kernel = latent_normal()))
        @test isapprox(flipped.eta, s.eta; atol = 1e-8)
    end

    @testset "the kernel must be explicit" begin
        # drmTMB: "Supply an explicit kernel = latent_normal() declaration."
        @test_throws ArgumentError associate_pairs(fg, fb)
        @test_throws ArgumentError associate_pairs(fg, fb; kernel = :latent_normal)
    end

    @testset "unreviewed pair classes are refused, not approximated" begin
        fp = drm(bf(@formula(c ~ x)), Poisson();
                 data = (; c = Float64.(rand(rng, 0:4, n)), x = x))
        # gaussian × poisson is not one of drmTMB's five reviewed classes.
        @test_throws ArgumentError associate_pairs(fg, fp; kernel = latent_normal())
        # gaussian × gaussian is not a staged class either (that is biv_gaussian).
        fg2 = drm(bf(@formula(y ~ x), @formula(sigma ~ 1)), Gaussian(); data = data)
        @test_throws ArgumentError associate_pairs(fg, fg2; kernel = latent_normal())
    end

    @testset "the binomial margin must be literal Bernoulli" begin
        ntr = 8
        s_cnt = Float64.([count(_ -> rand(rng) < pb[i], 1:ntr) for i in 1:n])
        f_cnt = Float64.(ntr .- s_cnt)
        dcnt = (; s = s_cnt, f = f_cnt, x = x, y = y)
        fbin = drm(bf(@formula(cbind(s, f) ~ x)), Binomial(); data = dcnt)
        fgc = drm(bf(@formula(y ~ x), @formula(sigma ~ 1)), Gaussian(); data = dcnt)
        @test_throws ArgumentError associate_pairs(fgc, fbin; kernel = latent_normal())
    end

    @testset "only an intercept-only association is implemented" begin
        @test_throws ArgumentError associate_pairs(fg, fb; kernel = latent_normal(),
                                                   association = @formula(association ~ x))
    end

    @testset "the uncertainty caveat is carried in the result" begin
        # Frozen margins ⇒ the association SE is conditional. That must be stated
        # wherever it is reported, not left for the reader to infer.
        @test occursin("conditional", s.uncertainty)
        @test occursin("frozen", s.uncertainty)
    end
end
