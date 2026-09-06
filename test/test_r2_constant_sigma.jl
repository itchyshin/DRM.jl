# test_r2_constant_sigma.jl — R² where it means one thing, and refusals elsewhere.
#
# The value test is a CROSS-CHECK against OLS computed from first principles in
# this file, not against a number copied from a previous run: on a constant-σ
# Gaussian fit, 1 - RSS/TSS must equal what `lm()` reports for the same mean model.
#
# The refusal tests are the point of the function. Each one is a RED CONTROL for a
# denominator that would otherwise be picked silently.
using DRM, Test, Random

@testset "r2_constant_sigma" begin
    @testset "constant σ: equals the OLS R² exactly" begin
        Random.seed!(20260906)
        n = 300
        x = randn(n)
        y = 1.0 .+ 2.0 .* x .+ 1.5 .* randn(n)
        fit = drm(bf(@formula(y ~ x), @formula(sigma ~ 1)), Gaussian(); data = (; y, x))
        r = r2_constant_sigma(fit)

        X = hcat(ones(n), x)
        b = X \ y
        ols = 1 - sum(abs2, y .- X * b) / sum(abs2, y .- sum(y) / n)

        @test isfinite(r)
        @test 0 < r < 1
        @test r ≈ ols atol = 1e-12          # the same quantity, not merely close
    end

    @testset "REFUSES a modelled σ, naming the offending term" begin
        Random.seed!(20260906)
        n = 400
        x = randn(n)
        sex = rand(["female", "male"], n)
        sd = [s == "male" ? 1.6 : 0.6 for s in sex]
        y = 1.0 .+ 2.0 .* x .+ sd .* randn(n)
        fit = drm(bf(@formula(y ~ x), @formula(sigma ~ sex)), Gaussian(); data = (; y, x, sex))
        @test_throws ArgumentError r2_constant_sigma(fit)
        msg = try
            r2_constant_sigma(fit)
        catch e
            sprint(showerror, e)
        end
        @test occursin("MODELLED", msg)
        @test occursin("sex: male", msg)     # names WHICH term, not just "some term"
        @test occursin("sigma ~ 1", msg)     # says what to do instead
    end

    @testset "REFUSES random effects (marginal vs conditional is a different question)" begin
        Random.seed!(3)
        G = 30; nper = 10; n = G * nper
        g = repeat(1:G, inner = nper)
        x = randn(n)
        b = 0.7 .* randn(G)
        y = 1.0 .+ 0.5 .* x .+ b[g] .+ 0.4 .* randn(n)
        fit = drm(bf(@formula(y ~ x + (1 | g))), Gaussian(); data = (; y, x, g))
        @test_throws ArgumentError r2_constant_sigma(fit)
        msg = try
            r2_constant_sigma(fit)
        catch e
            sprint(showerror, e)
        end
        @test occursin("MARGINAL", msg) && occursin("CONDITIONAL", msg)
    end

    @testset "REFUSES a non-Gaussian family" begin
        Random.seed!(11)
        n = 200; x = randn(n)
        yc = rand(0:5, n)
        fit = drm(bf(@formula(yc ~ x)), Poisson(); data = (; yc, x))
        @test_throws ArgumentError r2_constant_sigma(fit)
    end

    @testset "REFUSES a mean model with no intercept" begin
        Random.seed!(5)
        n = 200; x = randn(n)
        y = 2.0 .* x .+ randn(n)
        fit = drm(bf(@formula(y ~ 0 + x), @formula(sigma ~ 1)), Gaussian(); data = (; y, x))
        @test_throws ArgumentError r2_constant_sigma(fit)
    end
end
