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
        # `penalized_map` added by A4c: a penalized (MAP) fit reports credible-
        # interval-shaped SEs, and its stored UNPENALIZED gradient is non-zero at
        # the optimum by construction, so `ok` is not scored against it.
        @test keys(r) == (:converged, :max_abs_grad, :vcov_complete, :vcov_posdef,
                          :min_eigval, :cond, :penalized_map, :ok)
        @test r.vcov_complete isa Bool
        @test r.vcov_complete            # an ordinary fixed-effect fit has a full vcov
        @test r.converged isa Bool
        @test r.penalized_map isa Bool
        @test !r.penalized_map          # an ordinary ML fit is not penalized
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

    @testset "a partial (NaN) covariance is REPORTED, not raised" begin
        # Regression. `check_drm` used to throw `ArgumentError: matrix contains Infs
        # or NaNs` from `isposdef`/`eigvals` for any fit whose vcov held a NaN — and
        # that is the NORMAL state of the sparse phylo route, which computes the
        # fixed-effect block and leaves the variance-component block NaN. So running
        # the documented health check on a perfectly good phylo fit raised an
        # exception instead of returning a report, which is backwards for a
        # diagnostic whose entire purpose is to report trouble.
        rng = MersenneTwister(5); G = 16; m = 5
        phy = random_balanced_tree(G; branch_length = 0.3)
        C = sigma_phy_dense(phy; σ²_phy = 1.0)
        d = sqrt.(diag(C)); K = C ./ (d * d')
        n = G * m; species = repeat(1:G, inner = m); x = randn(rng, n)
        u = 0.9 .* (cholesky(Symmetric(K)).L * randn(rng, G))
        y = 0.2 .+ 0.5 .* x .+ u[species] .+ 0.4 .* randn(rng, n)
        fit = drm(bf(@formula(y ~ x + phylo(1 | species)), @formula(sigma ~ 1)),
                  Gaussian(); data = (; y, x, species), tree = phy)

        # the precondition this test is about — if the route ever starts returning a
        # complete covariance, this test is no longer exercising the bug
        @test any(isnan, fit.vcov)

        r = check_drm(fit)                      # must not throw
        @test r isa NamedTuple
        @test !r.vcov_complete
        @test !r.vcov_posdef
        @test isnan(r.min_eigval)
        @test r.cond == Inf
        @test !r.ok                             # honestly not-ok, rather than an exception
        @test r.converged                       # ...but the FIT itself converged
    end
end
