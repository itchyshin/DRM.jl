# VA front end (#136): the variational (ELBO) marginal kernels are now reachable
# from the public `drm(bf(...), Fam(); method = :VA)` call. Until this slice the
# `_fit_*_ranef_va` kernels (in src/variational.jl) existed only as internal
# proof-functions, verified directly in test_va_*.jl. Here we check the WIRING:
#
#   (1) Routing is lossless. For each of the five supported families
#       (Poisson, Binomial, NB2, Gamma, Beta) a single random intercept `(1 | g)`
#       under `method = :VA` must produce exactly the same fit (coef + loglik =
#       ELBO) as calling the corresponding `_fit_*_ranef_va` kernel directly. The
#       VA path is deterministic (no RNG, fixed Newton unroll + LBFGS from a fixed
#       start), so this is an exact `==`/`isapprox(...; atol = 0)` identity.
#
#   (2) The VA front-end fit recovers ≈ the Laplace front-end fit. `method = :VA`
#       and the default `method = :LA` on the same `(1 | g)` model must agree on
#       (β, σ_RE, dispersion) within the mean-field-VA tolerances already
#       established in the kernel tests (VA under-shrinks σ_RE slightly).
#
#   (3) `loglik` carries the ELBO. The DrmFit contract is unchanged (same blocks /
#       accessors); only the marginal differs, so the VA loglik is a lower bound
#       and need not equal the Laplace marginal loglik.
#
#   (4) Route-or-reject. `method = :VA` on any model WITHOUT a VA kernel
#       (fixed-effects-only, correlated `(1 + x | g)`, crossed `(1 | g) + (1 | h)`,
#       phylo, `sigma ~ x`) errors clearly rather than silently using Laplace; an
#       unknown `method` symbol is an ArgumentError.
#
# No external truth and no drmTMB call: the direct kernel IS the reference for the
# routing identity, and the Laplace front end is DRM.jl's own verified marginal.

using DRM
using Test
using Random
import Distributions

const DV = DRM   # internal kernels live under DRM.*

