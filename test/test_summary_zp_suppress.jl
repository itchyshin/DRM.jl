# test_summary_zp_suppress.jl — issues #320 and #323.2.
#
# #320: coeftable / show report z and two-sided p only for blocks whose
# working-scale-zero null is a meaningful hypothesis (:mu/:mu1/:mu2 and :rho12).
# For :sigma/:resd/:recov/:phylocov etc. the zero-on-working-scale null is not the
# scientific null (log σ = 0 ⇔ σ = 1, not σ = 0), so z / p are NaN.
#
# #323.2: a boundary / singular direction (Inf SE) reports NaN z / p in the table,
# not the misleading z = est/Inf = 0, p = 1 that reads as a confident null.
using DRM, Test, Random
import Distributions

@testset "coeftable/show z-p suppression (#320, #323.2)" begin
    @testset "sigma block z/p blanked; mu kept (#320)" begin
        Random.seed!(1)
        n = 300
        x = randn(n)
        y = 0.5 .- 0.8 .* x .+ exp.(-0.3 .+ 0.4 .* x) .* randn(n)
        fit = drm(bf(@formula(y ~ 1 + x), @formula(sigma ~ 1 + x)), Gaussian(); data = (; y, x))
        ct = coeftable(fit)
        z = ct.cols[3]; p = ct.cols[4]
        # Row order: mu:(Intercept), mu:x, sigma:(Intercept), sigma:x.
        @test isfinite(z[1]) && isfinite(z[2])          # mu z present
        @test isfinite(p[1]) && isfinite(p[2])          # mu p present
        @test isnan(z[3]) && isnan(z[4])                # sigma z suppressed
        @test isnan(p[3]) && isnan(p[4])                # sigma p suppressed
        # SEs are still reported for the sigma block (only the test is suppressed).
        @test all(isfinite, ct.cols[2])
        # show() prints NaN for the sigma rows' z/p.
        s = sprint(show, MIME("text/plain"), fit)
        @test occursin("NaN", s)
    end

    @testset "random-effect SD (:resd) z/p blanked (#320)" begin
        Random.seed!(3)
        G = 25; nper = 10; n = G * nper
        g = repeat(1:G, inner = nper); x = randn(n)
        b = 0.7 .* randn(G)
        y = 1.0 .+ 0.5 .* x .+ b[g] .+ 0.4 .* randn(n)
        fit = drm(bf(@formula(y ~ x + (1 | g))), Gaussian(); data = (; y, x, g))
        ct = coeftable(fit)
        # Find the :resd row(s) by row name prefix.
        resd_rows = findall(nm -> startswith(nm, "resd:"), ct.rownms)
        @test !isempty(resd_rows)
        for i in resd_rows
            @test isnan(ct.cols[3][i])                  # z suppressed
            @test isnan(ct.cols[4][i])                  # p suppressed
            @test isfinite(ct.cols[1][i])               # estimate present
        end
        # mu rows keep their z/p.
        mu_rows = findall(nm -> startswith(nm, "mu:"), ct.rownms)
        @test all(isfinite, ct.cols[3][mu_rows])
    end

    @testset "boundary Inf SE -> NaN z/p, not 0/1 (#323.2)" begin
        # Unit-level check of the shared z/p helper: a location block with an Inf SE
        # (singular / boundary direction) must report NaN z and NaN p, NOT z = 0,
        # p = 1 (which reads as a confident non-significant result).
        z, p = DRM._wald_zp(:mu, 0.7, Inf)
        @test isnan(z) && isnan(p)
        # A finite-SE location coefficient still gets a real test.
        z2, p2 = DRM._wald_zp(:mu, 2.0, 1.0)
        @test isfinite(z2) && z2 == 2.0
        @test isfinite(p2) && 0.0 <= p2 <= 1.0
        # A non-testable block (log-sigma) is always NaN regardless of SE.
        @test all(isnan, DRM._wald_zp(:sigma, -0.4, 0.05))
        @test all(isnan, DRM._wald_zp(:resd, 0.7, 0.2))
        @test all(isnan, DRM._wald_zp(:recov, 0.1, 0.3))
        # :rho12 keeps a real test (rho12 = 0 is a meaningful null).
        zr, pr = DRM._wald_zp(:rho12, 0.5, 0.1)
        @test isfinite(zr) && zr == 5.0
    end
end
