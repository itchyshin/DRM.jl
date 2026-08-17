# test_reml_ordinary_ranef.jl — TDD S1 for #439 (ordinary Gaussian mean (1 | g) REML).
#
# Standalone; not in test/runtests.jl this PR (Option A include waits on #423+#428).
# Worked example (after S2 lands):
#
#   using DRM
#   G, m = 12, 4; n = G * m
#   g = repeat(1:G, inner = m); x = randn(n)
#   y = 0.5 .+ 0.3 .* x .+ randn(G)[g] .+ 0.6 .* randn(n)
#   data = (; y, x, g)
#   fit = drm(bf(@formula(y ~ 1 + x + (1 | g)), @formula(sigma ~ 1)),
#             Gaussian(); data, method = :REML)
#   estimation_method(fit) === :REML
#
# Fence: σ-RE, random slopes, multi-ranef, non-Gaussian REML, q4 are out of scope.
# ML remains the default. Not a drmTMB numeric-parity fixture.
using DRM
using Test, Random

@testset "REML ordinary Gaussian mean (1 | g) — #439" begin
    Random.seed!(20260817)
    G = 12; m = 4; n = G * m
    g = repeat(1:G, inner = m)
    x = randn(n)
    b = 0.8 .* randn(G)
    y = 0.4 .+ 0.5 .* x .+ b[g] .+ 0.6 .* randn(n)
    data = (; y, x, g)
    fμ = @formula(y ~ 1 + x + (1 | g))
    fσ = @formula(sigma ~ 1)

    @testset "method omitted ≡ :ML (default unchanged)" begin
        f_default = drm(bf(fμ, fσ), Gaussian(); data)
        f_ml      = drm(bf(fμ, fσ), Gaussian(); data, method = :ML)
        @test coef(f_default) == coef(f_ml)
        @test loglik(f_default) == loglik(f_ml)
        @test estimation_method(f_default) === :ML
        @test isnan(reml_loglik(f_default))
        @test ml_loglik(f_default) == loglik(f_default)
    end

    # S1 red: method = :REML currently throws at gaussian_core.jl:413-423.
    # Catch so this is a Fail (not an Error); after S2 the else-branch is the gate.
    freml = nothing
    reml_err = nothing
    try
        freml = drm(bf(fμ, fσ), Gaussian(); data, method = :REML)
    catch e
        reml_err = e
    end

    @testset "method = :REML fits Gaussian mean (1 | g)" begin
        @test reml_err === nothing
        if reml_err !== nothing
            @test reml_err isa ArgumentError
            @test occursin("method = :REML", sprint(showerror, reml_err))
        else
            @test estimation_method(freml) === :REML
            @test isfinite(reml_loglik(freml))
            @test loglik(freml) == reml_loglik(freml)
            @test isfinite(ml_loglik(freml))
            @test freml.converged
        end
    end

    @testset "σ_b²_REML ≥ σ_b²_ML (skip while REML still throws)" begin
        if reml_err !== nothing
            @test_skip "σ_b²_REML ≥ σ_b²_ML — waiting for S2 Woodbury PT"
        else
            fml = drm(bf(fμ, fσ), Gaussian(); data, method = :ML)
            σb²_ml   = re_sd(fml)[:g]^2
            σb²_reml = re_sd(freml)[:g]^2
            @test σb²_reml ≥ σb²_ml - 1e-12
            σ_ml   = exp(coef(fml,   :sigma)[1])
            σ_reml = exp(coef(freml, :sigma)[1])
            @test σ_reml ≥ σ_ml - 1e-12
        end
    end

    @testset "σ-RE and random slopes still rejected under REML" begin
        @test_throws ArgumentError drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1 + (1 | g))),
                                       Gaussian(); data, method = :REML)
        @test_throws ArgumentError drm(bf(@formula(y ~ 1 + x + (0 + x | g)), @formula(sigma ~ 1)),
                                       Gaussian(); data, method = :REML)
    end
end
