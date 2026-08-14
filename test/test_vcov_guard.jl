# Guarded Hessian→covariance step (`src/vcov_guard.jl`).
#
# Regression for the 2026-08-14 CI failure: `anchor (c)` in test_variational.jl
# threw SingularException(3) on Julia 1.10.11 and passed on 1.10.0 / 1.11 with
# the same seeded data. The NB2 fit sits at r → ∞, so the σ coordinate is
# unidentified and the Hessian is singular by construction. The outcome must now
# be the same on every platform: a warning plus a pseudo-inverse, never a crash
# and never a silent finite-but-meaningless inverse.

using DRM
using Test
using Random
using LinearAlgebra
import Distributions

const DVG = DRM

@testset "vcov guard (boundary-singular Hessian)" begin

    @testset "well-conditioned Hessian inverts exactly" begin
        H = [4.0 1.0; 1.0 3.0]
        V = DVG._vcov_from_hessian(H)
        @test V ≈ inv(H)
        @test issymmetric(V)
    end

    @testset "singular Hessian warns and pseudo-inverts instead of throwing" begin
        # Third coordinate flat — the shape seen at an NB2 size boundary.
        H = [39.8 -14.5 0.0 3.8
             -14.5 85.6 0.0 0.4
             0.0 0.0 0.0 0.0
             3.8 0.4 0.0 12.1]
        V = @test_logs (:warn,) DVG._vcov_from_hessian(H)
        @test all(isfinite, V)
        @test issymmetric(V)
        # The flat coordinate must not acquire a spurious finite variance.
        @test V[3, 3] == 0
    end

    @testset "near-singular Hessian is treated as singular on every platform" begin
        # cond ~ 1e16: the knife edge where LAPACK may or may not throw.
        H = [39.8 -14.5 0.0 3.8
             -14.5 85.6 0.0 0.4
             0.0 0.0 9.85e-16 0.0
             3.8 0.4 0.0 12.1]
        V = @test_logs (:warn,) DVG._vcov_from_hessian(H)
        @test all(isfinite, V)
        @test V[3, 3] < 1.0   # not the 1e15 a raw inverse would produce
    end

    @testset "regression: NB2 at r → ∞ on Poisson data does not throw" begin
        # The exact fixture from test_variational.jl:105.
        rng = MersenneTwister(1362)
        ng, per = 8, 6
        gidx = repeat(1:ng, inner = per)
        n = ng * per
        x = randn(rng, n)
        Xμ = hcat(ones(n), x)
        Xσ = ones(n, 1)
        β = [0.4, -0.3]; logσb = log(0.5)
        bg = exp(logσb) .* randn(rng, ng)
        y = Float64.([rand(rng, Distributions.Poisson(exp((Xμ * β)[i] + bg[gidx[i]])))
                      for i in 1:n])

        fit_nb = DRM._fit_nb2_ranef_va(DRM.NegBinomial2(), y, Xμ, Xσ, gidx, ng,
                                       ["(Intercept)", "x"], ["(Intercept)"], :g, 1e-8)
        @test all(isfinite, fit_nb.theta)
        @test all(isfinite, fit_nb.vcov)
    end
end
