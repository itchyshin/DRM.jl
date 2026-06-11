# Public `drm()` routing for the non-Gaussian location–scale model (#202, 3b).
# The drmTMB/brms-style coupled tag `(1 | p | species)` shared by the mean and
# sigma formulas must route to the augmented-state engine and produce a DrmFit
# whose coefficients/Λ match a direct `_fit_locscale` call (parity), with a
# working summary and `vc` accessor.
using DRM
using Test, Random, LinearAlgebra, SparseArrays
import Distributions

_nb2_draw_f(η, ψ) = (r = exp(ψ); μ = exp(η);
                     Float64(rand(Distributions.NegativeBinomial(r, r / (r + μ)))))

@testset "drm() location–scale routing via (1|p|group)" begin
    Random.seed!(2026)
    G = 25; m = 25; n = G * m
    species = repeat(1:G, inner = m)
    x = randn(n)
    Λt = [0.25 0.05; 0.05 0.16]
    LΛ = cholesky(Symmetric(Λt)).L
    A = [LΛ * randn(2) for _ in 1:G]
    y = [_nb2_draw_f(0.5 + 0.4x[i] + A[species[i]][1], 0.3 + 0.2x[i] + A[species[i]][2])
         for i in 1:n]
    data = (; y, x, species)

    fit = drm(bf(@formula(y ~ x + (1 | p | species)),
                 @formula(sigma ~ x + (1 | p | species))), NegBinomial2(); data = data)

    # Parity with a direct engine call on the same design.
    Xμ = hcat(ones(n), x); Xψ = hcat(ones(n), x)
    gidx, Gd = DRM._group_index(species)
    Q = sparse(1.0 * I, Gd, Gd)
    # match the drm() default g_tol (NegBinomial2 uses 1e-8) so the fits coincide
    direct = DRM._fit_locscale(Val(:nb2), Float64.(y), Xμ, Xψ, gidx, Gd, Q; g_tol = 1e-8, se = true)

    @test coef(fit, :mu) ≈ direct.beta_mu rtol = 1e-6
    @test coef(fit, :sigma) ≈ direct.beta_psi rtol = 1e-6
    @test DRM.vc(fit)[:species] ≈ direct.Lambda rtol = 1e-6
    @test nobs(fit) == n
    @test isfinite(loglik(fit))
    @test all(isfinite, stderror(fit))

    # Summary renders, including the group-level covariance block.
    s = sprint(show, MIME("text/plain"), fit)
    @test occursin("Random-effect covariance", s)

    # Public Wald inference surface works end-to-end (mirrors drmTMB's confint).
    ci = confint(fit)                                  # method = :wald
    @test !isempty(ci)
    slope = first(r for r in ci if r.param === :mu && r.coef == "x")
    @test slope.lower < slope.estimate < slope.upper
    @test summary(fit) isa typeof(coeftable(fit))      # coeftable/summary build cleanly
end

@testset "drm() location–scale: a lone coupled tag is an error" begin
    Random.seed!(11)
    n = 60; x = randn(n); species = repeat(1:6, inner = 10)
    y = Float64.(rand(0:5, n))
    data = (; y, x, species)
    # Coupled tag on the mean only → must error (no partner on sigma).
    @test_throws Exception drm(bf(@formula(y ~ x + (1 | p | species)),
                                  @formula(sigma ~ x)), NegBinomial2(); data = data)
end

