# End-to-end fit for the non-Gaussian location–scale model (#202 groundwork).
# Simulates NB2 data with a shared random effect on BOTH the mean and the
# log-dispersion axis and checks the fitter recovers the fixed effects and the
# group-level covariance — for i.i.d. groups and for a phylogenetic tree.
#
# Gating philosophy: Laplace recovers the mean axis well, so βμ and the mean-axis
# SD are checked tightly; the scale-axis variance carries known Laplace bias
# (cf. #136), so it is only required to be estimated and positive here (its
# numerical accuracy is pinned separately by the marginal-vs-GHQ test).
using DRM
using Test, Random, LinearAlgebra, SparseArrays
import Distributions

_nb2_draw(η, ψ) = (r = exp(ψ); μ = exp(η);
                   Float64(rand(Distributions.NegativeBinomial(r, r / (r + μ)))))

@testset "location–scale fit: i.i.d. groups (NB2) recovery" begin
    Random.seed!(20260606)
    p = 20; m = 25; n = p * m
    Λtrue = [0.25 0.06; 0.06 0.16]              # σμ = 0.5, σψ = 0.4, ρ ≈ 0.30
    LΛ = cholesky(Symmetric(Λtrue)).L
    A = randn(p, 2) * LΛ'                        # rows iid N(0, Λ)
    species = repeat(1:p, inner = m)
    x = randn(n)
    βμ = [0.2, 0.4]; βψ = [0.3]
    Xμ = hcat(ones(n), x); Xψ = ones(n, 1)
    y = [_nb2_draw(βμ[1] + βμ[2] * x[i] + A[species[i], 1],
                   βψ[1] + A[species[i], 2]) for i in 1:n]

    Q = sparse(1.0 * I, p, p)
    fit = DRM._fit_locscale(Val(:nb2), y, Xμ, Xψ, species, p, Q)

    @test isfinite(fit.nll)
    @test fit.beta_mu[2] ≈ 0.4 atol = 0.15        # slope (mean axis)
    @test sqrt(fit.Lambda[1, 1]) ≈ 0.5 atol = 0.2  # mean-axis SD
    @test 0.1 < sqrt(fit.Lambda[2, 2]) < 1.2       # scale-axis SD: estimated, sane
end

@testset "location–scale fit: phylogenetic tree (NB2)" begin
    Random.seed!(20260607)
    p = 16; m = 12; n = p * m
    phy = random_balanced_tree(p; branch_length = 0.25)
    C = sigma_phy_dense(phy; σ²_phy = 1.0)         # leaf covariance consistent with Q
    LC = cholesky(Symmetric(C)).L
    Λtrue = [0.30 0.0; 0.0 0.20]                   # diagonal: σμ ≈ 0.55, σψ ≈ 0.45
    LΛ = cholesky(Symmetric(Λtrue)).L
    A = LC * randn(p, 2) * LΛ'                      # Cov(A[s,k],A[s',k']) = C[s,s']·Λ[k,k']
    species = repeat(1:p, inner = m)
    x = randn(n)
    βμ = [0.15, 0.4]; βψ = [0.2]
    Xμ = hcat(ones(n), x); Xψ = ones(n, 1)
    y = [_nb2_draw(βμ[1] + βμ[2] * x[i] + A[species[i], 1],
                   βψ[1] + A[species[i], 2]) for i in 1:n]

    Q, gidx, G = DRM._locscale_phylo_setup(phy, species)
    fit = DRM._fit_locscale(Val(:nb2), y, Xμ, Xψ, gidx, G, Q)

    @test isfinite(fit.nll)
    @test fit.beta_mu[2] ≈ 0.4 atol = 0.2          # slope (mean axis)
    @test sqrt(fit.Lambda[1, 1]) > 0.2             # mean-axis phylo SD detected
    @test fit.Lambda[2, 2] > 0.005                 # scale-axis variance positive
end
