# End-to-end PHYLOGENETIC location–scale fit + inference (#202, #209). Earlier
# this stalled (slow, gmax≥1e-3, non-finite SEs) because the cold inner solves
# were slow and LBFGS converged only linearly on the ill-conditioned tree. The
# fix: warm-start the inner mode + a trust-region Newton outer optimiser. This
# test now asserts real convergence (stationarity of the EXACT gradient through
# the tree precision + Takahashi) and finite Wald SEs.
using DRM
using Test, Random, LinearAlgebra, SparseArrays
import Distributions

_nb2_draw_p(η, ψ) = (r = exp(ψ); μ = exp(η);
                     Float64(rand(Distributions.NegativeBinomial(r, r / (r + μ)))))

@testset "phylogenetic location–scale: end-to-end fit + inference (NB2)" begin
    Random.seed!(606)
    p = 20; m = 15; n = p * m
    phy = random_balanced_tree(p; branch_length = 0.3)
    C = sigma_phy_dense(phy; σ²_phy = 1.0)
    LC = cholesky(Symmetric(C)).L
    Λtrue = [0.30 0.04; 0.04 0.18]
    LΛ = cholesky(Symmetric(Λtrue)).L
    A = LC * randn(p, 2) * LΛ'                 # phylo-correlated species effects
    species = repeat(1:p, inner = m)
    x = randn(n)
    Xμ = hcat(ones(n), x); Xψ = ones(n, 1)
    y = [_nb2_draw_p(0.2 + 0.4x[i] + A[species[i], 1], 0.3 + A[species[i], 2]) for i in 1:n]

    Q, gidx, G = DRM._locscale_phylo_setup(phy, species)
    fit = DRM._fit_locscale(Val(:nb2), y, Xμ, Xψ, gidx, G, Q; se = true)

    gmax = maximum(abs.(DRM._ls_marginal_grad(Val(:nb2), y, Xμ, Xψ, gidx, G, Q, fit.θ)))
    @test gmax < 1e-3                          # converged through the tree precision + Takahashi
    @test isposdef(Symmetric(fit.Lambda))
    @test fit.vcov !== nothing
    @test all(isfinite, fit.se)                # observed information is PD at the optimum
    @test fit.components.sd_mu ≈ sqrt(fit.Lambda[1, 1])
    @test fit.beta_mu[2] ≈ 0.4 atol = 0.2      # mean slope (loose, single seed)
end
