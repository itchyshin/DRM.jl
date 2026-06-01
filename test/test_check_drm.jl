# check_drm(fit): post-fit convergence / identifiability diagnostics,
# mirroring drmTMB's check_drm().
using DRM
using Test, Random

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
end
