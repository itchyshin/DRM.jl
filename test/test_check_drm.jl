# check_drm(fit): post-fit convergence / identifiability diagnostics,
# mirroring drmTMB's check_drm().
using DRM
using Test, Random, LinearAlgebra

@testset "check_drm() — convergence / identifiability report" begin
    @testset "well-identified model → ok" begin
        Random.seed!(20260601)
        n = 500; x = randn(n); z = randn(n)
        y = 0.4 .+ 0.8 .* x .- 0.5 .* z .+ 0.5 .* randn(n)
        fit = drm(bf(@formula(y ~ x + z), @formula(sigma ~ 1)), Gaussian(); data = (; y, x, z))
        r = check_drm(fit)
        @test r.converged
        @test r.vcov_posdef
        @test r.max_abs_grad < 1e-2          # near a clean interior optimum
        @test r.min_eigval > 0
        @test isfinite(r.cond)
        @test r.ok
    end

    @testset "report has the documented fields and types" begin
        Random.seed!(20260602)
        n = 300; x = randn(n)
        y = 1.0 .+ 0.5 .* x .+ 0.6 .* randn(n)
        fit = drm(bf(@formula(y ~ x), @formula(sigma ~ x)), Gaussian(); data = (; y, x))
        r = check_drm(fit)
        @test r isa NamedTuple
        @test keys(r) == (:converged, :max_abs_grad, :vcov_posdef, :min_eigval, :cond, :ok)
        @test r.converged isa Bool
        @test r.vcov_posdef isa Bool
        @test r.ok isa Bool
        @test r.max_abs_grad isa Float64
    end

    @testset "stored objective gradient is used when available" begin
        blocks = [:mu => 1:2]
        coefnames = [:mu => ["(Intercept)", "x"]]
        theta = [0.0, 0.0]
        V = Matrix{Float64}(I, 2, 2)
        empty = Dict{Symbol,Vector{Float64}}()
        nll(_) = error("check_drm should use the stored gradient")
        nllgrad!(g, _) = (fill!(g, 0.0); g)
        base = DRM.DrmFit(Gaussian(), blocks, coefnames, theta, V, -1.0, 2, true,
                          empty, empty, empty)
        fit = DRM._withnll(base, nll, nllgrad!)

        r = check_drm(fit)
        @test r.max_abs_grad == 0.0
        @test r.ok
    end
end
