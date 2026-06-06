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

    @test isfinite(fit.nll)
    @test isposdef(Symmetric(fit.Lambda))         # valid group-level covariance
    @test size(fit.Lambda) == (2, 2)
    @test fit.beta_mu[2] ≈ 0.4 atol = 0.3          # mean slope is well identified
    @test fit.converged isa Bool
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

    @test isfinite(fit.nll)
    @test isposdef(Symmetric(fit.Lambda))
    @test fit.beta_mu[2] ≈ 0.4 atol = 0.35        # mean slope, loose
end
