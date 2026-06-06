# Profile-likelihood CIs for the location–scale fit (#202). Two seed-robust gates:
# (1) for a WELL-IDENTIFIED parameter (the mean slope) the profile CI must agree
# with the Wald CI (the likelihood is near-quadratic there); (2) the profile NLL
# evaluated at an endpoint must sit on the χ²₁ threshold (the defining property),
# confirming the bracket/bisection found the right crossing.
using DRM
using Test, Random, LinearAlgebra, SparseArrays
import Distributions

_nb2_draw_pr(η, ψ) = (r = exp(ψ); μ = exp(η);
                      Float64(rand(Distributions.NegativeBinomial(r, r / (r + μ)))))

@testset "location–scale profile-likelihood CI" begin
    Random.seed!(2718)
    G = 30; m = 25; n = G * m
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

    # Mean slope (idx = 2): well identified ⇒ profile CI ≈ Wald CI.
    ci = DRM._ls_profile_ci(Val(:nb2), y, Xμ, Xψ, species, G, Q, fit.θ; idx = 2, nll_min = nllmin)
    @test ci.lower < fit.θ[2] < ci.upper
    wlo = fit.θ[2] - 1.96 * fit.se[2]
    whi = fit.θ[2] + 1.96 * fit.se[2]
    @test ci.lower ≈ wlo rtol = 0.2
    @test ci.upper ≈ whi rtol = 0.2

    # Defining property: 2·(profile NLL at the endpoint − NLL_min) = χ²₁(0.95).
    chi = Distributions.quantile(Distributions.Chisq(1), 0.95)
    dev_hi = 2 * (DRM._ls_profile_nll(Val(:nb2), y, Xμ, Xψ, species, G, Q, fit.θ, 2, ci.upper) - nllmin)
    @test dev_hi ≈ chi rtol = 1e-2

    # A variance parameter (idx = 4 = log L11) also yields a bracketed CI.
    civ = DRM._ls_profile_ci(Val(:nb2), y, Xμ, Xψ, species, G, Q, fit.θ; idx = 4, nll_min = nllmin)
    @test isfinite(civ.lower) && isfinite(civ.upper)
    @test civ.lower < fit.θ[4] < civ.upper
end