@testset "VA marginal through the public drm() front end (#136)" begin

    # ── (a) Poisson (1|g): mean-only, no sigma ────────────────────────────────
    @testset "Poisson: method=:VA routes to _fit_poisson_ranef_va" begin
        rng = MersenneTwister(20260611)
        G = 40; per = 8; n = G * per
        g = repeat(1:G, inner = per); x = randn(rng, n)
        β = [0.3, 0.5]; σb = 0.6
        bg = σb .* randn(rng, G)
        λ = exp.(β[1] .+ β[2] .* x .+ bg[g])
        y = Float64.([rand(rng, Distributions.Poisson(λi)) for λi in λ])
        data = (; y, x, g)

        fit_va = drm(bf(@formula(y ~ x + (1 | g))), Poisson(); data = data, method = :VA)
        fit_la = drm(bf(@formula(y ~ x + (1 | g))), Poisson(); data = data)            # default :LA
        gidx, _ = DV._group_index(g)
        ker = DV._fit_poisson_ranef_va(Poisson(), y, hcat(ones(n), x), gidx, G,
                                       ["(Intercept)", "x"], :g, 1e-8)

        @test is_converged(fit_va)
        # (1) routing identity: public VA fit == direct kernel fit (deterministic)
        @test coef(fit_va) ≈ coef(ker) atol = 1e-10
        @test loglik(fit_va) ≈ loglik(ker) atol = 1e-8
        # (2) recovery vs Laplace front end (same tolerances as the kernel test)
        # Intercept is the least-stable axis between VA and Laplace at finite G:
        # mean-field VA under-shrinks σ_RE, and the intercept absorbs the realized
        # mean of the group effects, so the two marginals agree on it only loosely
        # (cf. the looser intercept tolerances in the kernel + front-end RE tests).
        @test coef(fit_va, :mu)[1] ≈ coef(fit_la, :mu)[1] atol = 0.20
        # The slope is the well-behaved axis — VA matches Laplace tightly there.
        @test coef(fit_va, :mu)[2] ≈ coef(fit_la, :mu)[2] atol = 0.05
        @test re_sd(fit_va)[:g] ≈ re_sd(fit_la)[:g] atol = 0.12
        # …and recovers the truth
        @test coef(fit_va, :mu)[2] ≈ β[2] atol = 0.10
        @test re_sd(fit_va)[:g] ≈ σb atol = 0.20
        # (3) same DrmFit contract: family + finite ELBO loglik
        @test family(fit_va) isa Poisson
        @test isfinite(loglik(fit_va))
    end

    # ── (b) Binomial (1|g): cbind(s, f) response, mean-only ───────────────────
    @testset "Binomial: method=:VA routes to _fit_binomial_ranef_va" begin
        rng = MersenneTwister(20260612)
        G = 60; per = 20; n = G * per
        g = repeat(1:G, inner = per); x = randn(rng, n)
        β = [0.2, 0.6]; σb = 0.6
        bg = σb .* randn(rng, G)
        μ = DV._logistic.(β[1] .+ β[2] .* x .+ bg[g])
        ntr = fill(20, n)
        s = [rand(rng, Distributions.Binomial(ntr[i], μ[i])) for i in 1:n]
        fail = ntr .- s
        data = (; s = Float64.(s), fail = Float64.(fail), x, g)

        fit_va = drm(bf(@formula(cbind(s, fail) ~ x + (1 | g))), Binomial(); data = data, method = :VA)
        fit_la = drm(bf(@formula(cbind(s, fail) ~ x + (1 | g))), Binomial(); data = data)
        gidx, _ = DV._group_index(g)
        ker = DV._fit_binomial_ranef_va(Binomial(), Float64.(s), Float64.(ntr), hcat(ones(n), x),
                                        gidx, G, ["(Intercept)", "x"], :g, 1e-8)

        @test is_converged(fit_va)
        @test coef(fit_va) ≈ coef(ker) atol = 1e-10
        @test loglik(fit_va) ≈ loglik(ker) atol = 1e-8
        # Intercept is the least-stable axis between VA and Laplace at finite G:
        # mean-field VA under-shrinks σ_RE, and the intercept absorbs the realized
        # mean of the group effects, so the two marginals agree on it only loosely
        # (cf. the looser intercept tolerances in the kernel + front-end RE tests).
        @test coef(fit_va, :mu)[1] ≈ coef(fit_la, :mu)[1] atol = 0.20
        # The slope is the well-behaved axis — VA matches Laplace tightly there.
        @test coef(fit_va, :mu)[2] ≈ coef(fit_la, :mu)[2] atol = 0.05
        @test re_sd(fit_va)[:g] ≈ re_sd(fit_la)[:g] atol = 0.12
        @test coef(fit_va, :mu)[2] ≈ β[2] atol = 0.12
        @test family(fit_va) isa Binomial
        @test isfinite(loglik(fit_va))
    end

    # ── (c) NegBinomial2 (1|g): sigma ~ 1 (dispersion) ────────────────────────
    @testset "NB2: method=:VA routes to _fit_nb2_ranef_va" begin
        rng = MersenneTwister(20260613)
        G = 60; per = 15; n = G * per
        g = repeat(1:G, inner = per); x = randn(rng, n)
        β = [0.4, 0.5]; σb = 0.5; θsize = 3.0
        bg = σb .* randn(rng, G)
        μ = exp.(β[1] .+ β[2] .* x .+ bg[g])
        y = Float64.([rand(rng, Distributions.NegativeBinomial(θsize, θsize / (θsize + μ[i]))) for i in 1:n])
        data = (; y, x, g)

        fit_va = drm(bf(@formula(y ~ x + (1 | g)), @formula(sigma ~ 1)), NegBinomial2(); data = data, method = :VA)
        fit_la = drm(bf(@formula(y ~ x + (1 | g)), @formula(sigma ~ 1)), NegBinomial2(); data = data)
        gidx, _ = DV._group_index(g)
        ker = DV._fit_nb2_ranef_va(NegBinomial2(), y, hcat(ones(n), x), ones(n, 1), gidx, G,
                                   ["(Intercept)", "x"], ["(Intercept)"], :g, 1e-8)

        @test is_converged(fit_va)
        @test coef(fit_va) ≈ coef(ker) atol = 1e-10
        @test loglik(fit_va) ≈ loglik(ker) atol = 1e-8
        # Intercept is the least-stable axis between VA and Laplace at finite G:
        # mean-field VA under-shrinks σ_RE, and the intercept absorbs the realized
        # mean of the group effects, so the two marginals agree on it only loosely
        # (cf. the looser intercept tolerances in the kernel + front-end RE tests).
        @test coef(fit_va, :mu)[1] ≈ coef(fit_la, :mu)[1] atol = 0.20
        # The slope is the well-behaved axis — VA matches Laplace tightly there.
        @test coef(fit_va, :mu)[2] ≈ coef(fit_la, :mu)[2] atol = 0.05
        # dispersion θ = exp(coef sigma); compare on the size scale
        θ_va = exp(coef(fit_va, :sigma)[1]); θ_la = exp(coef(fit_la, :sigma)[1])
        @test θ_va ≈ θ_la atol = 0.6
        @test re_sd(fit_va)[:g] ≈ re_sd(fit_la)[:g] atol = 0.12
        @test family(fit_va) isa NegBinomial2
        @test isfinite(loglik(fit_va))
    end

    # ── (d) Gamma (1|g): sigma ~ 1 (shape α = exp(−2·logσ)) ───────────────────
    @testset "Gamma: method=:VA routes to _fit_gamma_ranef_va" begin
        rng = MersenneTwister(20260614)
        G = 60; per = 15; n = G * per
        g = repeat(1:G, inner = per); x = randn(rng, n)
        β = [0.4, 0.5]; σb = 0.5; α = 4.0
        bg = σb .* randn(rng, G)
        μ = exp.(β[1] .+ β[2] .* x .+ bg[g])
        y = Float64.([rand(rng, Distributions.Gamma(α, μ[i] / α)) for i in 1:n])
        data = (; y, x, g)

        fit_va = drm(bf(@formula(y ~ x + (1 | g)), @formula(sigma ~ 1)), Gamma(); data = data, method = :VA)
        fit_la = drm(bf(@formula(y ~ x + (1 | g)), @formula(sigma ~ 1)), Gamma(); data = data)
        gidx, _ = DV._group_index(g)
        ker = DV._fit_gamma_ranef_va(Gamma(), y, hcat(ones(n), x), ones(n, 1), gidx, G,
                                     ["(Intercept)", "x"], ["(Intercept)"], :g, 1e-8)

        @test is_converged(fit_va)
        @test coef(fit_va) ≈ coef(ker) atol = 1e-10
        @test loglik(fit_va) ≈ loglik(ker) atol = 1e-8
        # Intercept is the least-stable axis between VA and Laplace at finite G:
        # mean-field VA under-shrinks σ_RE, and the intercept absorbs the realized
        # mean of the group effects, so the two marginals agree on it only loosely
        # (cf. the looser intercept tolerances in the kernel + front-end RE tests).
        @test coef(fit_va, :mu)[1] ≈ coef(fit_la, :mu)[1] atol = 0.20
        # The slope is the well-behaved axis — VA matches Laplace tightly there.
        @test coef(fit_va, :mu)[2] ≈ coef(fit_la, :mu)[2] atol = 0.05
        α_va = exp(-2 * coef(fit_va, :sigma)[1]); α_la = exp(-2 * coef(fit_la, :sigma)[1])
        @test α_va ≈ α_la atol = 0.6
        @test re_sd(fit_va)[:g] ≈ re_sd(fit_la)[:g] atol = 0.12
        @test family(fit_va) isa Gamma
        @test isfinite(loglik(fit_va))
    end

    # ── (e) Beta (1|g): sigma ~ 1 (precision φ = exp(−2·logσ)) ─────────────────
    @testset "Beta: method=:VA routes to _fit_beta_ranef_va" begin
        rng = MersenneTwister(20260615)
        G = 60; per = 15; n = G * per
        g = repeat(1:G, inner = per); x = randn(rng, n)
        β = [0.3, -0.6]; σb = 0.5; φ = 12.0
        bg = σb .* randn(rng, G)
        μ = DV._logistic.(β[1] .+ β[2] .* x .+ bg[g])
        y = Float64.([rand(rng, Distributions.Beta(μ[i] * φ, (1 - μ[i]) * φ)) for i in 1:n])
        data = (; y, x, g)

        fit_va = drm(bf(@formula(y ~ x + (1 | g)), @formula(sigma ~ 1)), Beta(); data = data, method = :VA)
        fit_la = drm(bf(@formula(y ~ x + (1 | g)), @formula(sigma ~ 1)), Beta(); data = data)
        gidx, _ = DV._group_index(g)
        ker = DV._fit_beta_ranef_va(Beta(), y, hcat(ones(n), x), ones(n, 1), gidx, G,
                                    ["(Intercept)", "x"], ["(Intercept)"], :g, 1e-8)

        @test is_converged(fit_va)
        @test coef(fit_va) ≈ coef(ker) atol = 1e-10
        @test loglik(fit_va) ≈ loglik(ker) atol = 1e-8
        # Intercept is the least-stable axis between VA and Laplace at finite G:
        # mean-field VA under-shrinks σ_RE, and the intercept absorbs the realized
        # mean of the group effects, so the two marginals agree on it only loosely
        # (cf. the looser intercept tolerances in the kernel + front-end RE tests).
        @test coef(fit_va, :mu)[1] ≈ coef(fit_la, :mu)[1] atol = 0.20
        # The slope is the well-behaved axis — VA matches Laplace tightly there.
        @test coef(fit_va, :mu)[2] ≈ coef(fit_la, :mu)[2] atol = 0.05
        φ_va = exp(-2 * coef(fit_va, :sigma)[1]); φ_la = exp(-2 * coef(fit_la, :sigma)[1])
        @test φ_va ≈ φ_la atol = 2.0
        @test re_sd(fit_va)[:g] ≈ re_sd(fit_la)[:g] atol = 0.12
        @test family(fit_va) isa Beta
        @test isfinite(loglik(fit_va))
    end

    # ── (f) Route-or-reject: :VA on unsupported models errors clearly ─────────
    @testset "method=:VA on unsupported models errors" begin
        rng = MersenneTwister(7)
        G = 20; per = 10; n = G * per
        g = repeat(1:G, inner = per); h = repeat(1:G, inner = per)[randperm(rng, n)]
        x = randn(rng, n)
        y = Float64.([rand(rng, Distributions.Poisson(exp(0.3 + 0.5 * xi))) for xi in x])
        data = (; y, x, g, h)

        # fixed-effects-only (no random intercept) under :VA → reject
        @test_throws ArgumentError drm(bf(@formula(y ~ x)), Poisson(); data = data, method = :VA)
        # correlated random slope (1 + x | g) under :VA → reject
        @test_throws ArgumentError drm(bf(@formula(y ~ x + (1 + x | g))), Poisson(); data = data, method = :VA)
        # crossed intercepts (1|g)+(1|h) under :VA → reject
        @test_throws ArgumentError drm(bf(@formula(y ~ x + (1 | g) + (1 | h))), Poisson(); data = data, method = :VA)
        # unknown method symbol → ArgumentError from the resolver
        @test_throws ArgumentError drm(bf(@formula(y ~ x + (1 | g))), Poisson(); data = data, method = :nope)

        # non-intercept dispersion sigma ~ x with a (1|g) RE under :VA → reject
        yg = Float64.([rand(rng, Distributions.Gamma(4.0, exp(0.3 + 0.5 * x[i]) / 4.0)) for i in 1:n])
        dg = (; y = yg, x, g)
        @test_throws ArgumentError drm(bf(@formula(y ~ x + (1 | g)), @formula(sigma ~ x)), Gamma(); data = dg, method = :VA)

        # the SAME unsupported models must still work under the default :LA
        @test is_converged(drm(bf(@formula(y ~ x)), Poisson(); data = data))
        @test is_converged(drm(bf(@formula(y ~ x + (1 | g)), @formula(sigma ~ x)), Gamma(); data = dg))
    end

    # ── (g) Default is unchanged: method=:LA == omitting method ───────────────
    @testset "method=:LA reproduces the default Laplace fit" begin
        rng = MersenneTwister(99)
        G = 40; per = 8; n = G * per
        g = repeat(1:G, inner = per); x = randn(rng, n)
        y = Float64.([rand(rng, Distributions.Poisson(exp(0.3 + 0.5 * x[i] + 0.5 * randn(rng)))) for i in 1:n])
        data = (; y, x, g)
        f_default = drm(bf(@formula(y ~ x + (1 | g))), Poisson(); data = data)
        f_la = drm(bf(@formula(y ~ x + (1 | g))), Poisson(); data = data, method = :LA)
        @test coef(f_default) == coef(f_la)
        @test loglik(f_default) == loglik(f_la)
    end
end