# Build a unit-diagonal exponential-kernel correlation among `G` levels (a
# non-tree relatedness/spatial matrix), the established structured-cov idiom.
function _ls_fe_corr(rng, G; range = 0.8, jitter = 1e-8)
    pos = rand(rng, G, 2) .* 6.0
    D = [sqrt(sum(abs2, pos[k, :] .- pos[l, :])) for k in 1:G, l in 1:G]
    C = exp.(-D ./ range) + jitter * I
    d = sqrt.(diag(C))
    return Symmetric(C ./ (d * d'))
end

@testset "drm() location–scale: Beta + BetaBinomial coupled (1|p|g)" begin
    Random.seed!(515)
    G = 30; m = 22; n = G * m
    g = repeat(1:G, inner = m); x = randn(n)
    Λt = [0.22 0.04; 0.04 0.14]; LΛ = cholesky(Symmetric(Λt)).L
    A = [LΛ * randn(2) for _ in 1:G]

    # Beta: logit mean + log-σ axes, both carrying the coupled intercept RE.
    yβ = Float64[]
    for i in 1:n
        μ = 1 / (1 + exp(-(0.0 + 0.4x[i] + A[g[i]][1])))
        φ = exp(-2 * (-0.4 + A[g[i]][2]))
        push!(yβ, clamp(rand(Distributions.Beta(μ * φ, (1 - μ) * φ)), 1e-7, 1 - 1e-7))
    end
    dβ = (; y = yβ, x, g)
    fitβ = drm(bf(@formula(y ~ x + (1 | p | g)), @formula(sigma ~ 1 + (1 | p | g))),
               Beta(); data = dβ, se = true)
    # Parity with a direct engine call on the same design.
    Xμ = hcat(ones(n), x); Xψ = ones(n, 1)
    gidx, Gd = DRM._group_index(g); Q = sparse(1.0 * I, Gd, Gd)
    dirβ = DRM._fit_locscale(Val(:beta), yβ, Xμ, Xψ, gidx, Gd, Q; g_tol = 1e-8, se = true)
    @test coef(fitβ, :mu) ≈ dirβ.beta_mu rtol = 1e-5
    @test coef(fitβ, :sigma) ≈ dirβ.beta_psi rtol = 1e-5
    @test DRM.vc(fitβ)[:g] ≈ dirβ.Lambda rtol = 1e-5
    @test isposdef(Symmetric(DRM.vc(fitβ)[:g]))
    @test coef(fitβ, :mu)[2] ≈ 0.4 atol = 0.15        # mean slope recovered
    @test isfinite(loglik(fitβ))

    # BetaBinomial: two-column cbind response, same coupled structure.
    ntr = 30; s = Int[]; fl = Int[]
    for i in 1:n
        μ = 1 / (1 + exp(-(0.0 + 0.4x[i] + A[g[i]][1])))
        φ = exp(-2 * (-0.4 + A[g[i]][2]))
        si = rand(Distributions.BetaBinomial(ntr, μ * φ, (1 - μ) * φ))
        push!(s, si); push!(fl, ntr - si)
    end
    dbb = (; s, fl, x, g)
    fitbb = drm(bf(@formula(cbind(s, fl) ~ x + (1 | p | g)), @formula(sigma ~ 1 + (1 | p | g))),
                BetaBinomial(); data = dbb, se = true)
    ybb = [(Float64(s[i]), Float64(s[i] + fl[i])) for i in 1:n]
    dirbb = DRM._fit_locscale(Val(:betabinomial), ybb, Xμ, Xψ, gidx, Gd, Q; g_tol = 1e-8, se = true)
    @test coef(fitbb, :mu) ≈ dirbb.beta_mu rtol = 1e-5
    @test coef(fitbb, :sigma) ≈ dirbb.beta_psi rtol = 1e-5
    @test DRM.vc(fitbb)[:g] ≈ dirbb.Lambda rtol = 1e-5
    @test coef(fitbb, :mu)[2] ≈ 0.4 atol = 0.15
    @test isfinite(loglik(fitbb))
end

@testset "drm() location–scale: structured coupled (1|p|relmat(g))" begin
    Random.seed!(626)
    G = 60; m = 22; n = G * m
    id = repeat(1:G, inner = m); x = randn(n)
    C = _ls_fe_corr(MersenneTwister(7), G); LC = cholesky(C).L
    Λt = [0.25 0.05; 0.05 0.16]; LΛ = cholesky(Symmetric(Λt)).L
    Av = LC * randn(G, 2) * LΛ'

    # NB2 through the public structured route: the coupled group wears a relmat
    # marker, so the group covariance is C⁻¹ (not i.i.d.). `K = C` supplies it.
    y = [_nb2_draw_f(0.4 + 0.4x[i] + Av[id[i], 1], 0.2 + Av[id[i], 2]) for i in 1:n]
    data = (; y, x, id)
    fit = drm(bf(@formula(y ~ x + (1 | p | relmat(id))),
                 @formula(sigma ~ 1 + (1 | p | relmat(id)))),
              NegBinomial2(); data = data, K = C, se = false)
    # Parity with a direct engine call through `_locscale_relmat_setup`.
    Xμ = hcat(ones(n), x); Xψ = ones(n, 1)
    Q, gidx, Gd = DRM._locscale_relmat_setup(C, id)
    direct = DRM._fit_locscale(Val(:nb2), Float64.(y), Xμ, Xψ, gidx, Gd, Q; g_tol = 1e-8, se = false)
    @test coef(fit, :mu) ≈ direct.beta_mu rtol = 1e-5
    @test coef(fit, :sigma) ≈ direct.beta_psi rtol = 1e-5
    @test DRM.vc(fit)[:id] ≈ direct.Lambda rtol = 1e-5
    @test coef(fit, :mu)[2] ≈ 0.4 atol = 0.12          # mean slope through C⁻¹
    @test isposdef(Symmetric(DRM.vc(fit)[:id]))

    # A relmat coupled group with no `K` supplied is an error (mirrors the
    # mean-only relmat route).
    @test_throws Exception drm(bf(@formula(y ~ x + (1 | p | relmat(id))),
                                  @formula(sigma ~ 1 + (1 | p | relmat(id)))),
                               NegBinomial2(); data = data, se = false)
end
