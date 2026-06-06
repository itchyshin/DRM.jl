# End-to-end fit for the non-Gaussian location–scale model (#202 groundwork).
# SMOKE level: verifies the fitter runs end to end on NB2 data with a shared
# random effect on BOTH the mean and the log-dispersion axis — for i.i.d. groups
# and for a phylogenetic tree — and returns sane output (finite marginal, a valid
# 2×2 covariance, a sensible mean slope from the well-identified mean axis).
#
# Why smoke and not recovery: the outer optimiser here uses a finite-difference
# gradient of the (inner-solved) Laplace marginal, which is too noisy/slow for
# trustworthy variance-component recovery. Tight recovery waits on the exact O(p)
# outer gradient (Takahashi) slice; marginal accuracy is already pinned by the
# marginal-vs-Gauss–Hermite gate.
using DRM
using Test, Random, LinearAlgebra, SparseArrays
import Distributions

_nb2_draw(η, ψ) = (r = exp(ψ); μ = exp(η);
                   Float64(rand(Distributions.NegativeBinomial(r, r / (r + μ)))))

@testset "location–scale fit: i.i.d. groups (NB2) end-to-end smoke" begin
    Random.seed!(20260606)
    p = 6; m = 10; n = p * m
    Λtrue = [0.25 0.05; 0.05 0.16]
    LΛ = cholesky(Symmetric(Λtrue)).L
    A = randn(p, 2) * LΛ'
    species = repeat(1:p, inner = m)
    x = randn(n)
    βμ = [0.2, 0.4]; βψ = [0.3]
    Xμ = hcat(ones(n), x); Xψ = ones(n, 1)
    y = [_nb2_draw(βμ[1] + βμ[2] * x[i] + A[species[i], 1],
                   βψ[1] + A[species[i], 2]) for i in 1:n]

    Q = sparse(1.0 * I, p, p)
    fit = DRM._fit_locscale(Val(:nb2), y, Xμ, Xψ, species, p, Q)

    @test isfinite(fit.nll)                        # inner solves succeeded throughout
    @test isposdef(Symmetric(fit.Lambda))          # valid group-level covariance
    @test size(fit.Lambda) == (2, 2)
    @test all(isfinite, fit.beta_mu) && isfinite(fit.beta_psi[1])
    @test fit.converged isa Bool
    # NB: tight parameter recovery is intentionally NOT asserted here — it waits
    # on the exact O(p) outer gradient slice (see the PR notes).
end

@testset "location–scale fit: phylogenetic tree (NB2) end-to-end smoke" begin
    Random.seed!(20260607)
    p = 6; m = 8; n = p * m
    phy = random_balanced_tree(p; branch_length = 0.25)
    C = sigma_phy_dense(phy; σ²_phy = 1.0)
    LC = cholesky(Symmetric(C)).L
    Λtrue = [0.30 0.0; 0.0 0.20]
    LΛ = cholesky(Symmetric(Λtrue)).L
    A = LC * randn(p, 2) * LΛ'
    species = repeat(1:p, inner = m)
    x = randn(n)
    βμ = [0.15, 0.4]; βψ = [0.2]
    Xμ = hcat(ones(n), x); Xψ = ones(n, 1)
    y = [_nb2_draw(βμ[1] + βμ[2] * x[i] + A[species[i], 1],
                   βψ[1] + A[species[i], 2]) for i in 1:n]

    Q, gidx, G = DRM._locscale_phylo_setup(phy, species)
    fit = DRM._fit_locscale(Val(:nb2), y, Xμ, Xψ, gidx, G, Q)

    @test isfinite(fit.nll)                        # phylo precision path runs end-to-end
    @test isposdef(Symmetric(fit.Lambda))
    @test all(isfinite, fit.beta_mu) && isfinite(fit.beta_psi[1])
end

# With the exact gradient now driving an LBFGS fit, we can assert real
# convergence and parameter recovery (deferred at the smoke stage). The
# stationarity check is seed-robust: the optimiser must have driven the EXACT
# analytic gradient to ~0. Recovery tolerances are generous (single seed).
@testset "location–scale fit: gradient-based convergence + recovery (NB2)" begin
    Random.seed!(424242)
    G = 50; m = 35; n = G * m
    species = repeat(1:G, inner = m)
    x = randn(n)
    βμ = [0.5, 0.4]; βψ = [0.3]
    Λtrue = [0.25 0.05; 0.05 0.16]                  # sd_μ = 0.5, sd_ψ = 0.4
    LΛ = cholesky(Symmetric(Λtrue)).L
    A = [LΛ * randn(2) for _ in 1:G]
    Xμ = hcat(ones(n), x); Xψ = ones(n, 1)
    y = [_nb2_draw(βμ[1] + βμ[2] * x[i] + A[species[i]][1],
                   βψ[1] + A[species[i]][2]) for i in 1:n]
    Q = sparse(1.0 * I, G, G)
    fit = DRM._fit_locscale(Val(:nb2), y, Xμ, Xψ, species, G, Q)

    gmax = maximum(abs.(DRM._ls_marginal_grad(Val(:nb2), y, Xμ, Xψ, species, G, Q, fit.θ)))
    @test gmax < 1e-3                               # stationarity of the exact gradient (convergence evidence)
    @test fit.beta_mu[1] ≈ 0.5 atol = 0.2
    @test fit.beta_mu[2] ≈ 0.4 atol = 0.1
    @test fit.beta_psi[1] ≈ 0.3 atol = 0.25
    @test sqrt(fit.Lambda[1, 1]) ≈ 0.5 rtol = 0.3   # mean-axis RE SD
    @test sqrt(fit.Lambda[2, 2]) ≈ 0.4 rtol = 0.45  # scale-axis RE SD (harder)
end
