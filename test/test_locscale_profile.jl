# Profile-likelihood CIs for the location–scale fit (#202). The constrained inner
# solve is a trust-region Newton (robust on boundary steps) and is warm-started +
# Wald-seeded (fast). Gates:
# (1) for the well-identified mean slope the profile CI ≈ the Wald CI (the
#     likelihood is near-quadratic) — and the profile NLL at an endpoint sits on
#     the χ²₁ threshold (the defining property);
# (2) a VARIANCE parameter (log L11) — where Wald is least trustworthy — yields a
#     finite, bracketed CI containing the estimate.
using DRM
using Test, Random, LinearAlgebra, SparseArrays
import Distributions

_nb2_draw_pr(η, ψ) = (r = exp(ψ); μ = exp(η);
                      Float64(rand(Distributions.NegativeBinomial(r, r / (r + μ)))))

@testset "location–scale profile-likelihood CI" begin
    Random.seed!(2718)
    G = 20; m = 20; n = G * m
    species = repeat(1:G, inner = m)
    x = randn(n)
    Λt = [0.25 0.05; 0.05 0.16]
    LΛ = cholesky(Symmetric(Λt)).L
    A = [LΛ * randn(2) for _ in 1:G]
    Xμ = hcat(ones(n), x); Xψ = ones(n, 1)
    y = [_nb2_draw_pr(0.5 + 0.4x[i] + A[species[i]][1], 0.3 + A[species[i]][2]) for i in 1:n]
    Q = sparse(1.0 * I, G, G)

    fit = DRM._fit_locscale(Val(:nb2), y, Xμ, Xψ, species, G, Q; se = true)
    nllmin = fit.nll

    # (1) Mean slope (idx = 2): profile CI ≈ Wald CI, and endpoint on the threshold.
    ci = DRM._ls_profile_ci(Val(:nb2), y, Xμ, Xψ, species, G, Q, fit.θ; idx = 2, nll_min = nllmin)
    @test ci.lower < fit.θ[2] < ci.upper
    @test ci.lower ≈ fit.θ[2] - 1.96 * fit.se[2] rtol = 0.2
    @test ci.upper ≈ fit.θ[2] + 1.96 * fit.se[2] rtol = 0.2
    chi = Distributions.quantile(Distributions.Chisq(1), 0.95)
    dev_hi, _ = DRM._ls_profile_nll(Val(:nb2), y, Xμ, Xψ, species, G, Q, fit.θ, 2, ci.upper)
    @test 2 * (dev_hi - nllmin) ≈ chi rtol = 1e-2

    # (2) Variance parameter (idx = 4 = log L11): finite bracketed CI.
    civ = DRM._ls_profile_ci(Val(:nb2), y, Xμ, Xψ, species, G, Q, fit.θ; idx = 4, nll_min = nllmin)
    @test isfinite(civ.lower) && isfinite(civ.upper)
    @test civ.lower < fit.θ[4] < civ.upper
end

# Public-API surface: confint(:profile) on a drm()-fitted location–scale model
# routes to the robust profiler (#202, #209 item 2). The DrmFit covariance block
# is in :recov order; the router permutes to the engine packing — so the per-
# coefficient CIs must line up with the right parameters.
@testset "location–scale profile CI via public confint(:profile)" begin
    Random.seed!(2026)
    G = 25; m = 25; n = G * m
    species = repeat(1:G, inner = m)
    x = randn(n)
    Λt = [0.25 0.05; 0.05 0.16]
    LΛ = cholesky(Symmetric(Λt)).L
    A = [LΛ * randn(2) for _ in 1:G]
    y = [_nb2_draw_pr(0.5 + 0.4x[i] + A[species[i]][1], 0.3 + 0.2x[i] + A[species[i]][2])
         for i in 1:n]
    data = (; y, x, species)
    fit = drm(bf(@formula(y ~ x + (1 | p | species)),
                 @formula(sigma ~ x + (1 | p | species))), NegBinomial2(); data = data)

    wald = confint(fit)                                   # :wald (all coefs)
    # Profile the well-identified MEAN block. (Profiling a variance/covariance
    # parameter toward its boundary can drive Λ near-singular so the prior
    # factorisation fails; the marginal now returns its `ok = false` infeasible
    # flag there instead of throwing, but hardening the profiler's gradient/Hessian
    # callbacks for that regime is a follow-up — see PR. The mean block is the
    # common confint(:profile) use case and is well-conditioned.)
    prof = confint(fit; method = :profile, parm = :mu)
    waldmu = [r for r in wald if r.param === :mu]
    @test !isempty(prof) && all(r -> r.param === :mu, prof)
    @test length(prof) == length(waldmu)
    @test all(r -> r.lower ≤ r.estimate ≤ r.upper, prof)

    # Well-identified mean slope: profile ≈ Wald (near-quadratic likelihood).
    pslope = first(r for r in prof if r.coef == "x")
    wslope = first(r for r in waldmu if r.coef == "x")
    @test pslope.lower < pslope.estimate < pslope.upper
    @test pslope.lower ≈ wslope.lower rtol = 0.35
    @test pslope.upper ≈ wslope.upper rtol = 0.35

    # profile_result audit surface reports the locscale backend.
    res = profile_result(fit; parm = :mu)
    @test res.autodiff === :locscale
    @test res.attempted == length(prof)
    @test [r.coef for r in res.ci] == [r.coef for r in prof]

    # check_drm reports a real gradient norm for the location–scale fit
    # (exact analytic gradient; ForwardDiff can't pierce the Float64 inner solve).
    rep = check_drm(fit)
    @test isfinite(rep.max_abs_grad)
end
